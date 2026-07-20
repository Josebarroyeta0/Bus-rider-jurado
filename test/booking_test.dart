import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:bus_rider_app/services/firestore_service.dart';

void main() {
  test('addBooking stores booking doc in fake Firestore', () async {
    final fakeDb = FakeFirebaseFirestore();
    final service = FirestoreService.forTest(fakeDb);

    await service.addBooking(10, 5, 'testuser@example.com');
    final snapshots = await fakeDb.collection('bookings').get();
    expect(snapshots.docs.length, 1);
    final data = snapshots.docs.first.data();
    expect(data['horarioId'], 10);
    expect(data['seatIndex'], 5);
    expect(data['userEmail'], 'testuser@example.com');
  });
}
