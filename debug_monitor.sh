#!/bin/bash
# Godot Debug Monitor Script
# Monitors the game execution and logs errors/warnings

LOG_FILE="/tmp/godot_debug.log"
ERROR_LOG="/tmp/godot_errors.log"

echo "=== Godot Debug Monitor Started ===" | tee -a $ERROR_LOG
echo "Timestamp: $(date)" | tee -a $ERROR_LOG
echo "" | tee -a $ERROR_LOG

# Monitor for errors in real-time
tail -f $LOG_FILE | while read line; do
    # Check for errors
    if echo "$line" | grep -qE "(ERROR|SCRIPT ERROR|assert|failed|crash|Exception)"; then
        echo "[ERROR] $line" | tee -a $ERROR_LOG
    fi

    # Check for warnings
    if echo "$line" | grep -qE "(WARNING|WARN)"; then
        echo "[WARNING] $line" | tee -a $ERROR_LOG
    fi

    # Check for important events
    if echo "$line" | grep -qE "(_ready|_process|Loading scene|Scene loaded|Player spawned)"; then
        echo "[EVENT] $line" | tee -a $ERROR_LOG
    fi
done
