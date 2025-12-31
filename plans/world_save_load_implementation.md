# World Save/Load Implementation Plan

## Overview
Implement comprehensive world saving, loading, and creation functionality for the ScriptVoxel blocky game, allowing users to create new worlds, save their progress, and load saved worlds.

## Current State Analysis

### Existing Functionality
- Basic `_save_world()` function exists in `blocky_game.gd:192`
- Calls `_terrain.save_modified_blocks()` 
- Only triggers on window close (NOTIFICATION_WM_CLOSE_REQUEST)
- No load functionality exists
- No UI for managing saves

### World Structure
The world consists of:
- **Voxel Terrain**: Block data using Godot Voxel module
- **Player Data**: Position, inventory, character state
- **Game State**: Time, random ticks, water simulation state
- **Multiplayer**: Not supported for saves (singleplayer only)

## Implementation Plan

### Phase 1: Core Save/Load System

#### 1.1 Create World Save Manager
**File**: `project/blocky_game/world_manager.gd`

**Purpose**: Centralized management of world save/load operations

**Key Features**:
- Save slot management (multiple save files)
- Save metadata (name, timestamp, screenshot)
- File I/O operations using Godot's ResourceSaver/ResourceLoader
- Error handling and validation
- Version control for save format compatibility

**Methods**:
```gdscript
create_world(save_slot: int, world_name: String, seed: int) -> Error
save_world(save_slot: int, world_name: String) -> Error
load_world(save_slot: int) -> Error
delete_world(save_slot: int) -> Error
get_save_metadata(save_slot: int) -> Dictionary
list_saves() -> Array[Dictionary]
get_empty_slot() -> int  # Returns first available slot, -1 if none
```

#### 1.2 Implement Voxel Terrain Persistence

**Approach**: Leverage existing `VoxelTerrain.save_modified_blocks()` capability

**Implementation**:
- Save modified voxel blocks to temporary file
- Store terrain state (generation seed, modified regions)
- Use binary format for efficiency

**Files to modify**:
- `project/blocky_game/blocky_game.gd` - Extend save/load methods

#### 1.3 Player State Serialization

**Data to Save**:
- Player position and rotation
- Inventory contents (27 bag + 9 hotbar slots)
- Character appearance
- Health state (if applicable)

**Implementation**:
- Serialize inventory from `inventory.gd`
- Save player transform from `character_controller.gd`

### Phase 2: UI Integration

#### 2.1 Extend Main Menu UI
**File**: `project/blocky_game/main_menu.gd` and `project/blocky_game/main_menu.tscn`

**UI Elements to Add**:
- "New World" button
- "Load World" button (if saves exist)
- "Delete World" button
- Save slot display with metadata
- World preview (optional)

**Layout**:
```
[ New World      ]
[ Load World     ]
[ Singleplayer   ]
[ Connect to Server ]
[ Host Server    ]
[ UPNP ] Checkbox
```

#### 2.2 New World Dialog
**New File**: `project/blocky_game/new_world_dialog.tscn` and `new_world_dialog.gd`

**Features**:
- World name input (Line Edit)
- World seed input (SpinBox with Random button)
- Save slot selection (auto-select empty slot or manual)
- Create/Cancel buttons

**UI Layout**:
```
+-----------------------------+
| Create New World            |
+-----------------------------+
| World Name: [My World    ] |
| Seed:        [12345    ][🎲]|
| Slot:        [Auto     ][v] |
|                             |
|      [Create]  [Cancel]     |
+-----------------------------+
```

#### 2.3 Save/Load Dialog
**New File**: `project/blocky_game/save_load_dialog.tscn` and `save_load_dialog.gd`

**Features**:
- List of existing saves with metadata (name, date, playtime)
- Save slot selection
- Load/Delete/Back buttons
- Confirmation for overwriting/deleting

**UI Layout**:
```
+-----------------------------+
| Load World                  |
+-----------------------------+
| ┌───────────────────────┐  |
| │ My World - Today      │▶│  |
| │ Castle Build - 2 days │▶│  |
| │ Testing World - 1 week│▶│  |
| └───────────────────────┘  |
|                             |
|    [Load]  [Delete] [Back] |
+-----------------------------+
```

#### 2.4 In-Game Pause Menu
**New File**: `project/blocky_game/pause_menu.tscn` and `pause_menu.gd`

**Features**:
- ESC key to open pause menu
- Options: Resume, Save World, Load World, Settings, Main Menu, Quit
- Save slot selection dialog
- Confirmation dialogs

#### 2.5 Quick Save System
**Implementation**:
- Key binding (F5 for quick save, F9 for quick load)
- Auto-save on exit
- Visual feedback (toast message)

### Phase 3: Game State Management

#### 3.1 Complete World State Serialization

#### 3.1 Complete World State Serialization

**World Creation Parameters**:
```json
{
  "version": 1,
  "timestamp": "2025-12-30T12:00:00",
  "world_name": "My World",
  "creation_date": "2025-12-30T10:00:00",
  "playtime_seconds": 3600,
  "generation": {
    "seed": 12345,
    "modified_blocks_file": "terrain.vxl"
  },
  "players": [
    {
      "id": 1,
      "position": {"x": 10.0, "y": 64.0, "z": 0.0},
      "rotation": {"y": 45.0},
      "inventory": {...}
    }
  ],
  "game_state": {
    "random_ticks_enabled": true,
    "water_simulation_enabled": true
  }
}
```

#### 3.2 Multiplayer Considerations

**Restrictions**:
- Only save in SINGLEPLAYER or HOST mode
- Prevent saving when connected as CLIENT
- Show error message if attempted in multiplayer

**Implementation**:
```gdscript
if _network_mode == NETWORK_MODE_CLIENT:
    push_error("Cannot save world in multiplayer client mode")
    return ERR_UNAUTHORIZED
```

### Phase 4: Testing and Validation

#### 4.1 Save/Load Testing

**Test Cases**:
1. Create new world with default seed, explore, verify terrain
2. Create new world with custom seed, verify terrain reproducibility
3. Create multiple worlds in different slots
4. Load saved world, verify player position and terrain
5. Move player, save, reload - verify position
6. Fill inventory, save, reload - verify items
7. Save in different locations (different coordinates)
8. Test with multiple save slots
9. Verify error handling (disk full, corrupt saves)
10. Overwrite existing world with new world (confirm prompt)
11. Test seed same value produces identical terrain

#### 4.2 Performance Testing

**Metrics**:
- Save time for various world sizes
- Load time for saved worlds
- File size of saves
- Memory usage during save/load

#### 4.3 Edge Cases

**Error Handling**:
- Invalid save file
- Missing save slot
- Corrupted save data
- Version mismatch
- File system errors

## Technical Details

### File Structure

**Save Directory**: `user://worlds/`

**Save Format**:
```
user://worlds/
├── slot_01/
│   ├── world.json          # Metadata and references
│   ├── terrain.vxl         # Voxel terrain data
│   ├── players.res         # Player state resources
│   └── screenshot.png      # World preview (optional)
├── slot_02/
│   └── ...
└── saves.meta              # Save slot index
```

### World Creation Logic

**New World Process**:
1. User enters world name and optional seed in dialog
2. System selects empty save slot (or user manually selects)
3. Create save directory structure
4. Generate initial save metadata
5. Initialize terrain with specified seed
6. Spawn player at default spawn point
7. Start game

**Seed Handling**:
- Default seed: Random number generated by system
- Custom seed: User-specified integer
- Seed applies to: Terrain generation, tree placement, foliage distribution

**Save Slot Management**:
- Auto-select first empty slot when creating world
- Allow manual slot selection (1-9 slots supported)
- Prevent overwriting existing saves without confirmation
- Delete world clears slot for reuse

**Custom Scripts**:
- `world_manager.gd` - Save/load logic
- `pause_menu.gd` - UI handling
- Modified `blocky_game.gd`

### Version Management

**Save Format Versioning**:
- Version 1: Initial implementation
- Future versions: Migration support

**Version Check**:
```gdscript
if save_data.version > CURRENT_SAVE_VERSION:
    return ERR_FILE_CANT_OPEN  # Incompatible save version
```

### Terrain Generation Integration

**Seed Usage**:
```gdscript
# In generator.gd or new initialization
var _heightmap_noise := FastNoiseLite.new()

func set_world_seed(seed: int):
    _heightmap_noise.seed = seed
    # Apply seed to other noise generators
    _trees_min_y = seed % 50 + 10
    _trees_max_y = _trees_min_y + 30
```

**Initialization Flow**:
1. User provides seed in new world dialog
2. WorldManager passes seed to generator
3. Generator applies seed to all noise functions
4. World generates with reproducible terrain

**New World Startup**:
```gdscript
# In blocky_game.gd
func start_new_world(seed: int):
    var generator := _terrain.get_generator()
    if generator and "set_world_seed" in generator:
        generator.set_world_seed(seed)
    _terrain.stream.region_size = 16
    _terrain.view_distance = 128
```

## Implementation Steps

### Step 1: Create Core Files
1. Create `project/blocky_game/world_manager.gd`
2. Implement create_world, save_world, load_world framework
3. Add error handling and validation

### Step 2: Extend BlockyGame
1. Modify `blocky_game.gd` save/load methods
2. Add player state serialization
3. Integrate with WorldManager

### Step 3: Create UI Components
1. Update `main_menu.gd` and `.tscn` (add New World button)
2. Create `new_world_dialog.gd` and `.tscn`
3. Create `save_load_dialog.gd` and `.tscn`
4. Create `pause_menu.gd` and `.tscn`
5. Add save slot selection UI

### Step 4: Wire Up Systems
1. Connect UI to WorldManager
2. Implement pause menu integration
3. Add keyboard shortcuts

### Step 5: Testing
1. Unit tests for save/load
2. Integration testing with game
3. Performance optimization

### Step 6: Documentation
1. Update CLAUDE.md with save system info
2. Add user-facing documentation
3. Code comments for maintainability

## Risk Mitigation

### Known Risks
1. **Voxel Module API Changes**: Godot Voxel module may change API
   - *Mitigation*: Version check, fallback to alternative methods

2. **Save File Corruption**: Corrupted saves could crash game
   - *Mitigation*: Validation, error recovery, backup saves

3. **Large World Saves**: Save files could become very large
   - *Mitigation*: Incremental saves, compression, lazy loading

4. **Multiplayer Conflicts**: Saving in multiplayer could cause conflicts
   - *Mitigation*: Restrict to host/singleplayer only, clear UI indication

## Success Criteria

- ✅ User can create new world with custom name and seed
- ✅ User can save world with keyboard shortcut or menu
- ✅ User can load world from main menu
- ✅ Player position and inventory persist
- ✅ Terrain modifications persist
- ✅ Multiple save slots supported (auto-select empty slots)
- ✅ Error handling prevents data loss
- ✅ Clear UI feedback for operations
- ✅ Performance impact is minimal
- ✅ World seed controls terrain generation

## Future Enhancements

1. **Auto-Save**: Periodic automatic saves
2. **World Export**: Export world as standalone file
3. **Cloud Saves**: Integration with cloud storage
4. **World Sharing**: Share saves with other players
5. **Screenshot Preview**: Show world thumbnail in save list
6. **World Version Control**: Track world history
7. **World Templates**: Pre-generated world types (flat, survival, creative)
8. **World Import**: Import worlds from other sources
9. **Seed Favorites**: Save and favorite world seeds
10. **World Statistics**: Track blocks placed, time played, etc.

## Timeline Estimate

- Phase 1: Core System (including create_world) - 3-4 hours
- Phase 2: UI Integration (dialogs and menus) - 3-4 hours
- Phase 3: State Management (seed integration) - 1-2 hours
- Phase 4: Testing & Polish - 1-2 hours

**Total**: 8-12 hours of development time

## Notes

- New world creation replaces current "Singleplayer" button behavior
- World seed controls terrain generation (FastNoiseLite uses seed)
- Empty save slots are auto-selected when creating new worlds
- This implementation focuses on singleplayer experience
- Multiplayer saves require server-side architecture (out of scope)
- VoxelTerrain's `save_modified_blocks()` is used for terrain persistence
- All saves use Godot's native serialization for reliability
- User data stored in `user://` directory for cross-platform compatibility
