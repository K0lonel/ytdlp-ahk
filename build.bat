@echo off
echo ===================================================
echo 🛠️  Rebuilding Nuxt UI Frontend...
echo ===================================================
cd "%~dp0frontend"
call npm run build
if %ERRORLEVEL% neq 0 (
    echo ❌ Nuxt build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo ===================================================
echo 🩹 Patching index.html for relative local file loading...
echo ===================================================
cd "%~dp0"
powershell -NoProfile -Command ^
    "$filePath = 'frontend\.output\public\index.html';" ^
    "if (Test-Path $filePath) {" ^
    "  $content = Get-Content -Path $filePath -Raw;" ^
    "  $content = $content -replace '\"/_nuxt/', '\"_nuxt/';" ^
    "  $content = $content -replace '\"/favicon.ico\"', '\"favicon.ico\"';" ^
    "  $content = $content -replace '\"/_fonts/', '\"_fonts/';" ^
    "  $content = $content -replace \"'/_nuxt/'\", \"'_nuxt/'\";" ^
    "  $content = $content -replace 'baseURL:\"/\"', 'baseURL:\"\"';" ^
    "  Set-Content -Path $filePath -Value $content -Encoding UTF8;" ^
    "  Write-Host '✅ Successfully patched index.html paths!';" ^
    "} else {" ^
    "  Write-Error '❌ index.html not found in public output directory!';" ^
    "}"

echo ===================================================
echo 🎉 Done! You can now run main.ahk
echo ===================================================
pause
