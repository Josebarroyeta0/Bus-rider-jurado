import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firestore_service.dart';

class DenunciaFormScreen extends StatefulWidget {
  const DenunciaFormScreen({super.key});

  @override
  State<DenunciaFormScreen> createState() => _DenunciaFormScreenState();
}

class _DenunciaFormScreenState extends State<DenunciaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _busPlacaController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _loading = false;

  @override
  void dispose() {
    _busPlacaController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = picked.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _loading = true);

    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase no está disponible. Intenta nuevamente más tarde.')),
      );
      setState(() => _loading = false);
      return;
    }

    final busPlaca = _busPlacaController.text.trim();
    final description = _descriptionController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email') ?? 'anónimo';

    String? photoUrl;
    String? photoBase64;
    try {
      if (_selectedImageBytes != null && _selectedImageName != null) {
        final bytes = _selectedImageBytes!;
        try {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            final resized = img.copyResize(decoded, width: 600);
            final jpg = img.encodeJpg(resized, quality: 72);
            photoBase64 = base64Encode(jpg);
          } else {
            photoBase64 = base64Encode(bytes);
          }
        } catch (_) {
          photoBase64 = base64Encode(bytes);
        }

        if (Firebase.apps.isNotEmpty && !kIsWeb) {
          final safeName = _selectedImageName!.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
          try {
            photoUrl = await FirestoreService.instance.uploadDenunciaPhoto(userEmail, bytes, safeName);
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No se pudo subir la imagen a Storage, se guardará sólo la miniatura: $error')),
              );
            }
            photoUrl = null;
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('En Web no se sube la imagen a Storage; se guardará una miniatura en la base de datos.')),
            );
          }
          photoUrl = null;
        }
      }

      await FirestoreService.instance.addDenuncia(
        busPlaca,
        description,
        userEmail,
        photoUrl: photoUrl,
        photoBase64: photoBase64,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu denuncia se envió con éxito.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar denuncia: $e')),
      );
      setState(() => _loading = false);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Denuncia de irregularidad'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Denuncia de irregularidad',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Comparte la placa del bus, describe lo que sucedió y adjunta una foto si es posible. Las imágenes se guardan en Storage para no cargar la base de datos.',
                    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _busPlacaController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Placa del bus',
                      hintText: 'Ej. ABC-1234',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa la placa del bus';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 5,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: 'Descripción del problema',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Describe el problema';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Adjuntar foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (_selectedImageBytes != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Image.memory(
                            _selectedImageBytes!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enviar denuncia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
