import 'dart:async'; // <-- AGREGADO: Necesario para manejar el StreamSubscription
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import 'package:flutter/services.dart';
import '../models/ruta_data.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/download_utils.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class BusDetalleScreen extends StatefulWidget {
  final Horario horario;
  const BusDetalleScreen({super.key, required this.horario});

  @override
  State<BusDetalleScreen> createState() => _BusDetalleScreenState();
}

class _BusDetalleScreenState extends State<BusDetalleScreen> {
  late Horario horario;
  final Set<int> _selectedSeats = {};
  bool _purchasing = false;
  bool _isAdmin = false;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  
  // <-- AGREGADO: Guardamos la referencia de la suscripción para poder cancelarla al salir
  StreamSubscription? _horarioSubscription;

  @override
  void initState() {
    super.initState();
    horario = widget.horario;
    _loadAdminStatus();
    
    // Suscribirse a actualizaciones remotas del horario si están disponibles
    if (Firebase.apps.isNotEmpty) {
      // <-- CORREGIDO: Guardamos la suscripción y verificamos que el widget siga montado
      _horarioSubscription = FirestoreService.instance.horarioStream(horario.id).listen((h) {
        if (h != null && mounted) { 
          setState(() => horario = h);
        }
      });
    }
  }

  @override
  void dispose() {
    // <-- AGREGADO: Cancelamos la escucha activa al destruir la pantalla
    _horarioSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isAdmin = prefs.getBool('is_admin') ?? false;
    });
  }

  bool _isOccupied(int i) => horario.asientosOcupados.length > i && horario.asientosOcupados[i];

  void _toggleSeat(int i) {
    if (_isAdmin || _isOccupied(i)) return;
    setState(() {
      if (_selectedSeats.contains(i)) {
        _selectedSeats.remove(i);
      } else {
        _selectedSeats.add(i);
      }
    });
  }

  Future<void> _purchase() async {
    if (_selectedSeats.isEmpty) return;
    setState(() => _purchasing = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final userEmail = prefs.getString('user_email');
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe iniciar sesión para comprar.')));
      setState(() => _purchasing = false);
      return;
    }
    // Seleccionar método de pago
    String? selectedPayment;
    XFile? paymentReferenceImage;

    Bus? busInfo;
    if (Firebase.apps.isNotEmpty) {
      try {
        busInfo = await FirestoreService.instance.getBus(horario.busId);
      } catch (_) {
        busInfo = null;
      }
      // Si Firestore está inicializado pero no contiene el documento aún,
      // usamos el fallback local para evitar que la UI no muestre datos.
      if (busInfo == null) {
        try {
          busInfo = RutaGuarico.buses.firstWhere((bb) => bb.id == horario.busId);
        } catch (_) {
          busInfo = null;
        }
      }
    } else {
      try {
        busInfo = RutaGuarico.buses.firstWhere((bb) => bb.id == horario.busId);
      } catch (_) {
        busInfo = null;
      }
    }

    if (!mounted) {
      setState(() => _purchasing = false);
      return;
    }
    await showDialog<void>(context: context, builder: (ctx) {
      String temp = 'Efectivo';
      XFile? tempReference;
      Uint8List? tempReferenceBytes;
      String? errorText;
      final picker = ImagePicker();

      return StatefulBuilder(builder: (ctx2, setState) {
        Future<void> pickReferenceImage() async {
          final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
          if (picked != null) {
            tempReference = picked;
            tempReferenceBytes = await picked.readAsBytes();
            errorText = null;
            setState(() {});
          }
        }

        return AlertDialog(
          title: const Text('Método de pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'Efectivo',
                groupValue: temp,
                title: const Text('Efectivo'),
                onChanged: (v) { setState(() => temp = v!); },
              ),
              RadioListTile<String>(
                value: 'Pago movil',
                groupValue: temp,
                title: const Text('Pago movil'),
                onChanged: (v) { setState(() => temp = v!); },
              ),
              if (temp == 'Pago movil') ...[
                const SizedBox(height: 6),
                Builder(builder: (ctx3) {
                  final bus = busInfo;
                  if (bus == null) return const SizedBox.shrink();
                  final ced = bus.mobileCedula?.isNotEmpty == true ? bus.mobileCedula! : '-';
                  final code = bus.mobileBankCode?.isNotEmpty == true ? bus.mobileBankCode! : '-';
                  final name = bus.mobileBankName?.isNotEmpty == true ? bus.mobileBankName! : '-';
                  final phone = bus.mobilePhone?.isNotEmpty == true ? bus.mobilePhone! : '-';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Datos para Pago Móvil', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(children: [Expanded(child: Text('Cédula: $ced', style: const TextStyle(fontWeight: FontWeight.w600))), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.copy, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: ced)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cédula copiada'))); })]),
                      Row(children: [Expanded(child: Text('Código del Banco: $code', style: const TextStyle(fontWeight: FontWeight.w600))), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.copy, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: code)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado'))); })]),
                      Row(children: [Expanded(child: Text('Banco: $name', style: const TextStyle(fontWeight: FontWeight.w600))), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.copy, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: name)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banco copiado'))); })]),
                      Row(children: [Expanded(child: Text('Teléfono: $phone', style: const TextStyle(fontWeight: FontWeight.w600))), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.copy, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: phone)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teléfono copiado'))); })]),
                      const SizedBox(height: 6),
                      const Text('Realice la transferencia usando estos datos antes de adjuntar su comprobante.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ]),
                  );
                }),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: pickReferenceImage,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Adjuntar referencia bancaria'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
                if (tempReference != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tempReference!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (tempReferenceBytes != null)
                          Image.memory(tempReferenceBytes!, height: 140, fit: BoxFit.contain),
                      ],
                    ),
                  ),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (temp == 'Pago movil' && tempReference == null) {
                  errorText = 'Debe adjuntar la referencia bancaria para Pago movil.';
                  setState(() {});
                  return;
                }
                selectedPayment = temp;
                paymentReferenceImage = tempReference;
                Navigator.of(ctx).pop();
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      });
    });

    if (!mounted) return; // <-- AGREGADO por seguridad tras cerrar el diálogo

    if (_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El administrador no puede comprar asientos.')));
      setState(() => _purchasing = false);
      return;
    }
    if (selectedPayment == null) {
      setState(() => _purchasing = false);
      return;
    }

    String? paymentReferenceUrl;
    String? paymentReferenceBase64;
    if (paymentReferenceImage != null) {
      try {
        // create a small thumbnail for DB preview (keeps size small)
        final bytes = await paymentReferenceImage!.readAsBytes();
        try {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            final resized = img.copyResize(decoded, width: 600);
            final jpg = img.encodeJpg(resized, quality: 72);
            paymentReferenceBase64 = base64Encode(jpg);
          }
        } catch (_) {
          paymentReferenceBase64 = null;
        }

        if (Firebase.apps.isNotEmpty && !kIsWeb) {
          final safeName = paymentReferenceImage!.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
          final ref = FirebaseStorage.instance.ref().child('payment_references/$userEmail/${DateTime.now().millisecondsSinceEpoch}_$safeName');
          final uploadTask = await ref.putData(bytes);
          paymentReferenceUrl = await uploadTask.ref.getDownloadURL();
        } else {
          if (mounted && kIsWeb) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firebase Storage no está disponible en Web. Se guardará miniatura en la base de datos para vista previa.')));
          }
          paymentReferenceUrl = null;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error procesando la referencia bancaria: $e')));
        }
        paymentReferenceUrl = null;
      }
    }

    // Persistir la reserva en Firestore si está disponible, usando reserva atómica
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirestoreService.instance.addBookings(
          horario.id,
          _selectedSeats.toList(),
          userEmail,
          status: 'purchased',
          paymentType: selectedPayment,
          paymentVerified: true,
          paymentReferenceName: paymentReferenceImage?.name,
          paymentReferenceUrl: paymentReferenceUrl,
          paymentReferenceBase64: paymentReferenceBase64,
          amount: horario.precio,
        );
        for (final i in _selectedSeats) {
          if (i < horario.asientosOcupados.length) horario.asientosOcupados[i] = true;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error registrando en servidor: $e')));
          setState(() => _purchasing = false);
          for (final i in _selectedSeats) {
            if (i < horario.asientosOcupados.length) horario.asientosOcupados[i] = false;
          }
        }
        return;
      }
    } else {
      // No hay Firebase: registrar localmente para pruebas
      try {
        for (final i in _selectedSeats) {
          await FirestoreService.instance.addLocalBooking(
            horario.id,
            i,
            userEmail,
            status: 'purchased',
            paymentType: selectedPayment,
            paymentVerified: true,
            paymentReferenceName: paymentReferenceImage?.name,
              paymentReferenceUrl: paymentReferenceUrl,
              paymentReferenceBase64: paymentReferenceBase64,
            amount: horario.precio,
          );
          if (i < horario.asientosOcupados.length) horario.asientosOcupados[i] = true;
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error registrando localmente: $e')));
        for (final i in _selectedSeats) {
          if (i < horario.asientosOcupados.length) horario.asientosOcupados[i] = false;
        }
      }
    }

    final purchasedSeats = _selectedSeats.toList();
    
    if (!mounted) return; // <-- CORREGIDO: Protección antes de limpiar estados y lanzar diálogos
    setState(() {
      _selectedSeats.clear();
      _purchasing = false;
    });
    
    final totalAmount = horario.precio * purchasedSeats.length;
    final seatNumbers = purchasedSeats.map((i) => (i + 1).toString()).join(', ');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ticket de Compra'),
        content: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TICKET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Text('Usuario: $userEmail'),
                const SizedBox(height: 8),
                Text('Fecha: ${DateTime.now().toString()}'),
                const SizedBox(height: 8),
                Text('Asientos: $seatNumbers'),
                const SizedBox(height: 8),
                Text('Monto total: \$${totalAmount.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ElevatedButton(onPressed: _downloadImage, child: const Text('Descargar ticket')),
        ],
      ),
    );
  }

  Future<void> _downloadImage() async {
    final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();
      final filename = 'ticket_${DateTime.now().millisecondsSinceEpoch}.png';
      final success = await downloadFile(filename, pngBytes, mimeType: 'image/png');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Ticket descargado correctamente' : 'Error al descargar el ticket')),
        );
      }
    }
  }

  Future<void> _reserve() async {
    if (_selectedSeats.isEmpty) return;
    setState(() => _purchasing = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final userEmail = prefs.getString('user_email');
    if (_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El administrador no puede reservar asientos.')));
      setState(() => _purchasing = false);
      return;
    }
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe iniciar sesión para reservar.')));
      setState(() => _purchasing = false);
      return;
    }

    // Intentar reservar atómicamente
    if (Firebase.apps.isNotEmpty) {
      try {
        final success = await FirestoreService.instance.bookMultipleSeats(horario.id, _selectedSeats.toList(), userEmail);
        if (!success) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uno o más asientos ya fueron reservados por otro usuario.')));
          if (mounted) setState(() => _purchasing = false);
          return;
        }
        for (final i in _selectedSeats) {
          await FirestoreService.instance.addBooking(horario.id, i, userEmail, status: 'reserved');
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error registrando reserva: $e')));
      }
    } else {
      try {
        for (final i in _selectedSeats) {
          await FirestoreService.instance.addLocalBooking(horario.id, i, userEmail, status: 'reserved');
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error registrando reserva local: $e')));
      }
    }

    if (!mounted) return; // <-- CORREGIDO
    setState(() {
      _selectedSeats.clear();
      _purchasing = false;
    });
    
    await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Reserva realizada'), content: const Text('Sus asientos han sido reservados.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }

  @override
  Widget build(BuildContext context) {
    final totalSeats = horario.asientosTotal;
    final availableSeats = totalSeats - horario.asientosOcupados.where((e) => e).length;

    const Color colorSelected = Color(0xFF26D0CE);  // Celeste/Turquesa
    const Color colorAvailable = Color(0xFF76D211); // Verde
    const Color colorBooked = Color(0xFF2B54FA);    // Azul para Comprado
    const Color colorReserved = Colors.orange;      // Naranja para Reservado
    const Color textDark = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), 
      appBar: AppBar(
        title: Text('Detalle: ${horario.ruta}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ruta: ${horario.ruta}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 6),
            Text('Salida: ${horario.salida}  •  Llegada: ${horario.llegada}', style: TextStyle(color: Colors.grey.shade600)),
            Text('Asientos disponibles: $availableSeats', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (_isAdmin) ...[
              const SizedBox(height: 8),
              const Text('Modo administrador: solo visualización de asientos.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
            
            const SizedBox(height: 16),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.radio_button_checked_rounded, color: Colors.grey.shade400, size: 28),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1.5),

                    Expanded(
                      child: StreamBuilder<List<Booking>>(
                        stream: FirestoreService.instance.allBookingsStream(),
                        builder: (context, snap) {
                          final bookings = snap.data ?? [];
                          final bookingsBySeat = <int, Booking>{};
                          for (final b in bookings.where((b) => b.horarioId == horario.id)) {
                            bookingsBySeat[b.seatIndex] = b;
                          }

                          return GridView.count(
                            crossAxisCount: 4, 
                            childAspectRatio: 1.0,
                            padding: const EdgeInsets.all(16),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: List.generate(totalSeats, (i) {
                              final booking = bookingsBySeat[i];
                              final released = booking?.seatReleased ?? false;
                              final occupied = (booking != null && !released) || _isOccupied(i);
                              final selected = _selectedSeats.contains(i);
                              final isPurchased = booking?.status == 'purchased' || (booking?.paymentVerified ?? false);

                              Color seatColor = colorAvailable;
                              if (selected) {
                                seatColor = colorSelected;
                              } else if (occupied) {
                                seatColor = isPurchased ? colorBooked : colorReserved;
                              }

                              const textColor = Colors.white;

                              final tooltipMessage = released
                                  ? 'Asiento liberado'
                                  : occupied
                                      ? (booking != null ? '${booking.status == 'purchased' ? 'Comprado' : 'Reservado'}' : 'Ocupado')
                                      : 'Libre';

                              return Tooltip(
                                message: tooltipMessage,
                                child: GestureDetector(
                                  onTap: () => _toggleSeat(i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    decoration: BoxDecoration(
                                      color: seatColor,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: selected ? [
                                        BoxShadow(color: colorSelected.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))
                                      ] : null,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('${i + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                                          if (booking != null && _isAdmin && !released) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              booking.userEmail.split('@').first,
                                              style: TextStyle(fontSize: 9, color: textColor.withOpacity(0.9)),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 14),
            
            if (!_isAdmin) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedSeats.isEmpty || _purchasing ? null : _purchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorBooked,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _purchasing ? const CircularProgressIndicator(color: Colors.white) : Text('Comprar (${_selectedSeats.length})'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedSeats.isEmpty || _purchasing ? null : _reserve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _purchasing ? const CircularProgressIndicator(color: Colors.white) : Text('Reservar (${_selectedSeats.length})'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() => _selectedSeats.clear());
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: textDark,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    tooltip: 'Cancelar selección',
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'Modo administrador: solo visualización de asientos comprados/reservados.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}