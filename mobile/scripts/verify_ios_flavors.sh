#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_ENV="${APP_ENV:-staging}"
API_BASE_URL="${API_BASE_URL:-https://workforce-management-production.up.railway.app}"

echo "== Aurelia iOS flavor verification =="
echo "APP_ENV=${APP_ENV}"
echo "API_BASE_URL=${API_BASE_URL}"
echo

flutter --version
flutter pub get
flutter analyze
flutter test

build_flavor() {
  local flavor="$1"
  local target="$2"
  echo
  echo "== Building iOS flavor: ${flavor} (${target}) =="
  flutter build ios --debug --no-codesign \
    --flavor "$flavor" \
    -t "$target" \
    --dart-define="APP_ENV=${APP_ENV}" \
    --dart-define="API_BASE_URL=${API_BASE_URL}"
}

build_flavor employee lib/main_employee.dart
build_flavor manager lib/main_manager.dart
build_flavor admin lib/main_admin.dart
build_flavor platform lib/main_platform.dart

echo
echo "All iOS flavor builds completed."
