# ScriptVoxel Specifications (English)

This directory contains comprehensive technical specifications for the ScriptVoxel project.

## Documentation Index

### 01. [Project Overview](./01_project_overview.md)
High-level introduction to ScriptVoxel, including:
- Project purpose and goals
- Technology stack
- Key features overview
- Demo scene descriptions
- System requirements
- Architecture philosophy

**Start here** if you're new to the project.

### 02. [Architecture Specification](./02_architecture.md)
Detailed system architecture documentation, covering:
- C++ module integration patterns
- Core voxel system classes
- Blocky game architecture
- Terrain generation architecture
- Multiplayer architecture
- Simulation systems
- Data flow diagrams

**Essential reading** for understanding how the systems work together.

### 03. [Blocky Game System](./03_blocky_game.md)
Complete specification of the main demo (blocky_game), including:
- Block registry system
- Terrain generation details
- Player controller mechanics
- Inventory system
- Item database
- Random tick simulation
- Water simulation
- Multiplayer implementation

**Primary reference** for the most complex demo in the project.

### 04. [Terrain Generation](./04_terrain_generation.md)
In-depth coverage of terrain generation techniques:
- Single-pass heightmap generation
- Multi-pass generation system
- SDF (Signed Distance Field) generation
- Noise configuration strategies
- Structure placement algorithms
- Cave generation
- Performance optimization

**Technical deep-dive** into procedural generation.

### 05. [Development Guide](./05_development_guide.md)
Practical guide for developers working with ScriptVoxel:
- Getting started and prerequisites
- Building Godot with voxel module
- Creating new demos
- Common development tasks
- Best practices
- Debugging techniques
- Testing strategies
- Common pitfalls to avoid

**Hands-on guide** for development work.

## Quick Navigation

### By Topic

**Understanding the Project:**
- Start: [01_project_overview.md](./01_project_overview.md)
- Architecture: [02_architecture.md](./02_architecture.md)

**Working with Specific Systems:**
- Blocks and Items: [03_blocky_game.md](./03_blocky_game.md) § 1-4
- Terrain: [04_terrain_generation.md](./04_terrain_generation.md)
- Multiplayer: [03_blocky_game.md](./03_blocky_game.md) § 7
- Simulations: [03_blocky_game.md](./03_blocky_game.md) § 6

**Development:**
- Setup: [05_development_guide.md](./05_development_guide.md) § Getting Started
- Creating Content: [05_development_guide.md](./05_development_guide.md) § Creating a New Demo
- Best Practices: [05_development_guide.md](./05_development_guide.md) § Best Practices

### By Experience Level

**Beginner** (New to ScriptVoxel):
1. [01_project_overview.md](./01_project_overview.md)
2. [05_development_guide.md](./05_development_guide.md) § Getting Started
3. [02_architecture.md](./02_architecture.md) § Architectural Principles

**Intermediate** (Familiar with basics):
1. [03_blocky_game.md](./03_blocky_game.md)
2. [04_terrain_generation.md](./04_terrain_generation.md)
3. [05_development_guide.md](./05_development_guide.md) § Common Development Tasks

**Advanced** (Deep customization):
1. [02_architecture.md](./02_architecture.md)
2. [04_terrain_generation.md](./04_terrain_generation.md) § Performance Optimization
3. [03_blocky_game.md](./03_blocky_game.md) § Multiplayer System

### By Task

**I want to:**
- **Understand the codebase** → [02_architecture.md](./02_architecture.md)
- **Add new block types** → [05_development_guide.md](./05_development_guide.md) § Adding a New Block Type
- **Modify terrain generation** → [04_terrain_generation.md](./04_terrain_generation.md)
- **Implement multiplayer** → [03_blocky_game.md](./03_blocky_game.md) § 7, [05_development_guide.md](./05_development_guide.md) § Implementing Multiplayer
- **Create a new demo** → [05_development_guide.md](./05_development_guide.md) § Creating a New Demo
- **Debug issues** → [05_development_guide.md](./05_development_guide.md) § Debugging Techniques
- **Optimize performance** → [04_terrain_generation.md](./04_terrain_generation.md) § Performance Optimization

## Additional Resources

### Related Files
- **CLAUDE.md** (project root) - Instructions for AI assistants
- **project/project.godot** - Godot project configuration
- **project/common/** - Shared utility scripts

### External Resources
- [Godot Voxel Module](https://github.com/Zylann/godot_voxel)
- [Godot Engine Documentation](https://docs.godotengine.org/)
- [Godot Jolt Physics](https://github.com/godot-jolt/godot-jolt)

## Document Conventions

### Code Blocks
```gdscript
# GDScript examples shown like this
func example():
    pass
```

```bash
# Shell commands shown like this
godot --editor project/project.godot
```

### File Paths
- Absolute: `/Users/user/ScriptVoxel/project/main.tscn`
- Relative to project root: `project/blocky_game/main.tscn`
- Godot resource paths: `res://blocky_game/main.tscn`

### References
- Internal links: [Development Guide](./05_development_guide.md)
- File locations: `project/blocky_game/blocks/blocks.gd`
- Code references: `BlockyGame.blocks:712`

## Updating Documentation

When making changes to the project:
1. Update relevant specification files
2. Keep code examples synchronized with actual code
3. Update file path references if files move
4. Maintain consistency across all documents

## Language Versions

- **English:** `specs/en/` (this directory)
- **Japanese:** `specs/ja/`

Both versions contain the same information in different languages.
