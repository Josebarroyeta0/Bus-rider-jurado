import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class Horario {
  final int id;
  final String ruta, salida, llegada;
  final int busId, asientosTotal;
  final double precio;
  List<bool> asientosOcupados; // Ejemplo

  Horario({
    required this.id,
    required this.ruta,
    required this.salida,
    required this.llegada,
    required this.busId,
    required this.asientosTotal,
    required this.precio,
    List<bool>? asientosOcupados,
  }) : asientosOcupados = asientosOcupados ?? List.filled(asientosTotal, false);

  factory Horario.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as int? ?? 0;
    final asientosTotal = map['asientosTotal'] as int? ?? 40;
    final booked = List<int>.from(map['bookedSeats'] ?? []);
    final occupied = List<bool>.filled(asientosTotal, false);
    for (final i in booked) {
      if (i >= 0 && i < asientosTotal) {
        occupied[i] = true;
      }
    }
    return Horario(
      id: id,
      ruta: map['ruta'] ?? '',
      salida: map['salida'] ?? '',
      llegada: map['llegada'] ?? '',
      busId: map['busId'] ?? 0,
      asientosTotal: asientosTotal,
      precio: (map['precio'] ?? 0).toDouble(),
      asientosOcupados: occupied,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'ruta': ruta,
        'salida': salida,
        'llegada': llegada,
        'busId': busId,
        'asientosTotal': asientosTotal,
        'precio': precio,
        'bookedSeats': asientosOcupados.asMap().entries.where((e) => e.value).map((e) => e.key).toList(),
      };
}

class Bus {
  final int id;
  final String placa, estado;
  final LatLng? ubicacion;
  final DateTime? ultimaActualizacion;
  final String? mobileCedula;
  final String? mobileBankCode;
  final String? mobileBankName;
  final String? mobilePhone;
  Bus({required this.id, required this.placa, required this.estado, this.ubicacion, this.ultimaActualizacion, this.mobileCedula, this.mobileBankCode, this.mobileBankName, this.mobilePhone});
}

class Booking {
  final String id;
  final int horarioId;
  final int seatIndex;
  final String userEmail;
  final DateTime? timestamp;
  final String? status;
  final String? paymentType;
  final bool? paymentVerified;
  final bool? seatReleased;
  final String? paymentReferenceName;
  final String? paymentReferenceUrl;
  final String? paymentReferenceBase64;
  final DateTime? cancelledAt;
  final double? amount;
  Booking({required this.id, required this.horarioId, required this.seatIndex, required this.userEmail, this.timestamp, this.status, this.paymentType, this.paymentVerified, this.seatReleased, this.paymentReferenceName, this.paymentReferenceUrl, this.paymentReferenceBase64, this.cancelledAt, this.amount});
  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    DateTime? parsedTimestamp;
    if (rawTimestamp == null) {
      parsedTimestamp = null;
    } else if (rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      parsedTimestamp = rawTimestamp;
    }
    DateTime? cancelled;
    final rawCancelled = map['cancelledAt'];
    if (rawCancelled is Timestamp) {
      cancelled = rawCancelled.toDate();
    } else if (rawCancelled is DateTime) {
      cancelled = rawCancelled;
    }
    double? parsedAmount;
    final rawAmount = map['amount'];
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else {
      parsedAmount = null;
    }

    return Booking(
      id: id,
      horarioId: (map['horarioId'] as int?) ?? 0,
      seatIndex: (map['seatIndex'] as int?) ?? 0,
      userEmail: (map['userEmail'] as String?) ?? '',
      timestamp: parsedTimestamp,
      status: map['status'] as String?,
      paymentType: map['paymentType'] as String?,
      paymentVerified: map['paymentVerified'] as bool?,
      seatReleased: map['seatReleased'] as bool? ?? false,
      paymentReferenceName: map['paymentReferenceName'] as String?,
      paymentReferenceUrl: map['paymentReferenceUrl'] as String?,
      paymentReferenceBase64: map['paymentReferenceBase64'] as String?,
      cancelledAt: cancelled,
      amount: parsedAmount,
    );
  }

  Booking copyWith({
    String? id,
    int? horarioId,
    int? seatIndex,
    String? userEmail,
    DateTime? timestamp,
    String? status,
    String? paymentType,
    bool? paymentVerified,
    bool? seatReleased,
    String? paymentReferenceName,
    String? paymentReferenceUrl,
    String? paymentReferenceBase64,
    DateTime? cancelledAt,
    double? amount,
  }) {
    return Booking(
      id: id ?? this.id,
      horarioId: horarioId ?? this.horarioId,
      seatIndex: seatIndex ?? this.seatIndex,
      userEmail: userEmail ?? this.userEmail,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      paymentType: paymentType ?? this.paymentType,
      paymentVerified: paymentVerified ?? this.paymentVerified,
      seatReleased: seatReleased ?? this.seatReleased,
      paymentReferenceName: paymentReferenceName ?? this.paymentReferenceName,
      paymentReferenceUrl: paymentReferenceUrl ?? this.paymentReferenceUrl,
      paymentReferenceBase64: paymentReferenceBase64 ?? this.paymentReferenceBase64,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      amount: amount ?? this.amount,
    );
  }
}

class Denuncia {
  final String id;
  final String busPlaca;
  final String description;
  final String submittedBy;
  final DateTime? timestamp;
  final String status;
  final String? photoUrl;
  final String? photoBase64;

  Denuncia({
    required this.id,
    required this.busPlaca,
    required this.description,
    required this.submittedBy,
    this.timestamp,
    this.status = 'pendiente',
    this.photoUrl,
    this.photoBase64,
  });

  factory Denuncia.fromMap(String id, Map<String, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    DateTime? parsedTimestamp;
    if (rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      parsedTimestamp = rawTimestamp;
    }

    return Denuncia(
      id: id,
      busPlaca: (map['busPlaca'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      submittedBy: (map['submittedBy'] as String?) ?? '',
      timestamp: parsedTimestamp,
      status: (map['status'] as String?) ?? 'pendiente',
      photoUrl: map['photoUrl'] as String?,
      photoBase64: map['photoBase64'] as String?,
    );
  }
}
