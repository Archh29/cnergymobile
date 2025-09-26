@echo off
echo Fixing 403 Forbidden API Error...

echo.
echo ✅ PROBLEM IDENTIFIED:
echo - Flutter app trying to access: https://api.cnergy.site/guest_session_api.php
echo - But the PHP file is only on your local XAMPP server
echo - Need to upload PHP file to Hostinger server
echo.

echo.
echo 📋 STEPS TO FIX:
echo.
echo 1. Go to your Hostinger File Manager
echo 2. Navigate to public_html directory
echo 3. Create a folder called "api" (if it doesn't exist)
echo 4. Upload guest_session_api.php to the api folder
echo 5. The file should be accessible at: https://api.cnergy.site/api/guest_session_api.php
echo.

echo.
echo Step 1: Building with updated API URLs...
flutter clean
flutter pub get
flutter build web --release

echo.
echo ✅ Build completed!
echo.
echo After uploading the PHP file to Hostinger:
echo - API URL will be: https://api.cnergy.site/api/guest_session_api.php
echo - Guest registration should work properly
echo - No more 403 Forbidden errors
echo.
echo Upload the PHP file to Hostinger and test again!
echo.
pause
