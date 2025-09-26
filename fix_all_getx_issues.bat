@echo off
echo Fixing all GetX compilation issues...

echo.
echo Step 1: Adding GetX import to login_screen.dart...
powershell -Command "if (-not (Select-String -Path 'lib\login_screen.dart' -Pattern 'import ''package:get/get.dart'';')) { (Get-Content 'lib\login_screen.dart') -replace 'import ''package:flutter/material.dart'';', 'import ''package:flutter/material.dart'';`nimport ''package:get/get.dart'';' | Set-Content 'lib\login_screen.dart' }"

echo.
echo Step 2: Adding GetX import to SignUp.dart...
powershell -Command "if (-not (Select-String -Path 'lib\SignUp.dart' -Pattern 'import ''package:get/get.dart'';')) { (Get-Content 'lib\SignUp.dart') -replace 'import ''package:flutter/material.dart'';', 'import ''package:flutter/material.dart'';`nimport ''package:get/get.dart'';' | Set-Content 'lib\SignUp.dart' }"

echo.
echo Step 3: Adding GetX import to forgot_pass.dart...
powershell -Command "if (-not (Select-String -Path 'lib\forgot_pass.dart' -Pattern 'import ''package:get/get.dart'';')) { (Get-Content 'lib\forgot_pass.dart') -replace 'import ''package:flutter/material.dart'';', 'import ''package:flutter/material.dart'';`nimport ''package:get/get.dart'';' | Set-Content 'lib\forgot_pass.dart' }"

echo.
echo Step 4: Adding GetX import to guest_qr_display_screen.dart...
powershell -Command "if (-not (Select-String -Path 'lib\guest_qr_display_screen.dart' -Pattern 'import ''package:get/get.dart'';')) { (Get-Content 'lib\guest_qr_display_screen.dart') -replace 'import ''package:flutter/material.dart'';', 'import ''package:flutter/material.dart'';`nimport ''package:get/get.dart'';' | Set-Content 'lib\guest_qr_display_screen.dart' }"

echo.
echo Step 5: Building with all GetX imports fixed...
flutter clean
flutter pub get
flutter build web --release

echo.
echo All GetX issues should now be fixed!
pause
