# Blocky Game System Specification

## Overview

The Blocky Game demo (`project/blocky_game/`) is the most comprehensive demonstration in ScriptVoxel, implementing a Minecraft-like voxel game with multiplayer support, terrain generation, block editing, inventory management, and voxel simulations.

## System Components

### 1. Block System

#### Block Registry (blocks/blocks.gd)

**Initialization Requirement:** Must be the first child node in the scene tree.

**Responsibilities:**
- Central registry mapping voxel IDs to block types
- Provides block metadata (name, rotation type, properties)
- Handles voxel ID to block ID translation

**Block Structure:**
```gdscript
{
    "id": int,              # Logical block ID
    "name": String,         # Block identifier
    "voxel_id": int,        # Primary voxel ID
    "rotation_type": int,   # NONE, AXIAL, Y, CUSTOM
    "voxel_ids": Array,     # All rotation variant IDs
}
```

**Rotation Systems:**

| Type | Description | Examples | Variants |
|------|-------------|----------|----------|
| NONE | No rotation | Dirt, grass, stone | 1 |
| AXIAL | 3-axis rotation | Logs, pillars | 3 |
| Y | Y-axis only rotation | Stairs, signs | 4 |
| CUSTOM | Custom mapping | Rails, complex blocks | Variable |

**Key Methods:**
```gdscript
get_block_by_name(name: String) -> int
get_block(block_id: int) -> Dictionary
get_block_name(block_id: int) -> String
get_rotation_type(block_id: int) -> int
get_voxel_id_from_block_rotation(block_id: int, dir: Vector3i) -> int
```

**Important Distinction:**
- **Block ID:** Logical identifier used in game code
- **Voxel ID:** Raw ID stored in VoxelBuffer (includes rotation variants)
- The registry provides bidirectional mapping

#### Block Library (voxel_library.tres)

**Type:** VoxelBlockyLibrary resource

**Configuration:**
- Visual models for each voxel ID
- Collision shapes
- Material assignments
- Culling behavior
- Transparency settings

**Model Types:**
- Full cubes (most blocks)
- Custom meshes (stairs, slabs)
- Cross models (grass, flowers)
- Empty (air)

### 2. Terrain Generation System

#### Main Generator (generator/generator.gd)

**Base Class:** VoxelGeneratorScript

**Generation Process:**

##### Phase 1: Heightmap Generation

```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    # For each XZ position in chunk:
    var height = _get_height_at(x, z)
```

**Noise Configuration:**
- **Type:** FastNoiseLite
- **Algorithm:** Simplex noise
- **Frequency:** Configurable (affects terrain scale)
- **Amplitude:** Controls height variation

##### Phase 2: Layer Filling

```
For each voxel in chunk:
    if y < height - 4:
        block = STONE
    elif y < height:
        block = DIRT
    elif y == height:
        block = GRASS (or SAND near water)
    elif y <= WATER_LEVEL:
        block = WATER
    else:
        block = AIR
```

##### Phase 3: Structure Placement

**Tree Placement:**
1. Pre-generated tree structures (see TreeGenerator)
2. Placement conditions:
   - On grass blocks
   - Minimum spacing from chunk boundaries (Moore neighborhood handling)
   - Random distribution using noise
3. Paste using `VoxelTool.paste_masked()`

**Foliage Placement:**
- Tall grass on grass blocks
- Dead shrubs on sand blocks
- Random distribution

#### Tree Generator (generator/tree_generator.gd)

**Purpose:** Pre-generates tree structures for fast placement during terrain generation.

**Features:**
- Generates 16 tree variants at initialization
- Varies trunk height and canopy size
- Stores as VoxelBuffer structures
- Uses wood logs (AXIAL rotation) and leaf blocks

**Structure Format:**
```gdscript
{
    "buffer": VoxelBuffer,    # Pre-built tree structure
    "offset": Vector3i,       # Ground offset for placement
}
```

**Generation Algorithm:**
1. Create trunk (height 4-6 blocks)
2. Build canopy sphere (radius 2-3 blocks)
3. Use AXIAL rotation for logs
4. Return buffer ready for pasting

#### Moore Neighborhood Boundary Handling

**Problem:** Structures may span chunk boundaries

**Solution:**
```gdscript
# Don't place structures too close to chunk edges
if x < MARGIN or x >= CHUNK_SIZE - MARGIN:
    continue
if z < MARGIN or z >= CHUNK_SIZE - MARGIN:
    continue
```

**MARGIN typically:** Tree radius + 1 block

### 3. Player System

#### Character Controller (player/character_controller.gd)

**Physics System:** VoxelBoxMover (replaces CharacterBody3D)

**Movement System:**
```gdscript
var velocity: Vector3
var gravity: float = 20.0
var jump_strength: float = 8.0
var speed: float = 5.0

func _physics_process(delta):
    # Apply gravity
    velocity.y -= gravity * delta

    # Handle input
    var input_dir = get_input_direction()
    velocity.x = input_dir.x * speed
    velocity.z = input_dir.z * speed

    # Move with voxel collision
    velocity = _box_mover.get_motion(velocity, delta, terrain)
    global_position += velocity * delta
```

**VoxelBoxMover Features:**
- AABB collision with voxel world
- Sliding collision response
- Step-up handling
- Water/ladder detection support

#### Avatar Interaction (player/avatar_interaction.gd)

**Voxel Raycasting:**
```gdscript
var voxel_tool: VoxelTool = terrain.get_voxel_tool()

# Raycast from camera
var hit = voxel_tool.raycast(camera_origin, camera_direction, 10.0)

if hit:
    var hit_position: Vector3i = hit.position
    var prev_position: Vector3i = hit.previous_position
```

**Block Removal:**
```gdscript
func remove_block(position: Vector3i):
    voxel_tool.set_voxel(position, Blocks.AIR)
```

**Block Placement:**
```gdscript
func place_block(position: Vector3i, block_id: int):
    # Get appropriate voxel ID for rotation
    var look_dir = get_look_direction()
    var voxel_id = Blocks.get_voxel_id_from_block_rotation(block_id, look_dir)

    voxel_tool.set_voxel(position, voxel_id)
```

**Block Picking (Middle Click):**
```gdscript
func pick_block(position: Vector3i):
    var voxel_id = voxel_tool.get_voxel(position)
    var block_id = Blocks.get_block_from_voxel_id(voxel_id)
    # Add to hotbar
```

### 4. Inventory System (gui/inventory/inventory.gd)

#### Structure

**Total Slots:** 36
- **Bag:** 27 slots (3 rows × 9 columns)
- **Hotbar:** 9 slots (visible at bottom)

**Slot Definition:**
```gdscript
{
    "item_id": int,    # -1 for empty
    "amount": int,     # Stack size
}
```

#### Operations

**Add Item:**
```gdscript
func add_item(item_id: int, amount: int) -> int:
    # 1. Try to stack with existing items
    # 2. Fill empty slots
    # 3. Return remaining amount if full
```

**Remove Item:**
```gdscript
func remove_item(item_id: int, amount: int) -> bool:
    # Remove specified amount from inventory
    # Returns true if successful
```

**Drag and Drop:**
- Click to pick up stack
- Click empty slot to place
- Click same item to stack
- Right-click for half-stack operations

#### Hotbar Integration

- Hotbar slots are inventory slots 27-35
- Number keys (1-9) select hotbar slot
- Selected slot highlighted
- Current item used for block placement/tools

### 5. Item System (items/item_db.gd)

**Structure:**
```gdscript
var items: Dictionary = {
    0: {
        "name": "block_placer",
        "type": "block",
        "block_id": 1,
    },
    1: {
        "name": "rocket_launcher",
        "type": "tool",
        "script": "rocket_launcher.gd",
    },
}
```

**Item Types:**
- **block:** Places a block (references block ID)
- **tool:** Special functionality (implements use action)

**Tool Interface:**
```gdscript
# Custom tool script
func use(player: Node, terrain: VoxelTerrain):
    # Implement tool action
```

### 6. Simulation Systems

#### Random Tick System (random_ticks.gd)

**Purpose:** Grass spreading simulation

**Configuration:**
- **Tick Rate:** 512 voxels per frame
- **Range:** 100 block radius from player
- **Implementation:** `VoxelTool.run_blocky_random_tick()`

**Callback System:**
```gdscript
voxel_tool.run_blocky_random_tick(
    center,
    radius,
    tick_count,
    callback,
    batch_count
)
```

**Grass Spreading Logic:**
```gdscript
func _on_random_tick(voxel_info: Dictionary):
    var pos: Vector3i = voxel_info.position
    var voxel_id: int = voxel_info.voxel_id

    if voxel_id == Blocks.DIRT:
        # Check if block above is air (has light)
        var above = voxel_tool.get_voxel(pos + Vector3i(0, 1, 0))
        if above == Blocks.AIR:
            # Convert to grass
            voxel_tool.set_voxel(pos, Blocks.GRASS)
```

#### Water Simulation (water.gd)

**Algorithm:** Queue-based cellular automata

**Dual Queue System:**
- **Queue A:** Current processing queue
- **Queue B:** Next frame queue
- Swap after each update cycle

**Update Cycle:**
```gdscript
var updates_per_cycle = 64
var update_interval = 0.2  # seconds

func _process_water():
    for i in range(updates_per_cycle):
        if queue_a.is_empty():
            queue_a, queue_b = queue_b, queue_a
            break

        var pos = queue_a.pop_front()
        _spread_water_from(pos)
```

**Spread Logic:**
```gdscript
func _spread_water_from(pos: Vector3i):
    # Check 5 directions: 4 horizontal + down
    var directions = [
        Vector3i(1, 0, 0),
        Vector3i(-1, 0, 0),
        Vector3i(0, 0, 1),
        Vector3i(0, 0, -1),
        Vector3i(0, -1, 0),  # Prefer spreading down
    ]

    for dir in directions:
        var neighbor = pos + dir
        var voxel = voxel_tool.get_voxel(neighbor)

        if voxel == Blocks.AIR:
            # Convert to water
            voxel_tool.set_voxel(neighbor, Blocks.WATER)
            queue_b.append(neighbor)
```

**Water Variants:**
- **Full Block:** WATER (completely filled)
- **Top Surface:** WATER_SURFACE (partial block)

### 7. Multiplayer System

#### Game Modes

```gdscript
enum Mode {
    SINGLEPLAYER,
    CLIENT,
    HOST,
}
```

#### Network Architecture

**Server (HOST):**
- Runs terrain generation
- Executes simulations (water, random ticks)
- Authoritative for all terrain changes
- Creates VoxelViewer for each remote player

**Client:**
- Receives terrain data via synchronizer
- Runs local player physics
- Sends RPCs for block edits
- Broadcasts player position

#### Terrain Synchronization

**Setup:**
```gdscript
var synchronizer = VoxelTerrainMultiplayerSynchronizer.new()
synchronizer.terrain = terrain
add_child(synchronizer)
```

**Behavior:**
- Automatically syncs voxel changes from server to clients
- Handles chunk streaming based on VoxelViewer positions
- Compresses data for network transmission

#### RPC Methods

**Block Placement:**
```gdscript
@rpc("any_peer", "call_remote", "reliable")
func receive_place_single_block(pos: Vector3i, block_id: int):
    if not multiplayer.is_server():
        return  # Server authority

    # Validate and place block
    var voxel_tool = terrain.get_voxel_tool()
    voxel_tool.set_voxel(pos, block_id)
    # Automatically synced to clients
```

**Player Position:**
```gdscript
@rpc("any_peer", "call_remote", "unreliable")
func receive_player_position(pos: Vector3, rot: Vector3):
    # Update remote player avatar
```

#### Player Spawning

**Local Player:**
```gdscript
func spawn_local_player():
    var avatar = CharacterAvatar.instantiate()
    avatar.is_local = true
    add_child(avatar)
```

**Remote Player (Server):**
```gdscript
func spawn_remote_player(peer_id: int):
    var avatar = CharacterAvatar.instantiate()
    avatar.is_local = false
    avatar.peer_id = peer_id

    # Create VoxelViewer for terrain streaming
    var viewer = VoxelViewer.new()
    avatar.add_child(viewer)

    add_child(avatar)
```

#### UPNP Support (upnp_helper.gd)

**Port Forwarding:**
```gdscript
func setup_upnp(port: int):
    var upnp = UPNP.new()
    var result = upnp.discover()

    if result == UPNP.UPNP_RESULT_SUCCESS:
        upnp.add_port_mapping(port, port, "ScriptVoxel", "UDP")
```

## Performance Considerations

### Optimization Strategies

1. **Chunk-based Processing:** All terrain operations work on 16³ or 32³ chunks
2. **LOD System:** Fixed LOD in VoxelTerrain for consistent performance
3. **Simulation Throttling:** Limited updates per frame (512 random ticks, 64 water updates)
4. **VoxelViewer Range:** Controls terrain streaming radius per player

### Profiling Points

- Terrain generation time (see DDD debug output)
- Mesh update frequency
- Simulation system overhead
- Network bandwidth (multiplayer)

## Configuration

### Game Constants

```gdscript
const CHUNK_SIZE = 16
const WATER_LEVEL = 0
const PLAYER_SPAWN_HEIGHT = 64
const VOXEL_VIEW_DISTANCE = 256
const GRAVITY = 20.0
const PLAYER_SPEED = 5.0
const JUMP_STRENGTH = 8.0
```

### Block IDs

Defined in blocks.gd registry:
- 0: AIR
- 1: GRASS
- 2: DIRT
- 3: STONE
- ... (extensible)

## File Locations

| Component | Path |
|-----------|------|
| Main Scene | `project/blocky_game/main.tscn` |
| Game Script | `project/blocky_game/blocky_game.gd` |
| Block Registry | `project/blocky_game/blocks/blocks.gd` |
| Generator | `project/blocky_game/generator/generator.gd` |
| Tree Generator | `project/blocky_game/generator/tree_generator.gd` |
| Character Controller | `project/blocky_game/player/character_controller.gd` |
| Avatar Interaction | `project/blocky_game/player/avatar_interaction.gd` |
| Inventory | `project/blocky_game/gui/inventory/inventory.gd` |
| Item Database | `project/blocky_game/items/item_db.gd` |
| Random Ticks | `project/blocky_game/random_ticks.gd` |
| Water Simulation | `project/blocky_game/water.gd` |
| Interaction Common | `project/blocky_game/interaction_common.gd` |
| Block Library | `project/blocky_game/voxel_library.tres` |
