#!/usr/bin/env bash
set -euo pipefail

echo "Running Flutter environment checks..."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter CLI not found. Install Flutter and ensure it's in PATH." >&2
  exit 1
fi

echo "Fetching packages..."
flutter pub get

echo "Analyzing project..."
flutter analyze

echo "Running tests..."
flutter test

echo "All checks passed."
