# Development Guide

## Getting Started

### Prerequisites

1. **Godot Engine 4.4** with compiled godot_voxel module
   - Cannot use standard Godot builds
   - Must compile from source with voxel module

2. **Development Tools**
   - Git for version control
   - Text editor with GDScript support (VS Code, etc.)
   - Basic understanding of Godot's scene system

### Building Godot with Voxel Module

```bash
# Clone Godot
git clone https://github.com/godotengine/godot.git
cd godot
git checkout 4.4-stable

# Clone voxel module
cd modules
git clone https://github.com/Zylann/godot_voxel.git voxel

# Compile (example for Linux)
cd ..
scons platform=linuxbsd target=editor

# Result: Custom Godot build with voxel module
```

### Opening the Project

```bash
# Using custom Godot build
/path/to/custom/godot --editor project/project.godot
```

## Project Structure

### Directory Layout

```
ScriptVoxel/
├── project/                    # Godot project root
│   ├── project.godot           # Project configuration
│   ├── blocky_game/            # Main demo
│   ├── blocky_terrain/         # Simple blocky demo
│   ├── smooth_terrain/         # Smooth terrain demo
│   ├── grid_pathfinding/       # Pathfinding demo
│   ├── blocky_fluid/           # Fluid simulation
│   ├── multipass_generator/    # Multi-pass generation
│   ├── common/                 # Shared utilities
│   │   ├── util.gd
│   │   ├── mouse_look.gd
│   │   └── spectator_avatar.gd
│   └── addons/
│       └── zylann.debug_draw/  # Debug visualization
├── specs/                      # Documentation (this folder)
└── CLAUDE.md                   # AI assistant instructions
```

### File Organization

**Scene Files (.tscn):**
- Main entry points for demos
- Configure node hierarchy
- Reference scripts and resources

**Script Files (.gd):**
- Game logic implementation
- Extend C++ module classes
- Handle user interaction

**Resource Files (.tres):**
- VoxelBlockyLibrary definitions
- Material configurations
- Generator presets

## Creating a New Demo

### Step 1: Create Demo Directory

```bash
cd project
mkdir my_demo
cd my_demo
```

### Step 2: Create Main Scene

**File: `project/my_demo/main.tscn`**

```gdscript
# Create in Godot Editor:
# - Node3D (root)
#   ├── VoxelTerrain
#   ├── DirectionalLight3D
#   ├── Camera3D
#   └── Environment
```

### Step 3: Attach Main Script

**File: `project/my_demo/main.gd`**

```gdscript
extends Node3D

@onready var terrain: VoxelTerrain = $VoxelTerrain

func _ready():
    # Configure terrain
    terrain.generator = MyGenerator.new()
    terrain.voxel_library = _create_library()

func _create_library() -> VoxelBlockyLibrary:
    var library = VoxelBlockyLibrary.new()
    # Add block definitions
    return library
```

### Step 4: Create Generator

**File: `project/my_demo/generator.gd`**

```gdscript
extends VoxelGeneratorScript

var _noise: FastNoiseLite

func _init():
    _noise = FastNoiseLite.new()
    _noise.frequency = 0.01

func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    for y in range(out_buffer.get_size().y):
        for z in range(out_buffer.get_size().z):
            for x in range(out_buffer.get_size().x):
                var world_pos = origin + Vector3i(x, y, z)
                var height = _get_height_at(world_pos.x, world_pos.z)

                var block_id = 1 if world_pos.y < height else 0
                out_buffer.set_voxel(Vector3i(x, y, z), block_id, 0)

func _get_height_at(x: float, z: float) -> float:
    return 32.0 + _noise.get_noise_2d(x, z) * 10.0
```

## Common Development Tasks

### Adding a New Block Type

#### 1. Define in Block Registry

**File: `project/blocky_game/blocks/blocks.gd`**

```gdscript
func _init_blocks():
    # Existing blocks...

    _register_block({
        "name": "my_new_block",
        "voxel_id": 20,
        "rotation_type": ROTATION_NONE,
    })
```

#### 2. Add to VoxelBlockyLibrary

**In Godot Editor:**
1. Open `voxel_library.tres`
2. Add new Voxel definition
3. Set ID to 20
4. Configure model geometry
5. Set collision shape

#### 3. Add Texture (if needed)

1. Add texture to material's texture array
2. Reference texture index in voxel definition

### Implementing Voxel Editing

```gdscript
extends Node3D

@onready var terrain: VoxelTerrain = $VoxelTerrain
var _voxel_tool: VoxelTool

func _ready():
    _voxel_tool = terrain.get_voxel_tool()

func _input(event):
    if event is InputEventMouseButton and event.pressed:
        var camera = get_viewport().get_camera_3d()
        var from = camera.global_position
        var to = from + camera.global_transform.basis.z * -10.0

        var hit = _voxel_tool.raycast(from, to)
        if hit:
            if event.button_index == MOUSE_BUTTON_LEFT:
                _remove_block(hit.position)
            elif event.button_index == MOUSE_BUTTON_RIGHT:
                _place_block(hit.previous_position, 1)

func _remove_block(pos: Vector3i):
    _voxel_tool.set_voxel(pos, 0)  # 0 = AIR

func _place_block(pos: Vector3i, block_id: int):
    _voxel_tool.set_voxel(pos, block_id)
```

### Adding SDF Sculpting (Smooth Terrain)

```gdscript
extends Node3D

@onready var terrain: VoxelLodTerrain = $VoxelLodTerrain
var _voxel_tool: VoxelToolLodTerrain

func _ready():
    _voxel_tool = terrain.get_voxel_tool()
    _voxel_tool.set_channel(VoxelBuffer.CHANNEL_SDF)

func _sculpt_terrain(center: Vector3, radius: float, add_mode: bool):
    _voxel_tool.mode = VoxelTool.MODE_ADD if add_mode else VoxelTool.MODE_REMOVE
    _voxel_tool.do_sphere(center, radius)
```

### Implementing Multiplayer

#### Server Setup

```gdscript
func start_server(port: int):
    var peer = ENetMultiplayerPeer.new()
    peer.create_server(port, 32)
    multiplayer.multiplayer_peer = peer

    # Enable terrain synchronization
    var sync = VoxelTerrainMultiplayerSynchronizer.new()
    sync.terrain = $VoxelTerrain
    add_child(sync)

    multiplayer.peer_connected.connect(_on_player_connected)

func _on_player_connected(peer_id: int):
    # Spawn remote player avatar with VoxelViewer
    var avatar = preload("res://player/avatar.tscn").instantiate()
    avatar.name = str(peer_id)

    var viewer = VoxelViewer.new()
    avatar.add_child(viewer)

    $Players.add_child(avatar)
```

#### Client Setup

```gdscript
func join_server(address: String, port: int):
    var peer = ENetMultiplayerPeer.new()
    peer.create_client(address, port)
    multiplayer.multiplayer_peer = peer

    # Terrain will auto-sync from server
```

#### RPC Pattern

```gdscript
# Client calls this to request block edit
func place_block_request(pos: Vector3i, block_id: int):
    rpc_id(1, "server_place_block", pos, block_id)

# Server receives and executes
@rpc("any_peer", "call_remote", "reliable")
func server_place_block(pos: Vector3i, block_id: int):
    if not multiplayer.is_server():
        return

    var voxel_tool = terrain.get_voxel_tool()
    voxel_tool.set_voxel(pos, block_id)
    # Auto-syncs to all clients
```

## Best Practices

### Performance Optimization

#### 1. Limit Simulation Scope

```gdscript
# Good: Process limited voxels per frame
const UPDATES_PER_FRAME = 64

func _process(_delta):
    for i in range(UPDATES_PER_FRAME):
        _process_one_update()

# Bad: Process all voxels
func _process(_delta):
    for all_voxels:  # Can be millions!
        _process_one_update()
```

#### 2. Use VoxelTool Efficiently

```gdscript
# Good: Reuse VoxelTool instance
var _voxel_tool: VoxelTool

func _ready():
    _voxel_tool = terrain.get_voxel_tool()

func edit_voxel(pos: Vector3i, id: int):
    _voxel_tool.set_voxel(pos, id)

# Bad: Create new VoxelTool each time
func edit_voxel(pos: Vector3i, id: int):
    var tool = terrain.get_voxel_tool()  # Expensive!
    tool.set_voxel(pos, id)
```

#### 3. Batch Voxel Edits

```gdscript
# Good: Batch multiple edits
func place_structure(positions: Array):
    for pos in positions:
        _voxel_tool.set_voxel(pos, block_id)
    # Mesh updates once after all edits

# Bad: Force update after each edit
func place_structure(positions: Array):
    for pos in positions:
        _voxel_tool.set_voxel(pos, block_id)
        terrain.force_update()  # Don't do this!
```

#### 4. LOD Configuration

```gdscript
# VoxelLodTerrain settings
terrain.view_distance = 512  # Adjust based on needs
terrain.lod_count = 4        # More LODs = better performance
terrain.lod_distance = 32.0  # Distance between LOD levels
```

### Code Organization

#### 1. Singleton Pattern for Global Data

```gdscript
# blocks.gd - Global block registry
extends Node

var _blocks: Dictionary = {}

func get_block(id: int) -> Dictionary:
    return _blocks.get(id, {})
```

**Add to autoload** in project settings:
- Name: `Blocks`
- Path: `res://blocks/blocks.gd`

#### 2. Separate Concerns

```gdscript
# Good: Separate systems
# character_controller.gd - Movement only
# avatar_interaction.gd - Voxel editing only
# inventory.gd - Item management only

# Bad: God object
# player.gd - Does everything
```

#### 3. Use Composition

```gdscript
# Good: Components
CharacterAvatar
├── CharacterController (movement)
├── AvatarInteraction (voxel editing)
└── Inventory (items)

# Bad: Inheritance chain
Player extends CharacterController extends VoxelEditor extends InventoryManager
```

### Debugging Techniques

#### 1. Debug Draw Usage

```gdscript
# HUD text
DDD.set_text("Player Pos", global_position)
DDD.set_text("FPS", Engine.get_frames_per_second())

# 3D visualization
DDD.draw_box(position, size, Color.GREEN)
DDD.draw_ray(origin, direction, 10.0, Color.RED)
```

#### 2. Voxel Data Inspection

```gdscript
func debug_voxel_at(pos: Vector3i):
    var voxel_id = _voxel_tool.get_voxel(pos)
    var block_id = Blocks.get_block_from_voxel_id(voxel_id)
    print("Voxel ID: %d, Block ID: %d" % [voxel_id, block_id])
```

#### 3. Performance Profiling

```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    var start_time = Time.get_ticks_usec()

    # Generation logic...

    var elapsed = (Time.get_ticks_usec() - start_time) / 1000.0
    if elapsed > 5.0:  # Warn if > 5ms
        push_warning("Slow generation at %v: %.2f ms" % [origin, elapsed])
```

## Testing

### Manual Testing Checklist

#### Terrain Generation
- [ ] Terrain generates consistently with same seed
- [ ] No visible seams between chunks
- [ ] Structures don't cut off at chunk boundaries
- [ ] Performance is acceptable (< 5ms per chunk)

#### Voxel Editing
- [ ] Block placement works correctly
- [ ] Block removal works correctly
- [ ] Rotation variants place correctly
- [ ] Edits persist after moving away and back

#### Multiplayer (if applicable)
- [ ] Server starts successfully
- [ ] Client connects successfully
- [ ] Terrain syncs to clients
- [ ] Block edits sync to all clients
- [ ] No duplication of edits

### Automated Testing

```gdscript
# test_generator.gd
extends GutTest

var generator: VoxelGeneratorScript

func before_each():
    generator = MyGenerator.new()

func test_deterministic_generation():
    var buffer1 = VoxelBuffer.new()
    buffer1.create(16, 16, 16)
    generator._generate_block(buffer1, Vector3i.ZERO, 0)

    var buffer2 = VoxelBuffer.new()
    buffer2.create(16, 16, 16)
    generator._generate_block(buffer2, Vector3i.ZERO, 0)

    # Should produce identical results
    assert_true(_buffers_equal(buffer1, buffer2))

func _buffers_equal(a: VoxelBuffer, b: VoxelBuffer) -> bool:
    for y in range(a.get_size().y):
        for z in range(a.get_size().z):
            for x in range(a.get_size().x):
                if a.get_voxel(Vector3i(x, y, z), 0) != b.get_voxel(Vector3i(x, y, z), 0):
                    return false
    return true
```

## Common Pitfalls

### 1. Forgetting LOD Parameter

```gdscript
# Wrong: Ignores LOD
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    for x in range(16):  # Always 16!
        # ...

# Correct: Respects LOD
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    var stride = 1 << lod
    for x in range(out_buffer.get_size().x):
        var world_x = origin.x + x * stride
        # ...
```

### 2. Mixing Block IDs and Voxel IDs

```gdscript
# Wrong: Uses block ID directly
_voxel_tool.set_voxel(pos, GRASS_BLOCK_ID)

# Correct: Get voxel ID from block registry
var voxel_id = Blocks.get_voxel_id(GRASS_BLOCK_ID, rotation)
_voxel_tool.set_voxel(pos, voxel_id)
```

### 3. Not Initializing Blocks First

```gdscript
# Wrong: Blocks may not be initialized
func _ready():
    var grass_id = Blocks.get_block_by_name("grass")  # May fail!

# Correct: Ensure blocks are first child
# Configure in scene tree order:
# 1. Blocks (registry)
# 2. Everything else
```

### 4. Modifying Terrain on Client

```gdscript
# Wrong: Client directly modifies terrain
func place_block_client(pos: Vector3i, id: int):
    _voxel_tool.set_voxel(pos, id)  # Will desync!

# Correct: Client requests via RPC
func place_block_client(pos: Vector3i, id: int):
    rpc_id(1, "server_place_block", pos, id)
```

## Resources and References

### Official Documentation
- Godot Voxel Module: https://github.com/Zylann/godot_voxel
- Godot Engine Docs: https://docs.godotengine.org/en/stable/

### Useful Tools
- Godot Jolt Physics: https://github.com/godot-jolt/godot-jolt
- GUT (Godot Unit Testing): https://github.com/bitwes/Gut

### Learning Resources
- ScriptVoxel demos (this project)
- Godot Voxel demo scenes
- Community forum discussions

## Contributing

### Code Style

- Use `snake_case` for variables and functions
- Use `PascalCase` for classes and nodes
- Prefix private members with `_`
- Document public APIs with comments

### Commit Guidelines

```bash
# Good commit messages
git commit -m "Add new tree generation algorithm"
git commit -m "Fix chunk boundary structure placement"
git commit -m "Optimize water simulation performance"

# Bad commit messages
git commit -m "Update"
git commit -m "WIP"
git commit -m "asdfasdf"
```

### Pull Request Process

1. Test your changes thoroughly
2. Update documentation if needed
3. Ensure no regressions in existing demos
4. Follow code style guidelines
5. Provide clear description of changes
