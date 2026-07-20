import 'package:flutter/material.dart';



import 'package:shared_preferences/shared_preferences.dart';



import '../services/firestore_service.dart';



import '../models/models.dart';

import 'package:intl/intl.dart';







class MyBookingsScreen extends StatefulWidget {



  const MyBookingsScreen({super.key});







  @override



  State<MyBookingsScreen> createState() => _MyBookingsScreenState();



}







class _MyBookingsScreenState extends State<MyBookingsScreen> {



  String? _email;







  @override



  void initState() {



    super.initState();



    _loadEmail();



  }







  Future<void> _loadEmail() async {



    final prefs = await SharedPreferences.getInstance();



    setState(() => _email = prefs.getString('user_email'));



  }






@override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2563EB); // Azul del sistema unificado
    const Color cardBackground = Colors.white;

    if (_email == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis Reservas')), 
        body: const Center(child: Text('Debe iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Fondo gris claro para hacer resaltar los tickets
      appBar: AppBar(
        title: const Text('Mis Reservas', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Booking>>(
        stream: FirestoreService.instance.userBookingsStream(_email!),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryBlue)));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No tienes reservas activas.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final b = list[i];
              
              // Formatear la fecha para que se vea profesional (ej: 22 May 2026, 08:30 PM)
              String formattedDate = '—';
              if (b.timestamp != null) {
                formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(b.timestamp!.toLocal());
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      // Encabezado del Ticket estilizado
                      Container(
                        color: primaryBlue.withOpacity(0.08),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_bus_rounded, color: primaryBlue, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Ruta Interna / ID: ${b.horarioId}',
                              style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15), // Verde éxito
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Confirmado',
                                style: TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      ),
                      
                      // Cuerpo del Ticket
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Sección Pasajero
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PASAJERO', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _email!.split('@')[0], // Muestra el nombre de usuario antes del arroba de manera estética
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                                    ),
                                  ],
                                ),
                                // Sección Asiento (Inspirada en el color azul "Booked" de tu imagen)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('ASIENTO', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A8A), // Azul oscuro como el asiento ocupado de tu referencia
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '# ${b.seatIndex + 1}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                            ),
                            
                            // Fila de Fecha y Acción de Cancelar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Fecha y Hora de emisión
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('FECHA DE RESERVA', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Botón Cancelar (Mantiene exactamente tus funciones nativas)
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await FirestoreService.instance.cancelBooking(b.horarioId, b.seatIndex, _email!);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Reserva/cancelación realizada con éxito'))
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error cancelando: $e'))
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444), // Rojo moderno uniforme
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    minimumSize: Size.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Cancelar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
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
}