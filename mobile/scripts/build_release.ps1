# Builds the client-ready release (AAB for Play Store + APK for direct install).
# Refuses to build if Supabase keys or the release keystore are missing, so a
# build without cloud sync or signed with the debug key can't ship by mistake.
#
# Usage (from the mobile/ folder):  .\scripts\build_release.ps1

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

# 1. Supabase keys
$envFile = 'env/supabase.json'
if (-not (Test-Path $envFile)) { throw "$envFile not found. Copy env/supabase.example.json and fill it in." }
$cfg = Get-Content $envFile -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($cfg.SUPABASE_URL) -or $cfg.SUPABASE_URL -like '*YOUR_PROJECT_ID*') {
    throw "SUPABASE_URL is empty in $envFile."
}
if ([string]::IsNullOrWhiteSpace($cfg.SUPABASE_ANON_KEY) -or $cfg.SUPABASE_ANON_KEY -like '*YOUR_*') {
    throw "SUPABASE_ANON_KEY is empty in $envFile."
}

# 2. Release keystore
if (-not (Test-Path 'android/key.properties')) {
    throw 'android/key.properties not found. See RELEASE.md section 2 to create the upload keystore.'
}

# 3. Quality gates
flutter pub get
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze reported issues.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'flutter test failed.' }

# 4. Build
flutter build appbundle --release --dart-define-from-file=$envFile
if ($LASTEXITCODE -ne 0) { throw 'AAB build failed.' }
flutter build apk --release --dart-define-from-file=$envFile
if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }

Write-Host ''
Write-Host 'Release build ready:' -ForegroundColor Green
Write-Host '  build/app/outputs/bundle/release/app-release.aab  (Play Store)'
Write-Host '  build/app/outputs/flutter-apk/app-release.apk     (direct install)'
