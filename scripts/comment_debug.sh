#!/bin/bash

# Script to comment out debugPrint and print statements in Dart files
# This script will find and comment out debugPrint and print statements while preserving code structure

echo "🔍 Searching for debugPrint and print statements to comment out..."

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
    
    # Use sed to comment out debugPrint and print statements
    # Using extended regex (-E) for better compatibility
    
    # First, handle debugPrint statements
    sed -i '' -E 's/^([[:space:]]*)debugPrint[[:space:]]*\(/\1\/\/ debugPrint(/g' "$file"
    
    # Then handle print statements (but be careful not to affect other words containing "print")
    sed -i '' -E 's/^([[:space:]]*)print[[:space:]]*\(/\1\/\/ print(/g' "$file"
    
    # Also handle cases where debugPrint/print are not at the start of line but after if/else/etc
    sed -i '' -E 's/([[:space:]])debugPrint[[:space:]]*\(/\1\/\/ debugPrint(/g' "$file"
    sed -i '' -E 's/([[:space:]])print[[:space:]]*\(/\1\/\/ print(/g' "$file"
    
    echo "✅ Modified: $file"
    changes_made=true
done

echo ""
if [ "$changes_made" = true ]; then
    echo "✅ Debug statements have been commented out!"
    echo "� Use git to restore changes if needed: git checkout -- ."
else
    echo "ℹ️  No debug statements found to comment out"
fi

echo ""
echo "📊 Summary of commented debug statements:"
commented_count=$(grep -r "// debugPrint\|// print" --include="*.dart" . \
    --exclude-dir=build \
    --exclude-dir=.dart_tool \
    --exclude-dir=ios/Pods \
    --exclude-dir=android/build 2>/dev/null | wc -l | tr -d ' ')
echo "Total commented statements: $commented_count"
