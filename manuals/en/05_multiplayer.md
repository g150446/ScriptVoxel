# Multiplayer Guide

Complete guide to hosting servers, connecting to servers, and playing ScriptVoxel Blocky Game with others.

## Multiplayer Overview

### Network Modes

ScriptVoxel supports three network modes:

| Mode | Description | Who Can Join | Features |
|------|-------------|--------------|----------|
| **Singleplayer** | Local play only | Nobody | Python agent, offline |
| **Client** | Connect to server | You only | Play on remote world |
| **Host** | Run server + play | Up to 31 others | Full control, multiplayer |

### Key Concepts

**Server-Authoritative Terrain**:
- Server controls all terrain and block edits
- Clients send requests to modify blocks
- Server validates and applies changes
- Ensures consistency across all players

**Client-Authoritative Physics**:
- Each player controls their own movement
- No server validation of position (trust-based)
- Smooth local movement
- Position broadcast to other players

**Peer-to-Peer Architecture**:
- Uses ENet networking protocol
- Direct connections between clients and server
- UDP-based for low latency
- Reliable and unreliable message support

## Hosting a Server

### Step-by-Step Server Setup

**1. From Main Menu**:
- Click **"Host Server"** button
- Server configuration screen appears

**2. Configure Server Settings**:

**Port Number**:
- Default: **25000** (UDP)
- Can use any port between 1024-65535
- Remember this number - clients need it to connect

**UPnP Option** (Checkbox):
- **Enabled**: Automatic port forwarding (easiest)
- **Disabled**: Manual port forwarding required (advanced)

**3. Start Server**:
- Click **"Host server"** button
- Server initializes
- Window title changes to "Server"
- You spawn in the world as player 1

**4. Share Connection Info**:
- Give players your **IP address** and **port number**
- For LAN: Use local IP (192.168.x.x)
- For Internet: Use public IP (Google "what is my IP")

### Server Capabilities

**Maximum Players**: 32 concurrent connections
- You (the host) count as player 1
- Up to 31 additional players can join
- Server peer ID is always 1

**Server Authority**:
- All terrain modifications go through server
- Grass spreading simulation runs on server
- Water simulation runs on server
- Block edits validated and distributed to clients

**Server Features**:
- Real-time terrain synchronization to clients
- VoxelViewer created for each connected player
- Automatic chunk streaming based on player positions
- Network-efficient voxel data compression

### Port Forwarding

If **not using UPnP**, you must manually forward the port:

**Router Configuration**:
1. Access router admin panel (usually http://192.168.1.1 or http://192.168.0.1)
2. Login with router credentials
3. Find **"Port Forwarding"** or **"Virtual Server"** section
4. Create new rule:
   - **External Port**: 25000 (or your chosen port)
   - **Internal Port**: 25000 (same as external)
   - **Internal IP**: Your computer's local IP
   - **Protocol**: **UDP** (not TCP!)
5. Save and apply settings

**Finding Your Local IP**:
- **Windows**: Open CMD, type `ipconfig`, look for IPv4 Address
- **Mac**: System Preferences → Network, look for IP Address
- **Linux**: Terminal, type `hostname -I`

**Testing Port Forwarding**:
- Use online port checker tools
- Ask a friend to try connecting
- Check router logs for connection attempts

### UPnP Automatic Port Forwarding

**What is UPnP?**
- Universal Plug and Play
- Automatic router configuration
- No manual setup required

**How to Use**:
1. Enable UPnP checkbox in server setup
2. Click "Host server"
3. Game automatically configures router
4. Port forwarding created automatically

**Requirements**:
- Router must support UPnP
- UPnP must be enabled in router settings
- Not all routers support this

**Troubleshooting**:
- If UPnP fails, use manual port forwarding instead
- Check router admin panel for UPnP settings
- Some ISPs block UPnP

### Running a Server

**While Server is Running**:
- You can play normally (you're also a player)
- Your window shows "Server" in title bar
- All simulations run on your machine
- Other players connect to you

**Server Performance**:
- Your computer must stay running
- Other players depend on your connection
- Higher system resource usage (hosting + playing)
- Network upload bandwidth important

**Stopping Server**:
- Close game window normally
- **World is automatically saved** before shutdown
- All connected clients are disconnected
- They see "Server disconnected" message

## Connecting to a Server (Client Mode)

### Step-by-Step Client Connection

**1. From Main Menu**:
- Click **"Connect to Server"** button
- Client configuration screen appears

**2. Enter Server Info**:

**Server IP Address**:
- Get this from the server host
- For LAN: Local IP (e.g., 192.168.1.100)
- For Internet: Public IP (e.g., 203.0.113.45)
- For local testing: **127.0.0.1** (localhost)

**Port**:
- Default: **25000**
- Must match server's port exactly
- Ask host if different

**3. Connect**:
- Click **"Connect to server"** button
- Game attempts connection
- Shows "Connecting..." status

**4. Terrain Download**:
- Connected successfully!
- Begins downloading terrain from server
- May take a few seconds depending on world size
- You spawn in the server's world

### Client Capabilities

**What You Can Do**:
- Move and explore freely
- Place and remove blocks (via server)
- See other players in real-time
- Interact with the world
- Use all blocks and items

**What You Cannot Do**:
- Access Python agent editor (host/singleplayer only)
- Run simulations (grass spreading, water flow) - server handles this
- Play if server is offline
- Override server terrain decisions

### Client Features

**Terrain Synchronization**:
- Automatic download of terrain as you explore
- Voxel data compressed for efficiency
- Streaming based on your position
- VoxelTerrainMultiplayerSynchronizer handles this

**Player Interaction**:
- See other players moving
- Watch blocks being placed/removed by others
- Real-time collaboration

**Network Authority**:
- Your movement is client-authoritative (you control it)
- Block edits are server-authoritative (server validates)
- Smooth gameplay with minimal lag

## Troubleshooting Connection Issues

### Cannot Connect to Server

**Check These**:
1. **Server is Running**: Confirm with host that server is active
2. **Correct IP**: Double-check IP address (no typos)
3. **Correct Port**: Verify port number matches server
4. **Firewall**: Disable firewall temporarily to test
5. **Router**: Ensure port forwarding is configured correctly (host side)
6. **Same Version**: Client and server must use same game version

**Common Issues**:
- **"Connection Failed"**: Server isn't reachable (check IP/port)
- **Timeout**: Firewall or router blocking connection
- **Wrong IP**: Using wrong network interface IP

### Lag or Performance Issues

**Client-Side Lag**:
- **Causes**: Slow internet, high ping, server too far away
- **Solutions**: Check internet connection, try local server instead

**Server-Side Lag**:
- **Causes**: Too many players, server computer too slow, simulations overloading
- **Solutions**: Reduce player count, upgrade server hardware

**Terrain Loading Slow**:
- **Causes**: Large world, slow connection, server bandwidth limited
- **Solutions**: Wait patiently, move slower to allow streaming, ask host to improve upload speed

## Multiplayer Gameplay

### Playing with Others

**Coordination**:
- Communicate via external voice/text chat (no in-game chat)
- Agree on building areas to avoid conflicts
- Share resources mentally (all items are infinite anyway)

**Collaboration**:
- Build together on large projects
- One player places, another designs
- Work on different sections simultaneously

**Respect**:
- Don't destroy others' builds without permission
- Ask before modifying shared structures
- Be careful with water (can flood builds)

### Network Behavior

**Your Actions**:
- **Moving**: Instant locally, broadcast to server/others
- **Block Placement**: Sent to server, validated, synced to all clients
- **Block Removal**: Same as placement (server validates)

**Others' Actions**:
- **Moving**: Received via RPC, updated on your client
- **Block Edits**: Server sends updates, your client applies them
- **Simulations**: Only server runs them, you see the results

**Sync Details**:
- **Reliable RPCs**: Block edits (must arrive)
- **Unreliable RPCs**: Player positions (can drop packets)
- **VoxelTerrainMultiplayerSynchronizer**: Handles voxel sync automatically

### Special Multiplayer Features

**VoxelViewer System**:
- Each player has a VoxelViewer node on server
- Marks what terrain needs to be loaded for that player
- Server sends terrain chunks based on viewer position
- Automatic terrain streaming as you move

**Remote Player Avatars**:
- Other players appear as character avatars
- Movement synced in real-time
- Can see their orientation and position
- No collision with other players (can walk through each other)

**Terrain Persistence**:
- All block edits saved on server
- When you reconnect, world is as you left it
- Server auto-saves on shutdown

## Multiplayer Limitations

**Current Limitations**:

**No Voice/Text Chat**:
- Use external programs (Discord, TeamSpeak, etc.)
- No in-game communication system

**No Permissions/Roles**:
- All players have equal editing rights
- No admin controls or player ranks
- Trust-based system

**No Player List**:
- Can't see who's online
- No scoreboard or player roster
- Must track manually

**No Spawn Protection**:
- Players can edit anywhere
- No protected zones or claims
- No build restrictions

**No Player Names**:
- No name tags above players
- Can't identify who is who visually
- Must coordinate externally

## Advanced Multiplayer Topics

### Network Authority Details

**Client-Authoritative (Player Physics)**:
- You send position updates to server
- Server broadcasts to other clients
- No server validation (trust-based)
- Smooth movement, potential for cheating

**Server-Authoritative (Terrain)**:
```
Client → RPC Request → Server
Server → Validates → Applies Change
Server → Sync → All Clients
```

**Why This Hybrid?**:
- Player movement feels responsive
- Terrain changes are consistent
- Balance between performance and security

### RPC (Remote Procedure Call) System

**How Block Edits Work**:
1. You right-click to place a block
2. Client calls RPC: `receive_place_single_block(position, block_id)`
3. Server receives RPC
4. Server validates: Can this block be placed here?
5. Server places block in its terrain
6. VoxelTerrainMultiplayerSynchronizer automatically sends update to all clients
7. All clients receive and display the change

**Player Position Sync**:
1. Every frame, you broadcast position via RPC
2. Server receives and ignores it (clients handle it)
3. Other clients receive your position
4. Other clients update your avatar position on their screens

**RPC Types**:
- **Reliable**: Must arrive, in order (block edits)
- **Unreliable**: Can be dropped, faster (player position)

### Network Performance Optimization

**Server Optimization**:
- Reduce simulation ranges (grass spreading, water flow)
- Limit player count
- Use faster hardware
- Good internet upload speed (important!)

**Client Optimization**:
- Fast download speed
- Low ping to server
- Stable connection

**Bandwidth Usage**:
- Initial terrain download: Moderate (one-time)
- Ongoing sync: Low (only changes)
- Player positions: Very low (small packets)

## Hosting Best Practices

**For Server Hosts**:

1. **Stable Connection**: Use wired Ethernet, not Wi-Fi
2. **Good Upload Speed**: 5+ Mbps recommended for 10+ players
3. **Keep Server Running**: Don't shut down unexpectedly
4. **Communicate**: Tell players when server will be offline
5. **Backup Worlds**: Copy save files regularly (manual)
6. **Monitor Performance**: Watch for lag, adjust player count if needed

**For Players**:

1. **Respect Host**: They're providing the server for free
2. **Don't Grief**: Don't destroy others' work
3. **Be Patient**: Terrain takes time to load
4. **Coordinate**: Use external chat to communicate
5. **Save Mental Checkpoints**: Server may crash, be prepared

## Local Multiplayer (LAN)

**Same Network Play**:
- Easiest multiplayer setup
- Host uses local IP (192.168.x.x)
- No port forwarding needed
- Low latency, high performance

**Setup**:
1. Host starts server on default port (25000)
2. Host finds their local IP address
3. Clients use host's local IP to connect
4. Everyone plays on same LAN

**Perfect For**:
- LAN parties
- Family/housemate play
- Testing before internet hosting

## Internet Multiplayer (WAN)

**Cross-Internet Play**:
- More complex setup
- Requires port forwarding or UPnP
- Higher latency than LAN
- More rewarding (play with distant friends)

**Setup**:
1. Host configures port forwarding (or enables UPnP)
2. Host finds their public IP address
3. Host shares public IP + port with clients
4. Clients connect using public IP

**Challenges**:
- Dynamic IPs (may change)
- NAT traversal
- Firewall configurations
- ISP restrictions

---

**That's it!** You're now ready to enjoy ScriptVoxel in multiplayer. Happy building with friends!

**Return to**: [Manual Index](./README.md)
