# Browser Automation & Visual Verification Skill

**Status:** Ready for Deployment
**Version:** 1.0.0
**Created:** 2026-02-07
**Purpose:** Visual verification of website changes before deployment

---

## Description

Comprehensive browser automation system for verifying website changes before deployment. Prevents broken code from reaching production by implementing visual and content checks.

## Visual Verification Workflow

### Before ANY Git Push or Web Deploy:

```
1. curl check → Download HTML
2. web_fetch → Extract content
3. (Optional) Playwright → Screenshot
4. image tool → Analyze visual
5. Compare → Verify changes
6. THEN deploy
```

---

## 5 Verification Methods

### Method 1: curl + grep (Fastest)

```bash
# Download HTML
curl -s "https://wakinglove.com/page.html" > /tmp/page.html

# Check for specific elements
grep -n "element\|button\|class\|id" /tmp/page.html

# Verify changes present
grep "new-feature-class" /tmp/page.html && echo "✅ Change found"
```

**Best For:** Quick content verification, element presence checks

---

### Method 2: web_fetch (Content Analysis)

```bash
# Extract readable content
web_fetch --url "https://wakinglove.com/page.html" --extractMode "text"

# Get markdown
web_fetch --url "https://wakinglove.com/page.html" --extractMode "markdown"
```

**Best For:** Reading page content, extracting text for analysis

---

### Method 3: browser tool (Visual Snapshot - Needs Gateway)

```bash
# Requires browser gateway running
browser --action snapshot --profile "chrome" --url "https://wakinglove.com/page.html"
```

**Best For:** Full visual snapshot of rendered page

---

### Method 4: Playwright CLI (Full Automation - Recommended)

```bash
# Install
npm install playwright
npx playwright install chromium

# Create verification script
node /root/.openclaw/workspace/scripts/verify-deploy.js
```

**verify-deploy.js Example:**
```javascript
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    
    // Navigate
    await page.goto('https://wakinglove.com/page.html');
    
    // Click button (if testing functionality)
    await page.click('.my-button');
    
    // Take screenshot
    await page.screenshot({ path: '/tmp/deploy-check.png' });
    
    // Extract visible text
    const text = await page.textContent('.content');
    console.log('Content:', text);
    
    await browser.close();
    console.log('✅ Verification complete');
})();
```

**Best For:** Full interaction testing, button clicks, form fills

---

### Method 5: image tool (Visual Analysis)

```bash
# Analyze screenshot
image --image /tmp/deploy-check.png --prompt "Describe any visible errors, broken elements, or layout issues"

# Compare to previous
image --image /tmp/before.png --prompt "Compare to /tmp/after.png"
image --image /tmp/after.png --prompt "What changed from /tmp/before.png?"
```

**Best For:** Visual regression, spotting layout issues

---

## Pre-Deploy Verification Checklist

### Before Git Push:

- [ ] Run curl check on local file
- [ ] Run web_fetch on local or staging URL
- [ ] (Optional) Playwright screenshot
- [ ] (Optional) image tool analysis
- [ ] Compare to expected changes
- [ ] Document verification results
- [ ] THEN git add/commit/push

### Template:

```markdown
## Pre-Deploy Verification

**Date:** YYYY-MM-DD HH:MM
**File:** path/to/file.html

| Check | Method | Result |
|-------|--------|--------|
| Element present | curl | ✅ |
| Content correct | web_fetch | ✅ |
| Visual check | Playwright | ✅ |
| Image analysis | image tool | ✅ |

**Notes:** [Any observations]

**Status:** Ready to deploy ✅ / Not ready ❌
```

---

## Integration with AGENTS.md

Add to Phase 2.5 (Deployment Protocol Check):

```markdown
#### Phase 2.5: Visual Verification Before Deploy

**MUST DO before any git push:**

1. **Local Check:** `curl -s file://path/to/local.html > /tmp/check.html`
2. **Content Verify:** `web_fetch --url "file:///tmp/check.html" --extractMode "text"`
3. **Visual Verify (Optional):** Playwright screenshot
4. **Image Analysis (Optional):** `image --image /tmp/screenshot.png --prompt "Describe..."`
5. **Deploy Only After Verification**

**Commands:**
```bash
# Quick check
curl -s https://wakinglove.com/page.html | grep "feature-name"

# Full verification
node /root/.openclaw/workspace/scripts/verify-deploy.js
```

**Source:** `/root/.openclaw/workspace/Thinking/browser-automation/SKILL.md`

**Why:** Prevents deploying broken code. Visual check catches console misses.
```

---

## Troubleshooting

### Playwright Issues

| Problem | Solution |
|---------|----------|
| "Browser not found" | `npx playwright install chromium` |
| "Module not found" | `npm install playwright` |
| Timeout | Increase `timeoutMs` parameter |

### web_fetch Issues

| Problem | Solution |
|---------|----------|
| SSL errors | Use `curl` instead |
| Blocked access | Check robots.txt, headers |
| Large pages | Use `maxChars` limit |

### image tool Issues

| Problem | Solution |
|---------|----------|
| File too large | Resize before analysis |
| Unclear prompt | Be specific: "Describe layout, colors, errors" |

---

## Complete Verification Script

Create `/root/.openclaw/workspace/scripts/verify-deploy.js`:

```javascript
#!/usr/bin/env node
const { chromium } = require('playwright');
const fs = require('fs');

const url = process.argv[2] || 'https://wakinglove.com';
const output = process.argv[3] || '/tmp/verify-result.png';

(async () => {
    console.log(`🔍 Verifying: ${url}`);
    
    const browser = await chromium.launch();
    const page = await browser.newPage();
    
    await page.goto(url, { waitUntil: 'networkidle' });
    
    // Take screenshot
    await page.screenshot({ path: output, fullPage: true });
    
    // Check console errors
    const errors = [];
    page.on('console', msg => {
        if (msg.type() === 'error') errors.push(msg.text());
    });
    
    // Extract key content
    const title = await page.title();
    const h1 = await page.$eval('h1', el => el.textContent).catch(() => 'No H1');
    
    await browser.close();
    
    // Report
    console.log(`\n📊 Verification Report:`);
    console.log(`   Title: ${title}`);
    console.log(`   H1: ${h1}`);
    console.log(`   Screenshot: ${output}`);
    console.log(`   Errors: ${errors.length}`);
    
    if (errors.length > 0) {
        console.log(`\n⚠️ Console Errors:`);
        errors.forEach(e => console.log(`   - ${e}`));
    } else {
        console.log(`\n✅ No console errors detected`);
    }
    
    console.log(`\n🔍 Next: Run 'image --image ${output} --prompt \"Describe...\"'`);
})();
```

Usage:
```bash
node /root/.openclaw/workspace/scripts/verify-deploy.js https://wakinglove.com/tarot.html
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Quick HTML check | `curl -s url | grep "element"` |
| Content extraction | `web_fetch --url "url" --extractMode "text"` |
| Full page screenshot | `node /root/.openclaw/workspace/scripts/verify-deploy.js url` |
| Visual analysis | `image --image /tmp/screenshot.png --prompt "Describe..."` |
| Compare changes | `image --image /tmp/before.png` then `/tmp/after.png` |

---

## GitHub Actions Integration

For automated verification on push:

```yaml
name: Visual Verification
on: [push]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Playwright
        run: npm install playwright && npx playwright install chromium
      - name: Verify Deployment
        run: node /root/.openclaw/workspace/scripts/verify-deploy.js ${{ secrets.STAGING_URL }}
      - name: Image Analysis
        run: |
          echo "Analysis pending - requires image tool"
```

---

*This skill enables self-verification before deployment, reducing human dependency.*
