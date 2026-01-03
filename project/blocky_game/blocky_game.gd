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
const WorldManager = preload("./world_manager.gd")
const PauseMenuScene = preload("./pause_menu.tscn")
const SaveLoadDialogScene = preload("./save_load_dialog.tscn")

@onready var _light : DirectionalLight3D = $DirectionalLight3D
@onready var _terrain : VoxelTerrain = $VoxelTerrain
@onready var _characters_container : Node = $Players

var _network_mode: int = NETWORK_MODE_SINGLEPLAYER
var _ip: String = ""
var _port: int = -1
var _code_editor_ui: CanvasLayer = null
var _open_editor_button: Button = null

var _world_manager: WorldManager = null
var _current_save_slot: int = 0
var _world_name: String = ""
var _pause_menu: Control = null

# Initially needed because when running multiple instances in the editor, Godot is mixing up the
# outputs of server and clients in the same output console...
# 2025/05/01: had to prefix because Godot now has a Logger class
class BG_Logger:
	var prefix: String = ""

	func debug(msg: String):
		print(prefix, msg)

	func error(msg: String):
		push_error(prefix + msg)

var _logger: BG_Logger = BG_Logger.new()


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
	_world_manager = WorldManager.new()
	add_child(_world_manager)
	
	if _network_mode == NETWORK_MODE_SINGLEPLAYER:
		_setup_pause_menu()
	
	if _network_mode == NETWORK_MODE_HOST:
		_logger.prefix = "Server: "
		
		# Configure multiplayer API as server
		var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
		var err: Error = peer.create_server(_port, 32, 0, 0, 0)
		if err != OK:
			_logger.error(str("Failed to create server peer, error ", err))
			return
		var mp: MultiplayerAPI = get_tree().get_multiplayer()
		mp.peer_connected.connect(_on_peer_connected)
		mp.peer_disconnected.connect(_on_peer_disconnected)
		mp.multiplayer_peer = peer

		# Configure VoxelTerrain as server
		var synchronizer: VoxelTerrainMultiplayerSynchronizer = VoxelTerrainMultiplayerSynchronizer.new()
		_terrain.add_child(synchronizer)

	elif _network_mode == NETWORK_MODE_CLIENT:
		_logger.prefix = "Client: "
		
		# Configure multiplayer API as client
		var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
		var err: Error = peer.create_client(_ip, _port, 0, 0, 0, 0)
		if err != OK:
			_logger.error(str("Failed to create client peer, error ", err))
			return
		var mp: MultiplayerAPI = get_tree().get_multiplayer()
		mp.connected_to_server.connect(_on_connected_to_server)
		mp.connection_failed.connect(_on_connection_failed)
		mp.peer_connected.connect(_on_peer_connected)
		mp.peer_disconnected.connect(_on_peer_disconnected)
		mp.server_disconnected.connect(_on_server_disconnected)
		mp.multiplayer_peer = peer

		# Configure VoxelTerrain as client
		var synchronizer: VoxelTerrainMultiplayerSynchronizer = VoxelTerrainMultiplayerSynchronizer.new()
		_terrain.add_child(synchronizer)
		_terrain.stream = null

	if _network_mode == NETWORK_MODE_HOST or _network_mode == NETWORK_MODE_SINGLEPLAYER:
		add_child(RandomTicks.new())

		var water_updater: WaterUpdater = WaterUpdater.new()
		# Current code grabs this node by name, so must be named for now...
		water_updater.name = "Water"
		add_child(water_updater)

		# キャラクタースポーンは_initialize_gameplay()で実行されます


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
			var character: Node3D = _characters_container.get_child(i)
			if character != new_character:
				# TODO This sucks, find a better way to get peer ID from character
				var peer_id: int = character.name.to_int()
				_logger.debug(str("Sending remote character ", peer_id, " to ", new_peer_id))
				rpc_id(new_peer_id, &"receive_remote_character", peer_id, character.position)
		
		# Send new character to other clients
		var peers: Array = get_tree().get_multiplayer().get_peers()
		for peer_id in peers:
			if peer_id != new_peer_id:
				_logger.debug(str("Sending remote character ", peer_id, " to other ", new_peer_id))
				rpc_id(peer_id, &"receive_remote_character", new_peer_id, new_character.position)


func _on_peer_disconnected(peer_id: int):
	_logger.debug(str("Peer ", peer_id, " disconnected"))
	# Remove character
	var node_name: String = str(peer_id)
	if _characters_container.has_node(node_name):
		var character: Node3D = _characters_container.get_node(node_name)
		character.queue_free()
	else:
		_logger.debug(str("Character ", peer_id, " not found"))


func _on_server_disconnected():
	_logger.debug("Server disconnected")
	# TODO Go back to main menu, the game will spam RPC errors


func _unhandled_input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_ESCAPE:
				_show_pause_menu()
			elif event.keycode == KEY_L:
				# Toggle shadows
				_light.shadow_enabled = not _light.shadow_enabled
			elif event.keycode == KEY_F4:
				# Toggle Python code editor (singleplayer only)
				_toggle_code_editor()
			elif event.keycode == KEY_F5:
				# Quick save
				quick_save()
			elif event.keycode == KEY_F9:
				# Quick load
				quick_load()


func _notification(what: int):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			if _network_mode == NETWORK_MODE_HOST or _network_mode == NETWORK_MODE_SINGLEPLAYER:
				# Save game when the user closes the window
				_save_world()


func _save_world():
	if _current_save_slot == 0:
		_terrain.save_modified_blocks()
		return
	
	if _network_mode == NETWORK_MODE_CLIENT:
		_logger.error("Cannot save world in multiplayer client mode")
		return
	
	var world_data: Dictionary = _collect_world_data()
	var err: Error = _world_manager.save_world(_current_save_slot, world_data)
	if err != OK:
		_logger.error(str("Failed to save world: ", error_string(err)))
	else:
		_logger.debug(str("World saved to slot ", _current_save_slot))


func _collect_world_data() -> Dictionary:
	var players_data: Array = []
	
	for i in _characters_container.get_child_count():
		var character: Node3D = _characters_container.get_child(i)
		var player_data: Dictionary = {
			"id": int(character.name),
			"position": {
				"x": character.position.x,
				"y": character.position.y,
				"z": character.position.z
			},
			"rotation": {"y": character.rotation.y}
		}
		
		if character.has_method("get_inventory"):
			var inventory_data: Variant = character.get_inventory()
			if inventory_data:
				player_data["inventory"] = inventory_data
		
		players_data.append(player_data)
	
	var generator_seed: int = 0
	var generator: VoxelGeneratorScript = _terrain.get_generator()
	if generator and "set_world_seed" in generator:
		if generator._heightmap_noise:
			generator_seed = generator._heightmap_noise.seed
	
	var existing_data: Dictionary = {}
	if _current_save_slot > 0:
		existing_data = _world_manager.load_world(_current_save_slot)
	
	return {
		"world_name": _world_name,
		"generation": {
			"seed": generator_seed,
			"modified_blocks_file": ""
		},
		"players": players_data,
		"game_state": {
			"random_ticks_enabled": true,
			"water_simulation_enabled": true
		},
		"playtime_seconds": existing_data.get("playtime_seconds", 0)
	}


func _clear_world_state():
	"""既存のキャラクターやエンティティをクリアする"""
	# 既存のキャラクターをすべて削除
	for child in _characters_container.get_children():
		child.queue_free()

	# Godotがノードを完全に削除するまで待つ
	await get_tree().process_frame

	_logger.debug("World state cleared")


func _initialize_gameplay():
	"""ワールド作成後またはロード後に呼ばれる初期化処理"""
	# キャラクタースポーン
	var character: Node3D = _spawn_character(SERVER_PEER_ID, Vector3(0, 64, 0))
	if character == null:
		_logger.error("Failed to spawn player character")
		return

	# シングルプレイヤーのみ: Python agentとコードエディタ
	if _network_mode == NETWORK_MODE_SINGLEPLAYER:
		_spawn_programmable_agent(Vector3(5, 64, 0))
		_setup_code_editor()

	_logger.debug("Gameplay initialized successfully")


func start_new_world(slot: int, world_name: String, seed: int):
	_current_save_slot = slot
	_world_name = world_name

	# ジェネレーターのシード設定
	var generator: VoxelGeneratorScript = _terrain.get_generator()
	if generator and "set_world_seed" in generator:
		generator.set_world_seed(seed)

	# ゲームプレイ要素の初期化
	_initialize_gameplay()

func load_world_save(slot: int):
	var world_data: Dictionary = _world_manager.load_world(slot)
	if not world_data.has("world_name"):
		_logger.error(str("Failed to load world from slot ", slot))
		return

	# 既存のワールド状態をクリア
	await _clear_world_state()

	_current_save_slot = slot
	_world_name = world_data.get("world_name", "")

	# ジェネレーターシード設定
	var generator_seed: int = world_data.get("generation", {}).get("seed", 0)
	var generator: VoxelGeneratorScript = _terrain.get_generator()
	if generator and "set_world_seed" in generator:
		generator.set_world_seed(generator_seed)

	# プレイヤーデータから復元
	var players_loaded: int = 0
	for player_data in world_data.get("players", []):
		var player_id: int = player_data.get("id", 1)
		var pos: Vector3 = Vector3(
			player_data.get("position", {}).get("x", 0),
			player_data.get("position", {}).get("y", 64),
			player_data.get("position", {}).get("z", 0)
		)
		var character: Node3D = _spawn_character(player_id, pos)

		if character == null:
			_logger.error(str("Failed to spawn character ", player_id))
			continue

		players_loaded += 1

		# インベントリ復元
		if player_data.has("inventory"):
			var inventory: Node = character.get_node_or_null("Inventory")
			if inventory and inventory.has_method("clear"):
				inventory.clear()
			# TODO: Restore inventory items once inventory serialization is implemented

	# プレイヤーがロードされなかった場合はデフォルトスポーン
	if players_loaded == 0:
		_logger.debug("No player data found, spawning at default position")
		_initialize_gameplay()
	else:
		# シングルプレイヤーのみ: Python agentとコードエディタ
		if _network_mode == NETWORK_MODE_SINGLEPLAYER:
			_spawn_programmable_agent(Vector3(5, 64, 0))
			_setup_code_editor()

	_logger.debug(str("World loaded from slot ", slot, ", ", players_loaded, " player(s) restored"))


func quick_save():
	if _current_save_slot == 0:
		_logger.error("No save slot selected")
		return
	
	_save_world()


func quick_load():
	if _current_save_slot == 0:
		_logger.error("No save slot selected")
		return
	
	load_world_save(_current_save_slot)


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
		_logger.error(str("Character ", peer_id, " already created"))
		return null
	var character: Node3D = RemoteCharacterScene.instantiate()
	character.position = pos
	character.name = str(peer_id)
	if _network_mode == NETWORK_MODE_HOST:
		# The server is authoritative on voxel terrain, so it needs a viewer to load terrain
		# around each character. We'll also tell which peer ID it uses, so the terrain knows which
		# peer to send the voxels to.
		# TODO Make a specific scene?
		var viewer: VoxelViewer = VoxelViewer.new()
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
	var existing_agent: Node3D = _characters_container.get_node_or_null("ProgrammableAgent")
	if existing_agent:
		existing_agent.queue_free()
		await get_tree().process_frame  # Wait for deletion

	# Get player position or use default
	var spawn_pos: Vector3 = Vector3(5, 64, 0)
	var player: Node3D = _characters_container.get_node_or_null("1")  # SERVER_PEER_ID
	if player:
		spawn_pos = player.global_position + Vector3(3, 0, 0)  # Spawn 3 blocks to the right

	# Spawn new agent
	_spawn_programmable_agent(spawn_pos)

	# Wait for agent to be ready
	await get_tree().process_frame

	# Reconnect to editor
	if _code_editor_ui:
		var agent: Node3D = _characters_container.get_node_or_null("ProgrammableAgent")
		if agent:
			var agent_api: Node = agent.get_node_or_null("AgentAPI")
			if agent_api:
				_code_editor_ui.set_agent_api(agent_api)
				_logger.debug("Agent respawned and reconnected to editor")
			else:
				_logger.error("AgentAPI not found after spawning")
		else:
			_logger.error("ProgrammableAgent not found after spawning")


func _show_pause_menu():
	if _pause_menu == null:
		_pause_menu = PauseMenuScene.instantiate()
		add_child(_pause_menu)
		_pause_menu.resume_requested.connect(_on_pause_resume)
		_pause_menu.save_requested.connect(_on_pause_save)
		_pause_menu.load_requested.connect(_on_pause_load)
		_pause_menu.main_menu_requested.connect(_on_pause_main_menu)
		_pause_menu.quit_requested.connect(_on_pause_quit)
	
	_pause_menu.show_menu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var player: Node3D = _characters_container.get_node_or_null("1")
	if player and "input_enabled" in player:
		player.input_enabled = false


func _on_pause_resume():
	_pause_menu.hide_menu()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var player: Node3D = _characters_container.get_node_or_null("1")
	if player and "input_enabled" in player:
		player.input_enabled = true


func _on_pause_save():
	if _current_save_slot > 0:
		quick_save()
	else:
		push_warning("No save slot selected. Please save to a specific slot from the load menu.")


func _on_pause_load():
	var save_dialog: Control = SaveLoadDialogScene.instantiate()
	add_child(save_dialog)
	save_dialog.set_world_manager(_world_manager)
	save_dialog.load_requested.connect(_on_load_dialog_load_requested)


func _on_pause_main_menu():
	get_tree().change_scene_to_file("res://../project/blocky_game/main.tscn")


func _on_pause_quit():
	get_tree().quit()


func _on_load_dialog_load_requested(slot: int):
	load_world_save(slot)


func _setup_pause_menu():
	if _network_mode == NETWORK_MODE_SINGLEPLAYER:
		_pause_menu = PauseMenuScene.instantiate()
		add_child(_pause_menu)
		_pause_menu.resume_requested.connect(_on_pause_resume)
		_pause_menu.save_requested.connect(_on_pause_save)
		_pause_menu.load_requested.connect(_on_pause_load)
		_pause_menu.main_menu_requested.connect(_on_pause_main_menu)
		_pause_menu.quit_requested.connect(_on_pause_quit)
		_pause_menu.visible = false
