@echo off
echo Fixing White Screen Pattern Issues...

echo.
echo The pattern you identified is correct:
echo - Personal Trainer: No coach connected = White screen
echo - My Requests: No subscriptions = White screen  
echo - Any page with empty data = White screen
echo.
echo Root cause: SizedBox.shrink() and empty conditional rendering
echo causes white screens in web environment (but works locally)
echo.

echo.
echo Step 1: Building with Personal Training fixes...
flutter clean
flutter pub get
flutter build web --release

echo.
echo Key fixes applied:
echo - Replaced SizedBox.shrink() with meaningful content
echo - Added fallback content for empty states
echo - Ensured CustomScrollView always has content
echo - Added proper empty state handling
echo.
echo This should fix the white screen pattern you identified!
echo.
echo Test scenarios that should now work:
echo - Personal trainer page with no coach = Shows fallback content
echo - My requests with no subscriptions = Should show proper empty state
echo - Any page with empty data = Shows meaningful content instead of white
echo.
pause
