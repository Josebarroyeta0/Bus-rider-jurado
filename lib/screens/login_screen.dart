import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '', _password = '';
  bool _passwordVisible = false;

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

  Future<bool> _validateCredentials(String email, String password) async {
    final users = await _loadRegisteredUsers();
    for (final user in users) {
      if (user['email'] == email && user['password'] == password) {
        return true;
      }
    }
    return false;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // Usuarios de demostración: passenger@test.com / 123456 | admin@test.com / admin123
      final email = _email.trim();
      final password = _password;
      final isDemoValid = (email == 'passenger@test.com' && password == '123456') || (email == 'admin@test.com' && password == 'admin123');
      final isSavedUser = await _validateCredentials(email, password);
      if (!isDemoValid && !isSavedUser) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Credenciales incorrectas')));
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      await prefs.setString('user_email', email);
      await prefs.setBool('is_admin', email == 'admin@test.com');
      if (!mounted) return;
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => HomeScreen())
      );
    }
  }
  
@override
  Widget build(BuildContext context) {
    // Definición de la paleta de colores basada en la imagen de referencia
    const primaryBlue = Color(0xFF2B54FA);
    const textDark = Color(0xFF000000);
    const textMuted = Color(0xFF757575);
    const borderGrey = Color(0xFFD0D0D0);

    return Scaffold(
      backgroundColor: Colors.white, // Fondo limpio e iluminado como la referencia
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alineación a la izquierda para los labels
              children: [
                const SizedBox(height: 20),
                
                // Centramos el logo y el título principal de la App
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/images/Logo.png', width: 100, height: 100, errorBuilder: (context, error, stackTrace) {
                        // Placeholder por si no encuentra el asset inmediatamente
                        return const Icon(Icons.directions_bus, size: 80, color: primaryBlue);
                      }),
                      const SizedBox(height: 16),
                      const Text(
                        'Bus Guarico Rider',
                        style: TextStyle(fontSize: 24, color: textDark, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Título del Formulario "Log in"
                const Center(
                  child: Text(
                    'Inicio de sesión',
                    style: TextStyle(
                      fontSize: 32, 
                      color: textDark, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Campo de Usuario / Correo
                const Text(
                  'Correo electronico',
                  style: TextStyle(fontSize: 15, color: textDark, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  style: const TextStyle(color: textDark),
                  decoration: InputDecoration(
                    hintText: 'Email or ID',
                    hintStyle: const TextStyle(color: textMuted, fontSize: 15),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24), // Bordes redondeados y suaves
                      borderSide: const BorderSide(color: borderGrey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  onChanged: (v) => _email = v,
                ),
                
                const SizedBox(height: 20),
                
                // Campo de Contraseña
                const Text(
                  'contraseña',
                  style: TextStyle(fontSize: 15, color: textDark, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  obscureText: !_passwordVisible,
                  style: const TextStyle(color: textDark),
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    hintStyle: const TextStyle(color: textMuted, fontSize: 15),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: borderGrey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                  onChanged: (v) => _password = v,
                ),
                
                const SizedBox(height: 32),
                
                // Botón Iniciar Sesión (LOG IN)
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 0, // Plano, tal cual la imagen
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28), // Botón completamente ovalado en los bordes
                    ),
                  ),
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Enlace para ir al Registro
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const RegistrationScreen())
                    ),
                    child: const Text(
                      '¿No tienes cuenta? Crear cuenta',
                      style: TextStyle(
                        color: primaryBlue, 
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Credenciales de demostración legibles sobre fondo blanco
                Center(
                  child: Text(
                    'Demo:\npassenger@test.com / 123456\nadmin@test.com / admin123', 
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4), 
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}