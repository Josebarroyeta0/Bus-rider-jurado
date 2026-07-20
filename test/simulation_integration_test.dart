import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:bus_rider_app/services/firestore_service.dart';

void main() {
  test('simulation sends multiple updates and stream receives them', () async {
    final fakeDb = FakeFirebaseFirestore();
    final service = FirestoreService.forTest(fakeDb);
    final busId = 77;

    await service.setBus(busId, 'SIM-77', LatLng(0, 0), 'Init');

    final updates = <String>[];
    final sub = service.busStream(busId).listen((bus) {
      if (bus != null) updates.add(bus.estado);
    });

    // Simulate admin updates
    await service.updateBusLocation(busId, LatLng(1.0, 1.0), 'First');
    await Future.delayed(Duration(milliseconds: 10));
    await service.updateBusLocation(busId, LatLng(2.0, 2.0), 'Second');
    await Future.delayed(Duration(milliseconds: 50));

    expect(updates.length, greaterThanOrEqualTo(3)); // initial set plus 2 updates
    expect(updates.contains('First'), isTrue);
    expect(updates.contains('Second'), isTrue);

    await sub.cancel();
  });
}
