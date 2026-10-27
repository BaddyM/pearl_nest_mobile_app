#!/bin/bash

# Script to restore original files from backups
# This will restore files to their state before running comment_debug.sh

echo "🔄 Restoring original files from backups..."

# Find all backup files and restore them
find . -name "*.dart.backup" \
    -not -path "./build/*" \
    -not -path "./.dart_tool/*" \
    -not -path "./ios/Pods/*" \
    -not -path "./android/build/*" | while read -r backup_file; do
    
    # Get the original file name by removing .backup extension
    original_file="${backup_file%.backup}"
    
    if [ -f "$original_file" ]; then
        echo "📂 Restoring: $original_file"
        cp "$backup_file" "$original_file"
        echo "✅ Restored: $original_file"
    else
        echo "⚠️  Original file not found: $original_file"
    fi
done

echo ""
echo "✅ All files have been restored to their original state!"
echo "🗑️  You can now safely delete .backup files if desired:"
echo "    find . -name '*.dart.backup' -delete"
