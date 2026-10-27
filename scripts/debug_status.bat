@echo off
REM Script to show the current status of debug statements in the codebase (Windows Batch)
REM This helps you understand what debug statements exist before running other scripts

echo 📊 Debug Statement Status Report
echo =================================
echo.

REM Count active debug statements using PowerShell
for /f %%i in ('powershell -Command "(Get-ChildItem -Recurse -Include *.dart | Where-Object { $_.FullName -notmatch 'build|\.dart_tool|Pods' } | Select-String 'debugPrint\s*\(' | Where-Object { $_.Line -notmatch '// debugPrint' }).Count"') do set active_debug=%%i

for /f %%i in ('powershell -Command "(Get-ChildItem -Recurse -Include *.dart | Where-Object { $_.FullName -notmatch 'build|\.dart_tool|Pods' } | Select-String 'print\s*\(' | Where-Object { $_.Line -notmatch '// print' }).Count"') do set active_print=%%i

REM Count commented debug statements
for /f %%i in ('powershell -Command "(Get-ChildItem -Recurse -Include *.dart | Where-Object { $_.FullName -notmatch 'build|\.dart_tool|Pods' } | Select-String '// debugPrint\s*\(').Count"') do set commented_debug=%%i

for /f %%i in ('powershell -Command "(Get-ChildItem -Recurse -Include *.dart | Where-Object { $_.FullName -notmatch 'build|\.dart_tool|Pods' } | Select-String '// print\s*\(').Count"') do set commented_print=%%i

REM Calculate totals
set /a active_total=%active_debug%+%active_print%
set /a commented_total=%commented_debug%+%commented_print%
set /a total_debug=%active_debug%+%commented_debug%
set /a total_print=%active_print%+%commented_print%
set /a grand_total=%total_debug%+%total_print%

echo 🟢 Active Debug Statements:
echo    debugPrint: %active_debug%
echo    print:      %active_print%
echo    Total:      %active_total%
echo.

echo 💤 Commented Debug Statements:
echo    debugPrint: %commented_debug%
echo    print:      %commented_print%
echo    Total:      %commented_total%
echo.

echo 📈 Grand Total:
echo    debugPrint: %total_debug%
echo    print:      %total_print%
echo    All:        %grand_total%
echo.

REM Show recommendations
if %active_total% gtr 0 (
    echo 💡 Recommendations:
    echo    • For production builds: run .\scripts\comment_debug.bat
    echo    • To disable debug output temporarily without changing code
) else (
    echo 💡 Recommendations:
    echo    • All debug statements are commented out
    echo    • For development: run .\scripts\uncomment_debug.bat
)

echo.

echo 📂 Top Files with Debug Statements:
powershell -Command "Get-ChildItem -Recurse -Include *.dart | Where-Object { $_.FullName -notmatch 'build|\.dart_tool|Pods' } | ForEach-Object { $file = $_; $count = (Select-String 'debugPrint|print' $file.FullName).Count; if ($count -gt 0) { \"   $($file.FullName): $count statements\" } } | Sort-Object { [int]($_ -split ': ')[1].Split(' ')[0] } -Descending | Select-Object -First 5"

pause
