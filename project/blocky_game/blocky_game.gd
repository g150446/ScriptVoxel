extends Node

const NETWORK_MODE_SINGLEPLAYER = 0
const NETWORK_MODE_CLIENT = 1
const NETWORK_MODE_HOST = 2

const SERVER_PEER_ID = 1

const CharacterScene = preload("./player/character_avatar.tscn")
const RemoteCharacterScene = preload("./player/remote_character.tscn")
const RandomTicks = preload("./random_ticks.gd")
const WaterUpdater = preload("./water.gd")
const ProgrammableAgentScene = preload("./agent/programmable_agent.tscn")
const CodeEditorUIScene = preload("./agent/code_editor_ui.tscn")

@onready var _light : DirectionalLight3D = $DirectionalLight3D
@onready var _terrain : VoxelTerrain = $VoxelTerrain
@onready var _characters_container : Node = $Players

var _network_mode := NETWORK_MODE_SINGLEPLAYER
var _ip := ""
var _port := -1
var _code_editor_ui : CanvasLayer = null
var _open_editor_button : Button = null

# Initially needed because when running multiple instances in the editor, Godot is mixing up the
# outputs of server and clients in the same output console...
# 2025/05/01: had to prefix because Godot now has a Logger class
class BG_Logger:
	var prefix := ""
	
	func debug(msg: String):
		print(prefix, msg)

	func error(msg: String):
		push_error(prefix, msg)


var _logger := BG_Logger.new()


func get_terrain() -> VoxelTerrain:
	return _terrain


func get_network_mode() -> int:
	return _network_mode


func set_network_mode(mode: int):
	_network_mode = mode


func set_ip(ip: String):
	_ip = ip


func set_port(port: int):
	_port = port


func _ready():
	if _network_mode == NETWORK_MODE_HOST:
		_logger.prefix = "Server: "
		
		# Configure multiplayer API as server
		var peer := ENetMultiplayerPeer.new()
		var err := peer.create_server(_port, 32, 0, 0, 0)
		if err != OK:
			_logger.error(str("Failed to create server peer, error ", err))
			return
		var mp := get_tree().get_multiplayer()
		mp.peer_connected.connect(_on_peer_connected)
		mp.peer_disconnected.connect(_on_peer_disconnected)
		mp.multiplayer_peer = peer

		# Configure VoxelTerrain as server
		var synchronizer := VoxelTerrainMultiplayerSynchronizer.new()
		_terrain.add_child(synchronizer)

	elif _network_mode == NETWORK_MODE_CLIENT:
		_logger.prefix = "Client: "
		
		# Configure multiplayer API as client
		var peer := ENetMultiplayerPeer.new()
		var err := peer.create_client(_ip, _port, 0, 0, 0, 0)
		if err != OK:
			_logger.error(str("Failed to create client peer, error ", err))
			return
		var mp := get_tree().get_multiplayer()
		mp.connected_to_server.connect(_on_connected_to_server)
		mp.connection_failed.connect(_on_connection_failed)
		mp.peer_connected.connect(_on_peer_connected)
		mp.peer_disconnected.connect(_on_peer_disconnected)
		mp.server_disconnected.connect(_on_server_disconnected)
		mp.multiplayer_peer = peer

		# Configure VoxelTerrain as client
		var synchronizer := VoxelTerrainMultiplayerSynchronizer.new()
		_terrain.add_child(synchronizer)
		_terrain.stream = null

	if _network_mode == NETWORK_MODE_HOST or _network_mode == NETWORK_MODE_SINGLEPLAYER:
		add_child(RandomTicks.new())

		var water_updater := WaterUpdater.new()
		# Current code grabs this node by name, so must be named for now...
		water_updater.name = "Water"
		add_child(water_updater)

		_spawn_character(SERVER_PEER_ID, Vector3(0, 64, 0))

		# SINGLEPLAYER ONLY: Spawn programmable agent and code editor
		if _network_mode == NETWORK_MODE_SINGLEPLAYER:
			_spawn_programmable_agent(Vector3(5, 64, 0))
			_setup_code_editor()


func _on_connected_to_server():
	_logger.debug("connected to server")


func _on_connection_failed():
	_logger.debug("Connection failed")


func _on_peer_connected(new_peer_id: int):
	_logger.debug(str("peer ", new_peer_id, " connected"))
	
	if _network_mode == NETWORK_MODE_HOST:
		# Spawn own character
		var new_character = _spawn_remote_character(new_peer_id, Vector3(0, 64, 0))
		_logger.debug(str("Sending own character to ", new_peer_id))
		rpc_id(new_peer_id, &"receive_own_character", new_peer_id, new_character.position)
		
		# Send existing characters to the new peer
		for i in _characters_container.get_child_count():
			var character := _characters_container.get_child(i)
			if character != new_character:
				# TODO This sucks, find a better way to get peer ID from character
				var peer_id := character.name.to_int()
				_logger.debug(str("Sending remote character ", peer_id, " to ", new_peer_id))
				rpc_id(new_peer_id, &"receive_remote_character", peer_id, character.position)
		
		# Send new character to other clients
		var peers := get_tree().get_multiplayer().get_peers()
		for peer_id in peers:
			if peer_id != new_peer_id:
				_logger.debug(str("Sending remote character ", peer_id, " to other ", new_peer_id))
				rpc_id(peer_id, &"receive_remote_character", new_peer_id, new_character.position)


func _on_peer_disconnected(peer_id: int):
	_logger.debug(str("Peer ", peer_id, " disconnected"))
	# Remove character
	var node_name = str(peer_id)
	if _characters_container.has_node(node_name):
		var character = _characters_container.get_node(node_name)
		character.queue_free()
	else:
		_logger.debug(str("Character ", peer_id, " not found"))


func _on_server_disconnected():
	_logger.debug("Server disconnected")
	# TODO Go back to main menu, the game will spam RPC errors


func _unhandled_input(event: InputEvent):
	# TODO Make a pause menu with options?
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_L:
				# Toggle shadows
				_light.shadow_enabled = not _light.shadow_enabled
			elif event.keycode == KEY_F4:
				# Toggle Python code editor (singleplayer only)
				_toggle_code_editor()
#			if event.keycode == KEY_KP_0:
#				# Force save
#				_save_world()


func _notification(what: int):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			if _network_mode == NETWORK_MODE_HOST or _network_mode == NETWORK_MODE_SINGLEPLAYER:
				# Save game when the user closes the window
				_save_world()


func _save_world():
	_terrain.save_modified_blocks()


func _spawn_character(peer_id: int, pos: Vector3) -> Node3D:
	var node_name = str(peer_id)
	if _characters_container.has_node(node_name):
		_logger.error(str("Character ", peer_id, " already created"))
		return null
	var character : Node3D = CharacterScene.instantiate()
	character.name = node_name
	character.position = pos
	character.terrain = get_terrain().get_path()
	_characters_container.add_child(character)
	return character


func _spawn_remote_character(peer_id: int, pos: Vector3) -> Node3D:
	var node_name = str(peer_id)
	if _characters_container.has_node(node_name):
		_logger.debug(str("Remote character ", peer_id, " already created"))
		return null
	var character := RemoteCharacterScene.instantiate()
	character.position = pos
	character.name = str(peer_id)
	if _network_mode == NETWORK_MODE_HOST:
		# The server is authoritative on voxel terrain, so it needs a viewer to load terrain
		# around each character. We'll also tell which peer ID it uses, so the terrain knows which
		# peer to send the voxels to.
		# TODO Make a specific scene?
		var viewer := VoxelViewer.new()
		viewer.view_distance = 128
		viewer.requires_visuals = false
		viewer.requires_collisions = false
		viewer.set_network_peer_id(peer_id)
		viewer.set_requires_data_block_notifications(true)
		#viewer.requires_data_block_notifications = true
		character.add_child(viewer)
	_characters_container.add_child(character)
	return character


@rpc("authority", "call_remote", "reliable", 0)
func receive_remote_character(peer_id: int, pos: Vector3):
	_logger.debug(str("receive_remote_character ", peer_id, " at ", pos))
	_spawn_remote_character(peer_id, pos)


@rpc("authority", "call_remote", "reliable", 0)
func receive_own_character(peer_id: int, pos: Vector3):
	_logger.debug(str("receive_own_character ", peer_id, " at ", pos))
	_spawn_character(peer_id, pos)


func _spawn_programmable_agent(pos: Vector3):
	"""Spawn the programmable Python agent (singleplayer only)"""
	var agent = ProgrammableAgentScene.instantiate()
	agent.name = "ProgrammableAgent"
	agent.position = pos

	# Set terrain reference for controller and interaction
	var controller = agent.get_node("AgentController")
	if controller:
		controller.terrain = _terrain.get_path()

	var interaction = agent.get_node("AgentInteraction")
	if interaction:
		interaction.terrain_path = _terrain.get_path()

	_characters_container.add_child(agent)
	_logger.debug("Spawned programmable agent at " + str(pos))


func _setup_code_editor():
	"""Setup the in-game Python code editor (singleplayer only)"""
	_code_editor_ui = CodeEditorUIScene.instantiate()
	add_child(_code_editor_ui)

	# Connect spawn agent signal
	_code_editor_ui.spawn_agent_requested.connect(_on_spawn_agent_requested)

	# Wait for the editor UI to be ready, then connect agent API
	await get_tree().process_frame

	# Get agent reference and connect to editor
	var agent = _characters_container.get_node_or_null("ProgrammableAgent")
	if agent:
		var agent_api = agent.get_node_or_null("AgentAPI")
		if agent_api:
			_code_editor_ui.set_agent_api(agent_api)
			_logger.debug("Agent API connected to editor")
		else:
			_logger.error("AgentAPI node not found")
	else:
		_logger.error("ProgrammableAgent not found")

	# Create "Open Python Editor" button
	_create_editor_button()

	# Initially hidden
	_code_editor_ui.visible = false
	_logger.debug("Code editor UI initialized")


func _create_editor_button():
	"""Create a button to open the Python editor"""
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # Put it on top of other UI
	add_child(canvas_layer)

	_open_editor_button = Button.new()
	_open_editor_button.text = "Python Editor (F4)"
	_open_editor_button.custom_minimum_size = Vector2(200, 50)

	# Anchor to top-left corner
	_open_editor_button.anchor_left = 0.0
	_open_editor_button.anchor_top = 0.0
	_open_editor_button.anchor_right = 0.0
	_open_editor_button.anchor_bottom = 0.0
	_open_editor_button.offset_left = 10
	_open_editor_button.offset_top = 10
	_open_editor_button.offset_right = 210
	_open_editor_button.offset_bottom = 60

	# Style the button with a visible background
	_open_editor_button.add_theme_font_size_override("font_size", 18)

	# Create a simple StyleBox for visibility
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.3, 0.4, 0.9)
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.5, 0.7, 1.0, 1.0)
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	_open_editor_button.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.4, 0.5, 0.9)
	style_hover.border_width_left = 2
	style_hover.border_width_top = 2
	style_hover.border_width_right = 2
	style_hover.border_width_bottom = 2
	style_hover.border_color = Color(0.6, 0.8, 1.0, 1.0)
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	_open_editor_button.add_theme_stylebox_override("hover", style_hover)

	_open_editor_button.pressed.connect(_toggle_code_editor)
	canvas_layer.add_child(_open_editor_button)
	_logger.debug("Python editor button created")


func _toggle_code_editor():
	"""Toggle the visibility of the Python code editor"""
	if _code_editor_ui != null:
		_code_editor_ui.visible = not _code_editor_ui.visible

		# Get player character (the controller script is on the player node itself)
		var player = _characters_container.get_node_or_null("1")  # SERVER_PEER_ID

		if _code_editor_ui.visible:
			# Show editor, release mouse, disable player input
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if player and "input_enabled" in player:
				player.input_enabled = false
				print("CodeEditor: Disabled player input")
			else:
				print("CodeEditor: WARNING - Could not disable player input! Player found: ", player != null)
		else:
			# Hide editor, capture mouse for game, enable player input
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if player and "input_enabled" in player:
				player.input_enabled = true
				print("CodeEditor: Enabled player input")
			else:
				print("CodeEditor: WARNING - Could not enable player input! Player found: ", player != null)


func _on_spawn_agent_requested():
	"""Respawn the programmable agent at player position or default location"""
	# Remove existing agent if any
	var existing_agent = _characters_container.get_node_or_null("ProgrammableAgent")
	if existing_agent:
		existing_agent.queue_free()
		await get_tree().process_frame  # Wait for deletion

	# Get player position or use default
	var spawn_pos = Vector3(5, 64, 0)
	var player = _characters_container.get_node_or_null("1")  # SERVER_PEER_ID
	if player:
		spawn_pos = player.global_position + Vector3(3, 0, 0)  # Spawn 3 blocks to the right

	# Spawn new agent
	_spawn_programmable_agent(spawn_pos)

	# Wait for agent to be ready
	await get_tree().process_frame

	# Reconnect to editor
	if _code_editor_ui:
		var agent = _characters_container.get_node_or_null("ProgrammableAgent")
		if agent:
			var agent_api = agent.get_node_or_null("AgentAPI")
			if agent_api:
				_code_editor_ui.set_agent_api(agent_api)
				_logger.debug("Agent respawned and reconnected to editor")
			else:
				_logger.error("AgentAPI not found after spawning")
		else:
			_logger.error("ProgrammableAgent not found after spawning")
