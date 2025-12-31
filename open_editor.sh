#!/bin/bash
# Open Godot Editor for the project

GODOT_APP="$PWD/godot.macos.editor.app"
PROJECT_PATH="$PWD/project/project.godot"

echo "=== Opening Godot Editor ==="
echo "Project: $PROJECT_PATH"
echo ""
echo "Once the editor opens:"
echo "  1. Press F5 or click the 'Play' button (▶) to run the game"
echo "  2. The game window will open automatically"
echo "  3. Press F8 or close the game window to stop"
echo ""

# Open the editor using macOS 'open' command
open -a "$GODOT_APP" --args --editor "$PROJECT_PATH"

echo "Editor is opening..."
echo ""
echo "If the editor doesn't open, try running directly:"
echo "  ./godot.macos.editor.app/Contents/MacOS/Godot --editor project/project.godot"
