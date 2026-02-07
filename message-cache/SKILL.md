# Message Cache System

**Status:** Prototype Phase (Auto-Caching)
**Version:** 1.2.0 (Updated 2026-02-07)
**Author:** Waking Love (Neo Young)

## Description

OpenClaw Telegram delivery insurance system. Solves "did my message get delivered?" by caching all agent outputs to external files with metadata, enabling manual resend capability.

## The Problem

Telegram messages can be lost due to:
- Rate limiting
- Connection issues
- Rapid message bursts
- Character limits

## The Solution: Auto-Caching Protocol

### Manual Protocol (Current)

After EVERY `message --action send` call:

```bash
# 1. Send message
message --action send --message "Your content" --channel telegram

# 2. Cache it
read ~/.openclaw/message-cache/$(date +%Y-%m-%d).txt
write --content "---\ntimestamp: $(date +%H:%M:%S)\ndate: $(date +%Y-%m-%d)\ntokens: <estimate>\n---\n$(message_content)\n--- END ---\n" --path ~/.openclaw/message-cache/$(date +%Y-%m-%d).txt
```

### Template for Each Response

```
--- MESSAGE ---
timestamp: HH:MM:SS
date: YYYY-MM-DD
tokens: <estimate>
--- CONTENT ---
[Full message content here]
--- END ---
```

### Auto-Caching Helper (Prototype)

Location: `/root/.openclaw/workspace/scripts/cache-message.sh`

```bash
#!/bin/bash
# Usage: ./cache-message.sh "message content"
# Sends message + caches automatically
```

## Features

| Feature | Status | Notes |
|----------|--------|-------|
| Manual caching | ✅ Working | Requires explicit `write` after each message |
| Resend capability | ✅ Working | `resend last x` commands |
| Auto-cleanup | ⚠️ Manual | Cron job needed for 7-day cleanup |
| Auto-caching | 🔄 Prototype | Helper script created, full automation needs OpenClaw enhancement |

## Telegram-Friendly Message Formats

### Simple Line Table (Best for single lines)

```
| Line |
|------|
| Your message here |
```

**Why:** Tables prevent message fragmentation.

### Mini Table (Recommended for short messages)

```
| Status |
|--------|
| ✅ Message delivered |
```

### Multi-Line Without Table

Group all related content in ONE message to prevent fragmentation.

## Installation

```bash
# Create cache directory
mkdir -p ~/.openclaw/message-cache

# Make helper executable
chmod +x /root/.openclaw/workspace/scripts/cache-message.sh

# Test
./cache-message.sh "Test message"
```

## Usage

### Manual Caching (Current Workflow)

```bash
# After message tool call
read ~/.openclaw/message-cache/$(date +%Y-%m-%d).txt

# Append new message (replace placeholders)
write --content "---\ntimestamp: $(date +%H:%M:%S)\ndate: $(date +%Y-%m-%d)\ntokens: <count>\n---\nYour message here\n--- END ---\n" --path ~/.openclaw/message-cache/$(date +%Y-%m-%d).txt
```

### Resend Commands

When messages are lost:

- `resend last` → Last 1 message
- `resend last 2` → Last 2 messages
- `resend last x messages` → Any number
- `resend message <number>` → Specific message

### List Cache

```bash
read ~/.openclaw/message-cache/$(date +%Y-%m-%d).txt
cat ~/.openclaw/message-cache/$(date +%Y-%m-%d).txt | grep -A 10 "MESSAGE"
```

## Resend Workflow (For Lost Messages)

1. User says: "resend last 2"
2. Assistant reads cache file
3. Extracts last 2 messages
4. Resends via `message --action send`

## Future Enhancement: Full Auto-Caching

To achieve TRUE auto-caching (no manual `write` needed), OpenClaw would need:

1. **Message hook system** - Call a function after every message send
2. **Built-in caching** - OpenClaw core feature
3. **Channel integration** - Telegram plugin auto-caches

This requires architectural changes to OpenClaw itself.

## The Key Insight

Previous limitation thought: "I can't access my outputs"

Reality: External files persist! Use `read` + `write` tools!

```
read ~/.openclaw/message-cache/YYYY-MM-dd.txt
```

The limitation was understanding, not capability.

## Integration with AGENTS.md

Add to Phase 2.7:

```markdown
#### Phase 2.7: Message Cache Check
1. Read today's cache file
2. Check for "resend" flags
3. Resend if needed
4. AFTER EVERY RESPONSE: Cache the message with template
```

## Quick Reference

| Task | Command |
|------|---------|
| Save message | Write to `~/.openclaw/message-cache/YYYY-MM-DD.txt` |
| List messages | `read ~/.openclaw/message-cache/$(date +%Y-%m-%d).txt` |
| Resend last | Extract from cache, `message --action send` |
| Resend x | Extract x messages, send sequentially |
| Cleanup | Cron job to remove files older than 7 days |
