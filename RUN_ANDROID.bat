@echo off
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not added to PATH.
  echo Install Flutter first: https://docs.flutter.dev/install
  pause
  exit /b 1
)
if not exist android flutter create . --platforms=android,web
flutter pub get
flutter run
pause
