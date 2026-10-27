#!/bin/bash

# Script to show the current status of debug statements in the codebase
# This helps you understand what debug statements exist before running other scripts

echo "📊 Debug Statement Status Report"
echo "================================="
echo ""

# Count active debug statements
active_debug=$(grep -r "debugPrint\s*(" --include="*.dart" . \
    --exclude-dir=build \
    --exclude-dir=.dart_tool \
    --exclude-dir=ios/Pods \
    --exclude-dir=android/build 2>/dev/null | grep -v "// debugPrint" | wc -l | tr -d ' ')

active_print=$(grep -r "print\s*(" --include="*.dart" . \
    --exclude-dir=build \
    --exclude-dir=.dart_tool \
    --exclude-dir=ios/Pods \
    --exclude-dir=android/build 2>/dev/null | grep -v "// print" | wc -l | tr -d ' ')

# Count commented debug statements  
commented_debug=$(grep -r "// debugPrint\s*(" --include="*.dart" . \
    --exclude-dir=build \
    --exclude-dir=.dart_tool \
    --exclude-dir=ios/Pods \
    --exclude-dir=android/build 2>/dev/null | wc -l | tr -d ' ')

commented_print=$(grep -r "// print\s*(" --include="*.dart" . \
    --exclude-dir=build \
    --exclude-dir=.dart_tool \
    --exclude-dir=ios/Pods \
    --exclude-dir=android/build 2>/dev/null | wc -l | tr -d ' ')

# Calculate totals
total_debug=$((active_debug + commented_debug))
total_print=$((active_print + commented_print))
total_all=$((total_debug + total_print))

echo "🟢 Active Debug Statements:"
echo "   debugPrint: $active_debug"
echo "   print:      $active_print"
echo "   Total:      $((active_debug + active_print))"
echo ""

echo "💤 Commented Debug Statements:"
echo "   debugPrint: $commented_debug"
echo "   print:      $commented_print"
echo "   Total:      $((commented_debug + commented_print))"
echo ""

echo "📈 Grand Total:"
echo "   debugPrint: $total_debug"
echo "   print:      $total_print"
echo "   All:        $total_all"
echo ""

# Show recommendations
if [ $((active_debug + active_print)) -gt 0 ]; then
    echo "💡 Recommendations:"
    echo "   • For production builds: run ./scripts/comment_debug.sh"
    echo "   • To disable debug output temporarily without changing code"
else
    echo "💡 Recommendations:"
    echo "   • All debug statements are commented out"
    echo "   • For development: run ./scripts/uncomment_debug.sh"
fi

echo ""

# Show sample files with most debug statements
echo "📂 Top Files with Debug Statements:"
grep -r "debugPrint\|print" --include="*.dart" . \
    --exclude-dir=build \
    --exclude-dir=.dart_tool \
    --exclude-dir=ios/Pods \
    --exclude-dir=android/build 2>/dev/null | \
    cut -d: -f1 | sort | uniq -c | sort -nr | head -5 | \
    while read count file; do
        echo "   $file: $count statements"
    done
