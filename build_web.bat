@echo off
echo Building CNERGY Flutter Web App...

REM Clean previous build
echo Cleaning previous build...
flutter clean

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Build for web with proper configuration
echo Building for web...
flutter build web --web-renderer html --release

echo Build completed!
echo.
echo Your web app is ready in the build/web directory.
echo.
echo CSP Configuration Notes:
echo - Current CSP is set to development/testing mode (more permissive)
echo - For production, update web/index.html with stricter CSP from web/csp-config.html
echo - Test your app thoroughly before deploying to production
echo.
pause