#!/bin/bash
# Progress Interrupt Control
# Usage: bash scripts/progress-interrupt.sh [mode]
# Modes:
#   bash scripts/progress-interrupt.sh        → Stop job + reporting (default)
#   bash scripts/progress-interrupt.sh silent → Stop reporting only (job continues)
#   bash scripts/progress-interrupt.sh status → Show current status
#   bash scripts/progress-interrupt.sh clear  → Clear all interrupt files

MODE="${1:-job}"

INTERRUPT_FILE="/tmp/progress_interrupt"
SILENT_FILE="/tmp/silent_interrupt"
STATUS_FILE="/tmp/progress-reporter.status"

case "$MODE" in
    job)
        echo "🛑 Stopping JOB + REPORTING..."
        touch "$INTERRUPT_FILE"
        if [ -f "$STATUS_FILE" ]; then
            echo "Current status:"
            cat "$STATUS_FILE"
        fi
        pkill -f "progress-reporter.sh" 2>/dev/null && echo "✅ Killed reporter processes"
        echo "✅ Job will be stopped on next check"
        ;;
    
    silent)
        echo "🔕 Stopping REPORTING ONLY (job continues)..."
        touch "$SILENT_FILE"
        if [ -f "$STATUS_FILE" ]; then
            echo "Current status:"
            cat "$STATUS_FILE"
        fi
        echo "✅ Reporting will stop on next check (job continues)"
        ;;
    
    status)
        echo "📊 Current Status:"
        if [ -f "$STATUS_FILE" ]; then
            cat "$STATUS_FILE"
        else
            echo "   No active progress reporter"
        fi
        echo ""
        echo "Interrupt files:"
        [ -f "$INTERRUPT_FILE" ] && echo "   🛑 $INTERRUPT_FILE (exists)"
        [ -f "$SILENT_FILE" ] && echo "   🔕 $SILENT_FILE (exists)"
        ;;
    
    clear)
        echo "🧹 Clearing all interrupt files..."
        rm -f "$INTERRUPT_FILE" "$SILENT_FILE" "$STATUS_FILE"
        echo "✅ Cleared"
        ;;
    
    help|--help|-h)
        echo "Progress Interrupt Control"
        echo ""
        echo "Usage: $0 [mode]"
        echo ""
        echo "Modes:"
        echo "  (none)    Stop job + reporting (default)"
        echo "  silent    Stop reporting only (job continues)"
        echo "  status    Show current status"
        echo "  clear     Clear all interrupt files"
        echo "  help      Show this message"
        echo ""
        echo "Examples:"
        echo "  $0              # Stop the job completely"
        echo "  $0 silent       # Just stop updates, let job finish"
        echo "  $0 status      # Check what's running"
        ;;
    
    *)
        echo "Unknown mode: $MODE"
        echo "Use: $0 help"
        exit 1
        ;;
esac
