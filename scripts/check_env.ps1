<#
Simple PowerShell script to validate the workspace and run basic checks.
Usage: powershell -File scripts/check_env.ps1
#>

Write-Host "Running Flutter environment checks..."

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "Flutter CLI not found. Install Flutter and ensure it's in PATH."
  exit 1
}

Write-Host "Fetching packages..."
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Error "flutter pub get failed"; exit $LASTEXITCODE }

Write-Host "Analyzing project..."
flutter analyze
if ($LASTEXITCODE -ne 0) { Write-Error "flutter analyze found issues"; exit $LASTEXITCODE }

Write-Host "Running tests..."
flutter test
if ($LASTEXITCODE -ne 0) { Write-Error "flutter test failed"; exit $LASTEXITCODE }

Write-Host "All checks passed."
exit 0
