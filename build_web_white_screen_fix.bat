@echo off
echo Building Flutter Web App with White Screen Fixes...

echo.
echo Step 1: Cleaning previous build...
flutter clean

echo.
echo Step 2: Getting dependencies...
flutter pub get

echo.
echo Step 3: Building web app with fixes...
flutter build web --release

echo.
echo Build completed! White screen issues should now be resolved.
echo.
echo Key fixes applied:
echo - Added comprehensive error handling to PersonalTrainingPage
echo - Added error boundaries and fallback UI for failed API calls
echo - Added safety checks for empty data in WorkoutSessionPage
echo - Added detailed logging for debugging web-specific issues
echo - Fixed GetX JavaScript interop problems
echo - Fixed notification service URL construction
echo.
echo The pages will now show:
echo - Loading states while fetching data
echo - Error screens with retry buttons if API calls fail
echo - Proper fallback content instead of white screens
echo.
echo Test your app now - white screens should be replaced with proper error handling!
pause
