# Builds the client-ready APKs for direct installation (no Play Store).
# Refuses to build if Supabase keys or the release keystore are missing, so a
# build without cloud sync or signed with the debug key can't ship by mistake.
#
# Usage (from the mobile/ folder):
#   .\scripts\build_release.ps1              # small per-CPU APKs (recommended)
#   .\scripts\build_release.ps1 -Universal   # one bigger APK that runs on every phone

param([switch]$Universal)

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
if ($cfg.SUPABASE_ANON_KEY -like 'sb_secret_*') {
    throw 'SUPABASE_ANON_KEY is a SECRET key. Use the anon / publishable key — never ship the secret key.'
}

if ([string]::IsNullOrWhiteSpace($cfg.SUPPORT_PHONE) -or $cfg.SUPPORT_PHONE -eq '+919876543210') {
    Write-Warning "SUPPORT_PHONE is not set in $envFile. 'Forgot password?' will only say 'contact the person who installed this app'."
    $answer = Read-Host 'Continue without a support number? (y/N)'
    if ($answer -ne 'y') { throw 'Add "SUPPORT_PHONE": "+91XXXXXXXXXX" to env/supabase.json and run again.' }
}

# 2. Release keystore (same key for every build, otherwise updates can't install over the old app)
if (-not (Test-Path 'android/key.properties')) {
    throw 'android/key.properties not found. See RELEASE.md section 2 to create the signing keystore.'
}

# 3. Quality gates
flutter pub get
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze reported issues.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'flutter test failed.' }

# 4. Build
$buildArgs = @('build', 'apk', '--release', "--dart-define-from-file=$envFile")
if (-not $Universal) { $buildArgs += '--split-per-abi' }
flutter @buildArgs
if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }

# 5. Copy to dist/ with the app version in the file name
$version = ((Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value) -replace '\+', '-build'
$dist = 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$outDir = 'build/app/outputs/flutter-apk'
if ($Universal) {
    Copy-Item "$outDir/app-release.apk" "$dist/EliteFitness-v$version.apk" -Force
} else {
    Copy-Item "$outDir/app-arm64-v8a-release.apk" "$dist/EliteFitness-v$version.apk" -Force
    Copy-Item "$outDir/app-armeabi-v7a-release.apk" "$dist/EliteFitness-v$version-old-phones.apk" -Force
}

Write-Host ''
Write-Host "Release APKs ready in mobile/$dist :" -ForegroundColor Green
Get-ChildItem $dist -Filter "EliteFitness-v$version*.apk" | ForEach-Object {
    Write-Host ("  {0}  ({1:N1} MB)" -f $_.Name, ($_.Length / 1MB))
}
