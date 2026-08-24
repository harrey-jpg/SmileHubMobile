@echo off
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not added to PATH.
  echo Install Flutter first: https://docs.flutter.dev/install
  pause
  exit /b 1
)
if not exist web flutter create . --platforms=web,android
flutter pub get
flutter run -d chrome
pause
