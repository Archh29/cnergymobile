@echo off
echo Quick GetX Fix for Compilation Errors...

echo.
echo Step 1: Fixing main.dart GetMaterialApp...
powershell -Command "(Get-Content 'lib\main.dart') -replace 'GetMaterialApp', 'MaterialApp' | Set-Content 'lib\main.dart'"

echo.
echo Step 2: Fixing guest_registration_screen.dart GetX calls...
powershell -Command "(Get-Content 'lib\guest_registration_screen.dart') -replace 'Get\.snackbar\(', 'ScaffoldMessenger.of(context).showSnackBar(SnackBar(' | Set-Content 'lib\guest_registration_screen.dart'"
powershell -Command "(Get-Content 'lib\guest_registration_screen.dart') -replace 'snackPosition: SnackPosition\.BOTTOM,', '' | Set-Content 'lib\guest_registration_screen.dart'"
powershell -Command "(Get-Content 'lib\guest_registration_screen.dart') -replace 'colorText: Colors\.white,', 'content: Text(' | Set-Content 'lib\guest_registration_screen.dart'"

echo.
echo Step 3: Building with fixes...
flutter clean
flutter pub get
flutter build web --release

echo.
echo Quick fix completed!
pause
