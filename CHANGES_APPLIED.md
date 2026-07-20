Resumen de cambios aplicados
=============================

- Migraciones y correcciones:
  - Reemplazo de Google Maps por `flutter_map` + `latlong2` para soporte web sin API key.
  - Implementación de `FirestoreService` con métodos: `busStream`, `horarioStream`, `updateBusLocation`, `setBus`, `addBooking`, `cancelBooking`, `expireOldReservations`, `userBookingsStream`, `updateHorarioBookedSeats`, `bookMultipleSeats`.
  - Implementación de pantallas y UI: `login_screen`, `home_screen`, `mapa_tracking_screen`, `admin_screen`, `bus_detalle_screen`, `my_bookings_screen`.
  - Implementación de lógica de reserva atómica y expiración de reservas `reserved` antiguas con Cloud Function.

- Correcciones y lints:
  - Revisión y corrección de lints (uso de `super.key`, `State<T>`, `child` como último argumento, uso de `mounted` antes de usar `BuildContext`, reemplazo de `print` por `debugPrint`).
  - Limpieza de imports en tests y pequeños refactors para evitar `!` innecesarios.

- Tests y CI:
  - `flutter test` pasa con 6 tests; `flutter analyze` ahora no muestra issues.
  - Scripts para deployment y PR ya existen en `scripts/`.

Notas:
- El repositorio no cuenta con `git` instalado en el entorno de ejecución, por lo que no se pudieron crear ramas ni commits aquí.
- Para crear un parche de los cambios y enviarlo a GitHub, usa `scripts/generate_patch.sh` o tus comandos `git` habituales.

Siguientes pasos recomendados:
- Crear la rama y subir los cambios: `git checkout -b fix/lints-and-safety` + `git add .` + `git commit -m 'chore: …'` + `git push -u origin fix/lints-and-safety`.
- Crear PR (opcional con `gh pr create` o `scripts/create_pr.sh` / `scripts/create_pr.ps1`).
- Configurar `firebase_options.dart` y `FIREBASE_TOKEN` en GitHub Secrets para despliegue automatizado.  