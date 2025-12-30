# Controls Reference

Complete guide to all keyboard and mouse controls in ScriptVoxel Blocky Game.

## Quick Reference Table

| Action | Primary Key | Alternative Keys | Notes |
|--------|-------------|-----------------|-------|
| Move Forward | W | Z, Up Arrow | Walk in look direction |
| Move Backward | S | Down Arrow | Walk backward |
| Strafe Left | A | Q, Left Arrow | Side-step left |
| Strafe Right | D | Right Arrow | Side-step right |
| Jump | SPACE | - | Only when on ground |
| Look Around | Mouse Movement | - | First-person camera |
| Place Block | Right Mouse Button | - | Selected hotbar item |
| Remove Block | Left Mouse Button | - | Break/destroy block |
| Pick Block | Middle Mouse Button | - | Copy block to hotbar |
| Select Hotbar 1-9 | 1-9 Number Keys | - | Instant selection |
| Next Hotbar Slot | Mouse Wheel Down | - | Cycle forward |
| Previous Hotbar Slot | Mouse Wheel Up | - | Cycle backward |
| Open/Close Inventory | E | - | Toggle inventory |
| Release Mouse Cursor | ESC | - | Free cursor mode |
| Python Editor | F4 | - | Singleplayer only |
| Toggle Shadows | L | - | Debug feature |
| Print Debug Info | I | - | Console output |

## Movement Controls

### Basic Movement

The game uses standard first-person movement controls with multiple key options for different keyboard layouts.

**Forward Movement:**
- **W** - QWERTY layout standard
- **Z** - AZERTY layout support
- **Up Arrow** - Alternative/accessibility

**Backward Movement:**
- **S** - Standard backward
- **Down Arrow** - Alternative

**Strafing (Side Movement):**
- **A** - Strafe left (QWERTY)
- **Q** - Strafe left (AZERTY)
- **Left Arrow** - Alternative left
- **D** - Strafe right (universal)
- **Right Arrow** - Alternative right

### Movement Mechanics

**Speed**: 5.0 units per second
- Consistent movement speed in all directions
- No sprinting or crouching (yet)
- Speed is the same whether moving forward, backward, or strafing

**Diagonal Movement**:
- Combine forward/backward with left/right for diagonal movement
- Example: W + D = forward-right diagonal
- Movement vector is automatically normalized (no speed advantage)

### Jumping

**Jump Key:** **SPACE**

**Jump Mechanics:**
- **Jump Force**: 5.0 units (moderate height)
- **Can only jump when grounded** - you can't air-jump
- Hold direction keys while jumping to jump in that direction
- Gravity pulls you down at 9.8 units/second²

**Jump Height:**
- Can clear approximately 1 block in height
- Land safely from most reasonable heights
- Use jump + forward to cross gaps

### Step Climbing

**Automatic Feature:**
- Can walk up steps/blocks up to **0.5 units high** without jumping
- Smooth transition when walking up stairs
- No need to jump for small obstacles

### Grounded Detection

The game automatically detects when you're on the ground:
- Standing on blocks = grounded (can jump)
- In the air = not grounded (cannot jump)
- Just landed = grounded (can jump again)

## Camera Controls

### Mouse Look (First-Person)

**Mouse Movement:**
- Move mouse **left/right** = Turn (yaw)
- Move mouse **up/down** = Look up/down (pitch)

**Sensitivity:** 0.3 (default)
- Adjustable in code if needed
- Affects how fast camera rotates with mouse movement

**Pitch Limits:**
- **Maximum up**: 90 degrees (straight up)
- **Maximum down**: -90 degrees (straight down)
- Cannot flip camera upside down

**Camera Position:**
- Located 0.702 units above player center
- Provides realistic "eye level" first-person view
- Matches where you'd expect your eyes to be

### Mouse Capture

**Automatic Capture:**
- Mouse is captured when you click in the game window
- Cursor becomes invisible
- Mouse movements control camera

**Releasing the Mouse:**
- Press **ESC** to release mouse capture
- Cursor becomes visible
- Can interact with UI elements
- Mouse movement no longer controls camera

**Re-Capturing:**
- Click anywhere in the game window
- Mouse is captured again automatically

### Debug Camera Controls (Optional)

**Ctrl + Mouse Wheel Up:** Zoom camera in (decreases distance)
**Ctrl + Mouse Wheel Down:** Zoom camera out (increases distance)

These controls adjust the camera distance and are primarily for debugging or third-person viewing.

## Block Interaction

### Interaction Range

**Maximum Distance:** 10 blocks (10 units)
- Can only interact with blocks within this range
- Crosshair appears when pointing at a valid block
- No interaction beyond 10 blocks

### Mouse Button Actions

**Left Click (Left Mouse Button):**
- **Action**: Remove/destroy block
- **Effect**: Block disappears instantly
- **Multiplayer**: Sends RPC to server for validation

**Right Click (Right Mouse Button):**
- **Action**: Place selected block
- **Effect**: Places block at target position
- **Note**: Block comes from your selected hotbar slot
- **Placement**: On the face of the block you're pointing at

**Middle Click (Middle Mouse Button / Mouse Wheel Click):**
- **Action**: Pick block
- **Effect**: Copies the block type to your hotbar
- **Behavior**: Automatically selects matching block in hotbar
- **Quick Use**: Fast way to switch to the block you're looking at

### Block Placement Details

**Placement Position:**
- Blocks are placed on the **adjacent face** of the target block
- Point at a block, then right-click to place next to it
- Cannot place blocks inside existing blocks

**Rotation:**
- Some blocks rotate based on your look direction
- **Logs**: Align with the axis you're looking along (X/Y/Z)
- **Stairs**: Face the direction you're looking horizontally
- **Standard blocks**: No rotation

### Crosshair Indicator

- **Visible**: When pointing at a block within range
- **Hidden**: When pointing at empty space or out of range
- **Black wireframe cube**: Shows which block you're targeting

## Hotbar & Inventory Controls

### Hotbar Selection

**Number Keys (1-9):**
- Press **1** = Select hotbar slot 1
- Press **2** = Select hotbar slot 2
- ... and so on through **9**
- **Instant selection** - fastest method

**Mouse Wheel:**
- **Scroll Down** = Next slot (cycles forward)
- **Scroll Up** = Previous slot (cycles backward)
- **Wraps around** - after slot 9, goes to slot 1

**Visual Indicator:**
- Selected slot shows a **frame/border** around it
- Displayed at bottom of screen

### Inventory Management

**E Key:**
- **Press E** = Open inventory window
- **Press E again** (or ESC) = Close inventory

**Inside Inventory:**
- **Click and drag** = Move items between slots
- **Click on item** = Pick up entire stack
- **Click on empty slot** = Place item
- **Click on different item** = Swap items
- **ESC while dragging** = Cancel drag operation

**Inventory Structure:**
- **Hotbar**: 9 slots (bottom) - slots 0-8
- **Bag**: 27 slots (9×3 grid) - main storage
- **Total**: 36 slots

## Special Keys & Features

### Python Agent Editor (Singleplayer Only)

**F4 Key:**
- **Toggle** Python code editor window
- Allows writing code to control an AI agent
- **Only available in singleplayer mode**
- Disables player input while editor is open

**When Editor is Open:**
- Mouse becomes visible
- Movement controls disabled (W/A/S/D don't work)
- Can type code freely
- Press F4 again to close and resume playing

### Debug & Utility Keys

**L Key:** Toggle shadow rendering on/off
- Useful for performance testing
- Affects visual quality

**I Key:** Print debug information to console
- Outputs current position
- Shows forward direction vector
- Developer/testing feature

**ESC Key:**
- Release mouse cursor
- Close inventory (if open)
- Return to previous menu state

**Window Close / Alt+F4:**
- Auto-saves world before exiting
- Safe to close anytime

## Input Behavior Notes

### Keyboard Layout Support

The game supports multiple keyboard layouts:
- **QWERTY**: W/A/S/D
- **AZERTY**: Z/Q/S/D
- **Arrow Keys**: Universal alternative

You can use any combination that feels comfortable.

### Input Priority

When multiple inputs are pressed:
- Movement inputs combine (diagonal movement)
- Latest hotbar selection takes priority
- Mouse look is continuous and independent

### Input Disabled States

Player input is disabled when:
- Python editor is open (F4)
- Inventory window is open (UI interaction)
- Mouse is not captured (cursor visible)

In these states, movement and interaction controls won't work until you return to gameplay mode.

## Controller Support

**Currently Not Supported:**
- Gamepad/Controller input is not implemented
- Keyboard and mouse only

## Accessibility Notes

### Alternative Control Schemes

- Multiple key options for movement (WASD, ZQSD, Arrows)
- Mouse can be released anytime (ESC key)
- No required rapid button presses
- Step climbing reduces jump requirement

### Adjustable Settings

- Mouse sensitivity can be modified in code
- No in-game settings menu currently available

## Tips for New Players

1. **Practice Movement**: Spend a few minutes walking and jumping to get comfortable
2. **Master Mouse Look**: Get used to looking around smoothly
3. **Use Number Keys**: Faster than mouse wheel for hotbar selection
4. **Middle-Click is Handy**: Quickly switches to blocks you're looking at
5. **ESC is Your Friend**: Release mouse anytime you need to

---

**Next**: Learn about [Gameplay Mechanics](./03_gameplay.md) to understand blocks and game systems.
