#!/bin/bash

# Script to uncomment debugPrint and print statements in Dart files
# This script will find and uncomment previously commented debug statements

echo "🔍 Searching for commented debugPrint and print statements to uncomment..."

changes_made=false

# Find all Dart files in the project (excluding build directories and other non-source folders)
find . -name "*.dart" \
    -not -path "./build/*" \
    -not -path "./.dart_tool/*" \
    -not -path "./ios/Pods/*" \
    -not -path "./android/build/*" \
    -not -path "./macos/build/*" \
    -not -path "./linux/build/*" \
    -not -path "./windows/build/*" \
    -not -path "./web/build/*" | while read -r file; do
    
    echo "📂 Processing: $file"
    
    # Use sed to uncomment debugPrint and print statements
    # Using extended regex (-E) for better compatibility
    
    # Uncomment debugPrint statements (remove // and optional space)
    sed -i '' -E 's/^([[:space:]]*)\/\/ debugPrint[[:space:]]*\(/\1debugPrint(/g' "$file"
    
    # Uncomment print statements (remove // and optional space)
    sed -i '' -E 's/^([[:space:]]*)\/\/ print[[:space:]]*\(/\1print(/g' "$file"
    
    # Handle cases where commented statements are not at start of line
    sed -i '' -E 's/([[:space:]])\/\/ debugPrint[[:space:]]*\(/\1debugPrint(/g' "$file"
    sed -i '' -E 's/([[:space:]])\/\/ print[[:space:]]*\(/\1print(/g' "$file"
    
    echo "✅ Modified: $file"
    changes_made=true
done

echo ""
if [ "$changes_made" = true ]; then
    echo "✅ Debug statements have been uncommented!"
    echo "� Use git to restore changes if needed: git checkout -- ."
else
    echo "ℹ️  No commented debug statements found to uncomment"
fi

echo ""
echo "📊 Summary of active debug statements:"
active_count=$(grep -r "debugPrint\|print" --include="*.dart" . \
    --exclude-dir=build \
    --exclude-dir=.dart_tool \
    --exclude-dir=ios/Pods \
    --exclude-dir=android/build 2>/dev/null | grep -v "// debugPrint\|// print" | wc -l | tr -d ' ')
echo "Total active statements: $active_count"
