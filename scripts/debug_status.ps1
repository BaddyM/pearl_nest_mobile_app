# PowerShell script to show the current status of debug statements in the codebase
# This helps you understand what debug statements exist before running other scripts

Write-Host "📊 Debug Statement Status Report" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Find all Dart files (excluding build directories)
$dartFiles = Get-ChildItem -Recurse -Include *.dart | Where-Object { 
    $_.FullName -notmatch "build|\.dart_tool|Pods|android\\build|ios\\build|macos\\build|linux\\build|windows\\build|web\\build" 
}

# Count active debug statements
$activeDebug = ($dartFiles | Select-String "debugPrint\s*\(" | Where-Object { $_.Line -notmatch "// debugPrint" }).Count
$activePrint = ($dartFiles | Select-String "print\s*\(" | Where-Object { $_.Line -notmatch "// print" }).Count

# Count commented debug statements
$commentedDebug = ($dartFiles | Select-String "// debugPrint\s*\(").Count
$commentedPrint = ($dartFiles | Select-String "// print\s*\(").Count

# Calculate totals
$activeTotal = $activeDebug + $activePrint
$commentedTotal = $commentedDebug + $commentedPrint
$totalDebug = $activeDebug + $commentedDebug
$totalPrint = $activePrint + $commentedPrint
$grandTotal = $totalDebug + $totalPrint

Write-Host "🟢 Active Debug Statements:" -ForegroundColor Green
Write-Host "   debugPrint: $activeDebug" -ForegroundColor White
Write-Host "   print:      $activePrint" -ForegroundColor White
Write-Host "   Total:      $activeTotal" -ForegroundColor White
Write-Host ""

Write-Host "💤 Commented Debug Statements:" -ForegroundColor Yellow
Write-Host "   debugPrint: $commentedDebug" -ForegroundColor White
Write-Host "   print:      $commentedPrint" -ForegroundColor White
Write-Host "   Total:      $commentedTotal" -ForegroundColor White
Write-Host ""

Write-Host "📈 Grand Total:" -ForegroundColor Magenta
Write-Host "   debugPrint: $totalDebug" -ForegroundColor White
Write-Host "   print:      $totalPrint" -ForegroundColor White
Write-Host "   All:        $grandTotal" -ForegroundColor White
Write-Host ""

# Show recommendations
if ($activeTotal -gt 0) {
    Write-Host "💡 Recommendations:" -ForegroundColor Blue
    Write-Host "   • For production builds: run .\scripts\comment_debug.ps1" -ForegroundColor Cyan
    Write-Host "   • To disable debug output temporarily without changing code" -ForegroundColor Cyan
} else {
    Write-Host "💡 Recommendations:" -ForegroundColor Blue
    Write-Host "   • All debug statements are commented out" -ForegroundColor Cyan
    Write-Host "   • For development: run .\scripts\uncomment_debug.ps1" -ForegroundColor Cyan
}

Write-Host ""

# Show top files with most debug statements
Write-Host "📂 Top Files with Debug Statements:" -ForegroundColor Cyan
$fileStats = $dartFiles | ForEach-Object {
    $file = $_
    $debugCount = (Select-String "debugPrint|print" $file.FullName | Where-Object { $_.Line -notmatch "^\s*//" }).Count
    if ($debugCount -gt 0) {
        [PSCustomObject]@{
            File = $file.FullName
            Count = $debugCount
        }
    }
} | Sort-Object Count -Descending | Select-Object -First 5

foreach ($stat in $fileStats) {
    Write-Host "   $($stat.File): $($stat.Count) statements" -ForegroundColor White
}
