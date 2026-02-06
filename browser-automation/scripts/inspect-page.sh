#!/bin/bash
# Inspect webpage structure
# Usage: ./inspect-page.sh <url>
# Example: ./inspect-page.sh https://wakinglove.com/vibration-rising.html

URL="${1:-https://example.com}"

echo "=== Page Inspection: $URL ==="
echo "Timestamp: $(date)"
echo ""

# Download
TEMP_FILE="/tmp/inspect-page-$$.html"
curl -s "$URL" > "$TEMP_FILE"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to download $URL"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "=== Basic Info ==="
wc -l "$TEMP_FILE"
echo ""

echo "=== Page Title ==="
grep -o "<title>.*</title>" "$TEMP_FILE" 2>/dev/null || echo "No title found"
echo ""

echo "=== All IDs (potential hooks for automation) ==="
grep -oP 'id="[^"]*"' "$TEMP_FILE" 2>/dev/null | sort -u | head -30
echo ""

echo "=== Buttons and Interactive Elements ==="
grep -iP '(button|onclick|submit|clickable)' "$TEMP_FILE" 2>/dev/null | head -20
echo ""

echo "=== Images ==="
grep -oP 'src="[^"]*"' "$TEMP_FILE" 2>/dev/null | sort -u | head -20
echo ""

echo "=== Links ==="
grep -oP 'href="[^"]*"' "$TEMP_FILE" 2>/dev/null | sort -u | head -20
echo ""

echo "=== JavaScript Functions ==="
grep -oP 'function\s+\w+' "$TEMP_FILE" 2>/dev/null | sort -u | head -20
echo ""

echo "=== CSS Classes (first 30 unique) ==="
grep -oP 'class="[^"]*"' "$TEMP_FILE" 2>/dev/null | sort -u | head -30
echo ""

# Cleanup
rm -f "$TEMP_FILE"

echo "=== Inspection Complete ==="
