# Project Overview

## ScriptVoxel - Godot Voxel Module Demo Suite

### Introduction

ScriptVoxel is a comprehensive demo and test suite for the Godot Voxel module, showcasing various voxel terrain and gameplay systems. The project demonstrates the capabilities of the C++ voxel module through GDScript implementations, providing practical examples for developers working with voxel-based games in Godot.

### Technology Stack

- **Engine:** Godot 4.4
- **Physics Engine:** Jolt Physics
- **Core Dependency:** [godot_voxel](https://github.com/Zylann/godot_voxel) C++ module
- **Scripting:** GDScript

### Project Purpose

This project serves multiple purposes:

1. **Demonstration** - Showcases different voxel rendering techniques (blocky, smooth terrain)
2. **Testing** - Validates godot_voxel module functionality across various use cases
3. **Education** - Provides working examples for developers learning voxel game development
4. **Reference** - Serves as practical documentation for the voxel module API

### Key Features

#### Blocky Voxel System
- Minecraft-like block-based terrain
- Full block editing (place, remove, pick)
- Rotation system support (axial, Y-rotation, custom)
- Block registry with metadata

#### Terrain Generation
- Noise-based procedural generation
- Multi-pass generation system
- Structure placement (trees, foliage)
- Water bodies and biomes

#### Multiplayer
- Server-authoritative terrain synchronization
- Client-authoritative player physics
- RPC-based block editing
- UPNP port forwarding support

#### Voxel Simulations
- Random tick system (grass spreading)
- Queue-based water simulation
- Cellular automata patterns

#### Smooth Terrain
- Transvoxel algorithm-based rendering
- SDF (Signed Distance Field) sculpting
- Mesh stamping for complex shapes
- Variable LOD (Level of Detail)

#### Additional Systems
- A* pathfinding on voxel grid
- Fluid simulation
- Player inventory system
- Item database
- Debug visualization tools

### Main Demo Scenes

| Scene | Description | Key Features |
|-------|-------------|--------------|
| `blocky_game/main.tscn` | Full Minecraft-like game | Multiplayer, inventory, terrain editing |
| `blocky_terrain/main.tscn` | Simple blocky terrain | Basic block placement demo |
| `smooth_terrain/main.tscn` | Smooth terrain demo | SDF sculpting, Transvoxel meshing |
| `grid_pathfinding/test_grid_pathfinding.tscn` | A* pathfinding | Voxel-aware navigation |
| `blocky_fluid/main.tscn` | Fluid simulation | Water flow dynamics |
| `multipass_generator/multipass_terrain.tscn` | Multi-pass generation | Complex structure placement |

### System Requirements

**Critical Requirement:** The godot_voxel C++ module must be compiled into your Godot engine build. This project cannot run with vanilla Godot.

**Development Environment:**
- Godot 4.4 with compiled godot_voxel module
- Jolt Physics support (configured in project settings)

### Project Structure

```
ScriptVoxel/
├── project/                          # Godot project root
│   ├── blocky_game/                  # Main demo - full game
│   │   ├── blocks/                   # Block registry system
│   │   ├── generator/                # Terrain generation
│   │   ├── items/                    # Item database
│   │   ├── player/                   # Character controller
│   │   └── gui/                      # User interface
│   ├── blocky_terrain/               # Simple blocky demo
│   ├── smooth_terrain/               # Transvoxel demo
│   ├── grid_pathfinding/             # A* pathfinding demo
│   ├── blocky_fluid/                 # Fluid simulation
│   ├── multipass_generator/          # Multi-pass generation
│   ├── common/                       # Shared utilities
│   └── addons/                       # Plugins and tools
└── specs/                            # Project specifications (this folder)
```

### Architecture Philosophy

**C++ Module Integration:** All core voxel functionality resides in the C++ godot_voxel module. GDScript code in this project focuses on:
- Configuration of C++ node types
- Gameplay logic implementation
- User interface and interaction
- Networking and synchronization

**Demo-Centric Design:** Each demo is largely self-contained, demonstrating specific voxel module features without excessive interdependencies.

**Educational Code:** Code prioritizes clarity and demonstrative value over production optimization.

### Use Cases

This project is ideal for:
- Learning voxel game development in Godot
- Testing godot_voxel module features
- Prototyping voxel-based game mechanics
- Understanding multiplayer voxel synchronization
- Exploring procedural terrain generation

### License and Attribution

This is a demo/test project for the godot_voxel module. See the main godot_voxel repository for licensing information.

### Resources

- **Voxel Module Repository:** https://github.com/Zylann/godot_voxel
- **Godot Engine:** https://godotengine.org
- **Historical GDScript Version:** See branch `full_gdscript` (unmaintained)
