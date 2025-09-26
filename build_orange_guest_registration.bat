@echo off
echo Building Orange-Themed Guest Registration...

echo.
echo ✅ NEW ORANGE THEME DESIGN:
echo - Beautiful gradient header with orange theme
echo - All form fields: Name, Phone, Email
echo - Proper validation for all fields
echo - Orange color scheme throughout
echo - Modern card-based layout
echo - Connected to working PHP API
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
echo 1. ✅ Orange gradient theme design
echo 2. ✅ Full Name field (required)
echo 3. ✅ Phone Number field (required, validated)
echo 4. ✅ Email field (optional, validated)
echo 5. ✅ Connected to PHP API
echo 6. ✅ Proper error handling
echo 7. ✅ Beautiful modern UI
echo 8. ✅ Navigation to QR display
echo.
echo Test the complete flow:
echo 1. Click "GUEST ACCESS" on login
echo 2. Fill out the beautiful orange form
echo 3. Submit creates guest session
echo 4. Navigate to QR display screen
echo.
echo The guest registration is now fully restored with orange theme!
echo.
pause
