# Flutter Web App Debugging Guide

## Current Issue: JavaScript Error in main.dart.js

The error you're experiencing is a JavaScript runtime error in the compiled Flutter web code. This typically happens due to:

1. **Async/Await Issues**: Problems with asynchronous operations
2. **State Management**: Issues with GetX or other state management
3. **API Calls**: Network request failures
4. **SharedPreferences**: Local storage issues
5. **AuthService**: Authentication service problems

## Debugging Steps

### Step 1: Use Debug Build
Run the debug build script to get better error information:
```bash
debug_build.bat
```

This will create a build with source maps that provide better stack traces.

### Step 2: Check Browser Console
1. Open your web app in Chrome/Edge
2. Press F12 to open Developer Tools
3. Go to Console tab
4. Look for detailed error messages
5. Check the Network tab for failed API calls

### Step 3: Test with Safe Version
I've created a safer version of your main.dart file:

1. **Backup your current main.dart**:
   ```bash
   copy lib\main.dart lib\main_backup.dart
   ```

2. **Use the safe version**:
   ```bash
   copy lib\main_safe.dart lib\main.dart
   ```

3. **Rebuild and test**:
   ```bash
   flutter clean
   flutter pub get
   flutter build web --debug
   ```

### Step 4: Common Fixes

#### Fix 1: Clear Browser Cache
- Hard refresh: Ctrl+Shift+R
- Clear browser cache completely
- Try in incognito/private mode

#### Fix 2: Check API Endpoints
Verify these endpoints are working:
- `https://api.cnergy.site/loginapp.php?action=get_genders`
- `https://api.cnergy.site/user.php?action=fetch&user_id=7`
- `https://api.cnergy.site/membership_info.php?action=get_membership&user_id=7`

#### Fix 3: Check SharedPreferences
The error might be related to local storage. Try:
1. Clear browser local storage
2. Open DevTools → Application → Storage → Clear All

#### Fix 4: Test Minimal App
Create a minimal test to isolate the issue:

```dart
// lib/main_minimal.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World'),
        ),
      ),
    );
  }
}
```

### Step 5: Check Dependencies
Run these commands to check for dependency issues:
```bash
flutter pub deps
flutter pub outdated
flutter pub upgrade
```

### Step 6: Check Flutter Version
```bash
flutter --version
flutter doctor -v
```

## Error Patterns and Solutions

### Pattern 1: AuthService Errors
**Symptoms**: Errors related to authentication
**Solution**: Use the SafeAuthWrapper in main_safe.dart

### Pattern 2: API Call Errors
**Symptoms**: Network-related errors
**Solution**: Check API endpoints and CORS headers

### Pattern 3: SharedPreferences Errors
**Symptoms**: Local storage issues
**Solution**: Clear browser storage or use the _fixUserIdStorage function

### Pattern 4: GetX State Errors
**Symptoms**: State management errors
**Solution**: Ensure proper initialization and error handling

## Testing Checklist

- [ ] Debug build works
- [ ] Safe version works
- [ ] Minimal app works
- [ ] API endpoints respond
- [ ] Browser cache cleared
- [ ] Dependencies updated
- [ ] Flutter version current

## If All Else Fails

1. **Create a new Flutter project**:
   ```bash
   flutter create new_gym_app
   ```

2. **Copy your assets and lib files**:
   ```bash
   copy assets new_gym_app\assets
   copy lib new_gym_app\lib
   ```

3. **Update pubspec.yaml** with your dependencies

4. **Test the new project**

## Contact Information

If you need further assistance, provide:
1. Full error message from browser console
2. Flutter version (`flutter --version`)
3. Browser and version
4. Steps to reproduce the error






