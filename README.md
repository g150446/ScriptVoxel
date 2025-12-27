# ScriptVoxel

A Minecraft Education Edition-style voxel game with programmable Python agents, built with Godot Engine 4.5 and the voxel module.

![Screenshot](screenshots/2020_05_05_1953_small.png)

## Features

- **Programmable Python Agents**: Control in-game agents using Python code
- **In-Game Code Editor**: Write and execute Python scripts directly in the game (press **F4**)
- **Agent API**: Comprehensive API for movement, block manipulation, and world sensing
- **Minecraft-Style Visuals**: Humanoid character models with custom skin support
- **Voxel World**: Built on Godot's powerful voxel terrain system
- **Singleplayer**: Focus on educational programming experience

## Dependencies

This project uses:
- [Godot Voxel Module](https://github.com/Zylann/godot_voxel) - C++ voxel terrain module
- [py4godot](https://github.com/maiself/godot-python-extension) - Python scripting integration (4.5-alpha13)

## Agent API

The programmable agent supports the following commands:

### Movement
- `agent.move(direction, distance)` - Move in any direction: "forward", "back", "left", "right", "up", "down"
- `agent.turn(direction, degrees)` - Turn left or right
- `agent.jump()` - Make the agent jump

### Block Manipulation
- `agent.place_block(block_name)` - Place blocks like "planks", "grass", "dirt"
- `agent.break_block()` - Break the block in front of the agent
- `agent.inspect_block()` - Get information about a block

### World Sensing
- `agent.detect_nearby_blocks(radius)` - Detect blocks around the agent
- `agent.get_position()` - Get agent's current position
- `agent.get_facing_direction()` - Get the direction the agent is facing

## How to Use

1. Open the project in Godot 4.5.1+ with voxel module
2. Run `project/blocky_game/main.tscn`
3. Press **F4** or click the "Python Editor (F4)" button to open the code editor
4. Click **"Spawn Agent"** to create an agent in the world
5. Write Python code to control the agent
6. Click **"Run"** to execute your code
7. Click **"Help"** to see the full API documentation

## Example Code

```python
# Move in a square
agent.move("forward", 3)
agent.turn("right")
agent.move("forward", 3)
agent.turn("right")
agent.move("forward", 3)
agent.turn("right")
agent.move("forward", 3)

# Build a tower
for i in range(5):
    agent.place_block("planks")
    agent.move("up", 1)

# Fly around
agent.move("up", 10)
agent.move("forward", 5)
agent.move("down", 3)
```

## Technical Details

- **Engine**: Godot 4.5.1 with voxel module
- **Python Integration**: py4godot plugin (4.5-alpha13) with Python 3.12.4
- **Fallback Executor**: GDScript-based command parser for systems without py4godot
- **Agent Features**: Gravity-free movement, VoxelBoxMover collision detection, block interaction
- **Editor**: In-game Python code editor with syntax highlighting, 32px font size

## Project Structure

```
project/
├── blocky_game/          # Main game with Python agent system
│   ├── agent/           # Programmable agent implementation
│   ├── player/          # Player character
│   ├── blocks/          # Voxel block definitions
│   ├── gui/             # User interface
│   └── main.tscn        # Main game scene
├── addons/
│   └── py4godot/        # Python integration plugin
└── project.godot        # Godot project configuration
```

## Requirements

- Godot 4.5.1+ with voxel module
- macOS ARM64 (for included py4godot binaries)
- For other platforms, rebuild py4godot from source

## Credits

Based on the [voxelgame](https://github.com/Zylann/voxelgame) demo by Zylann.

Python agent system and in-game editor created with Claude Code.

## License

MIT License - See LICENSE.md for details
