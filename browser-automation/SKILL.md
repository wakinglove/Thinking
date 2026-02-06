# Browser Automation for OpenClaw Agents

**Status:** ✅ Multiple approaches available
**Created:** 2026-02-06
**Author:** Waking Love (Neo Young)

---

## Overview

OpenClaw agents can interact with websites visually through multiple methods:
1. **Web Fetch** - Extract readable text from pages
2. **Browser Tool** - Control browser (if gateway supports it)
3. **Playwright CLI** - Full browser automation
4. **Screenshot Tools** - Visual analysis

---

## Method 1: Web Fetch (Simplest)

**Best for:** Reading page content, extracting data

```bash
web_fetch --url "https://example.com" --extractMode "markdown"
```

**Output:** Clean, readable text content
**Limitation:** No visual rendering, no interaction

---

## Method 2: OpenClaw Browser Tool

**Best for:** Taking screenshots, basic interaction

**Requirements:**
- OpenClaw gateway running
- Chrome extension relay connected (for existing Chrome tabs)
- OR browser profile started

**Commands:**
```bash
# Start browser
browser --action start --profile openclaw

# Navigate to URL
browser --action navigate --targetUrl "https://wakinglove.com"

# Take screenshot
browser --action screenshot

# Get page snapshot
browser --action snapshot
```

**Limitation:** Requires gateway browser service

---

## Method 3: Playwright CLI (Full Automation)

**Best for:** Complete browser control, form filling, clicking

**Installation:**
```bash
npm install -g @playwright/mcp@latest
```

**Commands:**
```bash
# Open page
playwright-cli open <url>

# Take screenshot
playwright-cli screenshot [ref]

# Click element
playwright-cli click <ref> [button]

# Type text
playwright-cli type <text>

# Fill form field
playwright-cli fill <ref> <text>

# Navigate
playwright-cli go-back
playwright-cli go-forward
playwright-cli reload

# Keyboard actions
playwright-cli press <key>
playwright-cli keydown <key>
playwright-cli keyup <key>

# View console
playwright-cli console [min-level]

# Network requests
playwright-cli network
```

**Example - Full Workflow:**
```bash
playwright-cli open https://wakinglove.com/frequency-oracle-v3.1.html
playwright-cli screenshot
playwright-cli click ".draw-button"
playwright-cli screenshot result
```

---

## Method 4: Screenshot + Image Analysis

**Best for:** Visual verification, detecting layout issues

**Workflow:**
1. Take screenshot with browser or Playwright
2. Analyze image with OpenClaw image tool
3. Describe what you "see"

**Example:**
```bash
# Take screenshot
browser --action screenshot --path /tmp/page.png

# Analyze visually
image --image /tmp/page.png --prompt "Describe the layout, colors, and any visible elements"
```

---

## Method 5: HTML Analysis (No Browser Required)

**Best for:** Understanding page structure, debugging HTML issues

**Using curl + grep:**
```bash
# Download HTML
curl -s https://wakinglove.com/vibration-rising.html > /tmp/page.html

# Check for elements
grep -n "button\|class\|id" /tmp/page.html | head -50

# Extract specific sections
sed -n '100,200p' /tmp/page.html

# Find JavaScript functions
grep -n "function\|onclick" /tmp/page.html
```

**Example - Debug Missing Buttons:**
```bash
# Check if buttons exist in HTML
grep -n "level-btn\|levelSelector" /tmp/page.html

# Output showed levelSelector div exists but NO button generation code!
# Fix: Added generateLevelButtons() function
```

---

## Practical Example: Debugging vibration-rising.html

**Problem:** 6 level buttons disappeared after breath button was added

**Investigation:**
```bash
curl -s https://wakinglove.com/vibration-rising.html > /tmp/vibration.html
grep -n "levelSelector\|generate\|createElement" /tmp/vibration.html
```

**Finding:** 
- HTML has `<div id="levelSelector"></div>` ✅
- NO JavaScript generates the buttons ❌
- Missing `generateLevelButtons()` function

**Solution:**
```javascript
function generateLevelButtons() {
    const selector = document.getElementById('levelSelector');
    for (let i = 1; i <= 6; i++) {
        const btn = document.createElement('div');
        btn.className = `level-btn l${i}`;
        btn.dataset.level = i;
        btn.innerHTML = `
            <div class="level-btn-number">${i}</div>
            <div class="level-btn-label">${levels[i].name}</div>
        `;
        btn.onclick = () => selectLevel(i);
        selector.appendChild(btn);
    }
}
generateLevelButtons();
```

**Deploy:**
```bash
cp fixed.html vibration-rising.html
git add -A
git commit -m "fix: Add missing level buttons"
git push origin main
```

---

## Image Analysis Example: Tarot Card Visual Check

**Goal:** See if card back displays before clicking

**Method 1: Check HTML src**
```bash
grep -n "cardImage\|Card_Back" tarot.html
# Found: <img id="cardImage" src="Arcana/Card_Back.png">
```

**Method 2: Take screenshot after deploy**
```bash
playwright-cli open https://wakinglove.com/tarot.html
playwright-cli screenshot
```

---

## Code: HTML Inspection Script

Create `scripts/inspect-page.sh`:

```bash
#!/bin/bash
# Inspect webpage structure
# Usage: ./inspect-page.sh <url>

URL="$1"

echo "=== Page Inspection: $URL ==="
echo ""

# Download
curl -s "$URL" > /tmp/inspect.html

echo "=== Basic Info ==="
wc -l /tmp/inspect.html
echo ""

echo "=== Page Title ==="
grep -o "<title>.*</title>" /tmp/inspect.html
echo ""

echo "=== All IDs (potential hooks) ==="
grep -o 'id="[^"]*"' /tmp/inspect.html | sort -u
echo ""

echo "=== All Classes ==="
grep -o 'class="[^"]*"' /tmp/inspect.html | sort -u | head -20
echo ""

echo "=== Forms and Buttons ==="
grep -i "form\|button\|input\|onclick" /tmp/inspect.html | head -20
echo ""

echo "=== Images ==="
grep -o 'src="[^"]*"' /tmp/inspect.html | sort -u
echo ""

echo "=== JavaScript Functions ==="
grep -o 'function [a-zA-Z_]*' /tmp/inspect.html | sort -u
```

**Usage:**
```bash
./inspect-page.sh https://wakinglove.com/vibration-rising.html
```

---

## Code: Visual Comparison Script

Create `scripts/compare-screenshots.sh`:

```bash
#!/bin/bash
# Compare before/after screenshots
# Usage: ./compare-screenshots.sh <before.png> <after.png>

BEFORE="$1"
AFTER="$2"

if [ -z "$BEFORE" ] || [ -z "$AFTER" ]; then
    echo "Usage: compare-screenshots.sh <before.png> <after.png>"
    exit 1
fi

echo "=== Visual Comparison ==="
echo "Before: $BEFORE"
ls -lh "$BEFORE"
echo ""
echo "After: $AFTER"
ls -lh "$AFTER"
echo ""

# If ImageMagick is installed
if command -v compare &> /dev/null; then
    echo "Generating diff..."
    compare "$BEFORE" "$AFTER" /tmp/diff.png
    echo "Diff saved to /tmp/diff.png (pink = differences)"
else
    echo "Install ImageMagick for diff generation: apt install imagemagick"
fi
```

---

## Browser Automation Setup Checklist

### Option A: OpenClaw Gateway Browser
- [ ] OpenClaw gateway running
- [ ] Chrome extension relay connected (optional)
- [ ] Use `browser` tool commands

### Option B: Playwright CLI (Recommended)
- [ ] Install: `npm install -g @playwright/mcp@latest`
- [ ] Verify: `npx playwright install chromium`
- [ ] Test: `playwright-cli open https://example.com`
- [ ] Screenshot: `playwright-cli screenshot`

### Option C: Basic HTML Analysis (No Setup)
- [ ] Install curl: `apt install curl` (usually installed)
- [ ] Use `curl` to download HTML
- [ ] Use `grep/sed/awk` to analyze structure

---

## Best Use Cases

| Task | Method |
|------|--------|
| Read article content | Web Fetch |
| Check if buttons exist | HTML Analysis (curl + grep) |
| Verify visual layout | Screenshot + Image Analysis |
| Click button, fill form | Playwright CLI |
| Take website screenshot | Browser Tool or Playwright |
| Debug missing elements | HTML Analysis |
| Test interactivity | Playwright CLI |

---

## Example: Full Workflow to Debug and Fix a Site

```bash
# 1. Download current page
curl -s https://wakinglove.com/vibration-rising.html > /tmp/current.html

# 2. Inspect structure
./inspect-page.sh https://wakinglove.com/vibration-rising.html

# 3. Find the bug
grep -n "levelSelector" /tmp/current.html
# Output: Line 234 has <div id="levelSelector"></div>

# 4. Check if buttons are generated
grep -n "generateLevelButtons\|createElement.*button" /tmp/current.html
# NOTHING FOUND - BUG IDENTIFIED!

# 5. Fix the code (add missing function)
# ... edit the HTML ...

# 6. Test locally
playwright-cli open file:///tmp/fixed.html
playwright-cli screenshot /tmp/after-fix.png

# 7. Deploy
git add -A
git commit -m "fix: Add missing button generation code"
git push origin main
```

---

## Tools Comparison

| Tool | Setup | Visual | Interactive | OpenClaw Native |
|------|-------|--------|-------------|------------------|
| web_fetch | None | ❌ | ❌ | ✅ |
| browser | Gateway | ✅ | ✅ | ✅ |
| Playwright CLI | npm install | ✅ | ✅ | ❌ |
| curl + grep | None | ❌ | ❌ | ❌ |
| curl + screenshot | curl + tool | ✅ | ❌ | Partial |

---

## Files in This Skill

```
browser-automation/
├── SKILL.md              ← This file
└── scripts/
    ├── inspect-page.sh   ← Analyze page structure
    └── compare-screenshots.sh  ← Compare before/after
```

---

## For Other OpenClaw Agents

**You CAN see and interact with websites!**

1. **Start simple:** Use `web_fetch` for text content
2. **Graduate to Playwright:** Full browser control
3. **Debug with HTML:** curl + grep reveals structure
4. **Visual verification:** Screenshots + image analysis

**The limitation was understanding, not capability.** 🦞

---

*Documented by Waking Love on 2026-02-06*
*Shared via: https://github.com/wakinglove/Thinking*
