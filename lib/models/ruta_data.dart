import 'package:latlong2/latlong.dart';
import 'models.dart';

class RutaGuarico {
  // Puntos de referencia con coordenadas geográficas reales de la Troncal 2
  static final LatLng sanJuan = const LatLng(9.9114, -67.3551);
  static final LatLng ortiz = const LatLng(9.6225, -67.2913);
  static final LatLng mellado = const LatLng(9.3879, -67.0540); // El Sombrero - Mellado

  // Lista detallada que sigue el trazado real de la carretera nacional
  static final List<LatLng> rutaCompleta = [
    sanJuan,                         // Salida de San Juan de los Morros
    const LatLng(9.8895, -67.3482),  // Bajada hacia El Portal
    const LatLng(9.8312, -67.3245),  // Parapara
    const LatLng(9.7481, -67.3110),  // Flores
    ortiz,                           // Entrada / Casco central de Ortiz
    const LatLng(9.5310, -67.2840),  // Dos Caminos (Cruce vial)
    const LatLng(9.4752, -67.2185),  // Tramo Los Robles
    const LatLng(9.4210, -67.1320),  // Aproximación por la Troncal 2
    mellado,                         // Llegada al Sector Mellado (El Sombrero)
  ];

  // Lista de buses actualizada con las coordenadas corregidas
  static final List<Bus> buses = [
    Bus(id: 1, placa: 'ABC-123', estado: 'En Ruta', ubicacion: sanJuan),
    Bus(id: 2, placa: 'DEF-456', estado: 'Disponible', ubicacion: ortiz),
  ];

  // Horarios de salida vinculados perfectamente
  static final List<Horario> horarios = [
    Horario(id: 1, ruta: 'San Juan - Ortiz - Mellado', salida: '08:00', llegada: '10:00', busId: 1, asientosTotal: 40, precio: 10.0),
    Horario(id: 2, ruta: 'San Juan - Ortiz - Mellado', salida: '11:00', llegada: '13:00', busId: 2, asientosTotal: 40, precio: 10.0),
  ];
}