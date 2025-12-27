extends CanvasLayer

# In-game Python code editor UI

@onready var _code_edit : CodeEdit = $PanelContainer/VBoxContainer/CodeEdit
@onready var _output_console : TextEdit = $PanelContainer/VBoxContainer/OutputConsole
@onready var _run_button : Button = $PanelContainer/VBoxContainer/Controls/RunButton
@onready var _stop_button : Button = $PanelContainer/VBoxContainer/Controls/StopButton
@onready var _spawn_agent_button : Button = $PanelContainer/VBoxContainer/Controls/SpawnAgentButton
@onready var _clear_button : Button = $PanelContainer/VBoxContainer/Controls/ClearButton
@onready var _help_button : Button = $PanelContainer/VBoxContainer/Controls/HelpButton
@onready var _close_button : Button = $PanelContainer/VBoxContainer/Header/CloseButton

var _code_executor : CodeExecutor
var _is_running := false

signal spawn_agent_requested


func _ready():
	# Create code executor
	_code_executor = CodeExecutor.new()
	add_child(_code_executor)

	# Hide editor initially
	visible = false

	# Connect to visibility changed to grab focus when shown
	visibility_changed.connect(_on_visibility_changed)

	# Setup larger font sizes
	_code_edit.add_theme_font_size_override("font_size", 32)
	_output_console.add_theme_font_size_override("font_size", 28)

	# Setup text colors (white on dark background)
	_code_edit.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_code_edit.add_theme_color_override("background_color", Color(0.1, 0.1, 0.15))
	_output_console.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_output_console.add_theme_color_override("background_color", Color(0.15, 0.15, 0.2))

	# Setup CodeEdit syntax highlighting
	_setup_python_highlighting()

	# Connect signals
	_run_button.pressed.connect(_on_run_pressed)
	_stop_button.pressed.connect(_on_stop_pressed)
	_spawn_agent_button.pressed.connect(_on_spawn_agent_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	_help_button.pressed.connect(_on_help_pressed)
	_close_button.pressed.connect(_on_close_pressed)

	_code_executor.execution_started.connect(_on_execution_started)
	_code_executor.execution_finished.connect(_on_execution_finished)
	_code_executor.execution_error.connect(_on_execution_error)
	_code_executor.output_printed.connect(_on_output_printed)

	# Start with blank editor
	_code_edit.text = ""

	# Configure output console
	_output_console.editable = false
	_output_console.text = "Ready. Press 'Help' to see available API commands.\n"


func set_agent_api(agent_api):
	"""Set the agent API reference for code execution"""
	if _code_executor:
		_code_executor.set_agent_api(agent_api)
		_output_console.text += "Agent connected and ready!\n"


func get_code_executor() -> CodeExecutor:
	"""Get the code executor instance"""
	return _code_executor


func _setup_python_highlighting():
	"""Setup Python syntax highlighting for CodeEdit"""
	var highlighter = CodeHighlighter.new()

	# Set default color for regular text (white/light gray)
	highlighter.number_color = Color(0.7, 1.0, 0.7)  # Light green for numbers
	highlighter.symbol_color = Color(0.9, 0.9, 0.9)  # White for symbols
	highlighter.function_color = Color(0.6, 0.8, 1.0)  # Light blue for functions
	highlighter.member_variable_color = Color(0.9, 0.9, 0.9)  # White

	# Python keywords
	var keywords = ["def", "class", "if", "else", "elif", "for", "while",
					"in", "return", "import", "from", "as", "with", "try",
					"except", "finally", "raise", "pass", "break", "continue",
					"and", "or", "not", "True", "False", "None"]
	for keyword in keywords:
		highlighter.add_keyword_color(keyword, Color(1.0, 0.5, 0.5))  # Light red/pink

	# Comments
	highlighter.add_color_region("#", "", Color(0.6, 0.6, 0.6), true)

	# Strings
	highlighter.add_color_region("\"", "\"", Color(0.9, 0.9, 0.5))  # Yellow
	highlighter.add_color_region("'", "'", Color(0.9, 0.9, 0.5))  # Yellow
	highlighter.add_color_region('"""', '"""', Color(0.9, 0.9, 0.5))  # Yellow

	_code_edit.syntax_highlighter = highlighter


func _on_run_pressed():
	if _is_running:
		return

	var code = _code_edit.text
	_code_executor.execute_code(code)


func _on_stop_pressed():
	if _is_running:
		_code_executor.stop_execution()


func _on_clear_pressed():
	_output_console.text = ""


func _on_help_pressed():
	"""Display Agent API documentation"""
	_output_console.text = """=== AGENT API DOCUMENTATION ===

MOVEMENT COMMANDS:
  agent.move(direction, distance)
    - Move agent in a direction
    - direction: "forward", "back", "left", "right", "up", "down"
    - distance: number of blocks (default: 1.0)
    - Examples:
      agent.move("forward", 3)
      agent.move("up", 5)
      agent.move("left", 2)

  agent.turn(direction, degrees)
    - Turn agent in place
    - direction: "left" or "right"
    - degrees: rotation amount (default: 90.0)
    - Examples:
      agent.turn("right")
      agent.turn("left", 45)

  agent.jump()
    - Make agent jump
    - Example: agent.jump()

BLOCK MANIPULATION:
  agent.place_block(block_name)
    - Place a block in front of agent
    - block_name: "planks", "grass", "dirt", "stone", etc.
    - Returns: True if successful
    - Example: agent.place_block("planks")

  agent.break_block()
    - Break the block in front of agent
    - Returns: True if successful
    - Example: agent.break_block()

  agent.inspect_block()
    - Get info about block in front of agent
    - Returns: dictionary with block information
    - Example: info = agent.inspect_block()

WORLD SENSING:
  agent.detect_nearby_blocks(radius)
    - Detect blocks around agent
    - radius: detection range (default: 3)
    - Returns: list of nearby blocks
    - Example: blocks = agent.detect_nearby_blocks(5)

  agent.get_position()
    - Get agent's current position
    - Returns: Vector3 position
    - Example: pos = agent.get_position()

  agent.get_facing_direction()
    - Get the direction agent is facing
    - Returns: Vector3 direction
    - Example: dir = agent.get_facing_direction()

EXAMPLE PROGRAMS:

# Move in a square:
agent.move("forward", 3)
agent.turn("right")
agent.move("forward", 3)
agent.turn("right")
agent.move("forward", 3)
agent.turn("right")
agent.move("forward", 3)

# Build a tower:
for i in range(5):
    agent.place_block("planks")
    agent.move("up", 1)

# Fly around:
agent.move("up", 10)
agent.move("forward", 5)
agent.move("down", 3)
agent.turn("left")
agent.move("forward", 5)

================================
"""


func _on_execution_started():
	_is_running = true
	_run_button.disabled = true
	_output_console.text += "\n--- Executing ---\n"


func _on_execution_finished():
	_is_running = false
	_run_button.disabled = false
	_output_console.text += "\n--- Finished ---\n"


func _on_execution_error(error_message: String):
	_output_console.text += "[ERROR] " + error_message + "\n"


func _on_output_printed(text: String):
	_output_console.text += text + "\n"


func _on_visibility_changed():
	"""Called when editor visibility changes"""
	if visible:
		# Editor is now visible - grab focus for code edit
		await get_tree().process_frame  # Wait one frame for UI to be ready
		_code_edit.grab_focus()
		print("CodeEditorUI: Editor shown, grabbed focus")
	else:
		print("CodeEditorUI: Editor hidden")


func _on_close_pressed():
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Re-enable player input
	var game = get_tree().root.get_node_or_null("Main/Game")
	if game:
		var players = game.get_node_or_null("Players")
		if players:
			var player = players.get_node_or_null("1")
			if player and "input_enabled" in player:
				player.input_enabled = true
				print("CodeEditorUI: Re-enabled player input on close")


func _on_spawn_agent_pressed():
	spawn_agent_requested.emit()
	_output_console.text += "\n--- Spawning agent ---\n"
