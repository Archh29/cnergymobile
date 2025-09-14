@echo off
echo Building Flutter Web App for CNERGY GYM...
echo.

echo Cleaning previous build...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building web app...
flutter build web --release --base-href /

echo.
echo Build completed! 
echo.
echo Next steps:
echo 1. Upload the contents of 'build/web/' to your web server
echo 2. Make sure the following files are accessible:
echo    - https://app.cnergy.site/manifest.json
echo    - https://app.cnergy.site/icons/Icon-192.png
echo    - https://app.cnergy.site/icons/Icon-512.png
echo    - https://app.cnergy.site/favicon.png
echo.
echo 3. Test the PWA by visiting: https://app.cnergy.site
echo.
pause






