#!/bin/bash
# Enhanced Message Cache with Metadata
# Saves to: ~/.openclaw/message-cache/YYYY-MM-DD.txt
# Keeps: All messages with metadata
# Cleanup: Auto-removes files older than 7 days

CACHE_DIR="$HOME/.openclaw/message-cache"
TODAY=$(date +%Y-%m-%d)
CACHE_FILE="$CACHE_DIR/$TODAY.txt"
SESSION_FILE="$HOME/.openclaw/agents/main/sessions/sessions.json"

mkdir -p "$CACHE_DIR"

# Clean up files older than 7 days
find "$CACHE_DIR" -name "*.txt" -mtime +7 -delete

# Function to save a message with metadata
save_message() {
    local message="$1"
    local timestamp=$(date +%H:%M:%S)
    local token_count=${2:-0}

    # Get session info if available
    local session_info=""
    if [ -f "$SESSION_FILE" ]; then
        session_info=$(cat "$SESSION_FILE" 2>/dev/null | head -c 200 || echo "unknown")
    fi

    {
        echo "--- MESSAGE ---"
        echo "timestamp: $timestamp"
        echo "date: $TODAY"
        echo "tokens: $token_count"
        echo "--- CONTENT ---"
        echo "$message"
        echo ""
    } >> "$CACHE_FILE"
}

# Function to get last N messages
get_last() {
    local count=${1:-1}
    local output=""
    local msg_count=0

    # Read backwards and collect messages
    while IFS= read -r line; do
        if [ "$line" = "--- MESSAGE ---" ]; then
            msg_count=$((msg_count + 1))
        fi
        output="$line"$'\n'"$output"
    done < <(tac "$CACHE_FILE")

    # Extract requested number of messages
    local extracted=0
    local capturing=false

    while IFS= read -r line; do
        if [ "$extracted" -ge "$count" ]; then
            break
        fi

        if [ "$line" = "--- MESSAGE ---" ]; then
            capturing=true
            extracted=$((extracted + 1))
        fi

        if $capturing; then
            echo "$line"
        fi
    done <<< "$output"
}

case "$1" in
    --save)
        save_message "$2" "$3"
        echo "Saved: $TODAY"
        ;;
    --last)
        get_last "${2:-1}"
        ;;
    --list)
        ls -lt "$CACHE_DIR"/*.txt 2>/dev/null | head -10
        ;;
    --cleanup)
        find "$CACHE_DIR" -name "*.txt" -mtime +7 -delete
        echo "Cleaned files older than 7 days"
        ;;
    *)
        echo "Usage: message-cache.sh --save \"message\" [tokens]"
        echo "       message-cache.sh --last [count]"
        echo "       message-cache.sh --list"
        echo "       message-cache.sh --cleanup"
        ;;
esac
