param(
  [string]$FirebaseToken = ""
)

Write-Host "==> Preparando build"
flutter pub get
flutter analyze
try { flutter test --no-pub } catch {}
flutter build web --release

Write-Host "==> Desplegando a Firebase Hosting + Functions"
if ([string]::IsNullOrEmpty($FirebaseToken)) {
  Write-Host "FIREBASE_TOKEN no proporcionado: despliegue interactivo..."
  firebase deploy --only hosting,functions
} else {
  npm install -g firebase-tools
  firebase deploy --only hosting,functions --token "$FirebaseToken"
}
