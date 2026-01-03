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

	var i = 0
	while i < lines.size():
		var trimmed = lines[i].strip_edges()

		# Skip empty lines and comments
		if trimmed == "" or trimmed.begins_with("#"):
			i += 1
			continue

		# Check for for loop
		if trimmed.begins_with("for "):
			var for_result = _parse_for_loop(lines, i)
			if not for_result.success:
				result.error = for_result.error
				return result

			# Add loop output
			if for_result.has("output"):
				output_lines.append_array(for_result.output)

			# Skip the lines consumed by the loop
			i += for_result.lines_consumed
		else:
			# Parse the command
			var parse_result = _parse_and_execute(trimmed)
			if not parse_result.success:
				result.error = parse_result.error + " on line: " + trimmed
				return result

			if parse_result.has("output") and parse_result.output != "":
				output_lines.append(parse_result.output)

			i += 1

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


func _parse_for_loop(lines: Array, start_index: int) -> Dictionary:
	"""Parse and execute a for loop"""
	var result = {"success": false, "output": [], "lines_consumed": 1}

	if start_index >= lines.size():
		result.error = "Unexpected end of code in for loop"
		return result

	var loop_line = lines[start_index].strip_edges()

	# Match basic for loop: for i in range(n):
	var for_regex = RegEx.new()
	for_regex.compile('for\\s+(\\w+)\\s+in\\s+range\\s*\\(\\s*(\\d+)\\s*\\)')

	var for_match = for_regex.search(loop_line)
	if not for_match:
		result.error = "Unsupported for loop syntax: " + loop_line
		return result

	var var_name = for_match.get_string(1)
	var range_end_str = for_match.get_string(2)

	# Validate range_end is a valid integer
	if not range_end_str.is_valid_int():
		result.error = "Invalid range value: " + range_end_str
		return result

	var range_end = int(range_end_str)

	# Find the loop body (indented lines after the for statement)
	var loop_body = []
	var i = start_index + 1
	var indent_level = -1

	while i < lines.size():
		var line = lines[i]
		if line.strip_edges() == "":
			i += 1
			continue

		# Check indentation
		var line_indent = _get_indent_level(line)
		if indent_level == -1:
			if line_indent <= 0:
				result.error = "Expected indented loop body after for statement"
				return result
			indent_level = line_indent
		elif line_indent > 0 and line_indent < indent_level:
			# Less indented but still indented - this might be a syntax error
			result.error = "Inconsistent indentation in loop body"
			return result
		elif line_indent <= 0 and line.strip_edges() != "":
			# End of loop body (next non-indented line)
			break

		if line_indent >= indent_level:
			loop_body.append(line.substr(indent_level))  # Remove indentation

		i += 1

	if loop_body.is_empty():
		result.error = "Empty loop body"
		return result

	result.lines_consumed = i - start_index

	# Execute the loop
	var loop_output = []
	for iteration in range(range_end):
		# Execute each line in the loop body
		for body_line in loop_body:
			var trimmed_body = body_line.strip_edges()

			# Skip empty lines and comments
			if trimmed_body == "" or trimmed_body.begins_with("#"):
				continue

			# Replace the loop variable in the line
			var processed_line = trimmed_body.replace(var_name, str(iteration))

			# Parse and execute the command
			var parse_result = _parse_and_execute(processed_line)
			if not parse_result.success:
				result.error = parse_result.error + " in loop body: " + processed_line
				return result

			if parse_result.has("output") and parse_result.output != "":
				loop_output.append("Loop %d: %s" % [iteration, parse_result.output])

	result.success = true
	result.output = loop_output
	return result


func _get_indent_level(line: String) -> int:
	"""Get the indentation level of a line"""
	var count = 0
	for c in line:
		if c == " " or c == "\t":
			count += 1
		else:
			break
	return count
