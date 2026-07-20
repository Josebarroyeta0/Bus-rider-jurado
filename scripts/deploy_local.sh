#!/usr/bin/env bash
set -euo pipefail

# Uso: ./scripts/deploy_local.sh [FIREBASE_TOKEN]
FIREBASE_TOKEN=${1:-}

echo "==> Preparando build"
flutter pub get
flutter analyze
flutter test --no-pub || true
flutter build web --release

echo "==> Desplegando a Firebase Hosting + Functions"
if [ -z "$FIREBASE_TOKEN" ]; then
  echo "FIREBASE_TOKEN no proporcionado: se usará despliegue interactivo (requiere firebase-tools y login)."
  firebase deploy --only hosting,functions
else
  npm install -g firebase-tools
  firebase deploy --only hosting,functions --token "$FIREBASE_TOKEN"
fi
