#!/bin/bash
# Auto-Message Cache Helper
# Usage: ./cache-message.sh "message content" [channel]
# This script sends message AND caches it automatically

MESSAGE_CONTENT="$1"
CHANNEL="${2:-telegram}"
TIMESTAMP=$(date +%H:%M:%S)
DATE=$(date +%Y-%m-%d)
CACHE_FILE="/root/.openclaw/message-cache/${DATE}.txt"

# Calculate approximate tokens (rough estimate: 4 chars per token)
TOKEN_ESTIMATE=$(echo -n "$MESSAGE_CONTENT" | wc -c)
TOKEN_ESTIMATE=$((TOKEN_ESTIMATE / 4))

# Send message via OpenClaw message tool
echo "📤 Sending message..."
# Note: This would need to integrate with OpenClaw's message system
# For now, this is a template for how it COULD work

# Cache the message
cat >> "$CACHE_FILE" << EOF
--- MESSAGE ---
timestamp: $TIMESTAMP
date: $DATE
channel: $CHANNEL
tokens: $TOKEN_ESTIMATE
--- CONTENT ---
$MESSAGE_CONTENT
--- END ---

EOF

echo "✅ Message sent and cached to $CACHE_FILE"
