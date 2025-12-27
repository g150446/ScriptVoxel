extends Node
class_name CodeExecutor

# Executes user Python code and provides output/error handling

const SimpleExecutor = preload("res://blocky_game/agent/simple_executor.gd")

signal execution_started
signal execution_finished
signal execution_error(error_message: String)
signal output_printed(text: String)

var _agent_api_ref = null
var _is_executing := false
var _python_executor = null
var _agent_node = null
var _simple_executor = null


func set_agent_api(agent_api):
	"""Set reference to the agent API that will be exposed to user code"""
	_agent_api_ref = agent_api
	if agent_api:
		# Get the agent node (parent of agent_api)
		_agent_node = agent_api.get_parent()

		# Create simple executor fallback
		_simple_executor = SimpleExecutor.new()
		_simple_executor.set_agent(_agent_node)  # Pass the agent node, not the API
		add_child(_simple_executor)

		# Get the Python executor from the agent
		if _agent_node:
			_python_executor = _agent_node.get_node_or_null("PythonExecutor")
			if _python_executor:
				# Check if the method exists before calling
				if _python_executor.has_method("set_agent"):
					_python_executor.set_agent(agent_api)


func execute_code(code: String):
	"""Execute user Python code with agent API injected as global"""
	if _is_executing:
		output_printed.emit("Code is already executing. Please wait...")
		return

	if not _agent_api_ref:
		execution_error.emit("Agent API not initialized")
		return

	_is_executing = true
	execution_started.emit()

	var result = null

	# Try to use py4godot Python executor first
	if _python_executor and _python_executor.has_method("execute_code"):
		result = _python_executor.execute_code(code)
	elif _simple_executor:
		result = _simple_executor.execute_code(code)
	else:
		execution_error.emit("No executor available")
		_is_executing = false
		execution_finished.emit()
		return

	if result.has("success") and result.success:
		# Print any output
		if result.has("output"):
			for line in result.output:
				if line.strip_edges() != "":
					output_printed.emit(line)
	else:
		# Handle error
		if result.has("error"):
			execution_error.emit(result.error)

	_is_executing = false
	execution_finished.emit()


func stop_execution():
	"""Stop currently executing code (if possible)"""
	# This is difficult to implement safely
	# For now, just mark as not executing
	_is_executing = false
	execution_finished.emit()
