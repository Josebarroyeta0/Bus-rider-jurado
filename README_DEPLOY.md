# Despliegue local y CI para Bus Rider App

Este documento explica cómo desplegar la aplicación web y las Cloud Functions (expireOldReservations) localmente y cómo configurar el despliegue automático desde GitHub Actions.

Requisitos previos
- Node.js y npm
- Firebase CLI (`firebase-tools`) instalado globalmente
- Acceso al proyecto Firebase (ID) y permisos para desplegar

Pasos: instalación y login
1. Instalar Firebase CLI:
```bash
npm install -g firebase-tools
```
2. Autenticarse:
```bash
firebase login
```

Despliegue local (interactivo)
1. Desde la raíz del repo:
```bash
cd "C:/Users/jarma/Desktop/Tesis Rider_San juan/bus_rider_app"
# PowerShell
.\scripts\deploy_local.ps1
# Bash
./scripts/deploy_local.sh
```
El script hará `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web --release` y luego `firebase deploy --only hosting,functions` (interactivo).

Despliegue con token CI (no compartir el token públicamente)
1. Genera un token CI:
```bash
firebase login:ci
# copia el token
```
2. Despliega con token:
```bash
./scripts/deploy_local.sh "TU_FIREBASE_TOKEN"
# o PowerShell
.\scripts\deploy_local.ps1 -FirebaseToken 'TU_FIREBASE_TOKEN'
```

Configurar despliegue automático (GitHub Actions)
1. Añade el token a los Secrets del repositorio: `FIREBASE_TOKEN`.
2. La workflow `.github/workflows/deploy-firebase.yml` ya está incluida y se ejecutará en pushes a `main`/`master`.

Verificación y logs
- URL de Hosting: se muestra al final del `firebase deploy` (p.ej. `https://PROJECT.web.app`).
- Logs de Functions:
```bash
firebase functions:log
```

Emuladores (pruebas locales)
1. Instalar dependencias de `functions` y levantar emuladores:
```bash
cd functions
npm install
cd ..
firebase emulators:start --only functions,hosting
```

Problemas comunes
- `firebase` no encontrado: añade la carpeta global de npm a `PATH` o reinstala globalmente.
- Cloud Scheduler (para funciones programadas) requiere plan Blaze.

Contacto
Si quieres, puedo preparar un PR con instrucciones adicionales o ayudarte a generar el `FIREBASE_TOKEN` y configurarlo en GitHub (no compartas el token en este chat).
