import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _currentEmail;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _ciController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final raw = prefs.getString('registered_users');
    if (!mounted) return;

    if (email == null || raw == null || raw.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final users = (jsonDecode(raw) as List<dynamic>).whereType<Map<String, dynamic>>().toList();
    final user = users.cast<Map<String, dynamic>>().firstWhere(
          (u) => u['email'] == email,
          orElse: () => <String, dynamic>{},
        );

    if (user.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }

    setState(() {
      _currentEmail = email;
      _currentUser = user;
      _nombreController.text = user['nombre'] ?? '';
      _apellidoController.text = user['apellido'] ?? '';
      _ciController.text = user['ci'] ?? '';
      _emailController.text = user['email'] ?? '';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentEmail == null) return;

    setState(() {
      _saving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('registered_users');
    final users = raw == null || raw.isEmpty
        ? <Map<String, dynamic>>[]
        : (jsonDecode(raw) as List<dynamic>).whereType<Map<String, dynamic>>().toList();

    final index = users.indexWhere((u) => u['email'] == _currentEmail);
    if (index == -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró el perfil registrado.')));
      }
      setState(() {
        _saving = false;
      });
      return;
    }

    final updated = Map<String, dynamic>.from(users[index]);
    updated['nombre'] = _nombreController.text.trim();
    updated['apellido'] = _apellidoController.text.trim();
    updated['ci'] = _ciController.text.trim();
    final newPassword = _passwordController.text;
    if (newPassword.isNotEmpty) {
      updated['password'] = newPassword;
    }

    users[index] = updated;
    await prefs.setString('registered_users', jsonEncode(users));

    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado correctamente.')));
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    const borderGrey = Color(0xFFCCCCCC);
    const accentBlue = Color(0xFF2B54FA);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('No se encontró el perfil del usuario.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: accentBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Icons.person, size: 56, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderGrey)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _apellidoController,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderGrey)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _ciController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cédula',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderGrey)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Requerido';
                    if (!RegExp(r'^[0-9]{6,12}$').hasMatch(value.trim())) return 'Cédula inválida';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderGrey)),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña (dejar en blanco para mantener)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderGrey)),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
