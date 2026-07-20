param(
  [string]$Branch = "ci/firebase-deploy"
)

Write-Host "Creating branch $Branch and pushing..."
git fetch origin
git checkout -b $Branch
git add .
try { git commit -m "chore(ci): add firebase deploy workflow, functions and deploy scripts" } catch {}
git push -u origin $Branch

if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh pr create --fill --base main --head $Branch
} else {
  Write-Host "No se encontró 'gh' CLI. Crea un PR manualmente desde la rama: $Branch"
  Write-Host "URL: https://github.com/<OWNER>/<REPO>/compare/main...$Branch?expand=1"
}
