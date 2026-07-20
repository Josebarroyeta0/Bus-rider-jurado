import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' show LatLng;
import '../models/ruta_data.dart';
import '../models/models.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import 'dart:math';
import 'login_screen.dart';
import 'payments_screen.dart';
import 'purchased_tickets_screen.dart';
import 'denuncia_admin_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final fm.MapController _mapController = fm.MapController();
  late List<Bus> _buses;
  late List<Horario> _horarios;
  int _selectedBusId = RutaGuarico.buses.isNotEmpty ? RutaGuarico.buses.first.id : 0;
  bool _simulating = false;
  double _speed = 1.0; // valores menores = más lento
  LatLng? _currentPos;
  int _currentIndex = 0; // índice del segmento actual para dibujar la porción recorrida
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    // Apuntamos directamente a las referencias globales para mantener consistencia
    _buses = RutaGuarico.buses;
    _horarios = RutaGuarico.horarios;
    if (_buses.isNotEmpty && _selectedBusId == 0) {
      _selectedBusId = _buses.first.id;
    }
  }

  Future<void> _startSimulation() async {
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Firebase no está configurado. Simulación desactivada.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _simulating = true;
      _status = 'Simulación iniciada';
    });
    final bus = _buses.firstWhere((b) => b.id == _selectedBusId);

    // Recorrer los puntos de la ruta
    while (_simulating) {
      for (int seg = 0; seg < RutaGuarico.rutaCompleta.length - 1; seg++) {
        final p0 = RutaGuarico.rutaCompleta[seg];
        final p1 = RutaGuarico.rutaCompleta[seg + 1];
        final steps = (10 * _speed).round();
        for (int s = 0; s <= steps; s++) {
          if (!_simulating) break;
          final t = s / steps;
          final lat = p0.latitude + (p1.latitude - p0.latitude) * t;
          final lng = p0.longitude + (p1.longitude - p0.longitude) * t;
          final pos = LatLng(lat, lng);
          setState(() {
            _currentPos = pos;
            _currentIndex = seg;
            _status = 'En ruta segment $seg (${(t * 100).toStringAsFixed(0)}%)';
          });
          try {
            // No sobrescribir el estado operativo del bus con mensajes de segmento.
            await FirestoreService.instance.updateBusLocation(
              bus.id,
              pos,
              bus.estado.isNotEmpty ? bus.estado : 'Disponible',
            );
          } catch (e) {
            // Ignorar errores pero actualizar la interfaz
            debugPrint('Error actualizando ubicación del bus: $e');
          }
          _mapController.move(pos, 13);
          await Future.delayed(Duration(milliseconds: (1000 / _speed).round()));
        }
        if (!_simulating) break;
      }
      // Después de completar la ruta, pausar brevemente y repetir
      await Future.delayed(const Duration(seconds: 1));
    }
    setState(() {
      _status = 'Simulación detenida';
    });
  }

  void _stopSimulation() {
    setState(() {
      _simulating = false;
    });
  }

  // --- ELIMINAR AUTOBÚS ---
  Future<void> _deleteBus(Bus bus) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar unidad?'),
        content: Text('¿Está seguro de que desea eliminar la unidad con placa ${bus.placa}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      RutaGuarico.buses.removeWhere((b) => b.id == bus.id);
      // Si eliminamos el bus seleccionado, reasignamos la selección
      if (_selectedBusId == bus.id) {
        _selectedBusId = RutaGuarico.buses.isNotEmpty ? RutaGuarico.buses.first.id : 0;
      }
    });

    try {
      if (Firebase.apps.isNotEmpty) {
        // Intenta borrarlo en Firestore si el método existe en tu servicio
        await FirestoreService.instance.deleteBus(bus.id.toString());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unidad ${bus.placa} eliminada con éxito')),
      );
    } catch (e) {
      debugPrint('Nota: No se borró en Firestore o método no definido ($e). Limpieza local completada.');
    }
  }

  // --- ELIMINAR HORARIO ---
  Future<void> _deleteSchedule(Horario horario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar horario?'),
        content: Text('¿Desea remover el horario de las ${horario.salida}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      RutaGuarico.horarios.removeWhere((h) => h.id == horario.id);
    });

    if (!mounted) return;
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirestoreService.instance.deleteHorario(horario.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horario eliminado del sistema')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar horario: $e')),
      );
    }
  }

  Future<void> _clearOccupiedSeats() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar asientos ocupados'),
        content: const Text(
          'Esta acción liberará todos los asientos marcados como ocupados en los horarios. ¿Desea continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Limpiar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      for (final horario in RutaGuarico.horarios) {
        horario.asientosOcupados = List<bool>.filled(horario.asientosTotal, false);
      }
    });

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirestoreService.instance.clearAllBookedSeats();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asientos ocupados liberados correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al limpiar asientos ocupados: $e')),
      );
    }
  }

  Future<void> _showAddBusDialog() async {
    final placaCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final estadoCtrl = TextEditingController(text: 'Disponible');
    final cedulaCtrl = TextEditingController();
    final bankCodeCtrl = TextEditingController();
    final bankNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    const estadoOptions = [
      'Disponible',
      'Restablecimiento de combustible',
      'Fuera de servicio',
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Agregar nueva unidad'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: placaCtrl,
                  decoration: const InputDecoration(labelText: 'Placa'),
                ),
                TextField(
                  controller: latCtrl,
                  decoration: const InputDecoration(labelText: 'Latitud (opcional)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: lngCtrl,
                  decoration: const InputDecoration(labelText: 'Longitud (opcional)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                DropdownButtonFormField<String>(
                  value: estadoOptions.contains(estadoCtrl.text) ? estadoCtrl.text : estadoOptions.first,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: estadoOptions.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
                  onChanged: (value) {
                    if (value != null) estadoCtrl.text = value;
                  },
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Datos de Pago Móvil (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: cedulaCtrl,
                  decoration: const InputDecoration(labelText: 'Cédula (numérica)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: bankCodeCtrl,
                  decoration: const InputDecoration(labelText: 'Código del Banco (numérico)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: bankNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Banco'),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono (numérico, opcional)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final placa = placaCtrl.text.trim();
                if (placa.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La placa es obligatoria')),
                  );
                  return;
                }
                final lat = double.tryParse(latCtrl.text.trim());
                final lng = double.tryParse(lngCtrl.text.trim());
                final estado = estadoCtrl.text.trim().isEmpty ? 'Disponible' : estadoCtrl.text.trim();

                // Calcular nuevo id utilizando la lista de origen de datos
                final newId = RutaGuarico.buses.isEmpty ? 1 : (RutaGuarico.buses.map((b) => b.id).reduce(max) + 1);
                final ubic = (lat != null && lng != null) ? LatLng(lat, lng) : RutaGuarico.sanJuan;
                final newBus = Bus(
                  id: newId,
                  placa: placa,
                  estado: estado,
                  ubicacion: ubic,
                  mobileCedula: cedulaCtrl.text.trim().isEmpty ? null : cedulaCtrl.text.trim(),
                  mobileBankCode: bankCodeCtrl.text.trim().isEmpty ? null : bankCodeCtrl.text.trim(),
                  mobileBankName: bankNameCtrl.text.trim().isEmpty ? null : bankNameCtrl.text.trim(),
                  mobilePhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                );

                setState(() {
                  RutaGuarico.buses.add(newBus);
                  _selectedBusId = newId;
                });
                
                Navigator.of(ctx).pop();
                
                try {
                  if (Firebase.apps.isNotEmpty) {
                    await FirestoreService.instance.setBus(
                      newId,
                      placa,
                      ubic,
                      estado,
                      mobileCedula: newBus.mobileCedula,
                      mobileBankCode: newBus.mobileBankCode,
                      mobileBankName: newBus.mobileBankName,
                      mobilePhone: newBus.mobilePhone,
                    );
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unidad agregada (ID $newId)')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al guardar en Firestore: $e'),
                    ),
                  );
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddScheduleDialog() async {
    final rutaCtrl = TextEditingController(text: 'San Juan - Ortiz - Mellado');
    final salidaCtrl = TextEditingController();
    final llegadaCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final asientosCtrl = TextEditingController(text: '40');
    int selectedBusId = _selectedBusId;
    TimeOfDay? salidaHora;
    TimeOfDay? llegadaHora;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Agregar nuevo horario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: rutaCtrl,
                  decoration: const InputDecoration(labelText: 'Ruta'),
                ),
                TextField(
                  controller: salidaCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Salida'),
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: ctx,
                      initialTime: salidaHora ?? const TimeOfDay(hour: 6, minute: 0),
                    );
                    if (selected != null) {
                      salidaHora = selected;
                      if (!mounted) return;
                      salidaCtrl.text = selected.format(context);
                    }
                  },
                ),
                TextField(
                  controller: llegadaCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Llegada'),
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: ctx,
                      initialTime: llegadaHora ?? const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (selected != null) {
                      llegadaHora = selected;
                      if (!mounted) return;
                      llegadaCtrl.text = selected.format(context);
                    }
                  },
                ),
                // Si no hay buses disponibles, impedir crear un horario huérfano
                if (_buses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No hay unidades registradas. Agregue una unidad antes de crear horarios.', style: TextStyle(color: Colors.red.shade700)),
                  ),
                if (_buses.isNotEmpty)
                  DropdownButtonFormField<int>(
                    initialValue: _buses.any((b) => b.id == selectedBusId) ? selectedBusId : (_buses.isNotEmpty ? _buses.first.id : 0),
                    decoration: const InputDecoration(labelText: 'Unidad de autobús'),
                    items: _buses
                        .map(
                          (bus) => DropdownMenuItem<int>(
                            value: bus.id,
                            child: Text('${bus.placa} (ID ${bus.id})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) selectedBusId = v;
                    },
                  ),
                TextField(
                  controller: precioCtrl,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: asientosCtrl,
                  decoration: const InputDecoration(labelText: 'Asientos totales'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final ruta = rutaCtrl.text.trim();
                final salida = salidaCtrl.text.trim();
                final llegada = llegadaCtrl.text.trim();
                final precio = double.tryParse(precioCtrl.text.trim()) ?? 0.0;
                final asientosTotal = int.tryParse(asientosCtrl.text.trim()) ?? 40;
                
                if (ruta.isEmpty || salida.isEmpty || llegada.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Complete ruta, salida y llegada')),
                  );
                  return;
                }
                if (salidaHora == null || llegadaHora == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccione la hora de salida y llegada')),
                  );
                  return;
                }
                
                if (_buses.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No hay unidades registradas. Agregue una unidad antes de crear horarios.')),
                  );
                  return;
                }

                final newId = RutaGuarico.horarios.isEmpty ? 1 : (RutaGuarico.horarios.map((h) => h.id).reduce(max) + 1);
                final newHorario = Horario(
                  id: newId,
                  ruta: ruta,
                  salida: salida,
                  llegada: llegada,
                  busId: selectedBusId,
                  asientosTotal: asientosTotal,
                  precio: precio,
                );

                setState(() {
                  RutaGuarico.horarios.add(newHorario);
                });
                Navigator.of(ctx).pop();
                if (!mounted) return;
                // Persistir horario en Firestore si está inicializado
                try {
                  if (Firebase.apps.isNotEmpty) {
                    FirestoreService.instance.setHorario(newHorario);
                  }
                } catch (_) {}
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Horario agregado (ID $newId)')),
                );
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('is_admin');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedBus = _buses.firstWhere(
      (b) => b.id == _selectedBusId,
      orElse: () => Bus(id: 0, placa: 'S/N', estado: 'Desconocido', ubicacion: RutaGuarico.sanJuan),
    );
    final markerPosition = _currentPos ?? selectedBus.ubicacion ?? RutaGuarico.sanJuan;

    const primaryBg = Color(0xFFF8F9FA);
    const cardBg = Colors.white;
    const textDark = Color(0xFF212529);
    const textMuted = Color(0xFF6C757D);
    const accentGreen = Color(0xFF28A745);
    const accentOrange = Color(0xFFFD7E14);

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        foregroundColor: textDark,
        title: const Text(
          'Panel del Administrador',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'Ver pagos',
            icon: const Icon(Icons.payment, color: textMuted),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Denuncias',
            icon: const Icon(Icons.report_problem_outlined, color: textMuted),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DenunciaAdminScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Pasajes comprados',
            icon: const Icon(Icons.receipt_long, color: textMuted),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PurchasedTicketsScreen()),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: VerticalDivider(color: Colors.grey.shade300, width: 1),
          ),
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECCIÓN: CONTROL DE SIMULACIÓN ---
              _buildDashboardCard(
                title: 'Control de Simulación',
                subtitle: 'Monitoreo en tiempo real y simulación de movimiento',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                              initialValue: _buses.any((b) => b.id == _selectedBusId) ? _selectedBusId : (_buses.isNotEmpty ? _buses.first.id : 0),
                            decoration: InputDecoration(
                              labelText: 'Seleccionar Unidad',
                              labelStyle: const TextStyle(color: textMuted),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: primaryBg,
                            ),
                            items: _buses
                                .map(
                                  (b) => DropdownMenuItem<int>(
                                    value: b.id,
                                    child: Text('${b.placa} (ID ${b.id})', style: const TextStyle(color: textDark)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedBusId = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _simulating ? Colors.redAccent : accentGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: _simulating ? _stopSimulation : _startSimulation,
                          icon: Icon(_simulating ? Icons.stop : Icons.play_arrow),
                          label: Text(
                            _simulating ? 'Detener Simulación' : 'Iniciar Simulación',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.speed, color: textMuted, size: 20),
                        const SizedBox(width: 8),
                        const Text('Velocidad Multiplicadora', style: TextStyle(color: textDark, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text('${_speed.toStringAsFixed(2)}x', style: const TextStyle(color: accentOrange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _speed,
                      min: 0.25,
                      max: 5,
                      divisions: 19,
                      activeColor: accentOrange,
                      inactiveColor: Colors.grey.shade200,
                      label: _speed.toStringAsFixed(2),
                      onChanged: (v) => setState(() => _speed = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- SECCIÓN: MAPA EN VIVO ---
              _buildDashboardCard(
                title: 'Vista de Mapa en Tiempo Real',
                subtitle: 'Posición geográfica de la unidad seleccionada',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 280,
                    child: fm.FlutterMap(
                      mapController: _mapController,
                      options: fm.MapOptions(
                        initialCenter: selectedBus.ubicacion ?? RutaGuarico.sanJuan,
                        initialZoom: 12,
                      ),
                      children: [
                        fm.TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        // Dibujar la ruta completa y la porción recorrida
                        fm.PolylineLayer(
                          polylines: [
                            fm.Polyline(
                              points: RutaGuarico.rutaCompleta,
                              color: Colors.grey.shade400,
                              strokeWidth: 4,
                            ),
                            if (_currentPos != null)
                              fm.Polyline(
                                points: [
                                  ...RutaGuarico.rutaCompleta.sublist(0, min(_currentIndex + 1, RutaGuarico.rutaCompleta.length)),
                                  _currentPos!,
                                ],
                                color: const Color(0xFFFD7E14),
                                strokeWidth: 6,
                              ),
                          ],
                        ),
                        fm.MarkerLayer(
                          markers: [
                            fm.Marker(
                              width: 44,
                              height: 44,
                              point: markerPosition,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_bus,
                                  color: Color(0xFFFD7E14),
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- SECCIÓN: ACCIONES DE GESTIÓN ---
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardBg,
                            foregroundColor: textDark,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_business, color: accentOrange),
                          label: const Text('Agregar unidad', style: TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: _showAddBusDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardBg,
                            foregroundColor: textDark,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.schedule, color: accentOrange),
                          label: const Text('Agregar horario', style: TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: _showAddScheduleDialog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.cleaning_services, color: Colors.white),
                      label: const Text('Liberar asientos ocupados', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: _clearOccupiedSeats,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN: UNIDADES REGISTRADAS ---
              _buildDashboardCard(
                title: 'Unidades registradas',
                subtitle: 'Estado actual y coordenadas en Firestore',
                child: SizedBox(
                  height: 160,
                  child: ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    itemCount: _buses.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final bus = _buses[index];
                      final isSelected = bus.id == _selectedBusId;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? accentOrange.withOpacity(0.1) : Colors.grey.shade100,
                          child: Icon(Icons.directions_bus, color: isSelected ? accentOrange : textMuted),
                        ),
                        title: Text(
                          '${bus.placa} (ID ${bus.id})',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                        ),
                        subtitle: Text(
                          'Estado: ${bus.estado}${bus.ubicacion != null ? ' • ${bus.ubicacion!.latitude.toStringAsFixed(4)}, ${bus.ubicacion!.longitude.toStringAsFixed(4)}' : ''}',
                          style: const TextStyle(color: textMuted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                              onPressed: () => _showEditBusDialog(bus),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: bus.estado.toLowerCase() == 'activo' || bus.estado.toLowerCase() == 'disponible' ? accentGreen : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteBus(bus),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- SECCIÓN: HORARIOS DISPONIBLES ---
              _buildDashboardCard(
                title: 'Horarios disponibles',
                subtitle: 'Rutas activas y tarifas del sistema',
                child: SizedBox(
                  height: 200,
                  child: ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    itemCount: _horarios.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final horario = _horarios[index];
                      final bus = _buses.firstWhere(
                        (b) => b.id == horario.busId,
                        orElse: () => Bus(id: 0, placa: 'Desconocida', estado: 'N/A'),
                      );
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        title: Text(
                          '${horario.ruta} • ${horario.salida} - ${horario.llegada}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: textDark),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Unidad: ${bus.placa} (ID ${horario.busId}) • Asientos: ${horario.asientosTotal}',
                            style: const TextStyle(color: textMuted),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: accentGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Bs. ${horario.precio.toStringAsFixed(2)}',
                                style: const TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteSchedule(horario),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- FOOTER: ESTADO DE CONEXIÓN ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: accentGreen),
                        ),
                        const SizedBox(width: 8),
                        Text('Estado: $_status', style: const TextStyle(fontSize: 12, color: textDark, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text(
                      'Pos: ${_currentPos?.latitude.toStringAsFixed(5) ?? '-'}, ${_currentPos?.longitude.toStringAsFixed(5) ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: textMuted, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditBusDialog(Bus bus) async {
    final placaCtrl = TextEditingController(text: bus.placa);
    final latCtrl = TextEditingController(text: bus.ubicacion?.latitude.toString() ?? '');
    final lngCtrl = TextEditingController(text: bus.ubicacion?.longitude.toString() ?? '');
    final estadoCtrl = TextEditingController(text: bus.estado);
    final cedulaCtrl = TextEditingController(text: bus.mobileCedula ?? '');
    final bankCodeCtrl = TextEditingController(text: bus.mobileBankCode ?? '');
    final bankNameCtrl = TextEditingController(text: bus.mobileBankName ?? '');
    final phoneCtrl = TextEditingController(text: bus.mobilePhone ?? '');
    const estadoOptions = [
      'Disponible',
      'Restablecimiento de combustible',
      'Fuera de servicio',
    ];

    await showDialog<void>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Editar unidad'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: placaCtrl, decoration: const InputDecoration(labelText: 'Placa')),
            TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitud (opcional)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Longitud (opcional)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            DropdownButtonFormField<String>(
              value: estadoOptions.contains(estadoCtrl.text) ? estadoCtrl.text : null,
              hint: Text(estadoCtrl.text.isNotEmpty && !estadoOptions.contains(estadoCtrl.text) ? estadoCtrl.text : 'Seleccione Estado'),
              decoration: const InputDecoration(labelText: 'Estado'),
              items: estadoOptions.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
              onChanged: (value) {
                if (value != null) estadoCtrl.text = value;
              },
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Datos de Pago Móvil (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: cedulaCtrl, decoration: const InputDecoration(labelText: 'Cédula (numérica)'), keyboardType: TextInputType.number),
            TextField(controller: bankCodeCtrl, decoration: const InputDecoration(labelText: 'Código del Banco (numérico)'), keyboardType: TextInputType.number),
            TextField(controller: bankNameCtrl, decoration: const InputDecoration(labelText: 'Nombre del Banco')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono (numérico, opcional)'), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            final placa = placaCtrl.text.trim();
            if (placa.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La placa es obligatoria')));
              return;
            }
            final lat = double.tryParse(latCtrl.text.trim());
            final lng = double.tryParse(lngCtrl.text.trim());
            final estado = estadoOptions.contains(estadoCtrl.text.trim()) ? estadoCtrl.text.trim() : bus.estado;

            final updatedBus = Bus(
              id: bus.id,
              placa: placa,
              estado: estado,
              ubicacion: (lat != null && lng != null) ? LatLng(lat, lng) : bus.ubicacion,
              mobileCedula: cedulaCtrl.text.trim().isEmpty ? null : cedulaCtrl.text.trim(),
              mobileBankCode: bankCodeCtrl.text.trim().isEmpty ? null : bankCodeCtrl.text.trim(),
              mobileBankName: bankNameCtrl.text.trim().isEmpty ? null : bankNameCtrl.text.trim(),
              mobilePhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
            );

            setState(() {
              final idx = RutaGuarico.buses.indexWhere((b) => b.id == bus.id);
              if (idx != -1) RutaGuarico.buses[idx] = updatedBus;
              // keep selection
              if (_selectedBusId == 0) _selectedBusId = updatedBus.id;
            });

            Navigator.of(ctx).pop();

            try {
              if (Firebase.apps.isNotEmpty) {
                await FirestoreService.instance.setBus(
                  updatedBus.id,
                  updatedBus.placa,
                  updatedBus.ubicacion ?? RutaGuarico.sanJuan,
                  updatedBus.estado,
                  mobileCedula: updatedBus.mobileCedula,
                  mobileBankCode: updatedBus.mobileBankCode,
                  mobileBankName: updatedBus.mobileBankName,
                  mobilePhone: updatedBus.mobilePhone,
                );
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unidad ${updatedBus.placa} actualizada')));
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar en Firestore: $e')));
            }
          }, child: const Text('Guardar'))
        ],
      );
    });
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF212529))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}