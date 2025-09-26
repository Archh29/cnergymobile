# CNERGY Flutter Web Build Script
Write-Host "Building CNERGY Flutter Web App..." -ForegroundColor Green

# Clean previous build
Write-Host "Cleaning previous build..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build for web with proper configuration
Write-Host "Building for web..." -ForegroundColor Yellow
flutter build web --web-renderer html --release

Write-Host "Build completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Your web app is ready in the build/web directory." -ForegroundColor Cyan
Write-Host ""
Write-Host "CSP Configuration Notes:" -ForegroundColor Magenta
Write-Host "- Current CSP is set to development/testing mode (more permissive)" -ForegroundColor White
Write-Host "- For production, update web/index.html with stricter CSP from web/csp-config.html" -ForegroundColor White
Write-Host "- Test your app thoroughly before deploying to production" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to continue"

