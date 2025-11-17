#!/bin/bash

# Activity Logger for LLM Training Data (Wayland Compatible)
# Logs keyboard activity and active applications

LOG_FILE="$HOME/activity_log.jsonl"
INTERVAL=5  # Seconds between logging

# Detect display server
detect_display_server() {
    if [ -n "$WAYLAND_DISPLAY" ]; then
        echo "wayland"
    elif [ -n "$DISPLAY" ]; then
        echo "x11"
    else
        echo "unknown"
    fi
}

# Check dependencies based on display server
check_dependencies() {
    local display_server=$(detect_display_server)
    local missing=()
    
    if [ "$display_server" = "wayland" ]; then
        echo "Detected Wayland session"
        command -v evtest >/dev/null 2>&1 || missing+=("evtest")
    else
        echo "Detected X11 session"
        command -v xdotool >/dev/null 2>&1 || missing+=("xdotool")
        command -v xinput >/dev/null 2>&1 || missing+=("xinput")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing dependencies: ${missing[*]}"
        if [ "$display_server" = "wayland" ]; then
            echo "Install with: sudo apt install ${missing[*]}"
        else
            echo "Install with: sudo apt install ${missing[*]}"
        fi
        exit 1
    fi
}

# Get active window info (Wayland - GNOME)
get_active_window_wayland() {
    if command -v gdbus >/dev/null 2>&1; then
        local window_name=$(gdbus call --session \
            --dest org.gnome.Shell \
            --object-path /org/gnome/Shell/Extensions/WindowsExt \
            --method org.gnome.Shell.Extensions.WindowsExt.FocusTitle 2>/dev/null | sed "s/^'//;s/'$//")
        
        if [ -z "$window_name" ]; then
            # Fallback to active app
            window_name=$(gdbus call --session \
                --dest org.gnome.Shell \
                --object-path /org/gnome/Shell \
                --method org.freedesktop.DBus.Properties.Get \
                org.gnome.Shell FocusApp 2>/dev/null | grep -oP "'\K[^']+")
        fi
        
        echo "{\"window_name\":\"${window_name//\"/\\\"}\",\"display_server\":\"wayland\"}"
    else
        echo "{\"window_name\":\"unknown\",\"display_server\":\"wayland\"}"
    fi
}

# Get active window info (X11)
get_active_window_x11() {
    local window_id=$(xdotool getactivewindow 2>/dev/null)
    if [ -n "$window_id" ]; then
        local window_name=$(xdotool getwindowname "$window_id" 2>/dev/null)
        local window_class=$(xprop -id "$window_id" WM_CLASS 2>/dev/null | cut -d'"' -f2)
        echo "{\"window_name\":\"${window_name//\"/\\\"}\",\"window_class\":\"${window_class//\"/\\\"}\",\"display_server\":\"x11\"}"
    else
        echo "{\"window_name\":\"unknown\",\"window_class\":\"unknown\",\"display_server\":\"x11\"}"
    fi
}

# Monitor keyboard events (Wayland - requires root)
monitor_keyboard_wayland() {
    # Find keyboard device
    local kbd_device=$(ls /dev/input/by-path/*-kbd 2>/dev/null | head -1)
    
    if [ -z "$kbd_device" ]; then
        kbd_device=$(ls /dev/input/event* 2>/dev/null | head -1)
    fi
    
    if [ -z "$kbd_device" ]; then
        echo "Could not find keyboard device"
        exit 1
    fi
    
    echo "Monitoring device: $kbd_device"
    echo "Logging to: $LOG_FILE"
    echo "Press Ctrl+C to stop"
    echo ""
    
    if [ "$EUID" -ne 0 ]; then
        echo "WARNING: Running without root. Keyboard monitoring may not work."
        echo "Consider running with: sudo ./activity_logger.sh"
        echo ""
    fi
    
    local keystroke_count=0
    local start_time=$(date +%s)
    
    stdbuf -oL cat "$kbd_device" 2>/dev/null | while IFS= read -n1 char; do
        keystroke_count=$((keystroke_count + 1))
        current_time=$(date +%s)
        
        if [ $((current_time - start_time)) -ge $INTERVAL ]; then
            if [ $keystroke_count -gt 0 ]; then
                active_window=$(get_active_window_wayland)
                timestamp=$(date -Iseconds)
                
                echo "{\"timestamp\":\"$timestamp\",\"events\":$keystroke_count,\"duration\":$((current_time - start_time)),\"application\":$active_window}" >> "$LOG_FILE"
                
                keystroke_count=0
                start_time=$current_time
            fi
        fi
    done
}

# Monitor keyboard events (X11)
monitor_keyboard_x11() {
    local kbd_id=$(xinput list | grep -i keyboard | grep -i "slave.*keyboard" | head -1 | grep -oP 'id=\K\d+')
    
    if [ -z "$kbd_id" ]; then
        echo "Could not find keyboard device"
        exit 1
    fi
    
    echo "Monitoring keyboard ID: $kbd_id"
    echo "Logging to: $LOG_FILE"
    echo "Press Ctrl+C to stop"
    
    local keystroke_count=0
    local start_time=$(date +%s)
    
    xinput test "$kbd_id" | while read line; do
        if [[ "$line" =~ "key press" ]]; then
            keystroke_count=$((keystroke_count + 1))
            current_time=$(date +%s)
            
            if [ $((current_time - start_time)) -ge $INTERVAL ]; then
                if [ $keystroke_count -gt 0 ]; then
                    active_window=$(get_active_window_x11)
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
DISPLAY_SERVER=$(detect_display_server)
check_dependencies
touch "$LOG_FILE"

if [ "$DISPLAY_SERVER" = "wayland" ]; then
    monitor_keyboard_wayland
else
    monitor_keyboard_x11
fi