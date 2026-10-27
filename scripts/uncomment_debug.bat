@echo off
REM Script to uncomment debugPrint and print statements in Dart files (Windows Batch)
REM This script will find and uncomment previously commented debug statements

echo 🔍 Searching for commented debugPrint and print statements to uncomment...

set changes_made=false

REM Find all Dart files in the project (excluding build directories and other non-source folders)
for /r %%f in (*.dart) do (
    echo %%f | findstr /i /c:"build\" /c:".dart_tool\" /c:"Pods\" >nul && (
        REM Skip files in excluded directories
    ) || (
        echo 📂 Processing: %%f
        
        REM Use PowerShell to uncomment debugPrint and print statements
        powershell -Command "(Get-Content '%%f') | ForEach-Object { $_ -replace '^(\s*)// debugPrint\s*\(', '$1debugPrint(' -replace '^(\s*)// print\s*\(', '$1print(' -replace '(\s)// debugPrint\s*\(', '$1debugPrint(' -replace '(\s)// print\s*\(', '$1print(' } | Set-Content '%%f'"
        
        echo ✅ Modified: %%f
        set changes_made=true
    )
)

echo.
if "%changes_made%"=="true" (
    echo ✅ Debug statements have been uncommented!
    echo 🔄 Use git to restore changes if needed: git checkout -- .
) else (
    echo ℹ️  No commented debug statements found to uncomment
)

echo.
echo 📊 Summary of active debug statements:
powershell -Command "(Get-ChildItem -Recurse -Include *.dart | Where-Object { $_.FullName -notmatch 'build|\.dart_tool|Pods' } | Select-String 'debugPrint\(|print\(' | Where-Object { $_.Line -notmatch '// debugPrint|// print' }).Count"

pause
