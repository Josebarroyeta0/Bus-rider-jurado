import 'package:flutter/material.dart';
import '../models/ruta_data.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import 'bus_detalle_screen.dart';
import 'admin_screen.dart';
import 'denuncia_form_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mapa_tracking_screen.dart';
import 'my_bookings_screen.dart';
import 'mis_denuncias_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _isAdmin = prefs.getBool('is_admin') ?? false);
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
    const primaryBlue = Color(0xFF2B54FA);
    const accentOrange = Color(0xFFFF5722); 
    const bgLight = Color(0xFFF5F7FB);
    const textDark = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgLight,
      body: CustomScrollView(
        slivers: [
          // 1. App Bar Estilo Banner con Imagen de Fondo
          SliverAppBar(
            expandedHeight: 260.0,
            floating: false,
            pinned: true,
            backgroundColor: textDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Salir',
              onPressed: _logout,
            ),
            actions: [
              if (!_isAdmin)
                IconButton(
                  icon: const Icon(Icons.bookmark_outline, color: Colors.white),
                  tooltip: 'Mis Reservas',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
                ),
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                  tooltip: 'Panel Admin',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    );
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              title: const Text(
                'Bus Guárico Rider',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54, offset: Offset(0, 2))],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&q=80&w=800',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Panel Flotante de Información de la Ruta Principal
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -25),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.alt_route, color: primaryBlue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Línea Troncal Principal',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ruta San Juan - Ortiz - Mellado',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecciona un horario disponible para reservar tus asientos.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (!_isAdmin) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DenunciaFormScreen()),
                  ),
                  icon: const Icon(Icons.report_problem_outlined, size: 20),
                  label: const Text('Denunciar irregularidad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MisDenunciasScreen()),
                  ),
                  icon: const Icon(Icons.history_toggle_off, size: 20),
                  label: const Text('Mis denuncias'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],

          // 4. Listado de Horarios Disponibles
          SliverPadding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final horario = RutaGuarico.horarios[i];
                  
                  // CORREGIDO: Mapeo correcto utilizando id como int y estado como String
                  final asociatedBus = RutaGuarico.buses.firstWhere(
                    (b) => b.id == horario.busId,
                    orElse: () => Bus(
                      id: 0,                      // <-- Corregido a int
                      placa: 'No asignada', 
                      estado: 'Inactivo',         // <-- Corregido a String
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  horario.ruta,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accentOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Bs. ${horario.precio.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentOrange),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1),

                          Row(
                            children: [
                              const Icon(Icons.directions_bus_outlined, color: Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Unidad: ${asociatedBus.placa}',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${horario.salida}  ➔  ${horario.llegada}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Mostrar SOLO texto del estado operativo (usar únicamente las opciones del admin)
                          Builder(builder: (context) {
                            final allowed = ['Disponible', 'Restablecimiento de combustible', 'Fuera de servicio'];
                            final raw = asociatedBus.estado.trim();
                            String display = 'Sin asignar';
                            for (final a in allowed) {
                              if (raw.toLowerCase().contains(a.toLowerCase())) {
                                display = a;
                                break;
                              }
                            }
                            final color = display == 'Disponible'
                                ? Colors.green
                                : display == 'Fuera de servicio'
                                    ? Colors.red
                                    : display == 'Restablecimiento de combustible'
                                        ? Colors.orange
                                        : Colors.grey;

                            return Text(
                              'Estado: $display',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                            );
                          }),

                          const SizedBox(height: 8),

                          StreamBuilder<Horario?>(
                            stream: FirestoreService.instance.horarioStream(horario.id),
                            builder: (context, snap) {
                              final h = snap.data ?? horario;
                              final booked = h.asientosOcupados.where((e) => e).length;
                              final free = h.asientosTotal - booked;
                              final bool lowAvailability = free <= 5;

                              return Row(
                                children: [
                                  Icon(
                                    Icons.event_seat_outlined, 
                                    color: lowAvailability ? Colors.red : primaryBlue, 
                                    size: 18
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Disponibles: $free de ${h.asientosTotal}',
                                    style: TextStyle(
                                      fontSize: 13, 
                                      fontWeight: FontWeight.bold,
                                      color: lowAvailability ? Colors.red : primaryBlue,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (_) => MapaTrackingScreen(busId: horario.busId)
                                    )
                                  ),
                                  icon: const Icon(Icons.map_outlined, size: 18),
                                  label: const Text('Rastreo GPS'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textDark,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (_) => BusDetalleScreen(horario: horario)
                                    )
                                  ),
                                  icon: const Icon(Icons.airline_seat_recline_normal, size: 18),
                                  label: const Text('Asientos'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: RutaGuarico.horarios.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}