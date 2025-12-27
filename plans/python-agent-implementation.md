# Implementation Plan: Python Agent with In-Game Editor for Blocky Game

## Overview
Add Minecraft Education-style Python scripting to the blocky_game scene, allowing users to control an agent with Python code written in an in-game editor.

## User Requirements
- **Integration Method**: py4godot plugin
- **Agent Capabilities**: Movement (move forward, turn, jump), block manipulation (place, break, inspect), world sensing (raycast, detect blocks)
- **Editor UI**: Simple text area with Run button
- **Multiplayer**: Singleplayer only

## Implementation Steps

### 1. Install py4godot Plugin

**Download and Setup:**
- Download latest release from https://github.com/niklas2902/py4godot/releases
- Extract to `project/addons/py4godot/`
- System has Python 3.11.6 which meets requirement

**Enable Plugin:**
- Edit `project/project.godot` to add:
```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/py4godot/plugin.cfg")
```

**Test Installation:**
- Create simple Python script extending Node
- Verify it loads without errors

### 2. Create Agent Character Entity

**New Directory:** `project/blocky_game/agent/`

**File: `programmable_agent.tscn`**
```
ProgrammableAgent (Node3D)
├── AgentController (agent_controller.gd)
├── AgentVisual (MeshInstance3D - cyan colored cube)
├── AgentInteraction (agent_interaction.gd)
├── AgentAPI (agent_api.py) - Python API wrapper
└── VoxelViewer (for terrain streaming)
```

**File: `agent_controller.gd`**
- Extend Node3D
- Use VoxelBoxMover pattern from `player/character_controller.gd:13,60`
- Movement via command queue (not direct Input)
- Methods: `move_forward(distance)`, `turn_left(degrees)`, `turn_right(degrees)`, `jump()`
- Apply commands in `_physics_process()` using same physics as player

**File: `agent_interaction.gd`**
- Extend Node
- Reference VoxelTool from terrain
- Reuse `player/interaction_common.gd` for block placement
- Methods: `place_block(block_name)`, `break_block()`, `inspect_block()`, `raycast(direction, distance)`, `detect_nearby_blocks(radius)`
- Use `Blocks.get_block_by_name()` for block lookups

**File: `agent_visual.tscn`**
- BoxMesh (0.8, 1.8, 0.8)
- Cyan/blue material to distinguish from player

### 3. Create Python API Layer

**File: `agent_api.py`** (Python script using py4godot)
```python
from py4godot.classes import gdclass
from py4godot.classes.Node import Node

@gdclass
class AgentAPI(Node):
    def _ready(self):
        self._controller = self.get_parent().get_node("AgentController")
        self._interaction = self.get_parent().get_node("AgentInteraction")

    def move_forward(self, distance: float = 1.0):
        self._controller.move_forward(distance)

    def turn_left(self, degrees: float = 90.0):
        self._controller.turn_left(degrees)

    def turn_right(self, degrees: float = 90.0):
        self._controller.turn_right(degrees)

    def jump(self):
        self._controller.jump()

    def place_block(self, block_name: str) -> bool:
        return self._interaction.place_block(block_name)

    def break_block(self) -> bool:
        return self._interaction.break_block()

    def inspect_block(self) -> dict:
        return self._interaction.inspect_block()

    # Additional sensing methods...
```

### 4. Create Code Execution System

**File: `code_executor.gd`**
- Extend Node
- Signals: `execution_started`, `execution_finished`, `execution_error(msg)`, `output_printed(text)`
- Method: `execute_code(code: String)` - runs Python code via py4godot
- Inject `agent` global variable pointing to AgentAPI instance
- Redirect Python `print()` to `output_printed` signal
- Wrap execution in try-catch for error handling

### 5. Create In-Game Editor UI

**File: `code_editor_ui.tscn`**
```
CodeEditorUI (CanvasLayer)
└── PanelContainer
    └── VBoxContainer
        ├── Label ("Python Code Editor")
        ├── CodeEdit (main editor with syntax highlighting)
        ├── HBoxContainer
        │   ├── RunButton
        │   └── StopButton
        └── OutputConsole (TextEdit - read-only)
```

**File: `code_editor_ui.gd`**
- Setup Python syntax highlighting for CodeEdit
- Default template code with API examples
- Run button executes code via CodeExecutor
- Output console displays print statements and errors
- Toggle visibility with F4 key

**Default Template:**
```python
# Control the agent with Python!
# Available API:
# - agent.move_forward(distance)
# - agent.turn_left(degrees)
# - agent.turn_right(degrees)
# - agent.jump()
# - agent.place_block(block_name)
# - agent.break_block()
# - agent.inspect_block()

# Example: Move forward 3 blocks
agent.move_forward(3)
```

### 6. Integrate with blocky_game

**File: `blocky_game.gd` (modify)**

**Add preloads at top:**
```gdscript
const ProgrammableAgentScene = preload("./agent/programmable_agent.tscn")
const CodeEditorUIScene = preload("./agent/code_editor_ui.tscn")
```

**In `_ready()` method after line 100:**
```gdscript
if _network_mode == NETWORK_MODE_HOST or _network_mode == NETWORK_MODE_SINGLEPLAYER:
    add_child(RandomTicks.new())
    # ... existing water code ...

    # SINGLEPLAYER ONLY: Spawn agent and editor
    if _network_mode == NETWORK_MODE_SINGLEPLAYER:
        _spawn_programmable_agent(Vector3(5, 64, 0))
        _setup_code_editor()
```

**Add methods:**
```gdscript
func _spawn_programmable_agent(pos: Vector3):
    var agent = ProgrammableAgentScene.instantiate()
    agent.name = "ProgrammableAgent"
    agent.position = pos
    agent.get_node("AgentController").terrain = _terrain.get_path()
    agent.get_node("AgentInteraction").terrain_path = _terrain.get_path()
    _characters_container.add_child(agent)
    return agent

func _setup_code_editor():
    var editor_ui = CodeEditorUIScene.instantiate()
    add_child(editor_ui)

    var agent = _characters_container.get_node("ProgrammableAgent")
    var agent_api = agent.get_node("AgentAPI")
    editor_ui.set_agent_api(agent_api)

    editor_ui.visible = false  # Hidden by default
```

**Add input handling:**
```gdscript
func _unhandled_input(event: InputEvent):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F4:
            _toggle_code_editor()

func _toggle_code_editor():
    if _code_editor_ui != null:
        _code_editor_ui.visible = not _code_editor_ui.visible
        if _code_editor_ui.visible:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
```

## Critical Implementation Details

### VoxelBoxMover Pattern (from character_controller.gd)
```gdscript
var _box_mover := VoxelBoxMover.new()

func _ready():
    _box_mover.set_collision_mask(1)
    _box_mover.set_step_climbing_enabled(true)
    _box_mover.set_max_step_height(0.5)

func _physics_process(delta):
    var aabb := AABB(Vector3(-0.4, -0.9, -0.4), Vector3(0.8, 1.8, 0.8))
    motion = _box_mover.get_motion(position, motion, aabb, terrain_node)
    global_translate(motion)
```

### Block Placement Pattern (from interaction_common.gd)
```gdscript
static func place_single_block(terrain_tool: VoxelTool, pos: Vector3,
    look_dir: Vector3, block_id: int, block_types: Blocks, water_updater):

    var block := block_types.get_block(block_id)
    var voxel_id = block.base_info.voxels[0]
    terrain_tool.value = voxel_id
    terrain_tool.do_point(pos)
    water_updater.schedule(pos)
```

### Command Queue Pattern
```gdscript
var _move_queue := []

func move_forward(distance: float):
    _move_queue.append({"type": "move", "distance": distance, "remaining": distance})

func _physics_process(delta):
    if _move_queue.is_empty():
        return
    var cmd = _move_queue[0]
    # Execute movement...
    cmd.remaining -= step_distance
    if cmd.remaining <= 0.01:
        _move_queue.pop_front()
```

## Files to Create

```
project/blocky_game/agent/
├── programmable_agent.tscn       # Agent scene
├── agent_controller.gd            # Movement controller
├── agent_interaction.gd           # Block interaction
├── agent_visual.tscn              # Visual mesh
├── agent_api.py                   # Python API wrapper
├── code_executor.gd               # Code execution engine
├── code_editor_ui.tscn            # Editor UI scene
└── code_editor_ui.gd              # Editor UI script
```

## Files to Modify

1. `project/project.godot` - Enable py4godot plugin
2. `project/blocky_game/blocky_game.gd` - Add agent spawning, editor setup, F4 toggle

## Testing Plan

1. **py4godot Test**: Create simple Python Node script, verify it loads
2. **Agent Movement**: Test move_forward(), turn_left(), turn_right(), jump()
3. **Block Operations**: Test place_block(), break_block(), inspect_block()
4. **Editor UI**: Test syntax highlighting, Run button, output console
5. **End-to-End**: Write Python code to build a tower, verify it executes
6. **Multiplayer Check**: Verify agent doesn't spawn in multiplayer mode

## Example Test Programs

**Test 1 - Basic Movement:**
```python
agent.move_forward(5)
agent.turn_right(90)
agent.move_forward(3)
```

**Test 2 - Build Tower:**
```python
for i in range(5):
    agent.place_block("planks")
    agent.jump()
```

**Test 3 - Scan Surroundings:**
```python
blocks = agent.detect_nearby_blocks(3)
print(f"Found {len(blocks)} blocks nearby")
```

## Potential Challenges

1. **py4godot Stability**: Plugin is in alpha - may have bugs. Test thoroughly.
2. **Movement Timing**: Python executes instantly but movement takes time - use command queue.
3. **Thread Safety**: Execute Python on main thread to avoid voxel tool issues.
4. **Error Handling**: Wrap all Python execution in try-catch, display errors clearly.
5. **Mouse Input**: Switch Input.mouse_mode when toggling editor to avoid conflicts.

## Estimated Time

- py4godot setup: 1-2 hours
- Agent entity: 3-4 hours
- Python API: 2-3 hours
- Editor UI: 3-4 hours
- Integration: 2-3 hours
- Testing: 3-4 hours

**Total: 14-20 hours**
