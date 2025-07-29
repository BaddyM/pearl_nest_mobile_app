@echo off
REM Script to comment out debugPrint and print statements in Dart files (Windows Batch)
REM This script will find and comment out debugPrint and print statements while preserving code structure

echo 🔍 Searching for debugPrint and print statements to comment out...

set changes_made=false

REM Find all Dart files in the project (excluding build directories and other non-source folders)
for /r %%f in (*.dart) do (
    echo %%f | findstr /i /c:"build\" /c:".dart_tool\" /c:"Pods\" >nul && (
        REM Skip files in excluded directories
    ) || (
        echo 📂 Processing: %%f
        
        REM Use PowerShell to comment out debugPrint and print statements
        powershell -Command "(Get-Content '%%f') | ForEach-Object { $_ -replace '^(\s*)debugPrint\s*\(', '$1// debugPrint(' -replace '^(\s*)print\s*\(', '$1// print(' -replace '(\s)debugPrint\s*\(', '$1// debugPrint(' -replace '(\s)print\s*\(', '$1// print(' } | Set-Content '%%f'"
        
        echo ✅ Modified: %%f
        set changes_made=true
    )
)

echo.
if "%changes_made%"=="true" (
    echo ✅ Debug statements have been commented out!
    echo 🔄 Use git to restore changes if needed: git checkout -- .
) else (
    echo ℹ️  No debug statements found to comment out
)

echo.
echo 📊 Summary of commented debug statements:
powershell -Command "(Get-ChildItem -Recurse -Include *.dart | Where-Object { $_.FullName -notmatch 'build|\.dart_tool|Pods' } | Select-String '// debugPrint|// print').Count"

pause
