# PowerShell script to uncomment debugPrint and print statements in Dart files
# This script will find and uncomment previously commented debug statements

Write-Host "🔍 Searching for commented debugPrint and print statements to uncomment..." -ForegroundColor Cyan

$changesMAde = $false

# Find all Dart files in the project (excluding build directories and other non-source folders)
$dartFiles = Get-ChildItem -Recurse -Include *.dart | Where-Object { 
    $_.FullName -notmatch "build|\.dart_tool|Pods|android\\build|ios\\build|macos\\build|linux\\build|windows\\build|web\\build" 
}

foreach ($file in $dartFiles) {
    Write-Host "📂 Processing: $($file.FullName)" -ForegroundColor Yellow
    
    # Read the file content
    $content = Get-Content $file.FullName
    $modified = $false
    
    # Process each line
    $newContent = $content | ForEach-Object {
        $line = $_
        $originalLine = $line
        
        # Uncomment debugPrint statements (remove // and optional space)
        $line = $line -replace '^(\s*)// debugPrint\s*\(', '$1debugPrint('
        
        # Uncomment print statements (remove // and optional space)
        $line = $line -replace '^(\s*)// print\s*\(', '$1print('
        
        # Handle cases where commented statements are not at start of line
        $line = $line -replace '(\s)// debugPrint\s*\(', '$1debugPrint('
        $line = $line -replace '(\s)// print\s*\(', '$1print('
        
        if ($line -ne $originalLine) {
            $script:modified = $true
        }
        
        $line
    }
    
    if ($modified) {
        # Write the modified content back to the file
        $newContent | Set-Content $file.FullName -Encoding UTF8
        Write-Host "✅ Modified: $($file.FullName)" -ForegroundColor Green
        $changesMAde = $true
    } else {
        Write-Host "⚪ No changes: $($file.FullName)" -ForegroundColor Gray
    }
}

Write-Host ""
if ($changesMAde) {
    Write-Host "✅ Debug statements have been uncommented!" -ForegroundColor Green
    Write-Host "🔄 Use git to restore changes if needed: git checkout -- ." -ForegroundColor Cyan
} else {
    Write-Host "ℹ️  No commented debug statements found to uncomment" -ForegroundColor Blue
}

Write-Host ""
Write-Host "📊 Summary of active debug statements:" -ForegroundColor Cyan
$activeCount = (Get-ChildItem -Recurse -Include *.dart | Where-Object { 
    $_.FullName -notmatch "build|\.dart_tool|Pods" 
} | Select-String "debugPrint\(|print\(" | Where-Object { 
    $_.Line -notmatch "// debugPrint|// print" 
}).Count

Write-Host "Total active statements: $activeCount" -ForegroundColor White
