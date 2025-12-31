extends Control

signal world_created(slot: int, world_name: String, seed: int)

@onready var _world_name_line_edit: LineEdit = $PanelContainer/VBoxContainer/WorldNameLineEdit
@onready var _seed_spin_box: SpinBox = $PanelContainer/VBoxContainer/SeedHBox/SeedSpinBox
@onready var _random_seed_button: Button = $PanelContainer/VBoxContainer/SeedHBox/RandomSeedButton
@onready var _slot_spin_box: SpinBox = $PanelContainer/VBoxContainer/SlotHBox/SlotSpinBox
@onready var _create_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/CreateButton
@onready var _cancel_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/CancelButton


func _ready():
	_random_seed_button.pressed.connect(_on_random_seed_pressed)
	_create_button.pressed.connect(_on_create_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)

	_randomize_seed()
	_world_name_line_edit.text = "My World"

	var auto_slot: int = _find_empty_slot()
	if auto_slot > 0:
		_slot_spin_box.value = auto_slot


func _randomize_seed():
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_seed_spin_box.value = abs(rng.randi())


func _find_empty_slot() -> int:
	var dir: DirAccess = DirAccess.open("user://worlds/")
	if dir == null:
		return 1

	var slot_path: String = "slot_" + str(1).pad_zeros(2) + "/"

	for i in range(1, 10):
		slot_path = "slot_" + str(i).pad_zeros(2) + "/"
		if not dir.dir_exists(slot_path):
			return i

	return 1


func _on_random_seed_pressed():
	_randomize_seed()


func _on_create_pressed():
	var world_name: String = _world_name_line_edit.text.strip_edges()
	if world_name.is_empty():
		world_name = "My World"

	var seed: int = int(_seed_spin_box.value)
	var slot: int = int(_slot_spin_box.value)

	world_created.emit(slot, world_name, seed)
	queue_free()


func _on_cancel_pressed():
	queue_free()
