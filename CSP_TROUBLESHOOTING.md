# Content Security Policy (CSP) Troubleshooting Guide

## Problem Identified ✅
Your Flutter web app is being blocked by Content Security Policy (CSP) headers that prevent the use of `eval()` and other dynamic JavaScript execution that Flutter web requires.

## Error Messages
- `Content Security Policy of your site blocks the use of 'eval' in JavaScript`
- `script-src blocked`
- `Uncaught Error` in main.dart.js

## Solutions Applied

### 1. ✅ Updated `web/index.html`
Added CSP meta tag with proper permissions for Flutter web:
```html
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval' https://fonts.googleapis.com https://fonts.gstatic.com;
  style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
  font-src 'self' https://fonts.gstatic.com;
  img-src 'self' data: https: blob:;
  connect-src 'self' https://api.cnergy.site https://fonts.googleapis.com;
  media-src 'self' blob:;
  object-src 'none';
  frame-src 'none';
  worker-src 'self' blob:;
  child-src 'self' blob:;
">
```

### 2. ✅ Created `web/.htaccess` (Apache)
For Apache servers, this file configures:
- CSP headers at server level
- CORS headers for API calls
- Flutter web routing
- Static asset caching
- Compression

### 3. ✅ Created `web/nginx.conf` (Nginx)
For Nginx servers, this configuration provides:
- CSP headers
- CORS support
- Flutter web routing
- Caching and compression

## Deployment Steps

### For Apache Servers:
1. **Build the app**:
   ```bash
   build_web_csp_fixed.bat
   ```

2. **Upload files**:
   - Upload ALL contents of `build/web/` to your web server
   - **IMPORTANT**: Make sure `.htaccess` file is uploaded
   - Ensure your server supports `mod_headers` and `mod_rewrite`

3. **Verify server modules**:
   ```bash
   # Check if modules are enabled
   apache2ctl -M | grep headers
   apache2ctl -M | grep rewrite
   ```

### For Nginx Servers:
1. **Build the app**:
   ```bash
   build_web_csp_fixed.bat
   ```

2. **Configure Nginx**:
   - Copy the configuration from `web/nginx.conf`
   - Update the `root` path to your Flutter web build directory
   - Reload Nginx: `sudo nginx -s reload`

## Testing Your Fix

### 1. Check Browser Console
After deployment, open your app and check the browser console:
- **Good**: No CSP errors
- **Bad**: Still seeing CSP violations

### 2. Test API Calls
Verify that your API calls to `https://api.cnergy.site` work:
- Open Network tab in DevTools
- Check for successful API requests
- Look for CORS errors

### 3. Test PWA Features
- Check if the app can be installed
- Verify manifest.json loads correctly
- Test offline functionality

## Common Issues & Solutions

### Issue 1: Server doesn't support mod_headers
**Solution**: Contact your hosting provider to enable `mod_headers` and `mod_rewrite`

### Issue 2: .htaccess not working
**Solution**: 
- Check if `.htaccess` file is uploaded
- Verify file permissions (644)
- Check server error logs

### Issue 3: Still getting CSP errors
**Solution**: 
- Check if server-level CSP headers are overriding your settings
- Use browser DevTools to see which CSP directive is blocking
- Temporarily add `'unsafe-eval'` to script-src

### Issue 4: API calls failing
**Solution**:
- Verify CORS headers in `.htaccess` or Nginx config
- Check if `https://api.cnergy.site` is accessible
- Test API endpoints directly

## Security Considerations

### ⚠️ Important Notes:
- `'unsafe-eval'` is required for Flutter web but reduces security
- This is a known limitation of Flutter web compilation
- Consider using Flutter's `--web-renderer html` for better CSP compliance

### Alternative: Use HTML Renderer
For better CSP compliance, you can use Flutter's HTML renderer:
```bash
flutter build web --web-renderer html --base-href /
```

## Verification Checklist

- [ ] CSP meta tag added to index.html
- [ ] .htaccess file uploaded (Apache) OR Nginx configured
- [ ] Server modules enabled (mod_headers, mod_rewrite)
- [ ] Build completed with `build_web_csp_fixed.bat`
- [ ] All files uploaded to web server
- [ ] Browser console shows no CSP errors
- [ ] API calls working
- [ ] PWA features functional

## Support

If you're still experiencing issues:
1. Check browser console for specific error messages
2. Verify server configuration
3. Test with different browsers
4. Check server error logs
5. Contact your hosting provider for server configuration help

## Files Created/Modified:
- ✅ `web/index.html` - Added CSP meta tag
- ✅ `web/.htaccess` - Apache configuration
- ✅ `web/nginx.conf` - Nginx configuration  
- ✅ `build_web_csp_fixed.bat` - Build script
- ✅ `CSP_TROUBLESHOOTING.md` - This guide

















