import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class FirestoreService {
  final FirebaseFirestore? _db;
  static FirestoreService? _instance;
  /// Getter singleton perezoso; llamar a `FirestoreService.instance` para obtenerlo.
  static FirestoreService get instance => _instance ??= FirestoreService._internal();
  FirestoreService._internal([FirebaseFirestore? db]) : _db = db ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  // Local in-memory bookings for testing when Firebase isn't initialized.
  final List<Booking> _localBookings = [];
  final StreamController<List<Booking>> _localController = StreamController<List<Booking>>.broadcast();

  /// Crea una instancia del servicio para pruebas con una instancia de Firestore
  /// inyectada o falsa.
  factory FirestoreService.forTest(FirebaseFirestore db) => FirestoreService._internal(db);

  /// Elimina un autobús de la colección utilizando su ID.
  Future<void> deleteBus(String busId) async {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    try {
      // Borrar document de bus
      await db.collection('buses').doc(busId).delete();
      // Borrar horarios asociados y sus bookings en cascada
      final horariosQ = await db.collection('horarios').where('busId', isEqualTo: int.tryParse(busId) ?? 0).get();
      for (final hdoc in horariosQ.docs) {
        final hid = int.tryParse(hdoc.id) ?? (hdoc.data()['id'] as int? ?? 0);
        // Borrar bookings de este horario
        final bookingsQ = await db.collection('bookings').where('horarioId', isEqualTo: hid).get();
        for (final b in bookingsQ.docs) {
          await b.reference.delete();
        }
        // Borrar el horario
        await hdoc.reference.delete();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error al eliminar el autobús en Firestore: $e');
      rethrow;
    }
  }

  Future<void> setHorario(Horario horario) async {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    final docRef = db.collection('horarios').doc(horario.id.toString());
    final booked = horario.asientosOcupados.asMap().entries.where((e) => e.value).map((e) => e.key).toList();
    return docRef.set({
      'id': horario.id,
      'ruta': horario.ruta,
      'salida': horario.salida,
      'llegada': horario.llegada,
      'busId': horario.busId,
      'asientosTotal': horario.asientosTotal,
      'precio': horario.precio,
      'bookedSeats': booked,
    }, SetOptions(merge: true));
  }

  Future<void> deleteHorario(int horarioId) async {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    final docRef = db.collection('horarios').doc(horarioId.toString());
    // Borrar bookings asociados
    final bookingsQ = await db.collection('bookings').where('horarioId', isEqualTo: horarioId).get();
    for (final b in bookingsQ.docs) {
      await b.reference.delete();
    }
    await docRef.delete();
  }

  Stream<Bus?> busStream(int id) {
    final db = _db;
    if (db == null) return Stream.value(null);
    return db.collection('buses').doc(id.toString()).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      return Bus(
        id: id,
        placa: data['placa'] ?? '',
        estado: data['estado'] ?? '',
        ubicacion: LatLng((data['lat'] ?? 0).toDouble(), (data['lng'] ?? 0).toDouble()),
        mobileCedula: data['mobileCedula'] as String?,
        mobileBankCode: data['mobileBankCode'] as String?,
        mobileBankName: data['mobileBankName'] as String?,
        mobilePhone: data['mobilePhone'] as String?,
      );
    });
  }

  /// Obtiene una sola vez los datos del bus con id dado desde Firestore.
  Future<Bus?> getBus(int id) async {
    final db = _db;
    if (db == null) return null;
    final snap = await db.collection('buses').doc(id.toString()).get();
    if (!snap.exists) return null;
    final data = snap.data()!;
    return Bus(
      id: id,
      placa: data['placa'] ?? '',
      estado: data['estado'] ?? '',
      ubicacion: (data['lat'] != null && data['lng'] != null) ? LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble()) : null,
      mobileCedula: data['mobileCedula'] as String?,
      mobileBankCode: data['mobileBankCode'] as String?,
      mobileBankName: data['mobileBankName'] as String?,
      mobilePhone: data['mobilePhone'] as String?,
    );
  }

  /// Obtiene todos los buses desde Firestore.
  Future<List<Bus>> getAllBuses() async {
    final db = _db;
    if (db == null) return [];
    final snap = await db.collection('buses').get();
    return snap.docs.map((d) {
      final data = d.data();
      final id = int.tryParse(d.id) ?? 0;
      return Bus(
        id: id,
        placa: data['placa'] ?? '',
        estado: data['estado'] ?? '',
        ubicacion: (data['lat'] != null && data['lng'] != null) ? LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble()) : null,
        mobileCedula: data['mobileCedula'] as String?,
        mobileBankCode: data['mobileBankCode'] as String?,
        mobileBankName: data['mobileBankName'] as String?,
        mobilePhone: data['mobilePhone'] as String?,
      );
    }).toList();
  }

  /// Obtiene todos los horarios desde Firestore.
  Future<List<Horario>> getAllHorarios() async {
    final db = _db;
    if (db == null) return [];
    final snap = await db.collection('horarios').get();
    return snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      final id = int.tryParse(d.id) ?? (data['id'] as int?) ?? 0;
      final asientosTotal = (data['asientosTotal'] as int?) ?? 40;
      final booked = List<int>.from(data['bookedSeats'] ?? []);
      final occupied = List<bool>.filled(asientosTotal, false);
      for (final i in booked) {
        if (i >= 0 && i < asientosTotal) occupied[i] = true;
      }
      return Horario(
        id: id,
        ruta: data['ruta'] ?? '',
        salida: data['salida'] ?? '',
        llegada: data['llegada'] ?? '',
        busId: (data['busId'] as int?) ?? 0,
        asientosTotal: asientosTotal,
        precio: (data['precio'] ?? 0).toDouble(),
        asientosOcupados: occupied,
      );
    }).toList();
  }

  Stream<Horario?> horarioStream(int id) {
    final db = _db;
    if (db == null) return Stream.value(null);
    return db.collection('horarios').doc(id.toString()).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      final map = Map<String, dynamic>.from(data);
      map['id'] = id;
      return Horario.fromMap(map);
    });
  }

  Future<void> updateBusLocation(int id, LatLng ubicacion, String estado) {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    return db.collection('buses').doc(id.toString()).set({
      'lat': ubicacion.latitude,
      'lng': ubicacion.longitude,
      'estado': estado,
    }, SetOptions(merge: true));
  }

  Future<void> setBus(int id, String placa, LatLng ubicacion, String estado, {String? mobileCedula, String? mobileBankCode, String? mobileBankName, String? mobilePhone}) {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    return db.collection('buses').doc(id.toString()).set({
      'placa': placa,
      'lat': ubicacion.latitude,
      'lng': ubicacion.longitude,
      'estado': estado,
      if (mobileCedula != null) 'mobileCedula': mobileCedula,
      if (mobileBankCode != null) 'mobileBankCode': mobileBankCode,
      if (mobileBankName != null) 'mobileBankName': mobileBankName,
      if (mobilePhone != null) 'mobilePhone': mobilePhone,
    }, SetOptions(merge: true));
  }

  Future<void> addBooking(int horarioId, int seatIndex, String userEmail, {String status = 'purchased', String? paymentType, bool? paymentVerified, String? paymentReferenceName, String? paymentReferenceUrl, String? paymentReferenceBase64, double? amount}) {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    final bookingRef = db.collection('bookings').doc();
    final horarioRef = db.collection('horarios').doc(horarioId.toString());
    return db.runTransaction((tx) async {
      final horarioSnap = await tx.get(horarioRef);
      final data = horarioSnap.exists ? Map<String, dynamic>.from(horarioSnap.data()!) : <String, dynamic>{};
      final booked = List<int>.from(data['bookedSeats'] ?? []);
      if (!booked.contains(seatIndex)) {
        booked.add(seatIndex);
      }
      tx.set(horarioRef, {'bookedSeats': booked}, SetOptions(merge: true));
      final bookingData = <String, Object?>{
        'horarioId': horarioId,
        'seatIndex': seatIndex,
        'userEmail': userEmail,
        'status': status,
        'paymentVerified': paymentVerified,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      };
      if (paymentType != null) bookingData['paymentType'] = paymentType;
      if (paymentReferenceName != null) bookingData['paymentReferenceName'] = paymentReferenceName;
      if (paymentReferenceUrl != null) bookingData['paymentReferenceUrl'] = paymentReferenceUrl;
      if (paymentReferenceBase64 != null) bookingData['paymentReferenceBase64'] = paymentReferenceBase64;
      tx.set(bookingRef, bookingData);
    });
  }

  Future<String> uploadDenunciaPhoto(String userEmail, Uint8List bytes, String filename) async {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance.ref().child('denuncia_photos/$userEmail/${timestamp}_$safeName');
    final uploadTask = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return uploadTask.ref.getDownloadURL();
  }

  Future<void> addDenuncia(String busPlaca, String description, String submittedBy, {String? photoUrl, String? photoBase64}) {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    final denunciaRef = db.collection('denuncias').doc();
    return denunciaRef.set({
      'busPlaca': busPlaca,
      'description': description,
      'submittedBy': submittedBy,
      'status': 'pendiente',
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoBase64 != null) 'photoBase64': photoBase64,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Denuncia>> denunciasStream() {
    final db = _db;
    if (db == null) return Stream.value([]);
    return db.collection('denuncias').orderBy('timestamp', descending: true).snapshots().map((snap) {
      return snap.docs.map((d) => Denuncia.fromMap(d.id, d.data())).toList();
    });
  }

  Stream<List<Denuncia>> userDenunciasStream(String userEmail) {
    final db = _db;
    if (db == null) return Stream.value([]);
    return db
        .collection('denuncias')
        .where('submittedBy', isEqualTo: userEmail)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => Denuncia.fromMap(d.id, d.data())).toList();
          list.sort((a, b) {
            final aTs = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTs = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTs.compareTo(aTs);
          });
          return list;
        });
  }

  Future<void> updateDenunciaStatus(String denunciaId, String status) {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    return db.collection('denuncias').doc(denunciaId).set({'status': status}, SetOptions(merge: true));
  }

  Future<void> deleteDenuncia(String denunciaId) {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    return db.collection('denuncias').doc(denunciaId).delete();
  }

  Future<void> addBookings(int horarioId, List<int> seatIndexes, String userEmail, {String status = 'purchased', String? paymentType, bool? paymentVerified, String? paymentReferenceName, String? paymentReferenceUrl, String? paymentReferenceBase64, double? amount}) {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    final horarioRef = db.collection('horarios').doc(horarioId.toString());
    return db.runTransaction((tx) async {
      final horarioSnap = await tx.get(horarioRef);
      final data = horarioSnap.exists ? Map<String, dynamic>.from(horarioSnap.data()!) : <String, dynamic>{};
      final booked = List<int>.from(data['bookedSeats'] ?? []);
      for (final seatIndex in seatIndexes) {
        if (booked.contains(seatIndex)) {
          throw StateError('Uno o más asientos ya están reservados.');
        }
        booked.add(seatIndex);
      }
      tx.set(horarioRef, {'bookedSeats': booked}, SetOptions(merge: true));
      for (final seatIndex in seatIndexes) {
        final bookingRef = db.collection('bookings').doc();
        final bookingData = <String, Object?>{
          'horarioId': horarioId,
          'seatIndex': seatIndex,
          'userEmail': userEmail,
          'status': status,
          'paymentVerified': paymentVerified,
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
        };
        if (paymentType != null) bookingData['paymentType'] = paymentType;
        if (paymentReferenceName != null) bookingData['paymentReferenceName'] = paymentReferenceName;
        if (paymentReferenceUrl != null) bookingData['paymentReferenceUrl'] = paymentReferenceUrl;
        if (paymentReferenceBase64 != null) bookingData['paymentReferenceBase64'] = paymentReferenceBase64;
        tx.set(bookingRef, bookingData);
      }
    });
  }

  Future<void> cancelBooking(int horarioId, int seatIndex, String userEmail) async {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    final col = db.collection('bookings');
    final q = await col.where('horarioId', isEqualTo: horarioId).where('seatIndex', isEqualTo: seatIndex).where('userEmail', isEqualTo: userEmail).get();
    for (final d in q.docs) {
      await d.reference.delete();
    }
    // También eliminar el asiento de `horario.bookedSeats`
    final docRef = db.collection('horarios').doc(horarioId.toString());
    await db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = snap.exists ? snap.data()! : <String, dynamic>{};
      final booked = List<int>.from(data['bookedSeats'] ?? []);
      booked.removeWhere((s) => s == seatIndex);
      tx.set(docRef, {'bookedSeats': booked}, SetOptions(merge: true));
    });
  }

  /// Busca reservas con `status == 'reserved'` anteriores a [maxAge] y las cancela.
  /// Esto elimina el documento de booking y actualiza `horarios/{id}.bookedSeats` en una transacción.
  Future<void> expireOldReservations(Duration maxAge) async {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    final cutoff = DateTime.now().toUtc().subtract(maxAge);
    final q = await db.collection('bookings').where('status', isEqualTo: 'reserved').where('timestamp', isLessThan: cutoff).get();
    for (final doc in q.docs) {
      final data = doc.data();
      final horarioId = (data['horarioId'] as int?) ?? int.tryParse(data['horarioId']?.toString() ?? '') ?? 0;
      final seatIndex = (data['seatIndex'] as int?) ?? int.tryParse(data['seatIndex']?.toString() ?? '') ?? 0;
      final docRef = doc.reference;
      final horarioRef = db.collection('horarios').doc(horarioId.toString());
      await db.runTransaction((tx) async {
        final snap = await tx.get(horarioRef);
        final map = snap.exists ? Map<String, dynamic>.from(snap.data()!) : <String, dynamic>{};
        final booked = List<int>.from(map['bookedSeats'] ?? []);
        booked.removeWhere((s) => s == seatIndex);
        tx.set(horarioRef, {'bookedSeats': booked}, SetOptions(merge: true));
        tx.delete(docRef);
      });
    }
  }

  Future<void> clearAllBookedSeats() async {
    final db = _db;
    if (db == null) {
      // Marca localmente como liberado cuando Firebase no está disponible
      for (var i = 0; i < _localBookings.length; i++) {
        _localBookings[i] = _localBookings[i].copyWith(seatReleased: true);
      }
      _localController.add(List<Booking>.from(_localBookings));
      return;
    }

    final horarios = await db.collection('horarios').get();
    final bookings = await db.collection('bookings').get();
    if (horarios.docs.isEmpty && bookings.docs.isEmpty) return;

    var batch = db.batch();
    var writeCount = 0;

    for (final doc in horarios.docs) {
      batch.set(doc.reference, {'bookedSeats': []}, SetOptions(merge: true));
      writeCount += 1;
      if (writeCount >= 450) {
        await batch.commit();
        batch = db.batch();
        writeCount = 0;
      }
    }

    for (final doc in bookings.docs) {
      batch.set(doc.reference, {'seatReleased': true}, SetOptions(merge: true));
      writeCount += 1;
      if (writeCount >= 450) {
        await batch.commit();
        batch = db.batch();
        writeCount = 0;
      }
    }

    if (writeCount > 0) {
      await batch.commit();
    }
  }

  Stream<List<Booking>> userBookingsStream(String userEmail) {
    final db = _db;
    if (db == null) {
      return (() async* {
        // Emitir estado actual primero
        yield List<Booking>.from(_localBookings.where((b) => b.userEmail == userEmail).toList());
        await for (final list in _localController.stream) {
          yield list.where((b) => b.userEmail == userEmail).toList();
        }
      })();
    }
    return db.collection('bookings').where('userEmail', isEqualTo: userEmail).snapshots().map((snap) => snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  /// Stream de todas las reservas (útil para pantallas de administrador)
  Stream<List<Booking>> allBookingsStream() {
    final db = _db;
    if (db == null) {
      return (() async* {
        yield List<Booking>.from(_localBookings);
        await for (final list in _localController.stream) {
          yield List<Booking>.from(list);
        }
      })();
    }
    return db.collection('bookings').orderBy('timestamp', descending: true).snapshots().map((snap) => snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  /// Obtiene el precio del horario por su id. Devuelve null si no existe o no está inicializado.
  Future<double?> getHorarioPrice(int horarioId) async {
    final db = _db;
    if (db == null) return null;
    final doc = await db.collection('horarios').doc(horarioId.toString()).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final p = data['precio'];
    if (p == null) return null;
    try {
      return (p as num).toDouble();
    } catch (_) {
      return null;
    }
  }

  /// Añade una reserva local (para pruebas en entorno sin Firebase).
  Future<void> addLocalBooking(int horarioId, int seatIndex, String userEmail, {String status = 'purchased', String? paymentType, bool? paymentVerified, String? paymentReferenceName, String? paymentReferenceUrl, String? paymentReferenceBase64, double? amount}) async {
    final now = DateTime.now().toUtc();
    final id = 'local-${now.millisecondsSinceEpoch}';
    final booking = Booking(id: id, horarioId: horarioId, seatIndex: seatIndex, userEmail: userEmail, timestamp: now, status: status, paymentType: paymentType, paymentVerified: paymentVerified, paymentReferenceName: paymentReferenceName, paymentReferenceUrl: paymentReferenceUrl, paymentReferenceBase64: paymentReferenceBase64, cancelledAt: null, amount: amount);
    _localBookings.insert(0, booking);
    _localController.add(List<Booking>.from(_localBookings));
  }

  Future<void> updateHorarioBookedSeats(int horarioId, List<int> bookedSeats) {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    return db.collection('horarios').doc(horarioId.toString()).set({'bookedSeats': bookedSeats}, SetOptions(merge: true));
  }

  Future<bool> bookMultipleSeats(int horarioId, List<int> seats, String userEmail) async {
    final db = _db;
    if (db == null) return Future.error(StateError('Firebase not initialized'));
    final docRef = db.collection('horarios').doc(horarioId.toString());
    return db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = snap.exists ? snap.data()! : <String, dynamic>{};
      final booked = List<int>.from(data['bookedSeats'] ?? []);
      // Comprobar disponibilidad
      for (final s in seats) {
        if (booked.contains(s)) return false; // ya reservado
      }
      booked.addAll(seats);
      tx.set(docRef, {'bookedSeats': booked}, SetOptions(merge: true));
      return true;
    });
  }
}