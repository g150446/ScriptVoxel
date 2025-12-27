extends Node

# Agent block interaction - similar to avatar_interaction.gd but for programmatic control

const InteractionCommon = preload("res://blocky_game/player/interaction_common.gd")
const Blocks = preload("res://blocky_game/blocks/blocks.gd")

@export var terrain_path : NodePath

var _terrain : VoxelTerrain = null
var _terrain_tool : VoxelTool = null
var _block_types : Blocks = null
var _water_updater = null


func _ready():
	if has_node(terrain_path):
		_terrain = get_node(terrain_path)
		_terrain_tool = _terrain.get_voxel_tool()
		_terrain_tool.channel = VoxelBuffer.CHANNEL_TYPE

	# Get block registry
	var game_node = get_tree().root.get_node("Main/Game")
	if game_node:
		_block_types = game_node.get_node("Blocks")
		var water = game_node.get_node_or_null("Water")
		if water:
			_water_updater = water


func _get_agent_position() -> Vector3:
	return get_parent().global_position + Vector3(0, 0.5, 0)  # Eye level


func _get_agent_forward() -> Vector3:
	var controller = get_parent().get_node("AgentController")
	if controller:
		return controller.get_forward_direction()
	return Vector3.FORWARD


func _raycast_forward(distance: float = 3.0) -> VoxelRaycastResult:
	"""Raycast in the direction agent is facing"""
	var origin = _get_agent_position()
	var direction = _get_agent_forward()
	return _terrain_tool.raycast(origin, direction, distance)


func place_block(block_name: String) -> bool:
	"""Place a block in front of the agent"""
	if not _terrain_tool or not _block_types:
		push_error("Agent interaction not ready")
		return false

	var hit = _raycast_forward()
	if hit == null:
		return false  # Nothing to place on

	var pos = hit.previous_position
	var block = _block_types.get_block_by_name(block_name)
	if block == null:
		push_error("Unknown block: " + block_name)
		return false

	var block_id = block.base_info.id
	var look_dir = _get_agent_forward()

	InteractionCommon.place_single_block(
		_terrain_tool, pos, look_dir,
		block_id, _block_types, _water_updater
	)
	return true


func break_block() -> bool:
	"""Break the block the agent is looking at"""
	if not _terrain_tool:
		return false

	var hit = _raycast_forward()
	if hit == null:
		return false  # Nothing to break

	_terrain_tool.value = 0  # Air
	_terrain_tool.do_point(hit.position)

	if _water_updater:
		_water_updater.schedule(hit.position)

	return true


func inspect_block() -> Dictionary:
	"""Get info about the block in front of the agent"""
	if not _terrain_tool or not _block_types:
		return {"exists": false}

	var hit = _raycast_forward()
	if hit == null:
		return {"exists": false}

	var voxel_id = _terrain_tool.get_voxel(hit.position)
	var block = _block_types.get_block_by_voxel_id(voxel_id)

	if block:
		return {
			"exists": true,
			"name": block.base_info.name,
			"position": hit.position,
			"voxel_id": voxel_id
		}
	else:
		return {
			"exists": true,
			"name": "unknown",
			"position": hit.position,
			"voxel_id": voxel_id
		}


func raycast(direction: Vector3, distance: float = 10.0) -> VoxelRaycastResult:
	"""Perform raycast from agent position in specified direction"""
	if not _terrain_tool:
		return null

	var origin = _get_agent_position()
	return _terrain_tool.raycast(origin, direction.normalized(), distance)


func detect_nearby_blocks(radius: int = 3) -> Array:
	"""Detect all non-air blocks in a radius around the agent"""
	if not _terrain_tool or not _block_types:
		return []

	var agent_pos = get_parent().global_position
	var blocks_found = []

	# Scan a cube around the agent
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				var pos = agent_pos + Vector3(x, y, z)
				var voxel_id = _terrain_tool.get_voxel(pos)

				if voxel_id != 0:  # Not air
					var block = _block_types.get_block_by_voxel_id(voxel_id)
					if block:
						blocks_found.append({
							"name": block.base_info.name,
							"position": pos,
							"voxel_id": voxel_id
						})

	return blocks_found
