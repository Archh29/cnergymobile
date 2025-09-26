@echo off
echo ========================================
echo  CNERGY GYM - Final Flutter Web Build
echo ========================================
echo.

echo 🧹 Cleaning previous build...
flutter clean

echo.
echo 📦 Getting dependencies...
flutter pub get

echo.
echo 🔧 Building Flutter Web App with CSP compliance...
flutter build web --release --csp --base-href /

echo.
echo 📁 Copying .htaccess file to build...
copy web\.htaccess build\web\.htaccess

echo.
echo 🔧 Adding CSP meta tag to built index.html...
powershell -Command "(Get-Content 'build\web\index.html') -replace '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">', '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">`n  `n  <!-- Content Security Policy for Flutter Web -->`n  <meta http-equiv=\"Content-Security-Policy\" content=\"`n    default-src ''self'';`n    script-src ''self'' ''unsafe-inline'' ''unsafe-eval'' https://fonts.googleapis.com https://fonts.gstatic.com https://www.gstatic.com;`n    style-src ''self'' ''unsafe-inline'' https://fonts.googleapis.com;`n    font-src ''self'' https://fonts.gstatic.com;`n    img-src ''self'' data: https: blob:;`n    connect-src ''self'' https://api.cnergy.site https://fonts.googleapis.com https://www.gstatic.com;`n    media-src ''self'' blob:;`n    object-src ''none'';`n    frame-src ''none'';`n    worker-src ''self'' blob:;`n    child-src ''self'' blob:;`n    script-src-elem ''self'' ''unsafe-inline'' ''unsafe-eval'' https://fonts.googleapis.com https://fonts.gstatic.com https://www.gstatic.com;`n  \">" | Set-Content 'build\web\index.html'

echo.
echo ✅ Final build completed successfully!
echo.
echo 📁 Build files are in: build/web/
echo.
echo 🚀 Deployment Instructions:
echo    1. Upload ALL contents of 'build/web/' to your web server
echo    2. The .htaccess file is already included
echo    3. CSP meta tag is already added to index.html
echo    4. Ensure your server supports mod_headers and mod_rewrite
echo.
echo 🔍 What's Fixed:
echo    ✅ CSP compliance with --csp flag
echo    ✅ .htaccess file with proper headers
echo    ✅ CSP meta tag in index.html
echo    ✅ CanvasKit resources allowed
echo    ✅ API endpoints allowed
echo    ✅ 'unsafe-eval' allowed for Flutter
echo.
echo 🧪 Test your app at: https://app.cnergy.site
echo.
echo 📋 If you still get errors:
echo    1. Check browser console for specific error messages
echo    2. Verify server supports mod_headers and mod_rewrite
echo    3. Test API endpoints using test_api_endpoints.html
echo.
pause

















