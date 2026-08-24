#!/usr/bin/env bash
set -e
command -v flutter >/dev/null 2>&1 || {
  echo "Flutter is not installed or not in PATH. Install it from https://docs.flutter.dev/install"
  exit 1
}
[ -d web ] || flutter create . --platforms=web,android
flutter pub get
flutter run -d chrome
