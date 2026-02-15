#!/bin/bash
# Progress Command Parser
# Usage: Run this script and pipe commands or pass as arguments
# Commands:
#   stop process / stop job / kill        → Stop job + reporting
#   stop update / stop reporting          → Stop only updates (job continues)
#   update / status / progress now        → Send immediate update
#   help                                 → Show all commands

COMMAND="$*"
STATUS_FILE="/tmp/progress-reporter.status"

# Parse command (case insensitive)
cmd=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')

if [[ "$cmd" == *"help"* ]]; then
    echo "📋 Progress Command Help"
    echo ""
    echo "Commands:"
    echo "  stop process / stop job / kill      → Stop job + reporting"
    echo "  stop update / stop reporting        → Stop only updates (job continues)"
    echo "  update / status / progress now       → Send immediate update"
    echo "  help                                → Show this message"
    exit 0
fi

if [[ "$cmd" == *"stop process"* ]] || [[ "$cmd" == *"stop job"* ]] || [[ "$cmd" == *"kill"* ]]; then
    echo "🛑 Stopping JOB + REPORTING..."
    touch /tmp/progress_interrupt
    if [ -f "$STATUS_FILE" ]; then
        DESCRIPTION=$(grep "^DESCRIPTION=" "$STATUS_FILE" | cut -d= -f2-)
        ELAPSED=$(grep "^ELAPSED=" "$STATUS_FILE" | cut -d= -f2-)
        /usr/bin/openclaw message send --channel telegram --target 8580918185 --message "| 🛑 $DESCRIPTION |\n|--------|\n| Status: Stopping... |\n| Elapsed: $ELAPSED |" 2>/dev/null
    fi
    echo "✅ Job + reporting will stop"
    exit 0
fi

if [[ "$cmd" == *"stop update"* ]] || [[ "$cmd" == *"stop reporting"* ]]; then
    echo "🔕 Stopping REPORTING ONLY (job continues)..."
    touch /tmp/silent_interrupt
    if [ -f "$STATUS_FILE" ]; then
        DESCRIPTION=$(grep "^DESCRIPTION=" "$STATUS_FILE" | cut -d= -f2-)
        ELAPSED=$(grep "^ELAPSED=" "$STATUS_FILE" | cut -d= -f2-)
        /usr/bin/openclaw message send --channel telegram --target 8580918185 --message "| 🔕 $DESCRIPTION |\n|--------|\n| Status: Stopping updates |\n| Job continues |\n| Elapsed: $ELAPSED |" 2>/dev/null
    fi
    echo "✅ Reporting will stop, job continues"
    exit 0
fi

if [[ "$cmd" == *"update"* ]] || [[ "$cmd" == *"status"* ]] || [[ "$cmd" == *"progress"* ]]; then
    echo "📊 Sending immediate update..."
    if [ -f "$STATUS_FILE" ]; then
        STATUS=$(grep "^STATUS=" "$STATUS_FILE" | cut -d= -f2-)
        DESCRIPTION=$(grep "^DESCRIPTION=" "$STATUS_FILE" | cut -d= -f2-)
        ELAPSED=$(grep "^ELAPSED=" "$STATUS_FILE" | cut -d= -f2-)
        INTERVAL=$(grep "^SUBSEQUENT_INTERVAL=" "$STATUS_FILE" | cut -d= -f2-)
        
        if [ "$STATUS" == "running" ]; then
            /usr/bin/openclaw message send --channel telegram --target 8580918185 --message "| ⏳ $DESCRIPTION |\n|--------|\n| Status: Running |\n| Elapsed: $ELAPSED |\n| Next update: ${INTERVAL:-180}s |" 2>/dev/null
            echo "✅ Update sent"
        elif [ "$STATUS" == "complete" ]; then
            /usr/bin/openclaw message send --channel telegram --target 8580918185 --message "| ✅ $DESCRIPTION |\n|--------|\n| Status: Complete |\n| Time: $ELAPSED |" 2>/dev/null
            echo "✅ Job already complete"
        elif [ "$STATUS" == "interrupted" ]; then
            /usr/bin/openclaw message send --channel telegram --target 8580918185 --message "| 🛑 $DESCRIPTION |\n|--------|\n| Status: Interrupted |\n| Elapsed: $ELAPSED |" 2>/dev/null
            echo "✅ Status sent (interrupted)"
        else
            echo "⚠️ Unknown status: $STATUS"
        fi
    else
        echo "⚠️ No active progress reporter"
    fi
    exit 0
fi

echo "❓ Unknown command: $COMMAND"
echo "Use: help, stop process, stop update, update"
exit 1
