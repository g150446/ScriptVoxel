# Architecture Specification

## System Architecture Overview

### Architectural Principles

#### 1. C++ Module Integration Pattern

ScriptVoxel follows a **GDScript-over-C++** architecture where:

- **C++ Layer (godot_voxel module):** Handles performance-critical operations
  - Voxel data storage and compression
  - Mesh generation (marching cubes, transvoxel)
  - LOD management
  - Collision detection
  - Streaming and chunk management

- **GDScript Layer (this project):** Implements game logic
  - Terrain generation algorithms
  - Gameplay mechanics
  - User interaction
  - Networking logic
  - UI systems

#### 2. Demo-Centric Organization

Each demo is architecturally independent:
- Self-contained scene files
- Minimal cross-demo dependencies
- Shared utilities in `common/` directory
- Demonstrates specific voxel module capabilities

#### 3. Singleton Registry Pattern

Global registries for shared data:
- **Blocks** - Block type registry (must initialize first)
- **Items** - Item database
- **DDD** - Debug draw system (autoload)

### Core C++ Classes (godot_voxel module)

#### Terrain Nodes

| Class | Purpose | LOD Support | Use Case |
|-------|---------|-------------|----------|
| `VoxelTerrain` | Fixed LOD terrain | No | Blocky games, consistent detail |
| `VoxelLodTerrain` | Variable LOD terrain | Yes | Smooth terrain, large worlds |

#### Generation System

```
VoxelGenerator (base class)
├── VoxelGeneratorScript (GDScript extendable)
├── VoxelGeneratorNoise2D
├── VoxelGeneratorNoise3D
└── VoxelGeneratorMultipassCB (callback-based)
```

**Key Classes:**
- **VoxelGeneratorScript:** Base for custom GDScript generators
- **VoxelGeneratorMultipassCB:** Enables multi-pass generation (structure placement)
- **VoxelBuffer:** Voxel data container for read/write operations

#### Editing Tools

- **VoxelTool:** Base class for voxel manipulation
- **VoxelToolTerrain:** Terrain-specific editing operations
- **Operations:** `do_sphere()`, `do_box()`, `paste()`, `paste_masked()`

#### Physics Integration

- **VoxelBoxMover:** Character controller with voxel collision
  - Handles AABB-voxel collisions
  - Replaces Godot's CharacterBody3D for voxel worlds
  - Provides movement with collision resolution

#### Multiplayer System

- **VoxelTerrainMultiplayerSynchronizer:** Server-authoritative terrain sync
- **VoxelViewer:** Marks positions that require terrain loading
  - Attached to each player for streaming

#### Block System

- **VoxelBlockyLibrary:** Defines block models and collision
  - Maps voxel IDs to visual models
  - Configures collision shapes
  - Supports rotation variants

#### Pathfinding

- **VoxelAStarGrid3D:** A* pathfinding on voxel grids
  - Voxel-aware navigation
  - Configurable traversal rules

### Blocky Game Architecture

The most complex demo, structured as a full game system:

```
BlockyGame (Root Node)
├── Blocks (Registry - MUST BE FIRST CHILD)
│   └── Block definitions and mapping
├── VoxelTerrain (C++ terrain node)
│   ├── VoxelBlockyLibrary (models/collision)
│   └── Generator (extends VoxelGeneratorScript)
│       └── TreeGenerator (structure pre-generation)
├── Items (Item database singleton)
├── RandomTicks (Grass spreading simulation)
├── Water (Queue-based water simulation)
├── Players (Container)
│   └── CharacterAvatar instances
│       ├── CharacterController (VoxelBoxMover)
│       ├── AvatarInteraction (voxel raycasting)
│       ├── Inventory
│       └── Camera (MouseLook)
├── GUI
│   ├── Hotbar
│   ├── InventoryWindow
│   └── Crosshair
└── Environment
```

#### Critical Initialization Order

1. **Blocks Registry** - Must be first child, other systems depend on it
2. **VoxelTerrain** - Initialized with generator and library
3. **Items** - Item database
4. **Simulation Systems** - RandomTicks, Water
5. **Players** - Spawned after terrain is ready

### Terrain Generation Architecture

#### Single-Pass Generation Flow

```
VoxelGeneratorScript._generate_block()
    ↓
1. Calculate world position from chunk origin
    ↓
2. Generate heightmap using noise
    ↓
3. Fill voxel buffer layer by layer
    │
    ├─→ Below height: dirt/stone
    ├─→ At height: grass/sand
    └─→ Above height: air/water
    ↓
4. Place structures (trees, foliage)
    ↓
5. Return to C++ for meshing
```

#### Multi-Pass Generation Flow

```
Pass 0 (Terrain):
VoxelGeneratorMultipassCB._generate_block(pass_index=0)
    ↓
Generate base terrain (heightmap, blocks)
    ↓
Return to C++ module
    ↓
Pass 1 (Structures):
VoxelGeneratorMultipassCB._generate_block(pass_index=1)
    ↓
Can read terrain from Pass 0
    ↓
Place structures based on terrain
    ↓
Return to C++ module
```

**Advantage:** Pass 1 can read actual terrain from Pass 0, enabling:
- Trees placed only on grass blocks
- Structures that conform to terrain
- Complex multi-block features

### Multiplayer Architecture

#### Network Topology

```
Server (HOST mode)
├── Authoritative terrain state
├── VoxelTerrain with synchronizer
├── Simulation systems (water, random ticks)
└── Remote player VoxelViewers

Clients (CLIENT mode)
├── Synchronized terrain (read-only)
├── Local player (authoritative physics)
└── Remote player avatars (position sync)
```

#### Authority Model

| System | Authority | Sync Method |
|--------|-----------|-------------|
| Terrain/Voxels | Server | VoxelTerrainMultiplayerSynchronizer |
| Local Player Physics | Client | Local simulation |
| Player Position | Client | RPC broadcast |
| Block Edits | Server | RPC request/response |
| Simulations | Server | Automatic via terrain sync |

#### Network Flow: Block Placement

```
Client Action:
Player clicks to place block
    ↓
Client: Validate placement locally
    ↓
Client → Server RPC: receive_place_single_block(pos, block_id)
    ↓
Server: Validate and modify terrain
    ↓
Server → All Clients: Automatic sync via VoxelTerrainMultiplayerSynchronizer
    ↓
All Clients: Receive updated voxel data
```

### Voxel Simulation Architecture

#### Random Tick System

```
RandomTicks Node
    ↓
Every frame:
    ↓
1. Calculate 100-block radius around player
    ↓
2. Select 512 random voxel positions
    ↓
3. For each position:
    VoxelTool.run_blocky_random_tick(callback)
        ↓
    Callback receives voxel info
        ↓
    Apply simulation rules (e.g., grass spreading)
```

**Grass Spreading Algorithm:**
1. Check if voxel is dirt
2. Check if voxel above is air (has light)
3. If conditions met: convert dirt to grass

#### Water Simulation System

```
Water Node
├── Queue A (current frame)
├── Queue B (next frame)
└── Timer (0.2s interval)

Simulation Loop:
    ↓
Process 64 voxels from Queue A
    ↓
For each water voxel:
    ├─→ Check 4 horizontal neighbors
    ├─→ Check 1 down neighbor
    ├─→ If neighbor is air: convert to water, add to Queue B
    └─→ Continue
    ↓
After 64 updates:
    Swap Queue A ↔ Queue B
    ↓
Repeat
```

### Player System Architecture

#### Character Controller

```
CharacterAvatar
├── CharacterController (character_controller.gd)
│   ├── VoxelBoxMover (C++ collision)
│   ├── Input handling
│   ├── Movement physics
│   └── Jump/gravity
├── AvatarInteraction (avatar_interaction.gd)
│   ├── Voxel raycasting
│   ├── Block place/remove
│   ├── Block picking
│   └── Tool/item usage
├── Inventory (inventory.gd)
│   ├── 27 bag slots
│   ├── 9 hotbar slots
│   └── Drag-and-drop system
└── Camera
    └── MouseLook (first-person control)
```

#### Voxel Interaction Flow

```
Player Input (click)
    ↓
AvatarInteraction: Raycast into voxel world
    ↓
Hit Detection:
    ├─→ Primary action (remove block)
    ├─→ Secondary action (place block)
    └─→ Middle click (pick block)
    ↓
Get block at position via VoxelTool
    ↓
Apply rotation if needed
    ↓
Update terrain via VoxelTool
    ↓
Multiplayer: Send RPC to server
```

### Debug Systems

#### Debug Draw Architecture (DDD)

```
DebugDraw (Autoload as "DDD")
├── HUD Text System
│   ├── Key-value pairs
│   └── Auto-updating display
├── 3D Drawing System
│   ├── Boxes
│   ├── Lines
│   ├── Rays
│   ├── Meshes
│   └── Linger frame management
└── Performance Stats
```

**Usage Pattern:**
```gdscript
DDD.set_text("FPS", Engine.get_frames_per_second())
DDD.draw_box(position, size, Color.RED)
```

### Resource Management

#### Block Library (.tres files)

```
VoxelBlockyLibrary
├── Block Definitions
│   ├── Voxel ID assignments
│   ├── Mesh models
│   ├── Collision shapes
│   └── Material references
└── Loaded by VoxelTerrain
```

#### Material System

- **Blocky Materials:** Texture arrays for block textures
- **Smooth Materials:** Triplanar mapping for smooth terrain
- **Configured in .tres resource files**

### Data Flow Summary

```
User Input
    ↓
GDScript Game Logic
    ↓
C++ Voxel Module API
    ↓
Voxel Data Modification
    ↓
Mesh Generation (C++)
    ↓
Render (Godot Engine)
```

**Key Insight:** Performance-critical operations stay in C++, while game-specific logic remains flexible in GDScript.
