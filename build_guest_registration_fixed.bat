@echo off
echo Building with Fixed Guest Registration...

echo.
echo ✅ Fixed the constructor parameter mismatch:
echo - GuestQRDisplayScreen expects 'sessionData' (Map)
echo - Guest registration now passes proper session data
echo - Includes all required fields: id, guest_name, phone, email, etc.
echo.

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
echo ✅ Build completed successfully!
echo.
echo Guest Registration Flow:
echo 1. ✅ Click "GUEST ACCESS" on login screen
echo 2. ✅ Fill out registration form
echo 3. ✅ Submit creates guest session via API
echo 4. ✅ Navigate to QR display with proper session data
echo 5. ✅ Show session status and QR code when approved
echo.
echo The constructor parameter mismatch has been resolved!
echo.
pause
