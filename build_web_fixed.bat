@echo off
echo Building Flutter Web App with GetX fixes...

echo.
echo Step 1: Cleaning previous build...
flutter clean

echo.
echo Step 2: Getting dependencies...
flutter pub get

echo.
echo Step 3: Building web app...
flutter build web --release

echo.
echo Build completed! The GetX JavaScript interop issues should now be resolved.
echo.
echo Key fixes applied:
echo - Removed GetX imports from main.dart, guest screens
echo - Replaced Get.snackbar with ScaffoldMessenger.showSnackBar
echo - Added comprehensive error handling
echo - Fixed notification service URL construction
echo.
echo Test your app now - the JavaScript errors should be gone!
pause
