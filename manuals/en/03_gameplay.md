# Gameplay Guide

Everything you need to know about blocks, building, and game mechanics in ScriptVoxel Blocky Game.

## Game Objective

**This is a sandbox/creative game with no defined win condition.**

- No scores or achievements
- No mandatory objectives or quests
- No time limits
- **Goal**: Build, explore, and create freely

Your objectives are self-directed:
- Build structures and creations
- Experiment with mechanics
- Explore the procedurally generated world
- Collaborate with others in multiplayer
- Program AI agents (singleplayer)

## Available Blocks

### Complete Block List

| ID | Block Name | Type | Rotation | Description |
|----|-----------|------|----------|-------------|
| 0 | Air | Transparent | None | Empty space |
| 1 | Dirt | Solid | None | Basic building material |
| 2 | Grass | Solid | None | Spreads naturally on dirt |
| 3 | Stone | Solid | None | Strong building material |
| 4 | Sand | Solid | None | Desert/beach material |
| 5 | Planks | Solid | None | Processed wood |
| 6 | Log | Solid | Axial | Tree trunk, 3 rotations |
| 7 | Leaves | Transparent | None | Tree foliage |
| 8 | Oak Planks | Solid | None | Wood variant |
| 9 | Coal Block | Solid | None | Resource block |
| 10 | Stairs | Solid | Y-Axis | 4 rotations based on look direction |
| 11 | Glass | Transparent | None | See-through block |
| 12 | Tall Grass | Transparent | None | Decorative plant |
| 13-14 | Water | Liquid | None | Flows and spreads |
| 15-21 | Rails | Special | Custom | Track system blocks |
| 22 | Dead Shrub | Transparent | None | Desert decoration |

### Block Properties

**Solid Blocks:**
- Have collision (you can't walk through them)
- Can be placed on any face of another block
- Provide support for other blocks

**Transparent Blocks:**
- Have collision but can be seen through
- Examples: Glass, Leaves, Tall Grass
- Allow light to pass through

**Liquid Blocks:**
- Water flows and spreads (see Water Simulation section)
- Has collision but different behavior
- Can be placed like solid blocks

## Block Rotation Systems

### Understanding Rotation Types

Different blocks have different rotation behaviors when placed:

### 1. ROTATION_TYPE_NONE (0)

**No rotation** - block looks the same from all angles

**Examples**: Dirt, Grass, Stone, Sand, Glass

**Behavior**:
- Placed the same way regardless of look direction
- Symmetrical on all sides
- Simplest block type

### 2. ROTATION_TYPE_AXIAL (1)

**3-axis rotation** - aligns with X, Y, or Z axis

**Examples**: Logs, Pillars

**Behavior**:
- **Looking up/down**: Placed vertically (Y-axis)
- **Looking left/right**: Placed along X-axis
- **Looking forward/back**: Placed along Z-axis
- Total of 3 possible orientations

**Use Case**:
- Create horizontal or vertical log patterns
- Build pillars in any direction

### 3. ROTATION_TYPE_Y (2)

**Y-axis rotation only** - rotates around vertical axis

**Examples**: Stairs, Signs

**Behavior**:
- Rotates based on your horizontal look direction
- 4 possible rotations (North, East, South, West)
- Always "upright" but faces different directions

**Use Case**:
- Stairs that face toward or away from you
- Directional blocks that need to face certain ways

### 4. ROTATION_TYPE_CUSTOM_BEHAVIOR (3)

**Special rotation logic** - unique per block type

**Examples**: Rails (straight, curved, slopes)

**Behavior**:
- Complex placement rules
- May connect to adjacent blocks
- Automatically chooses appropriate variant

**Use Case**:
- Rail systems that connect intelligently
- Blocks with complex orientation needs

## Building Techniques

### Basic Building

**Placing Blocks:**
1. Select a block from your hotbar (number keys 1-9)
2. Point at an existing block
3. Right-click on the face where you want to place
4. New block appears on that face

**Removing Blocks:**
1. Point at the block you want to remove
2. Left-click
3. Block disappears instantly

### Quick Block Selection

**Middle-Click (Pick Block):**
- Point at any block in the world
- Press middle mouse button
- That block type is automatically selected in your hotbar
- Fastest way to switch between block types while building

### Building Tips

**1. Start with a Foundation**
- Place a flat layer of blocks as a base
- Makes building walls and structures easier
- Provides clear ground level

**2. Use Rotation for Logs**
- Look up to place vertical logs
- Look sideways to place horizontal logs
- Create interesting patterns and supports

**3. Plan Your Structure**
- Think about what you want to build first
- Count blocks if needed
- Use simpler blocks like dirt for planning, then replace

**4. Layer by Layer**
- Build floor by floor (horizontal layers)
- Easier than trying to build entire walls at once
- Can walk on lower layers while building upper ones

**5. Use Step Climbing**
- You can walk up 0.5-block-high steps without jumping
- Makes navigating partially built structures easier
- Stairs work automatically

## Game World Mechanics

### Terrain Generation

**Procedural Generation:**
- World generates automatically as you explore
- Uses noise-based algorithms for natural-looking terrain
- Creates hills, valleys, and flat areas
- Trees and plants placed randomly

**Chunk System:**
- World loads in 16×16×16 block chunks
- Chunks load as you move around
- Distant chunks may unload to save memory

### Grass Spreading Simulation

**How It Works:**
- Dirt blocks exposed to air above convert to grass blocks
- Happens automatically over time
- Processes 512 random blocks per frame
- Only works within 100 blocks of players
- Only runs on server/singleplayer (not on clients)

**What You'll See:**
- Freshly placed dirt slowly becomes grass
- Grass spreads across dirt surfaces
- Creates natural-looking meadows
- Dirt under other blocks stays as dirt (no light)

**Player Impact:**
- Place dirt = it will eventually become grass if exposed
- Dig grass = reveals dirt underneath
- Cover grass with blocks = it stays grass (doesn't revert)

**Simulation Details:**
- Server/singleplayer: Runs locally
- Multiplayer client: Receives updates from server
- Random tick system: 512 voxels per frame
- Radius: 100 blocks around each player

### Water Simulation

**How Water Works:**
- Water spreads in 5 directions: 4 horizontal + 1 down
- Prefers flowing downward
- Creates flowing streams and waterfalls
- Processes 64 water updates every 0.2 seconds

**Water Spreading:**

1. **Horizontal Spread**:
   - Water flows to adjacent air blocks (North, South, East, West)
   - Each water block tries to spread to neighbors

2. **Vertical Spread**:
   - Water strongly prefers flowing downward
   - Creates waterfalls when flowing over edges
   - Fills holes and cavities

**Water Variants:**
- **Water Full Block** (ID 13): Interior water, completely filled
- **Water Top Surface** (ID 14): Surface water with wave effect

**Building with Water:**
- Place water blocks like normal blocks
- Water will start spreading immediately
- To create a contained pool: build walls first, then add water
- Water flows naturally downhill

**Stopping Water:**
- Place solid blocks to stop water flow
- Water doesn't destroy blocks it flows into
- Remove water by breaking the source blocks

**Simulation Details:**
- Queue-based cellular automata algorithm
- 64 blocks updated every 0.2 seconds (10 updates per frame)
- Dual-queue system prevents infinite loops
- Only runs on server/singleplayer

## Natural World Features

### Trees

**Appearance:**
- Randomly placed during world generation
- Made from Log blocks (trunks) and Leaves (canopy)
- Variety of sizes and shapes (16 different variants)

**Harvesting:**
- Break logs and leaves like normal blocks
- Leaves are transparent blocks
- Logs have axial rotation

**Building with Trees:**
- Logs make great pillars and supports
- Leaves can be decorative roofing
- Can replant trees manually by building log+leaves

### Tall Grass

**Appearance:**
- Small decorative plants on grass blocks
- Transparent blocks (can walk through them)
- Generated during world creation

**Properties:**
- No collision (walk through freely)
- Breaks instantly when removed
- Purely decorative

### Dead Shrubs

**Appearance:**
- Desert decoration, like dried bushes
- Found on sand blocks
- Transparent blocks

**Properties:**
- Similar to tall grass
- Desert/arid biome indicator
- No collision

## Game World Behavior

### Day/Night Cycle

**Currently Not Implemented:**
- No day/night cycle
- Lighting is constant
- Directional light simulates sunlight

**Shadow System:**
- Press **L** to toggle shadows
- Affects visual quality and performance
- Shadows render based on directional light

### Physics

**Block Physics:**
- Blocks do not fall or obey gravity (except water)
- You can build floating structures
- No structural integrity requirements

**Player Physics:**
- Gravity pulls player downward (9.8 units/s²)
- Collisions with voxel terrain via VoxelBoxMover
- Step climbing enabled (0.5 block height)

**Item Physics:**
- No item dropping or pickup mechanics
- Items don't exist as physical objects in world
- All items stay in inventory

### World Boundaries

**World Size:**
- Effectively infinite (procedurally generated)
- Practical limit based on computer memory
- No invisible walls or boundaries

**Build Height:**
- No hard limit on vertical building
- Limited only by coordinate system range

## Advanced Mechanics

### Python Programmable Agent (Singleplayer Only)

**F4 Key** - Opens the Python code editor

**What It Does:**
- Spawn an AI agent in the game world
- Write Python code to control the agent
- Agent can move, place blocks, and interact
- Real-time code execution

**Features:**
- Agent spawns at position (5, 64, 0)
- Can be respawned near player
- Programmatic terrain interaction
- Useful for automation and experimentation

**Use Cases:**
- Automated building projects
- Testing game mechanics
- Learning programming
- Creating helper bots

### Multiplayer-Specific Behavior

**Client Authority (Your Player):**
- You control your own movement and physics
- Position is sent to server and other clients
- Smooth movement for your character

**Server Authority (Terrain):**
- All block edits go through server
- Server validates and applies changes
- Changes synchronized to all clients
- Prevents cheating and conflicts

**Simulations:**
- Grass spreading: Server only
- Water flow: Server only
- Clients see the results but don't run simulations

## Tips for Gameplay

### For Beginners

1. **Experiment Freely**: It's a sandbox - try things!
2. **Start Simple**: Build a small house before attempting castles
3. **Use Grass Spreading**: Let dirt become grass for natural look
4. **Water is Tricky**: Test water in small areas first
5. **Save Often**: Game auto-saves, but don't rely on it in multiplayer

### For Builders

1. **Plan Before Placing**: Think about structure layout
2. **Use Different Blocks**: Vary materials for visual interest
3. **Rotate Logs**: Create frames and supports with axial rotation
4. **Stairs for Details**: Add depth with directional stairs
5. **Glass for Windows**: Transparent blocks let you see outside

### For Multiplayer

1. **Coordinate with Others**: Agree on building areas
2. **Respect Others' Work**: Don't grief or destroy without permission
3. **Share Resources**: Work together on large projects
4. **Water Can Spread**: Be careful with water near others' builds

---

**Next**: Learn about [Items & Inventory](./04_items_inventory.md) to master item management.
