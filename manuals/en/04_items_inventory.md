# Items & Inventory

Complete guide to the inventory system, items, and how to use them in ScriptVoxel Blocky Game.

## Inventory System Overview

### Inventory Structure

Your inventory has **36 total slots** divided into two sections:

**Hotbar (9 slots)**:
- Bottom row of inventory
- Slots numbered 0-8 (displayed as 1-9 to player)
- Visible at bottom of screen during gameplay
- Quick access with number keys 1-9
- Currently selected slot shows a frame/border

**Bag (27 slots)**:
- 9 columns × 3 rows grid
- Main storage area
- Only visible when inventory window is open
- Drag-and-drop to/from hotbar

**Total Capacity**: 36 slots (27 bag + 9 hotbar)

### Opening and Closing Inventory

**E Key** - Toggle inventory window

**When Open**:
- Full inventory grid visible
- Bag (27 slots) at top
- Hotbar (9 slots) at bottom
- Can drag items between any slots
- Mouse cursor is visible and free

**When Closed**:
- Only hotbar visible at bottom of screen
- Gameplay continues normally
- Can switch hotbar items with number keys or mouse wheel

**Closing Methods**:
- Press **E** again
- Press **ESC**
- Click close button (if available)

## Item Types

The game has two fundamental item types:

### TYPE_BLOCK (0) - Placeable Blocks

**Description**: Voxel blocks that can be placed in the world

**Behavior**:
- **Right-click**: Place block in world
- **Left-click**: Remove block from world
- **Middle-click**: Pick block from world

**Examples**:
- Dirt, Grass, Stone, Sand
- Logs, Planks, Glass
- Stairs, Rails
- All construction materials

**Usage**: Primary building material for creating structures

### TYPE_ITEM (1) - Special Items

**Description**: Usable items with custom behavior

**Behavior**:
- **Left-click**: Activate item's special function
- Cannot be placed like blocks
- Each item has unique functionality

**Currently Available**:
- **Rocket Launcher** (ID: 0) - The only special item currently implemented

**Usage**: Tools, weapons, or special functionality items

## Starting Inventory

When you begin a new game, your inventory is pre-filled with essential blocks:

### Default Hotbar Contents

| Slot | Item | Description |
|------|------|-------------|
| 1 (index 0) | Dirt | Basic brown building block |
| 2 (index 1) | Grass | Green surface block |
| 3 (index 2) | Stone | Gray solid block |
| 4 (index 3) | Sand | Tan/yellow desert block |
| 5 (index 4) | Planks | Wooden planks |
| 6 (index 5) | Log | Tree trunk (rotatable) |
| 7 (index 6) | Leaves | Tree foliage (transparent) |
| 8 (index 7) | Oak Planks | Wood variant |
| 9 (index 8) | **Rocket Launcher** | Special weapon item |

### Default Bag Contents

| Slot | Item |
|------|------|
| Bag slot 0 | Coal Block |
| Remaining 26 slots | Empty |

**Note**: This is the standard starting inventory. It gives you basic building materials and one special item to experiment with.

## Managing Your Inventory

### Drag-and-Drop System

**Picking Up Items**:
1. Click on a slot with an item
2. Item is "picked up" (follows your cursor)
3. Slot becomes empty temporarily

**Placing Items**:
1. While holding an item, click on a slot
2. Item is placed in that slot
3. Previous item (if any) is picked up

**Swapping Items**:
1. Click on item A
2. Click on item B
3. Item A goes to B's location
4. Item B is now being held (can place elsewhere)

**Canceling**:
- Press **ESC** while holding an item
- Item returns to original slot
- Useful if you change your mind

### Hotbar Management

**Quick Selection (Number Keys)**:
- Press **1-9** to instantly select that hotbar slot
- Fastest method for switching items
- Works even when inventory window is closed

**Cycling (Mouse Wheel)**:
- **Scroll Up**: Previous hotbar slot
- **Scroll Down**: Next hotbar slot
- Wraps around (9 → 1 → 2 ... → 9)
- Good for browsing items

**Reorganizing**:
- Open inventory with **E**
- Drag items between hotbar slots
- Arrange items in your preferred order
- Close inventory when done

### Bag Management

**Storing Items**:
- Drag items from hotbar to bag for long-term storage
- Keeps hotbar free for frequently used items
- 27 slots available

**Retrieving Items**:
- Drag items from bag to hotbar for quick access
- No delay or penalty for moving items
- Can rearrange anytime

## Using Items

### Using Blocks

Blocks are used for building and terraforming:

**Placing Blocks**:
1. Select block in hotbar (number key or mouse wheel)
2. Point at a block in the world (within 10 blocks range)
3. Press **Right Mouse Button**
4. Block is placed on the face you're pointing at

**Removing Blocks**:
1. Point at any block in the world
2. Press **Left Mouse Button**
3. Block is destroyed instantly
4. No item drops (block doesn't enter inventory)

**Picking Blocks**:
1. Point at any block in the world
2. Press **Middle Mouse Button** (mouse wheel click)
3. If that block type is in your hotbar, it's auto-selected
4. Quick way to switch to the block you're looking at

**Block Behavior Notes**:
- Blocks don't "use up" from inventory (infinite supply)
- No durability or wear
- No crafting required
- Immediate placement/removal

### Using Special Items

Special items have unique functions:

**General Usage**:
1. Select item in hotbar
2. Press **Left Mouse Button** to activate
3. Item's custom function triggers
4. Effect depends on item type

**Currently only one special item exists: Rocket Launcher**

## Rocket Launcher - Special Item Guide

### Overview

The Rocket Launcher is a weapon/tool that fires explosive projectiles.

**Item ID**: 0 (first special item)
**Type**: TYPE_ITEM
**Default Location**: Hotbar slot 9 (index 8)

### How to Use

**Step-by-Step**:
1. Press **9** to select hotbar slot 9 (rocket launcher)
2. Aim at your target by moving mouse
3. Press **Left Mouse Button** to fire
4. Rocket launches from your camera position
5. Rocket travels forward in the direction you're looking

### Rocket Behavior

**Firing**:
- Rocket spawns at camera position (your eye level)
- Travels in the direction you're looking
- Physics-enabled projectile (affected by gravity)
- Visible rocket object with trail/effects

**On Impact**:
- Rocket explodes when it hits a block or terrain
- **Explosion creates terrain destruction** (voxels are destroyed)
- Blast radius removes multiple blocks
- Creates a crater/hole in the terrain

**Multiplayer**:
- Rocket launcher is **network-synchronized**
- Other players can see your rockets firing
- Explosion effects visible to all players
- Terrain damage synced across all clients

### Rocket Launcher Tips

**Combat Usage**:
- Can damage terrain (use carefully near builds)
- Good for clearing large areas quickly
- Useful for mining/excavation

**Building Usage**:
- Quick terrain removal for construction sites
- Create caves or tunnels
- Shape terrain for landscaping

**Safety**:
- Don't fire at your own builds
- In multiplayer, coordinate with other players
- Explosions are permanent (auto-saved)

**Experimental Uses**:
- Test voxel physics
- Create interesting terrain features
- Demolition tool for unwanted structures

## Item System Notes

### No Crafting System

**Current State**:
- No crafting recipes
- No resource gathering requirements
- No item combination mechanics

**Implications**:
- All items available from start
- No progression system
- Pure creative/sandbox mode

### No Item Drops

**When Blocks Are Destroyed**:
- Blocks don't drop as items
- Nothing enters your inventory
- Destroyed blocks simply disappear

**Why**:
- Creative mode design
- Simplified mechanics
- Focus on building, not resource management

### Infinite Supply

**All Items**:
- Never run out of blocks
- Can place unlimited blocks
- No resource limits

**Exception**:
- Special items like rocket launcher don't have ammo limits either
- Infinite uses

### No Durability

**Items Never Break**:
- No tool wear or degradation
- Items last forever
- No need to replace or repair

## Inventory Tips & Tricks

### Organization Strategies

**Method 1: By Material Type**
- Slot 1-3: Earth blocks (Dirt, Grass, Stone)
- Slot 4-6: Wood blocks (Logs, Planks)
- Slot 7-8: Special blocks (Glass, Stairs)
- Slot 9: Tools/Items (Rocket Launcher)

**Method 2: By Frequency**
- Most used blocks in slots 1-5
- Less used in slots 6-8
- Rarely used in slot 9

**Method 3: Color Coding**
- Group similar colored blocks together
- Easy visual identification
- Natural, wood, stone categories

**Choose What Works For You**: Experiment to find your preferred layout.

### Hotbar Efficiency

**Quick Switching**:
- Memorize your layout (muscle memory)
- Use number keys instead of scrolling
- Keep frequently used blocks in easy-to-reach slots (1-5)

**Middle-Click Trick**:
- Point at a block in the world
- Middle-click to instantly switch to that block type
- Faster than opening inventory or scrolling

**Minimize Inventory Time**:
- Organize hotbar before starting big projects
- Put all needed blocks in hotbar before building
- Reduces time spent in inventory menu

### Building Project Setup

**Before Starting a Build**:
1. Open inventory (E)
2. Drag all required blocks to hotbar
3. Arrange blocks in logical order (e.g., foundation → walls → roof)
4. Close inventory
5. Start building

**During Build**:
- Use number keys for quick switching
- Middle-click to grab blocks you're looking at
- Only open inventory when absolutely needed

## Advanced Inventory Techniques

### Hotbar Presets (Manual)

Create "presets" by organizing your hotbar for specific tasks:

**Building Preset**:
- Slots 1-6: Building materials
- Slot 7-8: Decorative blocks
- Slot 9: Empty or tool

**Landscaping Preset**:
- Slots 1-3: Dirt, Grass, Stone
- Slots 4-6: Sand, Water, Plants
- Slot 7-9: Empty or tools

**Creative Preset**:
- Mix of interesting blocks
- Experimental materials
- Tools and special items

Manually rearrange hotbar when switching between activities.

### Efficient Block Selection

**For Repetitive Building**:
1. Select block once (number key)
2. Build entire section without switching
3. Switch only when changing block type
4. Minimizes key presses

**For Varied Building**:
1. Use middle-click to grab blocks from existing structures
2. Copy patterns from your own builds
3. Faster than remembering which hotbar slot has which block

## Future Item Possibilities

**Not Yet Implemented** (but the system supports):
- More special items (tools, weapons, utilities)
- Custom item behaviors
- Item scripting via GDScript
- Additional item types beyond blocks and items

The item database (`item_db.gd`) is designed to be extensible for future additions.

---

**Next**: Learn about [Multiplayer Features](./05_multiplayer.md) for networked gameplay.
