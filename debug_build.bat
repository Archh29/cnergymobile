@echo off
echo Building Flutter Web App in DEBUG mode for better error tracking...
echo.

echo Cleaning previous build...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building web app in DEBUG mode...
flutter build web --debug --source-maps

echo.
echo Debug build completed! 
echo.
echo The debug build includes source maps for better error tracking.
echo Upload the contents of 'build/web/' to your web server.
echo.
echo When you encounter errors, check the browser console for more detailed stack traces.
echo.
pause






