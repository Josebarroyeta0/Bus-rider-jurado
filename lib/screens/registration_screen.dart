// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _submitting = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<List<Map<String, dynamic>>> _loadRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('registered_users');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveRegisteredUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registered_users', jsonEncode(users));
  }

  bool _validateCI(String ci) {
    return RegExp(r'^[0-9]{6,12}$').hasMatch(ci);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final ci = _ciController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final users = await _loadRegisteredUsers();
    final emailUsed = users.any((u) => u['email'] == email) || email == 'passenger@test.com' || email == 'admin@test.com';
    if (emailUsed) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ya existe una cuenta con ese correo.')));
      return;
    }

    users.add({
      'nombre': nombre,
      'apellido': apellido,
      'ci': ci,
      'email': email,
      'password': password,
    });
    final dialogContext = context;
    await _saveRegisteredUsers(users);

    if (!mounted) return;
    setState(() => _submitting = false);
    await showDialog<void>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text('Cuenta creada'),
        content: Text('Su cuenta ha sido registrada correctamente. Ahora puede iniciar sesión.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('OK')),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(dialogContext);
  }

  @override
  Widget build(BuildContext context) {
    // Paleta de colores consistente con la referencia visual
    const primaryBlue = Color(0xFF007BFF);
    const textDark = Color(0xFF333333);
    const textMuted = Color(0xFF9E9E9E);
    const borderGrey = Color(0xFFCCCCCC);

    // Estilo base reutilizable para los inputs circulares de la referencia
    final inputDecorationStyle = InputDecoration(
      hintStyle: const TextStyle(color: textMuted, fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: borderGrey, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Atrás', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Avatar Circular Superior de Referencia
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryBlue,
                      border: Border.all(color: borderGrey.withOpacity(0.6), width: 6),
                    ),
                    child: const Icon(Icons.person, size: 65, color: Colors.white),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 2. Título Central con Líneas Horizontales Laterales (CREATE NEW ACCOUNT)
                Row(
                  children: [
                    const Expanded(child: Divider(color: borderGrey, thickness: 1.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'Crear nueva cuenta',
                        style: TextStyle(
                          fontSize: 16, 
                          color: primaryBlue.withOpacity(0.9), 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: borderGrey, thickness: 1.5)),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // 3. Fila Doble: Nombre y Apellido (Como "Name" y "Surname")
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nombreController,
                        style: const TextStyle(color: textDark),
                        decoration: inputDecorationStyle.copyWith(hintText: 'Nombre'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _apellidoController,
                        style: const TextStyle(color: textDark),
                        decoration: inputDecorationStyle.copyWith(hintText: 'Apellido'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),
                
                // 4. Campo Único Adaptado para la Cédula (con estilo visual de la referencia)
                TextFormField(
                  controller: _ciController,
                  style: const TextStyle(color: textDark),
                  keyboardType: TextInputType.number,
                  decoration: inputDecorationStyle.copyWith(hintText: 'Cédula de identidad'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Requerido';
                    if (!_validateCI(value.trim())) return 'Cédula inválida';
                    return null;
                  },
                ),
                
                const SizedBox(height: 14),
                
                // 5. Campo de Correo Electrónico (Como "Email")
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: textDark),
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecorationStyle.copyWith(hintText: 'Correo electrónico'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Requerido';
                    final email = value.trim();
                    if (!email.contains('@') || !email.contains('.')) return 'Email inválido';
                    return null;
                  },
                ),
                
                const SizedBox(height: 14),
                
                // 6. Campo de Contraseña (Como "Login/Password")
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  style: const TextStyle(color: textDark),
                  decoration: inputDecorationStyle.copyWith(
                    hintText: 'contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requerido';
                    if (value.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                
                const SizedBox(height: 14),
                
                // 7. Campo de Confirmar Contraseña
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_confirmPasswordVisible,
                  style: const TextStyle(color: textDark),
                  decoration: inputDecorationStyle.copyWith(
                    hintText: 'Confirmar contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(_confirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requerido';
                    if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                
                
                // 8. Botón de Envió / Registrarse (SIGN UP)
                ElevatedButton(
                  onPressed: _submitting ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Crear cuenta',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}