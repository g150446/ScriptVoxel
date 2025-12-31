extends Control

signal load_requested(slot: int)
signal delete_requested(slot: int)

@onready var _world_list: ItemList = $PanelContainer/VBoxContainer/WorldList
@onready var _load_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/LoadButton
@onready var _delete_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/DeleteButton
@onready var _back_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/BackButton

var _world_manager = null
var _selected_slot: int = 0


func _ready():
	_load_button.pressed.connect(_on_load_pressed)
	_delete_button.pressed.connect(_on_delete_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_world_list.item_selected.connect(_on_world_selected)

	_update_button_states()


func set_world_manager(world_manager):
	_world_manager = world_manager
	_populate_world_list()


func _populate_world_list():
	_world_list.clear()

	if _world_manager == null:
		return

	var worlds: Dictionary = _world_manager.get_all_worlds()

	for slot in worlds.keys():
		var world_info: Dictionary = worlds[slot]
		var display_text: String = "Slot %d: %s" % [slot, world_info["name"]]
		_world_list.add_item(display_text)
		_world_list.set_item_metadata(_world_list.item_count - 1, slot)


func _on_world_selected(index: int):
	_selected_slot = _world_list.get_item_metadata(index)
	_update_button_states()


func _update_button_states():
	var has_selection: bool = _selected_slot > 0
	_load_button.disabled = not has_selection
	_delete_button.disabled = not has_selection


func _on_load_pressed():
	if _selected_slot > 0:
		load_requested.emit(_selected_slot)
		queue_free()


func _on_delete_pressed():
	if _selected_slot > 0 and _world_manager != null:
		_world_manager.delete_world(_selected_slot)
		_selected_slot = 0
		_populate_world_list()
		_update_button_states()


func _on_back_pressed():
	queue_free()
