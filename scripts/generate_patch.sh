#!/usr/bin/env bash
set -euo pipefail

# Genera un parche con los cambios no committeados (útil si git está instalado localmente)
# Uso: ./scripts/generate_patch.sh [output.patch]
OUT=${1:-changes.patch}
if ! command -v git >/dev/null 2>&1; then
  echo "git no está instalado. Instálalo y vuelve a ejecutar este script." >&2
  exit 1
fi

# Asegura que workspace limpio (opcional) — no se hace por defecto
# Guardar cambios staged y unstaged en un parche

# Incluir cambios contra HEAD
git add -A
# Crea el parche con los cambios entre HEAD y staging
# Si prefieres conservar staging, usa `git stash -u` y luego `git stash pop`.

git diff --staged > "/tmp/${OUT}"
# Si no hay cambios staged, intenta diff contra HEAD
if [ ! -s "/tmp/${OUT}" ]; then
  git diff HEAD > "/tmp/${OUT}"
fi
mv "/tmp/${OUT}" "${OUT}"

echo "Parche creado: ${OUT}"