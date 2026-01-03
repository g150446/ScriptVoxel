extends GutTest

# Test for AgentController, focusing on turn direction correctness

var AgentController = load("res://blocky_game/agent/agent_controller.gd")
var controller = null
var mock_parent = null

func before_each():
	# Create a mock parent node (ProgrammableAgent)
	mock_parent = Node3D.new()
	mock_parent.name = "MockAgent"
	add_child_autofree(mock_parent)

	# Create controller as child
	controller = autofree(AgentController.new())
	mock_parent.add_child(controller)

	# Set initial rotation
	mock_parent.rotation.y = 0.0
	controller._rotation_y = 0.0

func test_turn_right_direction():
	# Test that turn_right creates negative rotation (clockwise)
	var initial_rotation = controller._rotation_y

	controller.turn_right(90.0)

	# Manually call physics process to execute the turn
	controller._physics_process(0.016)

	# After turning right, rotation_y should be negative (clockwise)
	assert_lt(controller._rotation_y, initial_rotation, "turn_right should decrease rotation_y (clockwise)")

	# Should be approximately -PI/2 (-90 degrees)
	assert_almost_eq(controller._rotation_y, -PI/2, 0.01, "turn_right(90) should rotate -90 degrees")

func test_turn_left_direction():
	# Test that turn_left creates positive rotation (counter-clockwise)
	var initial_rotation = controller._rotation_y

	controller.turn_left(90.0)

	# Manually call physics process to execute the turn
	controller._physics_process(0.016)

	# After turning left, rotation_y should be positive (counter-clockwise)
	assert_gt(controller._rotation_y, initial_rotation, "turn_left should increase rotation_y (counter-clockwise)")

	# Should be approximately PI/2 (90 degrees)
	assert_almost_eq(controller._rotation_y, PI/2, 0.01, "turn_left(90) should rotate +90 degrees")

func test_turn_right_then_left_returns_to_zero():
	# Test that turning right then left returns to original position
	controller.turn_right(90.0)
	controller._physics_process(0.016)

	controller.turn_left(90.0)
	controller._physics_process(0.016)

	# Should return to approximately 0
	assert_almost_eq(controller._rotation_y, 0.0, 0.01, "Right then left should return to 0")

func test_turn_left_then_right_returns_to_zero():
	# Test that turning left then right returns to original position
	controller.turn_left(90.0)
	controller._physics_process(0.016)

	controller.turn_right(90.0)
	controller._physics_process(0.016)

	# Should return to approximately 0
	assert_almost_eq(controller._rotation_y, 0.0, 0.01, "Left then right should return to 0")

func test_turn_right_180():
	# Test turning right 180 degrees
	controller.turn_right(180.0)
	controller._physics_process(0.016)

	# Should be approximately -PI (-180 degrees)
	assert_almost_eq(controller._rotation_y, -PI, 0.01, "turn_right(180) should rotate -180 degrees")

func test_turn_left_180():
	# Test turning left 180 degrees
	controller.turn_left(180.0)
	controller._physics_process(0.016)

	# Should be approximately PI (180 degrees)
	assert_almost_eq(controller._rotation_y, PI, 0.01, "turn_left(180) should rotate +180 degrees")

func test_forward_direction_after_turn_right():
	# Test that forward direction changes correctly after turning right
	var initial_forward = controller.get_forward_direction()
	assert_almost_eq(initial_forward.x, 0.0, 0.01, "Initial forward X should be 0")
	assert_almost_eq(initial_forward.z, -1.0, 0.01, "Initial forward Z should be -1 (facing forward in Godot)")

	# Turn right 90 degrees
	controller.turn_right(90.0)
	controller._physics_process(0.016)

	var new_forward = controller.get_forward_direction()

	# After turning right (clockwise from above), should face right in world space (+X)
	assert_almost_eq(new_forward.x, 1.0, 0.01, "After turn_right(90), should face right (+X) in world space")
	assert_almost_eq(new_forward.z, 0.0, 0.01, "After turn_right(90), Z should be 0")

func test_forward_direction_after_turn_left():
	# Test that forward direction changes correctly after turning left
	var initial_forward = controller.get_forward_direction()
	assert_almost_eq(initial_forward.x, 0.0, 0.01, "Initial forward X should be 0")
	assert_almost_eq(initial_forward.z, -1.0, 0.01, "Initial forward Z should be -1 (facing forward in Godot)")

	# Turn left 90 degrees
	controller.turn_left(90.0)
	controller._physics_process(0.016)

	var new_forward = controller.get_forward_direction()

	# After turning left (counter-clockwise from above), should face left in world space (-X)
	assert_almost_eq(new_forward.x, -1.0, 0.01, "After turn_left(90), should face left (-X) in world space")
	assert_almost_eq(new_forward.z, 0.0, 0.01, "After turn_left(90), Z should be 0")

func test_multiple_turns_accumulate():
	# Test that multiple turns accumulate correctly
	controller.turn_right(45.0)
	controller._physics_process(0.016)
	controller.turn_right(45.0)
	controller._physics_process(0.016)

	# Should be -90 degrees total
	assert_almost_eq(controller._rotation_y, -PI/2, 0.01, "Two right(45) should equal -90 degrees")

func test_parent_rotation_syncs():
	# Test that parent node rotation syncs with controller rotation
	controller.turn_right(90.0)
	controller._physics_process(0.016)

	# Parent rotation should match controller rotation
	assert_almost_eq(mock_parent.rotation.y, controller._rotation_y, 0.01, "Parent rotation should sync with controller")
