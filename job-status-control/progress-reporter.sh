#!/bin/bash
# Progress Reporter with Dual Interrupt Modes
# Usage: bash scripts/progress-reporter.sh "Task description" "command"
#
# INTERRUPT MODES:
# 1. Stop JOB + REPORTING: touch /tmp/progress_interrupt
# 2. Stop ONLY REPORTING: touch /tmp/silent_interrupt
#
# Smart Intervals:
# - First update: 1 minute
# - Subsequent: 3 minutes
# - Interrupt checks: Every 5 seconds

set -e

DESCRIPTION="$1"
COMMAND="$2"
FIRST_INTERVAL="${3:-90}"      # Default: 1.5 minutes (90s)
SUBSEQUENT_INTERVAL="${4:-180}" # Default: 3 minutes
STATUS_FILE="/tmp/progress-reporter.status"
INTERRUPT_FILE="/tmp/progress_interrupt"
SILENT_FILE="/tmp/silent_interrupt"

format_time() {
    local seconds=$1
    if [ $seconds -lt 60 ]; then
        echo "${seconds}s"
    elif [ $seconds -lt 3600 ]; then
        echo "$((seconds / 60))m $((seconds % 60))s"
    else
        echo "$((seconds / 3600))h $(((seconds % 3600) / 60))m"
    fi
}

send_telegram() {
    local message="$1"
    /usr/bin/openclaw message send --channel telegram --target 8580918185 --message "$message" 2>/dev/null
}

write_status() {
    local status="$1"
    local elapsed="$2"
    local last_line="$3"
    echo "STATUS=$status" > "$STATUS_FILE"
    echo "DESCRIPTION=$DESCRIPTION" >> "$STATUS_FILE"
    echo "ELAPSED=$elapsed" >> "$STATUS_FILE"
    echo "FIRST_INTERVAL=${FIRST_INTERVAL}s" >> "$STATUS_FILE"
    echo "SUBSEQUENT_INTERVAL=${SUBSEQUENT_INTERVAL}s" >> "$STATUS_FILE"
    echo "LAST_LINE=$last_line" >> "$STATUS_FILE"
    echo "PID=$$" >> "$STATUS_FILE"
    echo "UPDATED=$(date +%s)" >> "$STATUS_FILE"
}

check_interrupt() {
    if [ -f "$INTERRUPT_FILE" ]; then
        return 0
    fi
    return 1
}

check_silent() {
    if [ -f "$SILENT_FILE" ]; then
        return 0
    fi
    return 1
}

cleanup_job() {
    local elapsed=$1
    local time_str=$(format_time $elapsed)
    echo "🛑 Interrupt (JOB) received!"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        echo "   Killing child process $pid"
        kill "$pid" 2>/dev/null
    fi
    write_status "interrupted" "$time_str" "Interrupted by user"
    send_telegram "| 🛑 $DESCRIPTION |\n|--------|\n| Status: Interrupted (job stopped) |\n| Time: $time_str |"
    rm -f "$INTERRUPT_FILE" "$SILENT_FILE"
    exit 130
}

cleanup_reporting() {
    local elapsed=$1
    local time_str=$(format_time $elapsed)
    echo "🔕 Silent interrupt - stopping only reporting"
    write_status "silent" "$time_str" "Reporting stopped, job continues"
    send_telegram "| 🔕 $DESCRIPTION |\n|--------|\n| Status: Reporting stopped |\n| Job continues in background |\n| Time: $time_str |"
    rm -f "$SILENT_FILE"
}

trap 'cleanup_job $elapsed' SIGINT SIGTERM

main() {
    if [ -z "$DESCRIPTION" ] || [ -z "$COMMAND" ]; then
        echo "Usage: $0 \"Task description\" \"command\""
        echo ""
        echo "Interrupt modes:"
        echo "  touch $INTERRUPT_FILE  → Stop job + reporting"
        echo "  touch $SILENT_FILE    → Stop ONLY reporting (job continues)"
        exit 1
    fi
    
    rm -f "$INTERRUPT_FILE" "$SILENT_FILE"
    
    local start_time=$(date +%s)
    local pid=""
    local running=true
    local elapsed=0
    local first_update_sent=false
    local reporting_active=true
    
    echo "🚀 Starting: $DESCRIPTION"
    echo "   First: ${FIRST_INTERVAL}s | Subsequent: ${SUBSEQUENT_INTERVAL}s"
    echo "   Interrupt: touch $INTERRUPT_FILE (stops job)"
    echo "   Silent: touch $SILENT_FILE (stops reporting only)"
    
    send_telegram "| ⏳ $DESCRIPTION |\n|--------|\n| Starting... |\n| 1st: ${FIRST_INTERVAL}s, then ${SUBSEQUENT_INTERVAL}s |"
    
    write_status "running" "0s" "Starting..."
    
    eval "$COMMAND" > /tmp/progress_output_$$.log 2>&1 &
    pid=$!
    
    echo "   PID: $pid"
    
    while $running; do
        sleep 5
        elapsed=$(($(date +%s) - start_time))
        local time_str=$(format_time $elapsed)
        
        # Check for job interrupt
        if check_interrupt; then
            cleanup_job $elapsed
            return 130
        fi
        
        # Check for silent interrupt (stop reporting only)
        if check_silent && [ "$reporting_active" = true ]; then
            cleanup_reporting $elapsed
            reporting_active=false
            echo "   🔇 Reporting stopped, job continues in background"
        fi
        
        # Check if job is still running
        if kill -0 $pid 2>/dev/null; then
            # Only send updates if reporting is active
            if [ "$reporting_active" = true ]; then
                local last_output=$(tail -3 /tmp/progress_output_$$.log 2>/dev/null | tail -1)
                [ -z "$last_output" ] && last_output="Processing..."
                
                local should_update=false
                if [ "$first_update_sent" = false ] && [ $elapsed -ge $FIRST_INTERVAL ]; then
                    should_update=true
                    first_update_sent=true
                elif [ "$first_update_sent" = true ] && [ $((elapsed - FIRST_INTERVAL)) -ge $SUBSEQUENT_INTERVAL ]; then
                    should_update=true
                fi
                
                if [ "$should_update" = true ]; then
                    echo "   ⏳ ${time_str}"
                    write_status "running" "$time_str" "$last_output"
                    send_telegram "| ⏳ $DESCRIPTION |\n|--------|\n| Elapsed: $time_str |\n| Next: ${SUBSEQUENT_INTERVAL}s |"
                fi
            fi
        else
            running=false
        fi
    done
    
    wait $pid
    local exit_code=$?
    elapsed=$(($(date +%s) - start_time))
    local time_str=$(format_time $elapsed)
    
    rm -f /tmp/progress_output_$$.log
    
    if [ $exit_code -eq 0 ]; then
        echo -e "✅ Complete! (${time_str})"
        write_status "complete" "$time_str" "Done!"
        send_telegram "| ✅ $DESCRIPTION |\n|--------|\n| Time: $time_str |\n| Status: Complete! |"
    else
        echo -e "❌ Failed (exit code: $exit_code, time: $time_str)"
        write_status "failed" "$time_str" "Exit code: $exit_code"
        send_telegram "| ❌ $DESCRIPTION |\n|--------|\n| Time: $time_str |\n| Status: Failed |"
    fi
    
    rm -f "$INTERRUPT_FILE" "$SILENT_FILE"
    return $exit_code
}

main "$@"
