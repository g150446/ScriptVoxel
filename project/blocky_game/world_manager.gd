extends Node

const SAVE_VERSION := 1
const MAX_SAVE_SLOTS := 9
const WORLDS_DIR := "user://worlds/"


signal world_saved(slot: int)
signal world_loaded(slot: int)
signal world_deleted(slot: int)
signal world_created(slot: int)


func get_save_path(slot: int) -> String:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return ""
	return WORLDS_DIR + "slot_" + str(slot).pad_zeros(2) + "/"


func get_empty_slot() -> int:
	for i in range(1, MAX_SAVE_SLOTS + 1):
		var metadata: Dictionary = get_save_metadata(i)
		if not metadata.has("world_name"):
			return i
	return -1


func create_world(slot: int, world_name: String, seed: int) -> Error:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return ERR_INVALID_PARAMETER
	
	var metadata: Dictionary = get_save_metadata(slot)
	if metadata.has("world_name"):
		return ERR_ALREADY_IN_USE
	
	var dir: DirAccess = DirAccess.open(WORLDS_DIR)
	if dir == null:
		dir = DirAccess.open("user://")
		if dir:
			dir.make_dir(WORLDS_DIR)
			dir = DirAccess.open(WORLDS_DIR)
	
	if dir == null:
		return ERR_CANT_CREATE
	
	var slot_path: String = get_save_path(slot)
	if dir.make_dir(slot_path) != OK:
		return ERR_CANT_CREATE
	
	var world_data: Dictionary = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"creation_date": Time.get_datetime_string_from_system(),
		"world_name": world_name,
		"generation": {
			"seed": seed,
			"modified_blocks_file": ""
		},
		"players": [],
		"game_state": {
			"random_ticks_enabled": true,
			"water_simulation_enabled": true
		},
		"playtime_seconds": 0
	}
	
	var config: ConfigFile = ConfigFile.new()
	config.set_value("world", "data", world_data)
	
	var save_path: String = slot_path + "world.json"
	var err: Error = config.save(save_path)
	if err != OK:
		return err
	
	world_created.emit(slot)
	return OK


func save_world(slot: int, world_data: Dictionary) -> Error:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return ERR_INVALID_PARAMETER
	
	var metadata: Dictionary = get_save_metadata(slot)
	if not metadata.has("world_name"):
		return ERR_DOES_NOT_EXIST
	
	var slot_path: String = get_save_path(slot)
	
	world_data["timestamp"] = Time.get_datetime_string_from_system()
	world_data["version"] = SAVE_VERSION
	
	var config: ConfigFile = ConfigFile.new()
	config.set_value("world", "data", world_data)
	
	var save_path: String = slot_path + "world.json"
	var err: Error = config.save(save_path)
	if err != OK:
		return err
	
	world_saved.emit(slot)
	return OK


func load_world(slot: int) -> Dictionary:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return {}
	
	var slot_path: String = get_save_path(slot)
	var save_path: String = slot_path + "world.json"
	
	if not FileAccess.file_exists(save_path):
		return {}
	
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(save_path)
	if err != OK:
		return {}
	
	var world_data: Dictionary = config.get_value("world", "data", {})
	
	if not world_data.has("version"):
		return {}
	
	if world_data.get("version", 0) > SAVE_VERSION:
		return {}
	
	world_loaded.emit(slot)
	return world_data


func delete_world(slot: int) -> Error:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return ERR_INVALID_PARAMETER
	
	var slot_path: String = get_save_path(slot)
	var dir: DirAccess = DirAccess.open(slot_path)
	
	if dir == null:
		return ERR_DOES_NOT_EXIST
	
	var err: Error = dir.list_dir_begin()
	if err != OK:
		return err
	
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	dir = DirAccess.open(WORLDS_DIR)
	err = dir.remove(slot_path)
	if err != OK:
		return err
	
	world_deleted.emit(slot)
	return OK


func get_save_metadata(slot: int) -> Dictionary:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return {}
	
	var slot_path: String = get_save_path(slot)
	var save_path: String = slot_path + "world.json"
	
	if not FileAccess.file_exists(save_path):
		return {}
	
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(save_path)
	if err != OK:
		return {}
	
	var world_data: Dictionary = config.get_value("world", "data", {})
	
	if not world_data.has("version"):
		return {}
	
	if world_data.get("version", 0) > SAVE_VERSION:
		return {}
	
	return {
		"slot": slot,
		"world_name": world_data.get("world_name", "Unknown"),
		"timestamp": world_data.get("timestamp", ""),
		"creation_date": world_data.get("creation_date", ""),
		"playtime_seconds": world_data.get("playtime_seconds", 0),
		"seed": world_data.get("generation", {}).get("seed", 0)
	}


func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	
	for i in range(1, MAX_SAVE_SLOTS + 1):
		var metadata: Dictionary = get_save_metadata(i)
		if metadata.has("world_name"):
			saves.append(metadata)
	
	return saves


func get_world_count() -> int:
	return len(list_saves())
