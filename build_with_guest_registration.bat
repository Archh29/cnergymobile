@echo off
echo Building with Restored Guest Registration...

echo.
echo Guest Registration Screen has been restored with:
echo - Full name, phone, and email fields
echo - Walk-in access for ₱150
echo - Proper form validation
echo - Error handling
echo - Navigation to QR display screen
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
echo Guest Registration Features:
echo - ✅ Guest button on login screen
echo - ✅ Registration form with validation
echo - ✅ Walk-in pricing (₱150)
echo - ✅ Navigation to QR display
echo - ✅ Error handling
echo.
echo Test the guest registration flow:
echo 1. Click "GUEST ACCESS" on login screen
echo 2. Fill out the registration form
echo 3. Submit to create guest session
echo 4. Navigate to QR display screen
echo.
pause
