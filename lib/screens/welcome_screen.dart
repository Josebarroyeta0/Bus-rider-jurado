import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

 @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2B54FA);
    const textDark = Color(0xFF000000);
    const textMuted = Color(0xFF555555);
    const bgLight = Color(0xFFF5F7FB);
    const sidebarDark = Color(0xFF1A2340); // El color azul oscuro de la franja izquierda de referencia

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Row(
          children: [
            // Franja lateral decorativa (Estilo maqueta Zagreb)
            Container(
              width: 80, // Puedes ajustar el ancho o removerlo si es para pantallas muy angostas
              color: sidebarDark,
              child: const Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'BUS GUÁRICO',
                    style: TextStyle(
                      color: Colors.white24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            
            // Contenido Principal del Sistema
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    
                    // 1. Encabezado con Logo y Nombre Centrado
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/Logo.png',
                            width: 90,
                            height: 90,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.directions_bus, size: 75, color: primaryBlue);
                            },
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Bus Guarico Rider',
                            style: TextStyle(
                              fontSize: 24, 
                              color: textDark, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 2. Primer Bloque Independiente: Sobre Nosotros
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Sobre nosotros',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Bus Guarico es el sistema de transporte público que conecta a las comunidades de Guárico con viajes seguros, eficientes y accesibles.',
                            style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // 3. Bloques en paralelo por separado: Misión y Visión
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cuadro Separado: Misión
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Nuestra Misión',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Proveer un servicio de transporte público masivo, eficiente, seguro y de alta calidad para todo el pueblo guariqueño. Nos comprometemos a conectar a nuestras comunidades, garantizar la movilidad diaria de estudiantes, trabajadores y familias, y ofrecer tarifas accesibles que impulsen el bienestar social y el desarrollo económico de nuestra región llanera.',
                                  style: TextStyle(fontSize: 11, color: textMuted, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Cuadro Separado: Visión
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Nuestra Visión',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Consolidarnos como el sistema de transporte terrestre modelo en el centro de Venezuela, reconocido por la modernización de nuestras unidades, la optimización inteligente de nuestras rutas y la excelencia en la atención al usuario. Aspiramos a ser una red de movilidad integrada y sostenible que transforme la manera de viajar en Guárico, conectando el futuro y el progreso de nuestro estado.',
                                  style: TextStyle(fontSize: 11, color: textMuted, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 4. NUEVO Cuadro Azul Destacado Grande (Alineado a la izquierda según especificaciones)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Text(
                        'El corazón de Guárico\nse mueve sobre ruedas.\n¡Viaja con nosotros!',
                        textAlign: TextAlign.left, // Alineación exacta a la izquierda
                        style: TextStyle(
                          fontSize: 18, // Texto más grande e impactante tipo Hero Banner
                          fontWeight: FontWeight.w800, 
                          color: Colors.white,
                          height: 1.4,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 5. Redes Sociales
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              await launchUrlString('https://www.facebook.com/profile.php?id=100063928697025', mode: LaunchMode.externalApplication);
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.facebook, color: textDark, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Facebook: @BusGuarico',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textDark.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              await launchUrlString('https://www.instagram.com/busguaricooficial?igsh=NXJ0ZjFocjRqZHh5', mode: LaunchMode.externalApplication);
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.camera_alt, color: textDark, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Instagram: @busguaricooficial',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textDark.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // 6. Botón de Acción Inferior
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryBlue,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Ir a inicio de sesión', 
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}