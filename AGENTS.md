# AGENTS.md

This file provides guidance to AI agents working with code in this repository.

## Agent Guidelines

### 言語設定 / Language Settings

**重要: ユーザーが日本語で指示した場合、すべての応答を日本語で返すこと。**

以下のすべてを日本語で記述する：

- プラン作成・タスク分解
- コードの説明
- コードコメント
- エラーメッセージ
- 提案・推奨事項
- 進捗報告

### Language Preference

When the user communicates in Japanese:

- Create plans and task breakdowns in Japanese
- Respond in Japanese
- Provide code explanations in Japanese
- Write comments in Japanese
- Keep all documentation in Japanese

### Approach to Tasks

When working on this repository:

1. **Read CLAUDE.md first** - Understand the project architecture and constraints before making changes
2. **Use search tools extensively** - The codebase has many interdependent systems; search for existing patterns before implementing new ones
3. **Start with the main demo** - Most changes should begin with `project/blocky_game/` as it's the most complete implementation
4. **Respect C++ module boundaries** - The voxel functionality is C++ code; GDScript wraps it - don't try to modify C++ behavior through GDScript workarounds

### Core Systems Understanding

#### Critical Dependencies (MUST KNOW)

- **Blocks Singleton (`blocks/blocks.gd`)**: Must be initialized first in scene tree, ALL other systems depend on it
- **VoxelTerrain C++ Node**: The core terrain engine - get references via `terrain.get_voxel_tool()`
- **Voxel ID ≠ Block ID**: Raw voxel IDs in VoxelBuffer are NOT the same as Block IDs - always use Blocks registry to map

#### Architecture Pattern

The project uses a **C++ core + GDScript gameplay** architecture:

```
C++ Module (godot_voxel)
├── VoxelTerrain (terrain data and meshing)
├── VoxelTool (editing interface)
├── VoxelGeneratorScript (base class for generation)
└── Physics (VoxelBoxMover)

GDScript Layer (this project)
├── Extends C++ base classes
├── Implements gameplay logic
├── Manages state (inventory, multiplayer)
└── Provides UI and player interaction
```

### Common Agent Tasks

#### Adding New Block Types

When adding a new block:

1. Register in `blocks/blocks.gd` - add to `_blocks` dictionary with proper ID
2. Create block sprites in `blocks/[block_name]/` - use `block_sprite_generator.tscn`
3. Define rotation type: NONE, AXIAL, Y_ROTATION, or CUSTOM
4. Update `voxel_library.tres` if using blocky terrain system
5. Test placement and rotation mechanics

**Pattern Example:**
```gdscript
# In blocks/blocks.gd
const MY_NEW_BLOCK = 27

func _init():
    _blocks["my_new_block"] = {
        "id": MY_NEW_BLOCK,
        "name": "My New Block",
        "rotation": Block.ROTATION_NONE,
        "voxels": [MY_NEW_BLOCK]
    }
```

#### Modifying Terrain Generation

When changing terrain generation:

1. Edit `generator/generator.gd` - this extends `VoxelGeneratorScript`
2. Noise-based generation uses FastNoiseLite - modify seed, frequency, octaves
3. Structure placement happens in `_generate_block()` - respect pass_index
4. Test with multiple seeds for reproducibility
5. Check performance - generation runs on multiple threads

**Key Method:**
```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    # Override to implement terrain generation
    # DO NOT modify VoxelBuffer outside this method
    var height = _heightmap_noise.get_noise_2d(x, z) * 10 + 64
    out_buffer.set_voxel(GRASS, x, height, z, VoxelBuffer.CHANNEL_TYPE)
```

#### Implementing Player Features

When adding player features:

1. Player controller: `player/character_controller.gd` - uses VoxelBoxMover for collision
2. Interaction: `player/avatar_interaction.gd` - raycasting, block operations
3. Inventory: `gui/inventory/inventory.gd` - 9x4 grid system
4. Network awareness: In multiplayer, use RPC for synchronized actions

**Multiplayer Pattern:**
```gdscript
# Client-side (player action)
@rpc("any_peer", "call_remote", "reliable")
func request_block_place(pos: Vector3i, block_id: int):
    # Send to server
    pass

# Server-side (authority)
@rpc("any_peer", "call_remote", "reliable")
func receive_block_place(pos: Vector3i, block_id: int):
    # Actually place the block
    # Then broadcast to other clients
    rpc_id(0, &"broadcast_block_place", pos, block_id)
```

#### Adding UI Elements

When adding UI:

1. Check existing patterns in `gui/` directory
2. UI is scene-based (.tscn) with attached scripts (.gd)
3. Use CanvasLayer for overlay UI
4. Connect signals properly to avoid memory leaks
5. Test with different window sizes/resolutions

### Code Patterns to Follow

#### Voxel Editing Pattern

ALWAYS use VoxelTool for terrain modification:

```gdscript
# CORRECT
var voxel_tool := terrain.get_voxel_tool()
voxel_tool.mode = VoxelTool.MODE_ADD
voxel_tool.do_sphere(center, radius)

# WRONG - Don't modify VoxelBuffer directly after generation
terrain.get_block(pos).set_voxel(...)
```

#### Singleton Access Pattern

Access global resources through singletons:

```gdscript
# CORRECT
var block_id = Blocks.get_block_by_name("grass")
var item = Items.get_item(item_id)

# WRONG - Don't hardcode IDs or duplicate registries
var block_id = 2  # This may change!
```

#### Error Handling Pattern

Use Godot's error system consistently:

```gdscript
var err := some_operation()
if err != OK:
    push_error(str("Operation failed: ", error_string(err)))
    return err
```

### Testing Strategy for Agents

#### Before Committing Changes

1. **Check scene tree order** - Ensure Blocks singleton is first child
2. **Test in both singleplayer and multiplayer modes** if applicable
3. **Verify voxel ID mapping** - Block IDs must match registry
4. **Test edge cases** - What happens at world boundaries? With 0 items? When network disconnects?
5. **Performance check** - Does this run on every frame? Can it be optimized?

#### Validation Checklist

- [ ] Does this respect the C++ module boundaries?
- [ ] Are all new blocks registered in Blocks singleton?
- [ ] Is multiplayer considered (RPC for synchronized actions)?
- [ ] Are file paths using `project/` prefix?
- [ ] Does this work with the existing save/load system (if applicable)?
- [ ] Are errors handled gracefully with user feedback?
- [ ] Is this tested with different terrain generation seeds?

### Common Pitfalls

#### DO NOT

- ❌ Modify C++ class behavior through GDScript - it won't work
- ❌ Hardcode voxel IDs - use Blocks registry
- ❌ Edit terrain directly on clients in multiplayer - use server RPC
- ❌ Create VoxelTool instances manually - use `terrain.get_voxel_tool()`
- ❌ Forget to check `lod` parameter in generators - affects performance
- ❌ Assume VoxelBuffer state persists between generation calls - it's recreated

#### DO

- ✅ Read existing code patterns before implementing new features
- ✅ Use Godot's signal system for decoupled communication
- ✅ Test with multiple random seeds for terrain generation
- ✅ Profile performance-critical code (generation, voxel editing)
- ✅ Use DDD (Debug Draw) for visualization during development
- ✅ Check if similar functionality already exists before implementing

### File Organization Rules

When creating new files:

1. **Keep it in `project/`** - All game code belongs there
2. **Follow directory structure** - Match the existing pattern (e.g., `blocks/`, `player/`, `gui/`)
3. **Use descriptive names** - `player_character_controller.gd` not `pc.gd`
4. **Create both .gd and .tscn** for visual elements - script + scene
5. **Register in CLAUDE.md** - Document new systems if they're significant

### Integration with Existing Systems

#### World Save/Load (When Implemented)

If working on save/load functionality:

- Use `WorldManager` class if it exists
- Save to `user://worlds/` directory
- Save player state, inventory, terrain modifications
- Handle version compatibility in save format
- Test loading with different save versions

#### Python Agent System

If modifying the programmable agent:

- Agent API is in `agent/agent_api.py`
- Controller: `agent/agent_controller.gd`
- Interaction: `agent/agent_interaction.gd`
- Code Editor UI: `agent/code_editor_ui.gd`
- Executor uses py4godot addon - don't break that integration

### Performance Considerations

#### Hot Paths

These run frequently and need optimization:

1. **Terrain Generation** - Runs on multiple threads, avoid blocking operations
2. **Voxel Random Ticks** - Processes 512 voxels per frame
3. **Water Simulation** - Queue-based, 64 updates per 0.2s
4. **Player Movement** - Uses VoxelBoxMover, physics-critical

#### Memory Management

- Pre-generate structures (like trees) to avoid runtime allocation
- Use object pooling for frequently spawned objects
- Free resources properly when scenes are destroyed
- Be careful with texture memory in block sprites

### Debugging Tools for Agents

#### Debug Draw Plugin (DDD)

Use for visualization during development:

```gdscript
# Draw a box (lasts for 1 frame by default)
DDD.draw_box(position, size, color)

# Draw persistent box with linger
DDD.draw_box(position, size, color, 60)  # Lasts 60 frames

# Set HUD text
DDD.set_text("fps", str(Engine.get_frames_per_second()))
```

#### Logging

Use consistent logging patterns:

```gdscript
# For user-facing messages
print("Game started")

# For errors that need attention
push_error("Critical error: " + str(error))

# For debug info (use sparingly)
print_debug("Debug info")
```

### When in Doubt

1. **Search the codebase** - Look for similar implementations
2. **Read the CLAUDE.md** - Check if your approach aligns with documented patterns
3. **Test incrementally** - Make small changes and test each step
4. **Ask for clarification** - If requirements are ambiguous, state assumptions

### Project-Specific Quirks

1. **Jolt Physics** - Project uses Jolt, not default Godot physics
2. **Voxel Module Version** - C++ module API may change between versions
3. **Multiplayer Authority** - Split authority (server=terrain, clients=player movement)
4. **Block Variants** - Some blocks have multiple voxel IDs for different rotations
5. **Generator Passes** - Multi-pass generation allows reading terrain from previous passes

### Code Style

- Follow Godot naming conventions (snake_case for functions, PascalCase for classes)
- Use type hints where appropriate
- Add comments for non-obvious logic
- Keep functions focused and single-purpose
- Use const for constants that don't change
- Prefer composition over inheritance for game objects

### Final Check Before Task Completion

Verify:

1. [ ] Code follows existing patterns in the repository
2. [ ] New blocks/items are properly registered
3. [ ] Multiplayer considerations are addressed (if applicable)
4. [ ] No hard-coded voxel IDs or magic numbers
5. [ ] Error handling is in place
6. [ ] Performance impact is considered
7. [ ] Documentation is updated (CLAUDE.md if significant change)
8. [ ] Testing approach is documented (in plan or comments)

Remember: This is a **demo/test suite** for the Voxel module. The code serves as documentation - clarity and correctness are more important than optimization.

### World Save/Load System

#### Overview

The project includes a comprehensive world save/load system that allows users to:
- Create new worlds with custom names and seeds
- Save current world state to multiple save slots
- Load previously saved worlds
- Quick save (F5) and quick load (F9) functionality
- Manage saves through UI dialogs

#### Core Components

**WorldManager (`world_manager.gd`)**
- Singleton for managing all save/load operations
- Save slots: 1-9 (stored in `user://worlds/slot_XX/`)
- Methods:
  - `create_world(slot, world_name, seed)` - Create new world
  - `save_world(slot, world_data)` - Save world data
  - `load_world(slot)` - Load world data
  - `delete_world(slot)` - Delete saved world
  - `list_saves()` - Get all saved worlds
  - `get_empty_slot()` - Find first available slot

**Save Data Format**
```json
{
  "version": 1,
  "timestamp": "2025-12-30T12:00:00",
  "creation_date": "2025-12-30T10:00:00",
  "world_name": "My World",
  "playtime_seconds": 3600,
  "generation": {
    "seed": 12345,
    "modified_blocks_file": ""
  },
  "players": [
    {
      "id": 1,
      "position": {"x": 10.0, "y": 64.0, "z": 0.0},
      "rotation": {"y": 45.0},
      "inventory": {...}
    }
  ],
  "game_state": {
    "random_ticks_enabled": true,
    "water_simulation_enabled": true
  }
}
```

#### Integration Points

**BlockyGame (`blocky_game.gd`)**
- `_current_save_slot` - Currently active save slot
- `_world_manager` - Reference to WorldManager
- `start_new_world(slot, name, seed)` - Initialize new world
- `load_world_save(slot)` - Load saved world
- `quick_save()` / `quick_load()` - F5/F9 shortcuts
- `_collect_world_data()` - Gather world state for saving
- `save_world()` - Persist world to disk

**Generator (`generator/generator.gd`)**
- `set_world_seed(seed)` - Set terrain generation seed
- Applies to: `_heightmap_noise`, tree placement, foliage distribution
- Ensures reproducible terrain from same seed

**UI Components**

**New World Dialog (`new_world_dialog.tscn/gd`)**
- World name input
- Seed input with random button (🎲)
- Slot selection (auto-selects empty slot)
- Signal: `world_created(slot, world_name, seed)`

**Save/Load Dialog (`save_load_dialog.tscn/gd`)**
- List of saved worlds with metadata
- Load, Delete, Back buttons
- Signal: `load_requested(slot)`, `delete_requested(slot)`

**Pause Menu (`pause_menu.tscn/gd`)**
- Resume, Save World, Load World, Main Menu, Quit
- Accessible via ESC key
- Toggle mouse mode when shown

**Main Menu (`main.tscn/gd`)**
- "New World" button
- "Load World" button
- "Quick Start" button (starts game without save slot)

#### Usage Patterns

**Creating a New World**
```gdscript
# In main.gd
func _on_new_world_created(slot: int, world_name: String, seed: int):
    _world_manager.create_world(slot, world_name, seed)
    _game.start_new_world(slot, world_name, seed)
```

**Saving World**
```gdscript
# Automatically triggered on:
# 1. Window close (NOTIFICATION_WM_CLOSE_REQUEST)
# 2. F5 key (quick save)
# 3. Pause menu "Save World" button

func _save_world():
    var world_data := _collect_world_data()
    _world_manager.save_world(_current_save_slot, world_data)
```

**Loading World**
```gdscript
func _on_load_world_requested(slot: int):
    var world_data := _world_manager.load_world(slot)
    _game.load_world_save(slot)
```

#### Constraints

- **Singleplayer Only**: Saves only work in singleplayer or host mode
- **Terrain Persistence**: Uses `VoxelTerrain.save_modified_blocks()` for terrain
- **Player State**: Saves position, rotation, inventory (basic)
- **Seed System**: Generator must support seed setting via `set_world_seed()`

#### File Structure
```
user://worlds/
├── slot_01/
│   ├── world.json          # Save metadata and state
│   └── terrain.vxl         # Modified terrain blocks (if implemented)
├── slot_02/
│   └── ...
└── saves.meta              # Save slot index (optional)
```

#### When Working with Save System

1. **Adding New Data to Save**: Extend `_collect_world_data()` to include new state
2. **Loading New Data**: Extend `load_world_save()` to restore new state
3. **Version Management**: Update `SAVE_VERSION` when changing save format
4. **Migration**: Handle old save versions if needed

#### Testing

1. Create world with custom seed, verify terrain generation
2. Move player, place blocks, save, reload
3. Test multiple save slots
4. Verify quick save/load (F5/F9)
5. Test deletion of saves
6. Check error handling (invalid slots, corrupt saves)
