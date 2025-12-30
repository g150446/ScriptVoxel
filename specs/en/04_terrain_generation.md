# Terrain Generation Specification

## Overview

ScriptVoxel demonstrates multiple terrain generation approaches, from simple noise-based heightmaps to complex multi-pass systems with structure placement. This specification covers the generation systems used across different demos.

## Generation Approaches

### 1. Single-Pass Heightmap Generation

**Used in:** Blocky Game, Blocky Terrain demos

**Process Flow:**
```
Generate Heightmap → Fill Layers → Place Structures → Return Buffer
```

#### Implementation Pattern

```gdscript
extends VoxelGeneratorScript

var _noise: FastNoiseLite

func _init():
    _noise = FastNoiseLite.new()
    _noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    _noise.frequency = 0.01
    _noise.fractal_octaves = 3

func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    var stride = 1 << lod  # LOD scaling

    for y in range(out_buffer.get_size().y):
        for z in range(out_buffer.get_size().z):
            for x in range(out_buffer.get_size().x):
                var world_pos = origin + Vector3i(x, y, z) * stride
                var height = _get_height_at(world_pos.x, world_pos.z)

                var block_id = _determine_block(world_pos.y, height)
                out_buffer.set_voxel(Vector3i(x, y, z), block_id, 0)
```

### 2. Multi-Pass Generation

**Used in:** Multipass Generator demo

**Purpose:** Enables structure placement that depends on terrain analysis

#### Pass System

```gdscript
extends VoxelGeneratorMultipassCB

func _get_pass_count() -> int:
    return 2  # Terrain pass + Structure pass

func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int, pass_index: int):
    if pass_index == 0:
        _generate_terrain(out_buffer, origin, lod)
    elif pass_index == 1:
        _place_structures(out_buffer, origin, lod)
```

#### Pass 0: Terrain Generation

```gdscript
func _generate_terrain(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    # Standard heightmap generation
    # No dependency on other chunks
```

#### Pass 1: Structure Placement

```gdscript
func _place_structures(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    # Can read terrain from Pass 0
    var voxel_tool = out_buffer.get_voxel_tool()

    for structure_pos in _get_structure_positions(origin):
        # Check ground block from Pass 0
        var ground_block = voxel_tool.get_voxel(structure_pos)

        if ground_block == GRASS:
            _place_tree(out_buffer, structure_pos)
```

**Advantages:**
- Structures can query actual terrain
- Natural placement on varied terrain
- Complex multi-block features

**Performance Cost:**
- Requires multiple passes over same chunk
- Increased generation time

### 3. SDF (Signed Distance Field) Generation

**Used in:** Smooth Terrain demo

**Approach:** Generate distance field instead of discrete blocks

```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    for y in range(out_buffer.get_size().y):
        for z in range(out_buffer.get_size().z):
            for x in range(out_buffer.get_size().x):
                var world_pos = origin + Vector3i(x, y, z)

                # Calculate signed distance
                var distance = _calculate_sdf(world_pos)

                # Store in SDF channel
                out_buffer.set_voxel_f(Vector3i(x, y, z), distance)
```

**SDF Properties:**
- Negative values: Inside terrain (solid)
- Positive values: Outside terrain (air)
- Zero: Surface boundary
- Enables smooth terrain with Transvoxel meshing

## Noise Configuration

### FastNoiseLite Settings

#### Basic Terrain

```gdscript
var noise = FastNoiseLite.new()
noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
noise.frequency = 0.005       # Larger scale features
noise.fractal_octaves = 4     # Detail levels
noise.fractal_lacunarity = 2.0
noise.fractal_gain = 0.5
```

**Frequency:** Controls feature size
- Low (0.001-0.005): Large continents, mountains
- Medium (0.01-0.02): Hills, valleys
- High (0.05-0.1): Small details

**Octaves:** Layered detail
- 1: Simple smooth noise
- 3-4: Natural terrain look
- 6+: Highly detailed (expensive)

#### Biome Variation

```gdscript
var biome_noise = FastNoiseLite.new()
biome_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
biome_noise.frequency = 0.001  # Large biome regions
```

**Noise Types:**
- **Simplex:** Smooth, organic terrain
- **Perlin:** Classic terrain generation
- **Cellular:** Biome regions, cave systems
- **Value:** Blocky features

### Heightmap Calculation

#### Basic Heightmap

```gdscript
func _get_height_at(x: float, z: float) -> float:
    var noise_value = _noise.get_noise_2d(x, z)  # Range: -1 to 1
    var height = BASE_HEIGHT + noise_value * AMPLITUDE
    return height
```

**Example Configuration:**
```gdscript
const BASE_HEIGHT = 32
const AMPLITUDE = 20

# Result: Height range 12 to 52
```

#### Multi-Octave Heightmap

```gdscript
func _get_height_at(x: float, z: float) -> float:
    var height = 0.0

    # Large features
    height += _noise_large.get_noise_2d(x, z) * 30.0

    # Medium features
    height += _noise_medium.get_noise_2d(x, z) * 10.0

    # Fine details
    height += _noise_small.get_noise_2d(x, z) * 3.0

    return BASE_HEIGHT + height
```

#### Biome-Blended Heightmap

```gdscript
func _get_height_at(x: float, z: float) -> float:
    var biome_value = _biome_noise.get_noise_2d(x, z)

    var plains_height = _plains_noise.get_noise_2d(x, z) * 5.0
    var mountain_height = _mountain_noise.get_noise_2d(x, z) * 50.0

    # Blend based on biome
    var blend = (biome_value + 1.0) / 2.0  # Remap to 0-1
    var height = lerp(plains_height, mountain_height, blend)

    return BASE_HEIGHT + height
```

## Layer Filling Strategies

### Simple Stratified Layers

```gdscript
func _determine_block(y: int, height: float) -> int:
    if y < height - 4:
        return STONE
    elif y < height:
        return DIRT
    elif y == int(height):
        return GRASS
    else:
        return AIR
```

### Water-Aware Layers

```gdscript
const WATER_LEVEL = 0

func _determine_block(y: int, height: float) -> int:
    if y < height:
        if y < height - 4:
            return STONE
        else:
            return DIRT
    elif y == int(height):
        if height < WATER_LEVEL:
            return SAND  # Underwater terrain
        else:
            return GRASS
    elif y <= WATER_LEVEL:
        return WATER
    else:
        return AIR
```

### Ore Distribution

```gdscript
func _determine_block(y: int, height: float, x: int, z: int) -> int:
    if y >= height:
        return AIR

    var base_block = STONE if y < height - 4 else DIRT

    # Ore veins using 3D noise
    var ore_noise = _ore_noise.get_noise_3d(x, y, z)

    if base_block == STONE:
        if ore_noise > 0.7 and y < 20:
            return DIAMOND_ORE
        elif ore_noise > 0.6 and y < 40:
            return IRON_ORE
        elif ore_noise > 0.5 and y < 60:
            return COAL_ORE

    return base_block
```

## Structure Placement

### Pre-Generation Pattern

**Purpose:** Avoid generating structures during terrain generation

```gdscript
# Initialization
var _tree_structures: Array = []

func _ready():
    _generate_tree_structures()

func _generate_tree_structures():
    for i in range(16):
        var tree = _generate_single_tree()
        _tree_structures.append(tree)

func _generate_single_tree() -> Dictionary:
    var buffer = VoxelBuffer.new()
    buffer.create(7, 10, 7)  # Size for tree

    # Build tree into buffer
    # ... tree generation logic ...

    return {
        "buffer": buffer,
        "offset": Vector3i(3, 0, 3),  # Ground anchor point
    }
```

### Placement During Generation

```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    # 1. Generate terrain
    _fill_terrain_layers(out_buffer, origin)

    # 2. Place structures
    var voxel_tool = out_buffer.get_voxel_tool()

    for tree_pos in _get_tree_positions(origin):
        var tree = _tree_structures[randi() % _tree_structures.size()]

        # Boundary check (Moore neighborhood)
        if _is_near_boundary(tree_pos, origin, tree.buffer.get_size()):
            continue

        # Place tree
        voxel_tool.paste_masked(
            tree_pos - tree.offset,
            tree.buffer,
            AIR,  # Mask value (don't replace non-air)
            0     # Channel
        )
```

### Boundary Handling

**Moore Neighborhood Problem:** Structures near chunk edges may be incomplete

```gdscript
func _is_near_boundary(pos: Vector3i, origin: Vector3i, size: Vector3i) -> bool:
    var local_pos = pos - origin
    var chunk_size = 16

    var margin = ceili(size.x / 2.0)  # Half structure size

    if local_pos.x < margin or local_pos.x >= chunk_size - margin:
        return true
    if local_pos.z < margin or local_pos.z >= chunk_size - margin:
        return true

    return false
```

**Solution:** Skip placement near boundaries, letting adjacent chunks handle it

### Deterministic Placement

**Requirement:** Same seed must produce same structures

```gdscript
func _get_tree_positions(origin: Vector3i) -> Array:
    var positions = []
    var chunk_size = 16

    # Use chunk position as seed for deterministic randomness
    var seed_hash = hash(Vector2i(origin.x, origin.z))
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_hash

    for i in range(rng.randi_range(0, 3)):  # 0-3 trees per chunk
        var x = origin.x + rng.randi_range(MARGIN, chunk_size - MARGIN)
        var z = origin.z + rng.randi_range(MARGIN, chunk_size - MARGIN)
        var y = int(_get_height_at(x, z))

        positions.append(Vector3i(x, y, z))

    return positions
```

## Foliage and Detail Placement

### Scatter Pattern

```gdscript
func _place_foliage(out_buffer: VoxelBuffer, origin: Vector3i):
    var voxel_tool = out_buffer.get_voxel_tool()

    for z in range(out_buffer.get_size().z):
        for x in range(out_buffer.get_size().x):
            var world_x = origin.x + x
            var world_z = origin.z + z

            var height = int(_get_height_at(world_x, world_z))
            var local_y = height - origin.y

            if local_y < 0 or local_y >= out_buffer.get_size().y:
                continue

            var surface_block = voxel_tool.get_voxel(Vector3i(x, local_y, z))

            if surface_block == GRASS:
                # Random foliage placement
                var foliage_noise = _foliage_noise.get_noise_2d(world_x, world_z)
                if foliage_noise > 0.3:
                    voxel_tool.set_voxel(Vector3i(x, local_y + 1, z), TALL_GRASS)
```

## Cave Generation

### 3D Noise Caves

```gdscript
func _generate_caves(out_buffer: VoxelBuffer, origin: Vector3i):
    var voxel_tool = out_buffer.get_voxel_tool()

    for y in range(out_buffer.get_size().y):
        for z in range(out_buffer.get_size().z):
            for x in range(out_buffer.get_size().x):
                var world_pos = origin + Vector3i(x, y, z)

                # Only carve caves in solid blocks
                var current_block = voxel_tool.get_voxel(Vector3i(x, y, z))
                if current_block == AIR:
                    continue

                # 3D noise for cave tunnels
                var cave_noise = _cave_noise.get_noise_3d(
                    world_pos.x,
                    world_pos.y,
                    world_pos.z
                )

                if cave_noise > 0.6:  # Carve cave
                    voxel_tool.set_voxel(Vector3i(x, y, z), AIR)
```

### Worm Caves

```gdscript
func _generate_worm_cave(origin: Vector3i, seed_value: int):
    var rng = RandomNumberGenerator.new()
    rng.seed = seed_value

    var pos = origin + Vector3i(8, 32, 8)  # Start position
    var direction = Vector3(rng.randf(), rng.randf(), rng.randf()).normalized()

    var voxel_tool = terrain.get_voxel_tool()

    for i in range(200):  # Tunnel length
        # Carve sphere at current position
        voxel_tool.do_sphere(pos, 3.0)

        # Update position
        pos += direction * 2.0

        # Randomly adjust direction
        direction += Vector3(
            rng.randf() - 0.5,
            rng.randf() - 0.5,
            rng.randf() - 0.5
        ) * 0.2
        direction = direction.normalized()
```

## Performance Optimization

### Chunk Caching

```gdscript
var _generated_chunks: Dictionary = {}

func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    var chunk_key = Vector3i(origin.x / 16, origin.y / 16, origin.z / 16)

    if _generated_chunks.has(chunk_key):
        return  # Already generated

    # Generate chunk
    # ...

    _generated_chunks[chunk_key] = true
```

### LOD-Aware Generation

```gdscript
func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int):
    var stride = 1 << lod  # 1, 2, 4, 8...

    if lod > 0:
        # Simplified generation for distant chunks
        _generate_simplified(out_buffer, origin, stride)
    else:
        # Full detail for nearby chunks
        _generate_detailed(out_buffer, origin)
```

### Async Structure Generation

```gdscript
func _ready():
    _generate_structures_async()

func _generate_structures_async():
    for i in range(16):
        var tree = _generate_single_tree()
        _tree_structures.append(tree)
        await get_tree().process_frame  # Spread over multiple frames
```

## VoxelBuffer Operations

### Writing Voxels

```gdscript
# Single voxel
out_buffer.set_voxel(Vector3i(x, y, z), voxel_id, channel)

# Fill region
out_buffer.fill(voxel_id, channel)
out_buffer.fill_area(voxel_id, Vector3i(min), Vector3i(max), channel)
```

### Pasting Structures

```gdscript
# Paste all voxels
voxel_tool.paste(position, source_buffer, channel, mask_value)

# Paste only non-mask voxels
voxel_tool.paste_masked(position, source_buffer, mask_value, channel)
```

### Channels

- **Channel 0:** Block type (most common)
- **Channel 1:** SDF values (smooth terrain)
- **Channel 2-3:** Custom data (metadata, rotation, etc.)

## Testing and Debugging

### Debug Visualization

```gdscript
# Show chunk boundaries
DDD.draw_box(origin, Vector3(16, 16, 16), Color.RED)

# Show structure placement
DDD.set_text("Trees Placed", tree_count)
```

### Generation Metrics

```gdscript
var start_time = Time.get_ticks_usec()
_generate_block(out_buffer, origin, lod)
var end_time = Time.get_ticks_usec()

DDD.set_text("Gen Time (ms)", (end_time - start_time) / 1000.0)
```

## File Locations

| Component | Path |
|-----------|------|
| Blocky Generator | `project/blocky_game/generator/generator.gd` |
| Tree Generator | `project/blocky_game/generator/tree_generator.gd` |
| Multipass Generator | `project/multipass_generator/multipass_generator.gd` |
| Smooth Terrain Generator | `project/smooth_terrain/*.tres` (resource files) |
