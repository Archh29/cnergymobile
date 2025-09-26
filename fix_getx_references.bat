@echo off
echo Fixing GetX references in Flutter files...

echo.
echo Step 1: Removing GetX imports...
powershell -Command "(Get-Content 'lib\login_screen.dart') -replace 'import ''package:get/get.dart'';', '' | Set-Content 'lib\login_screen.dart'"
powershell -Command "(Get-Content 'lib\SignUp.dart') -replace 'import ''package:get/get.dart'';', '' | Set-Content 'lib\SignUp.dart'"
powershell -Command "(Get-Content 'lib\forgot_pass.dart') -replace 'import ''package:get/get.dart'';', '' | Set-Content 'lib\forgot_pass.dart'"
powershell -Command "(Get-Content 'lib\guest_qr_display_screen.dart') -replace 'import ''package:get/get.dart'';', '' | Set-Content 'lib\guest_qr_display_screen.dart'"

echo.
echo Step 2: Replacing GetMaterialApp with MaterialApp...
powershell -Command "(Get-Content 'lib\main_safe.dart') -replace 'GetMaterialApp', 'MaterialApp' | Set-Content 'lib\main_safe.dart'"
powershell -Command "(Get-Content 'lib\forgot_pass.dart') -replace 'GetMaterialApp', 'MaterialApp' | Set-Content 'lib\forgot_pass.dart'"

echo.
echo Step 3: Replacing Get.snackbar with ScaffoldMessenger...
powershell -Command "(Get-Content 'lib\login_screen.dart') -replace 'Get\.snackbar\(', 'ScaffoldMessenger.of(context).showSnackBar(SnackBar(' | Set-Content 'lib\login_screen.dart'"
powershell -Command "(Get-Content 'lib\SignUp.dart') -replace 'Get\.snackbar\(', 'ScaffoldMessenger.of(context).showSnackBar(SnackBar(' | Set-Content 'lib\SignUp.dart'"
powershell -Command "(Get-Content 'lib\forgot_pass.dart') -replace 'Get\.snackbar\(', 'ScaffoldMessenger.of(context).showSnackBar(SnackBar(' | Set-Content 'lib\forgot_pass.dart'"
powershell -Command "(Get-Content 'lib\guest_qr_display_screen.dart') -replace 'Get\.snackbar\(', 'ScaffoldMessenger.of(context).showSnackBar(SnackBar(' | Set-Content 'lib\guest_qr_display_screen.dart'"

echo.
echo Step 4: Removing SnackPosition references...
powershell -Command "(Get-Content 'lib\login_screen.dart') -replace 'snackPosition: SnackPosition\.BOTTOM,', '' | Set-Content 'lib\login_screen.dart'"
powershell -Command "(Get-Content 'lib\SignUp.dart') -replace 'snackPosition: SnackPosition\.BOTTOM,', '' | Set-Content 'lib\SignUp.dart'"
powershell -Command "(Get-Content 'lib\forgot_pass.dart') -replace 'snackPosition: SnackPosition\.BOTTOM,', '' | Set-Content 'lib\forgot_pass.dart'"
powershell -Command "(Get-Content 'lib\guest_qr_display_screen.dart') -replace 'snackPosition: SnackPosition\.BOTTOM,', '' | Set-Content 'lib\guest_qr_display_screen.dart'"

echo.
echo Step 5: Replacing colorText with content...
powershell -Command "(Get-Content 'lib\login_screen.dart') -replace 'colorText: Colors\.white,', 'content: Text(' | Set-Content 'lib\login_screen.dart'"
powershell -Command "(Get-Content 'lib\SignUp.dart') -replace 'colorText: Colors\.white,', 'content: Text(' | Set-Content 'lib\SignUp.dart'"
powershell -Command "(Get-Content 'lib\forgot_pass.dart') -replace 'colorText: Colors\.white,', 'content: Text(' | Set-Content 'lib\forgot_pass.dart'"
powershell -Command "(Get-Content 'lib\guest_qr_display_screen.dart') -replace 'colorText: Colors\.white,', 'content: Text(' | Set-Content 'lib\guest_qr_display_screen.dart'"

echo.
echo Step 6: Replacing Get.to with Navigator.push...
powershell -Command "(Get-Content 'lib\forgot_pass.dart') -replace 'Get\.to\(', 'Navigator.push(context, MaterialPageRoute(builder: (context) => ' | Set-Content 'lib\forgot_pass.dart'"
powershell -Command "(Get-Content 'lib\forgot_pass.dart') -replace 'Get\.offAll\(', 'Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => ' | Set-Content 'lib\forgot_pass.dart'"

echo.
echo GetX references fixed! Now building...
flutter clean
flutter pub get
flutter build web --release

echo.
echo Build completed! All GetX references have been removed.
pause
