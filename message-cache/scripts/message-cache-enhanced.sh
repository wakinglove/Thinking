#!/bin/bash
# Enhanced Message Cache with Metadata
# Saves to: ~/.openclaw/message-cache/YYYY-MM-DD.txt
# Keeps: All messages with metadata
# Cleanup: Auto-removes files older than 7 days

CACHE_DIR="$HOME/.openclaw/message-cache"
TODAY=$(date +%Y-%m-%d)
CACHE_FILE="$CACHE_DIR/$TODAY.txt"

mkdir -p "$CACHE_DIR"

# Clean up files older than 7 days
find "$CACHE_DIR" -name "*.txt" -mtime +7 -delete

# Function to save a message with metadata
save_message() {
    local message="$1"
    local timestamp=$(date +%H:%M:%S)
    local token_count=${2:-0}

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

# Function to get last N messages (FIXED: proper multiline extraction)
get_last() {
    local count=${1:-1}
    
    # Get the file line count and total messages
    local total=$(grep -c "^--- MESSAGE ---" "$CACHE_FILE")
    
    if [ "$count" -gt "$total" ]; then
        count=$total
    fi
    
    # Calculate which line to start from (last message starts at end)
    # Find the line numbers of all MESSAGE markers
    local lines=$(grep -n "^--- MESSAGE ---" "$CACHE_FILE" | cut -d: -f1 | tail -n "$count" | head -1)
    
    if [ -z "$lines" ]; then
        lines=1
    fi
    
    # Extract from the starting line to the end
    tail -n "+$lines" "$CACHE_FILE"
}

# Function to get total message count
get_count() {
    grep -c "^--- MESSAGE ---" "$CACHE_FILE" 2>/dev/null || echo "0"
}

case "$1" in
    --save)
        save_message "$2" "$3"
        echo "Saved message to $TODAY.txt"
        ;;
    --last)
        get_last "${2:-1}"
        ;;
    --count)
        get_count
        ;;
    --list)
        ls -lt "$CACHE_DIR"/*.txt 2>/dev/null
        ;;
    --cleanup)
        find "$CACHE_DIR" -name "*.txt" -mtime +7 -delete
        echo "Cleaned files older than 7 days"
        ;;
    *)
        echo "Usage: message-cache.sh --save \"message\" [tokens]"
        echo "       message-cache.sh --last [count]    ← Resend last N messages"
        echo "       message-cache.sh --count          ← Show total messages"
        echo "       message-cache.sh --list"
        echo "       message-cache.sh --cleanup"
        ;;
esac
