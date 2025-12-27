# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a demo/test suite for the Godot Voxel module, showcasing various voxel terrain and gameplay systems. The project contains multiple independent demo scenes demonstrating different capabilities of the C++ voxel module through GDScript implementations.

**Engine:** Godot 4.4
**Physics Engine:** Jolt Physics (configured in project.godot)
**Dependencies:** [godot_voxel](https://github.com/Zylann/godot_voxel) C++ module (must be compiled into the Godot engine)

## Running the Project

Since this is a Godot project with a required C++ module dependency:

1. The godot_voxel module must be compiled into your Godot engine build
2. Open the project in Godot Editor: `godot --editor project/project.godot`
3. Run individual demo scenes from the Godot Editor

**Main Runnable Scenes:**
- `project/blocky_game/main.tscn` - Full Minecraft-like game with multiplayer
- `project/blocky_terrain/main.tscn` - Simple blocky terrain demo
- `project/smooth_terrain/main.tscn` - Transvoxel smooth terrain demo
- `project/grid_pathfinding/test_grid_pathfinding.tscn` - A* pathfinding demo
- `project/blocky_fluid/main.tscn` - Fluid simulation demo
- `project/multipass_generator/multipass_terrain.tscn` - Multi-pass generation demo

No traditional build/test/lint commands - this is a Godot Engine project developed through the editor.

## Architecture Overview

### Demo-Centric Organization

The project is organized around independent demo scenes, each showcasing different voxel module capabilities. Each demo is largely self-contained with its own resources and scripts.

### C++ Module Integration Pattern

All voxel functionality comes from the C++ `godot_voxel` module. GDScript code in this project:
- Creates and configures C++ node types (`VoxelTerrain`, `VoxelLodTerrain`)
- Extends C++ base classes (e.g., `VoxelGeneratorScript`, `VoxelGeneratorMultipassCB`)
- Uses C++ utility classes (`VoxelTool`, `VoxelBuffer`, `VoxelBoxMover`)
- Implements gameplay logic on top of voxel primitives

**Key C++ Classes Used:**
- **Terrain Nodes:** `VoxelTerrain` (fixed LOD), `VoxelLodTerrain` (variable LOD)
- **Generation:** `VoxelGeneratorScript`, `VoxelGeneratorMultipassCB`, `VoxelBuffer`
- **Editing Tools:** `VoxelTool`, `VoxelToolTerrain`
- **Physics:** `VoxelBoxMover` (character controller collision)
- **Multiplayer:** `VoxelTerrainMultiplayerSynchronizer`, `VoxelViewer`
- **Libraries:** `VoxelBlockyLibrary` (block models/collision)
- **Pathfinding:** `VoxelAStarGrid3D`

### Blocky Game Architecture (Main Demo)

The most complex demo, structured as:

```
BlockyGame (blocky_game/blocky_game.gd)
├── VoxelTerrain (C++ terrain node)
│   └── Generator (generator/generator.gd - extends VoxelGeneratorScript)
├── Blocks (blocks/blocks.gd - singleton registry)
├── Items (items/item_db.gd - singleton registry)
├── RandomTicks (random_ticks.gd - grass spreading simulation)
├── Water (water.gd - queue-based water simulation)
├── Players (container for character_avatar.tscn instances)
└── GUI (inventory, hotbar)
```

**Important Note:** The `Blocks` singleton must be first in the scene tree - other systems depend on it being initialized first.

#### Block System

- **blocks/blocks.gd**: Central registry mapping voxel IDs to block types
- Supports rotation systems: NONE, AXIAL (logs), Y-rotation (stairs), CUSTOM (rails)
- Each block type can have multiple voxel variants for rotations
- Raw voxel IDs ≠ Block IDs (registry handles mapping)
- Block placement logic in `interaction_common.gd`

#### Terrain Generation

- **generator/generator.gd**: Main terrain generator extending `VoxelGeneratorScript`
- Noise-based heightmap using FastNoiseLite
- Layers: dirt base, grass surface, water bodies
- Structure placement (trees) with Moore neighborhood boundary handling
- Procedural foliage placement (tall grass, dead shrubs)
- **generator/tree_generator.gd**: Pre-generates 16 tree variants for pasting

#### Multiplayer System

Three modes: SINGLEPLAYER, CLIENT, HOST
- Server-authoritative terrain using `VoxelTerrainMultiplayerSynchronizer`
- Client-authoritative player physics (each client controls their own movement)
- RPC-based block placement and player position sync
- Each remote player gets a `VoxelViewer` on server for terrain streaming
- UPNP port forwarding support in `upnp_helper.gd`

**Network Flow:**
1. Server maintains terrain state and runs simulations (water, random ticks)
2. Clients receive voxel data via synchronizer
3. Block edits sent to server via RPC (`receive_place_single_block`)
4. Player positions broadcast via RPC

#### Voxel Simulation Systems

**Random Ticks (random_ticks.gd):**
- Grass spreading: dirt converts to grass when exposed to light
- Processes 512 voxels per frame in 100-block radius
- Uses `VoxelTool.run_blocky_random_tick()`

**Water (water.gd):**
- Queue-based cellular automata
- Spreads in 5 directions (4 horizontal + down)
- Dual-queue processing (64 updates per 0.2s)
- Water variants: full block vs top surface

#### Player System

- **player/character_controller.gd**: Uses `VoxelBoxMover` for voxel collision
- **player/avatar_interaction.gd**: Voxel raycasting, block place/remove/pick
- **gui/inventory/inventory.gd**: 9x4 grid (27 bag + 9 hotbar), drag-and-drop
- **items/**: Extensible item system (currently includes rocket launcher)

### Smooth Terrain Architecture

Uses `VoxelLodTerrain` with Transvoxel meshing:
- **main.gd**: Scene setup with spectator camera
- **interaction.gd**: SDF-based sculpting using `VoxelTool.do_sphere()`
- **sdf_stamper.gd**: Mesh-to-SDF stamping for complex shapes
- Add/remove modes for terrain sculpting

### Multipass Generation

Demonstrates `VoxelGeneratorMultipassCB`:
- **Pass 0**: Basic terrain generation
- **Pass 1**: Structure placement (can read terrain from Pass 0)
- Enables complex features like trees that need ground detection

### Common Utilities (common/)

Shared across all demos:
- **util.gd**: Mesh generation (`create_wirecube_mesh`), direction helpers, validation
- **mouse_look.gd**: First-person camera controller with yaw/pitch
- **spectator_avatar.gd**: Free-flight camera for terrain demos
- **grid.gd**, **wireframe_builder.gd**: Debug visualization helpers

### Debug Draw Plugin

**addons/zylann.debug_draw/debug_draw.gd** (autoload as "DDD"):
- HUD text: `DDD.set_text(key, value)`
- 3D primitives: boxes, lines, rays, meshes
- Automatic cleanup with linger frames
- Used extensively for performance stats and debugging

## Development Patterns

### Voxel Editing Pattern

All voxel modification goes through `VoxelTool`:
```gdscript
var voxel_tool := terrain.get_voxel_tool()
voxel_tool.mode = VoxelTool.MODE_ADD
voxel_tool.do_sphere(center, radius)
```

### Structure Pasting Pattern

Pre-generate structures, then paste during terrain generation:
```gdscript
# Generation time
var tree_structure = tree_generator.get_random_tree()
voxel_tool.paste_masked(tree_position, tree_structure, ...)
```

### Singleton Registry Pattern

Blocks and Items use node-based registries accessed globally:
```gdscript
var block_id = Blocks.get_block_by_name("grass")
var item = Items.get_item(item_id)
```

### RPC Networking Pattern

All multiplayer uses Godot's high-level RPC:
```gdscript
@rpc("any_peer", "call_remote", "reliable")
func receive_place_single_block(pos: Vector3i, block_id: int):
    # Server-authoritative block placement
```

### Multi-pass Generation Pattern

Complex terrain features use multiple passes:
```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int, pass_index: int):
    if pass_index == 0:
        # Generate base terrain
    elif pass_index == 1:
        # Place structures using terrain from pass 0
```

## File Paths and Locations

All project files are under `project/` directory.

**Critical Singleton Files:**
- `project/blocky_game/blocks/blocks.gd` - Block registry (must be first child)
- `project/blocky_game/items/item_db.gd` - Item database
- `project/addons/zylann.debug_draw/debug_draw.gd` - Debug draw (autoload as "DDD")

**Terrain Generators:**
- `project/blocky_game/generator/generator.gd` - Blocky game generator
- `project/multipass_generator/multipass_generator.gd` - Multi-pass example
- Various `.tres` files define built-in generators (noise-based)

**Resource Files (.tres):**
- `voxel_library.tres` files define `VoxelBlockyLibrary` instances (block models)
- `*_material.tres` files define terrain materials
- Generator `.tres` files configure built-in C++ generators

## Important Constraints

1. **C++ Module Dependency**: Project requires godot_voxel module compiled into Godot engine. Cannot run with vanilla Godot.

2. **Block Registry Initialization**: `Blocks` node must be first child in blocky_game scene - other systems depend on it.

3. **Voxel ID Mapping**: Raw voxel IDs in `VoxelBuffer` ≠ Block IDs. Always use `Blocks` registry to map between them.

4. **Network Authority**: In multiplayer:
   - Server is authoritative for terrain/voxels
   - Clients are authoritative for their own player physics
   - Never edit terrain directly on client - always send RPC to server

5. **VoxelTool Context**: `VoxelTool` instances are specific to terrain nodes. Get new instances via `terrain.get_voxel_tool()`.

6. **LOD Awareness**: `VoxelLodTerrain` has variable LOD - modifications may occur at different detail levels. `VoxelTerrain` is fixed LOD.

7. **Physics Engine**: Project configured for Jolt Physics - collision behavior may differ from default Godot physics.

## Resources and References

- Voxel Module Repo: https://github.com/Zylann/godot_voxel
- Old GDScript Version: See branch `full_gdscript` (unmaintained)
- This project serves as practical examples for the voxel module - code is documentation
