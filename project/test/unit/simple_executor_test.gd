extends GutTest

# Test for SimpleExecutor, focusing on for loop functionality

var SimpleExecutor = load("res://blocky_game/agent/simple_executor.gd")
var executor = null
var mock_controller = null
var mock_interaction = null
var mock_agent = null

func before_each():
	# Set up mocks and executor
	mock_controller = double(Node).new()
	mock_interaction = double(Node).new()
	mock_agent = double(Node).new()

	# Mock the get_node methods
	stub(mock_agent, 'get_node').to_return(mock_controller).when_passed('AgentController')
	stub(mock_agent, 'get_node').to_return(mock_interaction).when_passed('AgentInteraction')

	executor = SimpleExecutor.new()
	executor.set_agent(mock_agent)

func after_each():
	# Clean up
	if executor:
		executor.free()
	executor = null
	mock_controller = null
	mock_interaction = null
	mock_agent = null

func test_for_loop_basic():
	# Test basic for loop execution
	var code = """for i in range(3):
    agent.move("forward", 1)"""

	# Mock the move_forward method
	stub(mock_controller, 'move_forward').to_do_nothing()

	var result = executor.execute_code(code)

	assert_true(result.success, "For loop should execute successfully")
	assert_eq(result.output.size(), 3, "Should have 3 output lines for 3 iterations")

	# Verify move_forward was called 3 times
	assert_called(mock_controller, 'move_forward', [1.0])
	assert_eq(get_call_count(mock_controller, 'move_forward'), 3)

func test_for_loop_with_variable_substitution():
	# Test for loop with variable in parameters
	var code = """for i in range(2):
    agent.move("forward", i + 1)"""

	stub(mock_controller, 'move_forward').to_do_nothing()

	var result = executor.execute_code(code)

	assert_true(result.success, "For loop with variable should execute successfully")

	# Verify calls with correct distances
	assert_called(mock_controller, 'move_forward', [1.0])
	assert_called(mock_controller, 'move_forward', [2.0])
	assert_eq(get_call_count(mock_controller, 'move_forward'), 2)

func test_for_loop_with_block_placement():
	# Test for loop with block placement
	var code = """for i in range(2):
    agent.place_block("planks")"""

	stub(mock_interaction, 'place_block').to_return(true)

	var result = executor.execute_code(code)

	assert_true(result.success, "For loop with block placement should execute successfully")
	assert_called(mock_interaction, 'place_block', ['planks'])
	assert_eq(get_call_count(mock_interaction, 'place_block'), 2)

func test_for_loop_invalid_syntax():
	# Test invalid for loop syntax
	var code = """for i in invalid_range(3):
    agent.move("forward", 1)"""

	var result = executor.execute_code(code)

	assert_false(result.success, "Invalid for loop syntax should fail")
	assert_string_contains(result.error, "Unsupported for loop syntax")

func test_for_loop_empty_body():
	# Test for loop with empty body
	var code = """for i in range(2):
    # This is just a comment"""

	var result = executor.execute_code(code)

	assert_true(result.success, "For loop with empty body should execute successfully")
	assert_eq(result.output.size(), 0, "Should have no output for empty loop body")

func test_for_loop_mixed_commands():
	# Test for loop with multiple commands
	var code = """for i in range(2):
    agent.move("forward", 1)
    agent.turn("right", 90)
    agent.place_block("dirt")"""

	stub(mock_controller, 'move_forward').to_do_nothing()
	stub(mock_controller, 'turn_right').to_do_nothing()
	stub(mock_interaction, 'place_block').to_return(true)

	var result = executor.execute_code(code)

	assert_true(result.success, "Mixed commands in for loop should execute successfully")

	# Verify all methods were called twice
	assert_called(mock_controller, 'move_forward', [1.0])
	assert_called(mock_controller, 'turn_right', [90.0])
	assert_called(mock_interaction, 'place_block', ['dirt'])
	assert_eq(get_call_count(mock_controller, 'move_forward'), 2)
	assert_eq(get_call_count(mock_controller, 'turn_right'), 2)
	assert_eq(get_call_count(mock_interaction, 'place_block'), 2)

func test_for_loop_zero_iterations():
	# Test for loop with 0 iterations
	var code = """for i in range(0):
    agent.move("forward", 1)"""

	var result = executor.execute_code(code)

	assert_true(result.success, "For loop with 0 iterations should execute successfully")
	assert_eq(result.output.size(), 0, "Should have no output for 0 iterations")

	# Verify move_forward was never called
	assert_eq(get_call_count(mock_controller, 'move_forward'), 0)


func test_for_loop_execution_reset():
	# Test that multiple executions work properly (regression test for 2nd run issue)
	var code1 = """for i in range(2):
    agent.move("forward", 1)"""

	var code2 = """for i in range(3):
    agent.turn("right", 90)"""

	# First execution
	var result1 = executor.execute_code(code1)
	assert_true(result1.success, "First for loop should execute successfully")
	assert_eq(get_call_count(mock_controller, 'move_forward'), 2)

	# Second execution
	var result2 = executor.execute_code(code2)
	assert_true(result2.success, "Second for loop should execute successfully")
	assert_eq(get_call_count(mock_controller, 'turn_right'), 3)

	# Third execution (same as first)
	var result3 = executor.execute_code(code1)
	assert_true(result3.success, "Third for loop should execute successfully")
	assert_eq(get_call_count(mock_controller, 'move_forward'), 4)  # Should accumulate