extends Control

signal resume_requested
signal save_requested
signal load_requested
signal main_menu_requested
signal quit_requested

@onready var _resume_button: Button = $VBoxContainer/ResumeButton
@onready var _save_button: Button = $VBoxContainer/SaveButton
@onready var _load_button: Button = $VBoxContainer/LoadButton
@onready var _main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var _quit_button: Button = $VBoxContainer/QuitButton


func _ready():
	_resume_button.pressed.connect(_on_resume_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	
	visible = false


func show_menu():
	visible = true
	
	if OS.has_feature("web"):
		_quit_button.visible = false
	else:
		_quit_button.visible = true


func hide_menu():
	visible = false


func _on_resume_pressed():
	hide_menu()
	resume_requested.emit()


func _on_save_pressed():
	hide_menu()
	save_requested.emit()


func _on_load_pressed():
	hide_menu()
	load_requested.emit()


func _on_main_menu_pressed():
	hide_menu()
	main_menu_requested.emit()


func _on_quit_pressed():
	hide_menu()
	quit_requested.emit()
