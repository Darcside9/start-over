#!/bin/bash

# Activity Logger for LLM Training Data
# Logs keyboard activity and active applications

LOG_FILE="$HOME/activity_log.jsonl"
INTERVAL=5  # Seconds between checks

# Check dependencies
check_dependencies() {
    local missing=()
    command -v xdotool >/dev/null 2>&1 || missing+=("xdotool")
    command -v xinput >/dev/null 2>&1 || missing+=("xinput")
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing dependencies: ${missing[*]}"
        echo "Install with: sudo apt install ${missing[*]}"
        exit 1
    fi
}

# Get active window info
get_active_window() {
    local window_id=$(xdotool getactivewindow 2>/dev/null)
    if [ -n "$window_id" ]; then
        local window_name=$(xdotool getwindowname "$window_id" 2>/dev/null)
        local window_class=$(xprop -id "$window_id" WM_CLASS 2>/dev/null | cut -d'"' -f2)
        echo "{\"window_name\":\"${window_name//\"/\\\"}\",\"window_class\":\"${window_class//\"/\\\"}\"}"
    else
        echo "{\"window_name\":\"unknown\",\"window_class\":\"unknown\"}"
    fi
}

# Monitor keyboard events
monitor_keyboard() {
    local kbd_id=$(xinput list | grep -i keyboard | grep -i "slave.*keyboard" | head -1 | grep -oP 'id=\K\d+')
    
    if [ -z "$kbd_id" ]; then
        echo "Could not find keyboard device"
        exit 1
    fi
    
    echo "Monitoring keyboard ID: $kbd_id"
    echo "Logging to: $LOG_FILE"
    echo "Press Ctrl+C to stop"
    
    local last_active=""
    local keystroke_count=0
    local start_time=$(date +%s)
    
    xinput test "$kbd_id" | while read line; do
        if [[ "$line" =~ "key press" ]]; then
            keystroke_count=$((keystroke_count + 1))
            current_time=$(date +%s)
            
            # Log every INTERVAL seconds
            if [ $((current_time - start_time)) -ge $INTERVAL ]; then
                if [ $keystroke_count -gt 0 ]; then
                    active_window=$(get_active_window)
                    timestamp=$(date -Iseconds)
                    
                    echo "{\"timestamp\":\"$timestamp\",\"keystrokes\":$keystroke_count,\"duration\":$((current_time - start_time)),\"application\":$active_window}" >> "$LOG_FILE"
                    
                    keystroke_count=0
                    start_time=$current_time
                fi
            fi
        fi
    done
}

# Main
check_dependencies
touch "$LOG_FILE"
monitor_keyboard