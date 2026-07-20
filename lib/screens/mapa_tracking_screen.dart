import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ruta_data.dart';
import '../models/models.dart';

class MapaTrackingScreen extends StatefulWidget {
  final int busId;
  const MapaTrackingScreen({super.key, required this.busId});

  @override
  State<MapaTrackingScreen> createState() => _MapaTrackingScreenState();
}

class _MapaTrackingScreenState extends State<MapaTrackingScreen> {
  final fm.MapController _mapController = fm.MapController();
  final List<fm.Marker> _markers = [];
  final List<fm.Polyline> _polylines = [];
  Bus? _busActual;

  @override
  void initState() {
    super.initState();
    _escucharUbicacionBus();
    _buildPolylines();
  }

  void _escucharUbicacionBus() {
    // Si Firebase no está configurado (no hay apps inicializadas), no suscribirse.
    if (Firebase.apps.isEmpty) return;

    // Escucha directa en tiempo real al documento 'autous' dentro de 'viajes_activos'
    FirebaseFirestore.instance
        .collection('viajes_activos')
        .doc('autous') // ID exacto de tu consola Firebase
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        
        // Controlamos de forma segura que los números se lean como double (evita crasheos en Web)
        final double? lat = data['latitud'] is int ? (data['latitud'] as int).toDouble() : data['latitud'];
        final double? lng = data['longitud'] is int ? (data['longitud'] as int).toDouble() : data['longitud'];

        if (lat != null && lng != null) {
          final pos = LatLng(lat, lng);

          setState(() {
            _busActual = Bus(
              id: widget.busId,
              placa: data['placa'] ?? 'Bus-01',
              estado: (data['velocidad'] != null && data['velocidad'] > 0) 
                  ? 'En movimiento (${data['velocidad']} km/h)' 
                  : 'Detenido',
              ultimaActualizacion: DateTime.now(),
              ubicacion: pos,
            );
            _actualizarMarcadorBus();
          });

          // Mueve la cámara del mapa para seguir al autobús de forma fluida
          _mapController.move(pos, 14.5);
          
          // Recalcula el segmento iluminado de la ruta en base a la nueva posición
          _buildPolylines(pos);
        }
      }
    });
  }

  void _actualizarMarcadorBus() {
    final pos = _busActual?.ubicacion;
    if (pos == null) return;
    
    _markers.removeWhere((m) => m.key == Key('bus_${widget.busId}'));
    _markers.add(fm.Marker(
      key: Key('bus_${widget.busId}'),
      point: pos,
      width: 40,
      height: 40,
      child: const Icon(Icons.directions_bus, color: Colors.red, size: 32),
    ));
  }

  void _buildPolylines([LatLng? busPos]) {
    final route = RutaGuarico.rutaCompleta;
    final List<fm.Polyline> built = [];
    
    // Contorno y línea base
    built.add(fm.Polyline(points: route, color: Colors.black.withAlpha(204), strokeWidth: 9));
    built.add(fm.Polyline(points: route, color: Colors.redAccent, strokeWidth: 5));

    // Si tenemos posición del bus, calcular el segmento más cercano y resaltarlo
    if (busPos != null && route.length >= 2) {
      int nearestSegIndex = 0;
      double minSegD = double.infinity;

      double distanceToSegment(LatLng p, LatLng a, LatLng b) {
        final dx = b.longitude - a.longitude;
        final dy = b.latitude - a.latitude;
        final len2 = dx * dx + dy * dy;
        if (len2 == 0) {
          final dist = Distance();
          return dist.distance(p, a);
        }
        final t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) / len2;
        final tt = t < 0 ? 0 : (t > 1 ? 1 : t);
        final proj = LatLng(a.latitude + dy * tt, a.longitude + dx * tt);
        final dist = Distance();
        return dist.distance(p, proj);
      }

      for (int i = 0; i < route.length - 1; i++) {
        final a = route[i];
        final b = route[i + 1];
        final d = distanceToSegment(busPos, a, b);
        if (d < minSegD) {
          minSegD = d;
          nearestSegIndex = i;
        }
      }

      // Aumentar la ventana del segmento resaltado
      const int highlightRadius = 3;
      final startSeg = (nearestSegIndex - highlightRadius) < 0 ? 0 : (nearestSegIndex - highlightRadius);
      final endSeg = (nearestSegIndex + highlightRadius) >= (route.length - 1) ? (route.length - 2) : (nearestSegIndex + highlightRadius);
      
      final highlightPoints = route.sublist(startSeg, endSeg + 2);
      if (highlightPoints.length >= 2) {
        built.add(fm.Polyline(points: highlightPoints, color: Colors.yellowAccent, strokeWidth: 8));
      }
    }

    setState(() {
      _polylines
        ..clear()
        ..addAll(built);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking ${_busActual?.placa ?? 'Bus'}'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          fm.FlutterMap(
            mapController: _mapController,
            // CORREGIDO: Se quitó el 'const' aquí para solucionar el error invalid_constant
            options: fm.MapOptions(
              initialCenter: RutaGuarico.sanJuan, 
              initialZoom: 13,
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              fm.PolylineLayer(polylines: _polylines),
              fm.MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _busActual?.estado ?? 'Cargando ubicación...', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Última actualización: ${DateTime.now().toString().substring(11, 16)}',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}