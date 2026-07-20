import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/firestore_service.dart';

class DenunciaAdminScreen extends StatefulWidget {
  const DenunciaAdminScreen({super.key});

  @override
  State<DenunciaAdminScreen> createState() => _DenunciaAdminScreenState();
}

class _DenunciaAdminScreenState extends State<DenunciaAdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Denuncias de usuarios'),
      ),
      body: StreamBuilder<List<Denuncia>>(
        stream: FirestoreService.instance.denunciasStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final denuncias = snapshot.data ?? [];
          if (denuncias.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.report_gmailerrorred_outlined, size: 78, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No hay denuncias registradas.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemCount: denuncias.length,
            itemBuilder: (context, index) {
              final denuncia = denuncias[index];
              final timestampText = denuncia.timestamp != null ? '${denuncia.timestamp!.toLocal()}'.split('.').first : 'Fecha no disponible';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Placa ${denuncia.busPlaca}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: denuncia.status == 'pendiente' ? const Color(0xFFFFF4DB) : denuncia.status == 'revisada' ? const Color(0xFFD1FAE5) : const Color(0xFFD1D4FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              denuncia.status.toUpperCase(),
                              style: TextStyle(
                                color: denuncia.status == 'pendiente' ? const Color(0xFF92400E) : denuncia.status == 'revisada' ? const Color(0xFF166534) : const Color(0xFF4338CA),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Reporte por: ${denuncia.submittedBy}', style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                      Text(denuncia.description, style: const TextStyle(fontSize: 14, height: 1.45)),
                      if (denuncia.photoUrl != null || denuncia.photoBase64 != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: denuncia.photoUrl != null
                              ? Image.network(
                                  denuncia.photoUrl!,
                                  fit: BoxFit.cover,
                                  height: 180,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 180,
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Text('No se pudo cargar la imagen', style: TextStyle(color: Colors.redAccent)),
                                    );
                                  },
                                )
                              : Image.memory(
                                  base64Decode(denuncia.photoBase64!),
                                  fit: BoxFit.cover,
                                  height: 180,
                                ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(timestampText, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                          Wrap(
                            spacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: denuncia.status == 'resuelta' ? null : () => _updateStatus(denuncia.id, 'resuelta'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D4ED8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Marcar resuelta'),
                              ),
                              OutlinedButton(
                                onPressed: denuncia.status == 'revisada' || denuncia.status == 'resuelta'
                                    ? null
                                    : () => _updateStatus(denuncia.id, 'revisada'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1D4ED8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Marcar revisada'),
                              ),
                              OutlinedButton(
                                onPressed: () => _confirmDelete(denuncia.id),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade700),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await FirestoreService.instance.updateDenunciaStatus(id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Denuncia marcada como $status.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo actualizar el estado: $e')));
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar denuncia'),
          content: const Text('¿Deseas eliminar esta denuncia? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirestoreService.instance.deleteDenuncia(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Denuncia eliminada.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar la denuncia: $e')));
    }
  }
}
