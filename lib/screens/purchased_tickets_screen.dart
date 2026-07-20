import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

class PurchasedTicketsScreen extends StatelessWidget {
  const PurchasedTicketsScreen({super.key});

  String _formatDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _buildGroupedList(List<Booking> items) {
    final Map<String, List<Booking>> grouped = {};
    for (final b in items) {
      final ts = b.timestamp ?? DateTime.now().toUtc();
      final key = _formatDate(ts.toLocal());
      grouped.putIfAbsent(key, () => []).add(b);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: keys.length,
      itemBuilder: (context, idx) {
        final key = keys[idx];
        final list = grouped[key]!;
        final total = list.fold<double>(0.0, (s, e) => s + (e.amount ?? 0.0));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner superior informativo (Estilo "Pagos Verificados" de tu captura de pantalla)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAGOS VERIFICADOS • $key'.toUpperCase(),
                        style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${list.length} viajes',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TOTAL RECAUDADO',
                        style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bs. ${total.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Mapeo directo de las tarjetas de pasajes sin usar ExpansionTile
            ...list.map((b) {
              final dateText = b.timestamp?.toLocal().toString() ?? '-';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Detalle del pasaje', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Usuario: ${b.userEmail}'),
                            Text('Horario ID: ${b.horarioId}'),
                            Text('Asiento: ${b.seatIndex + 1}'),
                            Text('Fecha: $dateText'),
                            Text('Método de pago: ${b.paymentType ?? '—'}'),
                            Text('Monto: ${b.amount == null ? '—' : 'Bs. ${b.amount!.toStringAsFixed(2)}'}'),
                            Text('Estado: ${b.status ?? '—'}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cerrar', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ID de Horario y la etiqueta del estado del pasaje
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.directions_bus_filled_outlined, color: Colors.blue.shade700, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Horario / ID: ${b.horarioId}',
                                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'COMPRADO',
                                style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Sección de Cliente / Usuario y el distintivo del Asiento (Igual al de la foto)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CLIENTE / USUARIO',
                                    style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b.userEmail,
                                    style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'ASIENTO',
                                  style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade900,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.airline_seat_recline_normal, color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        '# ${b.seatIndex + 1}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Sección inferior con la fecha y el monto/método de pago correspondiente
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FECHA DE PAGO',
                                  style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateText.length > 16 ? dateText.substring(0, 16) : dateText,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  (b.paymentType ?? 'EFECTIVO').toUpperCase(),
                                  style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b.amount == null ? 'Bs. —' : 'Bs. ${b.amount!.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.black, // Fondo negro plano superior idéntico a la web de admin
          title: const Text(
            'Pagos Realizados',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: [
              Tab(text: 'Comprados'),
              Tab(text: 'Reservados'),
            ],
          ),
        ),
        body: StreamBuilder<List<Booking>>(
          stream: FirestoreService.instance.allBookingsStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final all = snap.data ?? [];
            final purchased = all.where((b) => (b.status == 'purchased') || (b.paymentVerified ?? false)).toList();
            final reserved = all.where((b) => b.status == 'reserved').toList();
            return TabBarView(
              children: [
                purchased.isEmpty ? const Center(child: Text('No hay pasajes comprados.')) : _buildGroupedList(purchased),
                reserved.isEmpty ? const Center(child: Text('No hay reservas.')) : _buildGroupedList(reserved),
              ],
            );
          },
        ),
      ),
    );
  }
}