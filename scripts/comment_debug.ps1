# PowerShell script to comment out debugPrint and print statements in Dart files
# This script will find and comment out debugPrint and print statements while preserving code structure

Write-Host "🔍 Searching for debugPrint and print statements to comment out..." -ForegroundColor Cyan

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
        
        # Comment out debugPrint statements at start of line (with indentation)
        $line = $line -replace '^(\s*)debugPrint\s*\(', '$1// debugPrint('
        
        # Comment out print statements at start of line (with indentation)
        $line = $line -replace '^(\s*)print\s*\(', '$1// print('
        
        # Comment out debugPrint in other contexts (after spaces)
        $line = $line -replace '(\s)debugPrint\s*\(', '$1// debugPrint('
        
        # Comment out print in other contexts (after spaces)
        $line = $line -replace '(\s)print\s*\(', '$1// print('
        
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
    Write-Host "✅ Debug statements have been commented out!" -ForegroundColor Green
    Write-Host "🔄 Use git to restore changes if needed: git checkout -- ." -ForegroundColor Cyan
} else {
    Write-Host "ℹ️  No debug statements found to comment out" -ForegroundColor Blue
}

Write-Host ""
Write-Host "📊 Summary of commented debug statements:" -ForegroundColor Cyan
$commentedCount = (Get-ChildItem -Recurse -Include *.dart | Where-Object { 
    $_.FullName -notmatch "build|\.dart_tool|Pods" 
} | Select-String "// debugPrint|// print").Count

Write-Host "Total commented statements: $commentedCount" -ForegroundColor White
