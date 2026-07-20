import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../services/firestore_service.dart';
import '../models/models.dart';
import '../utils/download_utils.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _selectedReportPeriod = 'Diario';
  final List<String> _periodOptions = ['Diario', 'Semanal', 'Mensual'];

  List<Booking> _filterPaidByPeriod(List<Booking> paid) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    final weekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    return paid.where((b) {
      if (b.timestamp == null) return false;
      final date = b.timestamp!.toLocal();
      if (_selectedReportPeriod == 'Diario') {
        return date.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) && date.isBefore(todayEnd.add(const Duration(milliseconds: 1)));
      }
      if (_selectedReportPeriod == 'Semanal') {
        return date.isAfter(weekStart.subtract(const Duration(milliseconds: 1))) && date.isBefore(todayEnd.add(const Duration(milliseconds: 1)));
      }
      if (_selectedReportPeriod == 'Mensual') {
        return date.year == now.year && date.month == now.month;
      }
      return true;
    }).toList();
  }

  Future<void> _downloadReportAsPdf(List<Booking> bookings) async {
    if (bookings.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay pagos disponibles para descargar en este período')),
      );
      return;
    }

    final doc = pw.Document();

    // Cargar logo desde assets (usado en el encabezado)
    Uint8List? logoBytes;
    try {
      final bd = await rootBundle.load('assets/images/Logo.png');
      logoBytes = bd.buffer.asUint8List();
    } catch (_) {
      logoBytes = null;
    }

    // Encabezado y resumen
    final total = bookings.fold<double>(0.0, (s, b) => s + (b.amount ?? 0.0));
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return [
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoBytes != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      margin: const pw.EdgeInsets.only(right: 12),
                      child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Informe de pasajes - $_selectedReportPeriod', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text('Generado: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('${bookings.length} registros', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Total: Bs. ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Divider(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Listado de pasajes
            pw.Column(
              children: bookings.map((b) {
                final formattedDate = b.timestamp != null ? DateFormat('dd MMM yyyy, hh:mm a').format(b.timestamp!.toLocal()) : '—';
                final isVerified = b.status == 'purchased' || (b.paymentVerified ?? false);
                final estado = isVerified ? 'COMPRADO' : 'RESERVADO';
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Horario / ID: ${b.horarioId}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(color: isVerified ? PdfColors.green100 : PdfColors.orange100, borderRadius: pw.BorderRadius.circular(4)),
                            child: pw.Text(estado, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: isVerified ? PdfColors.green800 : PdfColors.orange800)),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('CLIENTE / USUARIO', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                              pw.SizedBox(height: 2),
                              pw.Text(b.userEmail, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('ASIENTO', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                              pw.SizedBox(height: 2),
                              pw.Text('# ${b.seatIndex + 1}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('FECHA DE PAGO', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                              pw.SizedBox(height: 2),
                              pw.Text(formattedDate, style: pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(b.paymentType?.toUpperCase() ?? '-', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                              pw.SizedBox(height: 2),
                              pw.Text('Bs. ${ (b.amount ?? 0.0).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    final pdfBytes = await doc.save();
    final filename = 'pasajes_${_selectedReportPeriod.toLowerCase()}.pdf';
    final success = await downloadFile(filename, pdfBytes, mimeType: 'application/pdf');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Informe ${_selectedReportPeriod.toLowerCase()} descargado'
            : 'Descarga no disponible en esta plataforma'),
      ),
    );
  }

  void _showImageDialog(Booking b) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: b.paymentReferenceUrl != null
                ? Image.network(b.paymentReferenceUrl!, fit: BoxFit.contain)
                : (b.paymentReferenceBase64 != null
                    ? Image.memory(base64Decode(b.paymentReferenceBase64!), fit: BoxFit.contain)
                    : Container()),
          ),
        );
      },
    );
  }

  

  

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2563EB); 
    const Color bgLight = Color(0xFFF3F4F6); 

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Pagos Realizados', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Booking>>(
        stream: FirestoreService.instance.allBookingsStream(),
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
                  Icon(Icons.monetization_on_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No hay pagos registrados', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          // Calcular totales
          final paid = list.where((b) => b.status == 'purchased' || (b.paymentVerified ?? false)).toList();
          final filteredPaid = _filterPaidByPeriod(paid);
          final filteredTotal = filteredPaid.fold<double>(0.0, (s, b) => s + (b.amount ?? 0.0));

          return Column(
            children: [
              // Cuadro bonito de reporte y descarga
              Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.download_rounded, color: primaryBlue, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Descargar pasajes comprados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                              SizedBox(height: 4),
                              Text('Genera un informe completo de los pasajes comprados para tu control y reportes.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedReportPeriod,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              items: _periodOptions.map((period) {
                                return DropdownMenuItem<String>(
                                  value: period,
                                  child: Text(period, style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937))),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedReportPeriod = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _downloadReportAsPdf(filteredPaid),
                          icon: const Icon(Icons.file_download, size: 18),
                          label: const Text('Descargar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pasajes incluidos', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                              const SizedBox(height: 4),
                              Text('${filteredPaid.length} registros', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total recaudado', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                              const SizedBox(height: 4),
                              Text('Bs. ${filteredTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: primaryBlue)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Listado de Transacciones Estilo Boleto Digital
              Expanded(
                child: filteredPaid.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'No hay pagos registrados para el periodo $_selectedReportPeriod.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        itemCount: filteredPaid.length,
                        itemBuilder: (context, i) {
                          final b = filteredPaid[i];
                    
                    String formattedDate = '—';
                    if (b.timestamp != null) {
                      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(b.timestamp!.toLocal());
                    }

                    final paymentMethod = b.paymentType ?? '—';
                    final statusText = b.status ?? '—';

                    // Traducción lógica y estética a Español del estado
                    final bool isVerified = statusText == 'purchased' || (b.paymentVerified ?? false);
                    final String estadoEnEspanol = isVerified ? 'COMPRADO' : 'RESERVADO';
                    
                    final Color statusColor = isVerified ? const Color(0xFF059669) : const Color(0xFFD97706);
                    final Color statusBg = isVerified ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFF59E0B).withValues(alpha: 0.12);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            Container(
                              color: primaryBlue.withValues(alpha: 0.06),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.receipt_long_rounded, color: primaryBlue, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Horario / ID: ${b.horarioId}',
                                    style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  // Badge de Estado traducido completamente a Español
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      estadoEnEspanol,
                                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('CLIENTE / USUARIO', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                            const SizedBox(height: 4),
                                            Text(
                                              b.userEmail,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Contenedor de Asiento Rediseñado con Icono Alusivo de Asiento de Bus
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('ASIENTO', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E3A8A),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.airline_seat_recline_normal_rounded, 
                                                  color: Colors.white, 
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '# ${b.seatIndex + 1}',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.0),
                                    child: Divider(color: Color(0xFFF3F4F6), thickness: 1.5),
                                  ),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('FECHA DE PAGO', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            paymentMethod.toUpperCase(),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            b.amount == null ? 'Bs. —' : 'Bs. ${b.amount!.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (b.paymentReferenceUrl != null || b.paymentReferenceBase64 != null) ...[
                                    const SizedBox(height: 16),
                                    const Text('Referencia bancaria', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: GestureDetector(
                                        onTap: () => _showImageDialog(b),
                                        child: SizedBox(
                                          height: 120,
                                          width: double.infinity,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Positioned.fill(
                                                child: b.paymentReferenceUrl != null
                                                    ? Image.network(
                                                        b.paymentReferenceUrl!,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (context, child, loadingProgress) {
                                                          if (loadingProgress == null) return child;
                                                          return const Center(child: CircularProgressIndicator());
                                                        },
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            color: Colors.grey.shade200,
                                                            alignment: Alignment.center,
                                                            child: const Text('No se pudo cargar la referencia', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                                                          );
                                                        },
                                                      )
                                                    : (b.paymentReferenceBase64 != null
                                                        ? Image.memory(base64Decode(b.paymentReferenceBase64!), fit: BoxFit.cover)
                                                        : Container(color: Colors.grey.shade200)),
                                              ),
                                              Positioned(
                                                right: 8,
                                                top: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                                                  child: const Icon(Icons.open_in_full, color: Colors.white, size: 18),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}