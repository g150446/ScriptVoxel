extends Node3D

# Agent movement controller - similar to character_controller.gd but command-based

@export var speed := 5.0
@export var gravity := 9.8
@export var jump_force := 5.0
@export var terrain : NodePath

var _velocity := Vector3()
var _grounded := false
var _box_mover := VoxelBoxMover.new()
var _rotation_y := 0.0

# Command queue for programmatic control
var _move_queue := []
var _turn_queue := []
var _jump_requested := false


func _ready():
	_box_mover.set_collision_mask(1)  # Excludes rails and grass
	_box_mover.set_step_climbing_enabled(true)
	_box_mover.set_max_step_height(0.5)


func get_forward_direction() -> Vector3:
	var forward = Vector3.FORWARD.rotated(Vector3.UP, _rotation_y)
	return forward.normalized()


func move_forward(distance: float = 1.0):
	"""Queue a forward movement command"""
	_move_queue.append({
		"distance": distance,
		"remaining": distance,
		"direction": "horizontal"
	})


func move_up(distance: float = 1.0):
	"""Queue an upward movement command"""
	_move_queue.append({
		"distance": distance,
		"remaining": distance,
		"direction": "up"
	})


func move_down(distance: float = 1.0):
	"""Queue a downward movement command"""
	_move_queue.append({
		"distance": distance,
		"remaining": distance,
		"direction": "down"
	})


func turn_left(degrees: float = 90.0):
	"""Queue a left turn command"""
	_turn_queue.append({
		"degrees": deg_to_rad(degrees)  # 正の値 = 反時計回り（左回転）
	})


func turn_right(degrees: float = 90.0):
	"""Queue a right turn command"""
	_turn_queue.append({
		"degrees": -deg_to_rad(degrees)  # 負の値 = 時計回り（右回転）
	})


func jump():
	"""Request a jump"""
	if _grounded:
		_jump_requested = true


func _physics_process(delta: float):
	# Process turn commands first (instant)
	if not _turn_queue.is_empty():
		var turn_cmd = _turn_queue.pop_front()
		_rotation_y += turn_cmd.degrees
		get_parent().rotation.y = _rotation_y  # Rotate parent so visual rotates too

	# Process movement commands
	var motor := Vector3()

	if not _move_queue.is_empty():
		var move_cmd = _move_queue[0]
		var step_distance = min(move_cmd.remaining, speed * delta)

		# Handle different movement directions
		if move_cmd.direction == "up":
			motor = Vector3.UP * (step_distance / delta)
		elif move_cmd.direction == "down":
			motor = Vector3.DOWN * (step_distance / delta)
		else:  # horizontal movement
			var forward = get_forward_direction()
			motor = forward * (step_distance / delta)

		move_cmd.remaining -= step_distance
		if move_cmd.remaining <= 0.01:
			_move_queue.pop_front()

	_velocity.x = motor.x
	_velocity.y = motor.y  # Allow vertical movement
	_velocity.z = motor.z
	# Agent is not affected by gravity - can float in the air
	# _velocity.y -= gravity * delta

	if _grounded and _jump_requested:
		_velocity.y = jump_force
		_grounded = false
		_jump_requested = false

	var motion := _velocity * delta

	if has_node(terrain):
		var aabb := AABB(Vector3(-0.4, -0.9, -0.4), Vector3(0.8, 1.8, 0.8))
		var terrain_node : VoxelTerrain = get_node(terrain)

		var parent_pos = get_parent().position
		var vt := terrain_node.get_voxel_tool()
		if vt.is_area_editable(AABB(aabb.position + parent_pos, aabb.size)):
			var prev_motion := motion

			# Modify motion taking collisions into account
			motion = _box_mover.get_motion(parent_pos, motion, aabb, terrain_node)

			# Apply motion to parent (ProgrammableAgent node) so visual moves too
			get_parent().global_translate(motion)

			# If new motion doesn't move vertically and we were falling before, we just landed
			if absf(motion.y) < 0.001 and prev_motion.y < -0.001:
				_grounded = true

			if _box_mover.has_stepped_up():
				# When we step up, the motion vector will have vertical movement,
				# however it is not caused by falling or jumping, but by snapping the body on
				# top of the step. So after we applied motion, we consider it grounded,
				# and we reset motion.y so we don't induce a "jump" velocity later.
				motion.y = 0
				_grounded = true

			# Otherwise, if new motion is moving vertically, we may not be grounded anymore
			elif absf(motion.y) > 0.001:
				_grounded = false
