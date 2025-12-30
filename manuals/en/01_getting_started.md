# Getting Started

## Welcome to ScriptVoxel Blocky Game!

This guide will help you get started with the game, from launching it for the first time to understanding the different game modes available.

## System Requirements

### Required
- **Godot Engine 4.4** with the **godot_voxel** C++ module compiled in
- **Jolt Physics** support (included in project settings)
- Modern graphics card with OpenGL support

### Important Note
This game **cannot run on standard Godot builds**. You must use a custom Godot build with the voxel module compiled from source. See the main project documentation for build instructions.

## Launching the Game

1. Open your custom Godot build
2. Load the project: `File > Open Project` or run from command line:
   ```bash
   godot project/project.godot
   ```
3. Press **F5** or click the "Play" button to start the game

The game will launch to the main menu.

## Main Menu

When you start the game, you'll see the **"Blocky Game Demo"** main menu with three options:

### 1. Singleplayer Button
Click this to start a local single-player game.

**What happens:**
- Immediately starts the game
- You spawn at position (0, 64, 0) in a procedurally generated world
- Full access to all features including the Python agent editor
- Your world auto-saves when you close the game

**Best for:**
- Learning the game
- Building in creative mode
- Experimenting with the Python agent system
- Offline play

### 2. Connect to Server (Client Mode)
Click this to join an existing multiplayer server.

**Setup required:**
- **Server IP Address**: Enter the host's IP address (default: `127.0.0.1` for local testing)
- **Port**: Enter the server port (default: `25000`)
- Click **"Connect to server"**

**What happens:**
- Connects to the remote server
- Downloads terrain data from the server
- You spawn in the server's world
- Can interact with other players in real-time

**Best for:**
- Playing with friends
- Joining public servers
- Collaborative building
- Multiplayer experiences

### 3. Host Server (Host Mode)
Click this to create your own multiplayer server.

**Setup required:**
- **Port**: Choose a port number (default: `25000`)
- **UPnP Checkbox** (Optional): Enable automatic port forwarding
- Click **"Host server"**

**What happens:**
- Creates a server that others can connect to
- Your window title changes to "Server"
- You can play while hosting (you're also a player)
- Supports up to 32 players simultaneously
- Server saves the world when shut down

**Best for:**
- Hosting games for friends
- Running a persistent world
- Controlling the server environment
- LAN parties

## Your First Game

### Starting in Singleplayer

1. Click **"Singleplayer"** on the main menu
2. Wait a few seconds for terrain to generate
3. You'll spawn in a grassy area at position (0, 64, 0)
4. Look around by moving your mouse
5. Walk forward by pressing **W**

**What you'll see:**
- Procedurally generated terrain with hills and valleys
- Trees scattered across the landscape
- Grass blocks on the surface
- Your hotbar at the bottom of the screen with 9 item slots
- A crosshair in the center (when pointing at blocks)

### Spawn Location

You always spawn at coordinates:
- **X**: 0
- **Y**: 64 (height)
- **Z**: 0

This is near the center of the world, usually on or above the surface.

## Understanding Game Modes

### Mode Comparison

| Feature | Singleplayer | Client | Host |
|---------|-------------|--------|------|
| Play Offline | ✓ | ✗ | ✗ |
| Python Agent Editor | ✓ | ✗ | ✗ |
| Multiplayer | ✗ | ✓ | ✓ |
| Terrain Control | Full | View Only | Full |
| Simulations Run Locally | ✓ | ✗ | ✓ |
| World Saves | ✓ | Server Saves | ✓ |
| Max Players | 1 | Up to 32 | Up to 32 |
| Port Forwarding Needed | ✗ | ✗ | ✓ |

### Singleplayer Mode

**Features:**
- Full control over your world
- Access to Python programmable agent (F4 key)
- Grass spreading and water simulations run locally
- Auto-save on exit

**Limitations:**
- No multiplayer interaction
- Only you can see your world

**When to use:**
- Learning the game
- Building alone
- Programming agents
- Testing mechanics

### Client Mode

**Features:**
- Connect to any compatible server
- Play with other players in real-time
- See terrain and buildings from the server
- Your actions are visible to all players

**Limitations:**
- No Python agent editor
- Dependent on server connection
- Server has authority over terrain

**When to use:**
- Joining friends' servers
- Participating in multiplayer sessions
- Collaborative projects

### Host Mode

**Features:**
- Run your own server
- Play while hosting (you're a player too)
- Full control over the world
- Grass spreading and water simulations run on your machine
- Optional UPnP for easy connectivity

**Limitations:**
- Requires port forwarding (or UPnP)
- Your computer must stay running for others to play
- Higher system resource usage

**When to use:**
- Playing with specific friends
- Controlling the game environment
- Persistent multiplayer worlds

## Networking Setup (Multiplayer)

### For Clients (Connecting to a Server)

1. Get the server IP address from the host
2. Get the port number (usually 25000)
3. Enter these values in the "Connect to Server" screen
4. Click "Connect to server"
5. Wait for terrain to download

**Troubleshooting:**
- Make sure the server is running
- Check that the IP and port are correct
- Ensure your firewall allows the connection
- Try connecting to `127.0.0.1` for local testing

### For Hosts (Running a Server)

1. Choose a port number (default: 25000 is fine)
2. If playing over the internet:
   - **Option A**: Enable UPnP checkbox (automatic port forwarding)
   - **Option B**: Manually forward the port in your router settings
3. Click "Host server"
4. Share your public IP address with players (for internet play) or local IP (for LAN)

**Finding Your IP:**
- **LAN Play**: Use your local IP (usually 192.168.x.x)
- **Internet Play**: Use your public IP (search "what is my IP" online)

**Port Forwarding (if not using UPnP):**
- Access your router settings (usually 192.168.1.1 or 192.168.0.1)
- Forward **UDP port 25000** to your computer's local IP
- Consult your router's manual for specific steps

## First Steps in the Game

Once you're in the game world:

1. **Look Around**: Move your mouse to look in any direction
2. **Walk Forward**: Press **W** to move forward
3. **Try Jumping**: Press **SPACE** to jump
4. **Point at a Block**: The crosshair appears when you point at nearby blocks
5. **Open Inventory**: Press **E** to see your items
6. **Try Placing a Block**: Press **Right Click** on the ground

Congratulations! You're now ready to explore and build.

## Next Steps

- **Learn the Controls**: See [Controls Reference](./02_controls.md) for all keyboard and mouse controls
- **Understand Gameplay**: Read [Gameplay Guide](./03_gameplay.md) to learn about blocks and mechanics
- **Master Inventory**: Check [Items & Inventory](./04_items_inventory.md) for item management
- **Try Multiplayer**: Visit [Multiplayer Guide](./05_multiplayer.md) for advanced networking

Happy building!
