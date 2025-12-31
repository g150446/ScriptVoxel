#!/bin/bash
# Automated Game Launch and Debug Script

GODOT_BIN="./godot.macos.editor.app/Contents/MacOS/Godot"
PROJECT_PATH="project/project.godot"
SCENE_PATH="res://blocky_game/main.tscn"
LOG_FILE="/tmp/godot_debug.log"
ERROR_LOG="/tmp/godot_errors.log"

# Clear previous logs
> $LOG_FILE
> $ERROR_LOG

echo "=== Starting Godot with Debug Logging ==="
echo "Scene: $SCENE_PATH"
echo "Log file: $LOG_FILE"
echo "Error log: $ERROR_LOG"
echo ""

# Kill any existing Godot processes
pkill -f "godot.macos.editor" 2>/dev/null
sleep 1

# Start the game directly (not in editor mode)
echo "Launching game..."
$GODOT_BIN $PROJECT_PATH $SCENE_PATH 2>&1 | tee $LOG_FILE &
GODOT_PID=$!

echo "Godot PID: $GODOT_PID"
echo ""

# Wait for initial load
sleep 5

# Check if process is still running
if ps -p $GODOT_PID > /dev/null 2>&1; then
    echo "✓ Game is running (PID: $GODOT_PID)"
    echo ""

    # Show any errors/warnings from the log
    echo "=== Checking for Errors/Warnings ==="
    grep -E "(ERROR|WARNING)" $LOG_FILE | head -10 || echo "No errors or warnings found"
    echo ""

    # Show resource loading stats
    echo "=== Resource Loading Stats ==="
    echo "Total resources loaded: $(grep -c "Loading resource:" $LOG_FILE)"
    echo "Generated previews: $(grep -c "Generated.*preview" $LOG_FILE)"
    echo ""

    # Show game state
    echo "=== Game State ==="
    tail -5 $LOG_FILE
    echo ""

    echo "Game is running. Monitor logs with:"
    echo "  tail -f $LOG_FILE"
    echo ""
    echo "Stop the game with:"
    echo "  pkill -f godot.macos.editor"
else
    echo "✗ Game failed to start or crashed"
    echo ""
    echo "Last 20 lines of log:"
    tail -20 $LOG_FILE
    exit 1
fi
