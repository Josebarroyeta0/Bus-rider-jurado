#!/usr/bin/env bash
set -euo pipefail

# Uso: ./scripts/create_pr.sh [branch-name]
BRANCH=${1:-ci/firebase-deploy}
git fetch origin
git checkout -b "$BRANCH"
git add .
git commit -m "chore(ci): add firebase deploy workflow, functions and deploy scripts" || true
git push -u origin "$BRANCH"

if command -v gh >/dev/null 2>&1; then
  gh pr create --fill --base main --head "$BRANCH"
else
  echo
  echo "PR no creado automáticamente (no se encontró 'gh')."
  echo "Crea un PR manualmente desde la rama: $BRANCH"
  echo "URL para crear PR: https://github.com/<OWNER>/<REPO>/compare/main...$BRANCH?expand=1"
fi
