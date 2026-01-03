extends Node

const BlockyGame = preload("./blocky_game.gd")
const BlockyGameScene = preload("./blocky_game.tscn")
const MainMenu = preload("./main_menu.gd")
const UPNPHelper = preload("./upnp_helper.gd")
const NewWorldDialogScene = preload("./new_world_dialog.tscn")
const SaveLoadDialogScene = preload("./save_load_dialog.tscn")
const WorldManager = preload("./world_manager.gd")

@onready var _main_menu : MainMenu = $MainMenu

var _game : BlockyGame
var _upnp_helper : UPNPHelper
var _world_manager : WorldManager

class MG_Logger:
	var prefix: String = ""

	func debug(msg: String):
		print(prefix, msg)

	func error(msg: String):
		push_error(prefix + msg)

var _logger: MG_Logger = MG_Logger.new()


func _on_main_menu_singleplayer_requested():
	_game = BlockyGameScene.instantiate()
	_game.set_network_mode(BlockyGame.NETWORK_MODE_SINGLEPLAYER)
	add_child(_game)

	# クイックプレイ: セーブスロットなし、デフォルトシード
	# _ready()ではキャラクターがスポーンされないため、明示的に初期化を呼ぶ
	_game.start_new_world(0, "Quick Play", 0)

	_main_menu.hide()
	_logger.debug("Quick started new game (no save slot)")


func _on_main_menu_connect_to_server_requested(ip: String, port: int):
	_game = BlockyGameScene.instantiate()
	_game.set_ip(ip)
	_game.set_port(port)
	_game.set_network_mode(BlockyGame.NETWORK_MODE_CLIENT)
	add_child(_game)

	_main_menu.hide()

	get_viewport().get_window().title = "Client"


func _on_main_menu_host_server_requested(port: int):
	if _upnp_helper != null and not _upnp_helper.is_setup():
		_upnp_helper.setup(port, PackedStringArray(["UDP"]), "VoxelBlockyGame", 20 * 60)

	_game = BlockyGameScene.instantiate()
	_game.set_port(port)
	_game.set_network_mode(BlockyGame.NETWORK_MODE_HOST)
	add_child(_game)

	# HOSTモードでもワールド初期化が必要
	# デフォルトのシードでワールドを作成
	_game.start_new_world(0, "Multiplayer Server", 0)

	_main_menu.hide()

	get_viewport().get_window().title = "Server"


func _on_main_menu_upnp_toggled(pressed: bool):
	if pressed:
		if _upnp_helper == null:
			_upnp_helper = UPNPHelper.new()
			add_child(_upnp_helper)
	else:
		if _upnp_helper != null:
			_upnp_helper.queue_free()
			_upnp_helper = null


func _on_main_menu_new_world_requested():
	if _world_manager == null:
		_world_manager = WorldManager.new()
		add_child(_world_manager)
	
	var new_world_dialog: Control = NewWorldDialogScene.instantiate()
	add_child(new_world_dialog)
	new_world_dialog.world_created.connect(_on_new_world_created)


func _on_new_world_created(slot: int, world_name: String, seed: int):
	var err: Error = _world_manager.create_world(slot, world_name, seed)
	if err != OK:
		push_error(str("Failed to create world: ", error_string(err)))
		return
	
	_start_new_game(slot, world_name, seed)


func _start_new_game(slot: int, world_name: String, seed: int):
	if _game != null:
		_game.queue_free()
	
	_game = BlockyGameScene.instantiate()
	_game.set_network_mode(BlockyGame.NETWORK_MODE_SINGLEPLAYER)
	add_child(_game)
	
	_game.start_new_world(slot, world_name, seed)
	
	_main_menu.hide()


func _on_main_menu_load_world_requested():
	if _world_manager == null:
		_world_manager = WorldManager.new()
		add_child(_world_manager)
	
	var save_load_dialog: Control = SaveLoadDialogScene.instantiate()
	add_child(save_load_dialog)
	save_load_dialog.set_world_manager(_world_manager)
	save_load_dialog.load_requested.connect(_on_load_world_requested)


func _on_load_world_requested(slot: int):
	if _game != null:
		_game.queue_free()
	
	_game = BlockyGameScene.instantiate()
	_game.set_network_mode(BlockyGame.NETWORK_MODE_SINGLEPLAYER)
	add_child(_game)
	
	_game.load_world_save(slot)
	
	_main_menu.hide()
