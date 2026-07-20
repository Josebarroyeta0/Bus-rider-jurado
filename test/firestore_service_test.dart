import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:bus_rider_app/services/firestore_service.dart';

void main() {
  test('setBus and busStream work with fake Firestore', () async {
    final fakeDb = FakeFirebaseFirestore();
    final service = FirestoreService.forTest(fakeDb);

    final busId = 42;
    final placa = 'ZZZ-999';
    final estado = 'En Ruta Test';
    final ubicacion = LatLng(1.1, 2.2);

    await service.setBus(busId, placa, ubicacion, estado);

    // Read back document
    final stream = service.busStream(busId);
    final bus = await stream.first;

    expect(bus, isNotNull);
    expect(bus!.placa, placa);
    expect(bus.estado, estado);
    expect(bus.ubicacion!.latitude, closeTo(1.1, 0.00001));
    expect(bus.ubicacion!.longitude, closeTo(2.2, 0.00001));
  });

  test('updateBusLocation updates an existing doc', () async {
    final fakeDb = FakeFirebaseFirestore();
    final service = FirestoreService.forTest(fakeDb);

    final busId = 100;

    await service.setBus(busId, 'TEST-100', LatLng(0, 0), 'Inicial');
    await service.updateBusLocation(busId, LatLng(3.3, 4.4), 'Actualizado');

    final bus = await service.busStream(busId).firstWhere((b) => b != null);
    expect(bus, isNotNull);
    expect(bus!.estado, 'Actualizado');
    expect(bus.ubicacion!.latitude, closeTo(3.3, 0.00001));
    expect(bus.ubicacion!.longitude, closeTo(4.4, 0.00001));
  });
}
