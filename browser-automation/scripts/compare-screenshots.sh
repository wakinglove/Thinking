#!/bin/bash
# Compare before/after screenshots
# Usage: ./compare-screenshots.sh <before.png> <after.png>
# Example: ./compare-screenshots.sh before.png after.png

BEFORE="$1"
AFTER="$2"

if [ -z "$BEFORE" ] || [ -z "$AFTER" ]; then
    echo "Usage: compare-screenshots.sh <before.png> <after.png>"
    echo ""
    echo "This script compares two screenshots to detect visual differences."
    echo "Install ImageMagick for automatic diff generation: apt install imagemagick"
    exit 1
fi

echo "=== Visual Comparison ==="
echo "Timestamp: $(date)"
echo ""

echo "Before: $BEFORE"
if [ -f "$BEFORE" ]; then
    ls -lh "$BEFORE"
else
    echo "  ERROR: File not found"
fi
echo ""

echo "After: $AFTER"
if [ -f "$AFTER" ]; then
    ls -lh "$AFTER"
else
    echo "  ERROR: File not found"
fi
echo ""

# Check if ImageMagick is installed
if command -v compare &> /dev/null; then
    echo "=== Generating Difference Map ==="
    DIFF_FILE="/tmp/visual-diff-$(date +%s).png"
    
    if compare "$BEFORE" "$AFTER" "$DIFF_FILE" 2>/dev/null; then
        echo "Diff saved to: $DIFF_FILE"
        echo "Pink/highlighted areas = differences between before and after"
        ls -lh "$DIFF_FILE"
    else
        echo "WARNING: Could not generate diff (images may be different sizes)"
    fi
else
    echo "=== ImageMagick Not Installed ==="
    echo "Install for automatic diff:"
    echo "  Ubuntu/Debian: apt install imagemagick"
    echo "  macOS: brew install imagemagick"
    echo ""
    echo "=== Manual Comparison ==="
    echo "Open both images side by side and look for:"
    echo "  - Missing elements"
    echo "  - Color changes"
    echo "  - Layout shifts"
    echo "  - Button visibility"
    echo "  - Text differences"
fi

echo ""
echo "=== File Sizes Comparison ==="
BEFORE_SIZE=$(stat -f%z "$BEFORE" 2>/dev/null || stat -c%s "$BEFORE" 2>/dev/null)
AFTER_SIZE=$(stat -f%z "$AFTER" 2>/dev/null || stat -c%s "$AFTER" 2>/dev/null)
echo "Before: $BEFORE_SIZE bytes"
echo "After: $AFTER_SIZE bytes"
DIFF=$((AFTER_SIZE - BEFORE_SIZE))
echo "Difference: $DIFF bytes ($((DIFF * 100 / BEFORE_SIZE))%)"
