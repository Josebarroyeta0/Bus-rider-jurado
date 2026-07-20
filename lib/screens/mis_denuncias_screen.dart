import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/firestore_service.dart';

class MisDenunciasScreen extends StatefulWidget {
  const MisDenunciasScreen({super.key});

  @override
  State<MisDenunciasScreen> createState() => _MisDenunciasScreenState();
}

class _MisDenunciasScreenState extends State<MisDenunciasScreen> {
  Future<String?> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis denuncias'),
      ),
      body: FutureBuilder<String?>(
        future: _loadUserEmail(),
        builder: (context, emailSnapshot) {
          if (emailSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userEmail = emailSnapshot.data;
          if (userEmail == null || userEmail.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'No se encontró el correo de usuario. Vuelve a iniciar sesión para ver tus denuncias.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            );
          }

          return StreamBuilder<List<Denuncia>>(
            stream: FirestoreService.instance.userDenunciasStream(userEmail),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Error al cargar tus denuncias: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final denuncias = snapshot.data ?? [];
              if (denuncias.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.report_problem_outlined, size: 72, color: Colors.grey),
                      SizedBox(height: 14),
                      Text('Aún no has enviado ninguna denuncia.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      SizedBox(height: 8),
                      Text('Envía una denuncia desde el inicio para ver su estado aquí.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black45)),
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
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
                                  color: denuncia.status == 'pendiente'
                                      ? const Color(0xFFFFF4DB)
                                      : denuncia.status == 'revisada'
                                          ? const Color(0xFFD1FAE5)
                                          : const Color(0xFFD1D4FF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  denuncia.status.toUpperCase(),
                                  style: TextStyle(
                                    color: denuncia.status == 'pendiente'
                                        ? const Color(0xFF92400E)
                                        : denuncia.status == 'revisada'
                                            ? const Color(0xFF166534)
                                            : const Color(0xFF4338CA),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Enviado: $timestampText', style: const TextStyle(fontSize: 12, color: Colors.black45)),
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
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
