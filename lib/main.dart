import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/firestore_service.dart';
import 'models/ruta_data.dart';

void main() async {
  // Asegura que los bindings de Flutter estén listos antes de inicializar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializa Firebase correctamente en cualquier plataforma (Web, Android, Windows)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('¡Firebase inicializado con éxito!');
  } catch (e) {
    // Si ocurre un problema, te lo mostrará detalladamente en la terminal
    debugPrint('Error crítico al inicializar Firebase: $e');
  }

  // Si Firebase se inicializó, cargamos los datos persistidos (buses y horarios)
  if (Firebase.apps.isNotEmpty) {
    try {
      final buses = await FirestoreService.instance.getAllBuses();
      final horarios = await FirestoreService.instance.getAllHorarios();
      if (buses.isNotEmpty) {
        RutaGuarico.buses
          ..clear()
          ..addAll(buses);
      } else {
        // Si Firestore no tiene buses pero hay datos locales, subirlos para persistencia
        if (RutaGuarico.buses.isNotEmpty) {
          for (final b in RutaGuarico.buses) {
              try {
              await FirestoreService.instance.setBus(b.id, b.placa, b.ubicacion ?? RutaGuarico.sanJuan, b.estado, mobileCedula: b.mobileCedula, mobileBankCode: b.mobileBankCode, mobileBankName: b.mobileBankName, mobilePhone: b.mobilePhone);
            } catch (e) {
              debugPrint('No se pudo migrar bus ${b.id} a Firestore: $e');
            }
          }
        }
      }
      if (horarios.isNotEmpty) {
        // Filtrar horarios que referencien buses inexistentes para evitar horarios huérfanos (busId 0)
        if (buses.isNotEmpty) {
          final validBusIds = buses.map((b) => b.id).toSet();
          final filtered = horarios.where((h) => validBusIds.contains(h.busId)).toList();
          final skipped = horarios.length - filtered.length;
          if (skipped > 0) debugPrint('Se omitieron $skipped horarios que referenciaban buses inexistentes.');
          RutaGuarico.horarios
            ..clear()
            ..addAll(filtered);
        } else {
          RutaGuarico.horarios
            ..clear()
            ..addAll(horarios);
        }
      }
      debugPrint('Datos cargados desde Firestore: ${RutaGuarico.buses.length} buses, ${RutaGuarico.horarios.length} horarios');
    } catch (e) {
      debugPrint('No se pudieron cargar datos desde Firestore al inicio: $e');
    }
  }

  // Si Firebase no logró inicializar ninguna app, inserta los datos locales de prueba
  if (Firebase.apps.isEmpty) {
    try {
      final horarioId = RutaGuarico.horarios.isNotEmpty ? RutaGuarico.horarios.first.id : 1;
      final seat = 1;
      final email = 'tester@example.com';
      final amount = RutaGuarico.horarios.isNotEmpty ? RutaGuarico.horarios.first.precio : 10.0;
      
      await FirestoreService.instance.addLocalBooking(
        horarioId, 
        seat, 
        email, 
        status: 'purchased', 
        paymentType: 'Efectivo', 
        paymentVerified: true, 
        amount: amount,
      );
      debugPrint('Compra de prueba local añadida con éxito');
    } catch (e) {
      debugPrint('No se pudo añadir la compra de prueba local: $e');
    }
  }

  // Arranca la aplicación
  runApp(const BusRiderGuaricoApp());
}

class BusRiderGuaricoApp extends StatelessWidget {
  const BusRiderGuaricoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus San Juan - Ortiz - Mellado',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.red).copyWith(
          secondary: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, 
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, 
            foregroundColor: Colors.white,
          ),
        ),
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}