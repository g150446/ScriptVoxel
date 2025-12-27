extends Node
class_name SimpleExecutor

# Simple fallback executor that parses basic Python-like commands
# Used when py4godot is not available

var _controller = null
var _interaction = null


func set_agent(agent_node):
	"""Set the agent node and get GDScript component references"""
	if agent_node:
		_controller = agent_node.get_node_or_null("AgentController")
		_interaction = agent_node.get_node_or_null("AgentInteraction")


func execute_code(code: String) -> Dictionary:
	"""Parse and execute simple movement commands"""
	var result = {
		"success": false,
		"output": [],
		"error": ""
	}

	if not _controller:
		result.error = "Agent controller not set"
		return result

	# Split code into lines
	var lines = code.split("\n")
	var output_lines = []

	for line in lines:
		var trimmed = line.strip_edges()

		# Skip empty lines and comments
		if trimmed == "" or trimmed.begins_with("#"):
			continue

		# Parse the command
		var parse_result = _parse_and_execute(trimmed)
		if not parse_result.success:
			result.error = parse_result.error + " on line: " + trimmed
			return result

		if parse_result.has("output") and parse_result.output != "":
			output_lines.append(parse_result.output)

	result.success = true
	result.output = output_lines
	return result


func _parse_and_execute(line: String) -> Dictionary:
	"""Parse and execute a single command line"""
	var result = {"success": false, "output": ""}

	# Match agent.move("direction", distance)
	var move_regex = RegEx.new()
	move_regex.compile('agent\\.move\\s*\\(\\s*["\']([^"\']+)["\']\\s*(?:,\\s*(\\d+(?:\\.\\d+)?))?\\s*\\)')
	var move_match = move_regex.search(line)

	if move_match:
		var direction = move_match.get_string(1).to_lower()
		var distance = 1.0
		if move_match.get_group_count() >= 2 and move_match.get_string(2) != "":
			distance = float(move_match.get_string(2))

		# Execute movement using GDScript controller
		if direction == "forward":
			_controller.move_forward(distance)
		elif direction == "back" or direction == "backward":
			_controller.move_forward(-distance)
		elif direction == "left":
			_controller.turn_left(90.0)
			_controller.move_forward(distance)
			_controller.turn_right(90.0)
		elif direction == "right":
			_controller.turn_right(90.0)
			_controller.move_forward(distance)
			_controller.turn_left(90.0)
		elif direction == "up":
			_controller.move_up(distance)
		elif direction == "down":
			_controller.move_down(distance)
		else:
			result.error = "Unknown direction: " + direction
			return result

		result.success = true
		result.output = "Moving %s by %.1f" % [direction, distance]
		return result

	# Match agent.turn("direction", degrees)
	var turn_regex = RegEx.new()
	turn_regex.compile('agent\\.turn\\s*\\(\\s*["\']([^"\']+)["\']\\s*(?:,\\s*(\\d+(?:\\.\\d+)?))?\\s*\\)')
	var turn_match = turn_regex.search(line)

	if turn_match:
		var direction = turn_match.get_string(1).to_lower()
		var degrees = 90.0
		if turn_match.get_group_count() >= 2 and turn_match.get_string(2) != "":
			degrees = float(turn_match.get_string(2))

		# Execute turn using GDScript controller
		if direction == "left":
			_controller.turn_left(degrees)
		elif direction == "right":
			_controller.turn_right(degrees)
		else:
			result.error = "Unknown turn direction: " + direction
			return result

		result.success = true
		result.output = "Turning %s by %.1f degrees" % [direction, degrees]
		return result

	# Match agent.jump()
	if line.contains("agent.jump()"):
		_controller.jump()
		result.success = true
		result.output = "Jumping"
		return result

	# Match agent.place_block("block_name")
	var place_regex = RegEx.new()
	place_regex.compile('agent\\.place_block\\s*\\(\\s*["\']([^"\']+)["\']\\s*\\)')
	var place_match = place_regex.search(line)

	if place_match:
		var block_name = place_match.get_string(1)
		if _interaction:
			var success = _interaction.place_block(block_name)
			result.success = true
			result.output = "Placed block: %s (success: %s)" % [block_name, str(success)]
		else:
			result.error = "Interaction system not available"
		return result

	# Match agent.break_block()
	if line.contains("agent.break_block()"):
		if _interaction:
			var success = _interaction.break_block()
			result.success = true
			result.output = "Broke block (success: %s)" % str(success)
		else:
			result.error = "Interaction system not available"
		return result

	# If we got here, unknown command
	result.error = "Unknown command or syntax error"
	return result
