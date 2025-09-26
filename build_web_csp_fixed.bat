@echo off
echo ========================================
echo  CNERGY GYM - Flutter Web Build (CSP Fixed)
echo ========================================
echo.

echo 🧹 Cleaning previous build...
flutter clean

echo.
echo 📦 Getting dependencies...
flutter pub get

echo.
echo 🔧 Building Flutter Web App with CSP fixes...
flutter build web --base-href /

echo.
echo ✅ Build completed successfully!
echo.
echo 📁 Build files are in: build/web/
echo.
echo 🚀 Deployment Instructions:
echo    1. Upload ALL contents of 'build/web/' to your web server
echo    2. Make sure the .htaccess file is uploaded (for Apache servers)
echo    3. Ensure your server supports mod_headers and mod_rewrite
echo.
echo 🔍 CSP Configuration Applied:
echo    - Content Security Policy headers set
echo    - 'unsafe-eval' allowed for Flutter web
echo    - CORS headers configured
echo    - Static asset caching enabled
echo.
echo ⚠️  Important Notes:
echo    - The .htaccess file must be uploaded to your web root
echo    - Your server must support Apache mod_headers and mod_rewrite
echo    - If using Nginx, you'll need to configure CSP headers differently
echo.
echo 🧪 Test your app at: https://app.cnergy.site
echo.
pause

















