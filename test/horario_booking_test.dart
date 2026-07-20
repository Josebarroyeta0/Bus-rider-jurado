import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_rider_app/services/firestore_service.dart';

void main() {
  test('bookMultipleSeats updates horario bookedSeats atomically', () async {
    final fakeDb = FakeFirebaseFirestore();
    final service = FirestoreService.forTest(fakeDb);
    final horarioId = 55;
    // Initialize horario doc
    await fakeDb.collection('horarios').doc(horarioId.toString()).set({'bookedSeats': [1,3]});
    // Try booking seats: one already booked (3) and one free (2)
    final success = await service.bookMultipleSeats(horarioId, [2,4], 'user@test.com');
    expect(success, true);
    final doc = await fakeDb.collection('horarios').doc(horarioId.toString()).get();
    final booked = List<int>.from(doc.data()!['bookedSeats']);
    expect(booked.contains(2), true);
    expect(booked.contains(4), true);
  });
}
