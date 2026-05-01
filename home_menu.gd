extends Control

const TALK_BUBBLE_TEXTURE = preload("res://Assets/talk.png")
const START_SCENE_TEXTURE = preload("res://Assets/backgrounds/start_screen.png")
const DEFAULT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_default.png")
const OBJECT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_object.png")
const CURSOR_HOTSPOT = Vector2(8, 0)
const CURSOR_SCALE = 1.35
const HOVER_TINT = Color(1.0, 0.95, 0.8, 1.0)
const DEFAULT_TINT = Color.WHITE

@onready var background: TextureRect = $Background
@onready var tutorial_button: TextureButton = $ButtonStack/TutorialButton
@onready var level_1_button: TextureButton = $ButtonStack/Level1Button
@onready var level_2_button: TextureButton = $ButtonStack/Level2Button
@onready var credits_button: TextureButton = $ButtonStack/CreditsButton
@onready var credits_overlay: Control = $CreditsOverlay
@onready var credits_close_button: TextureButton = $CreditsOverlay/CreditsPanel/CloseButton
var cursor_sprite: TextureRect

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	cursor_sprite = TextureRect.new()
	cursor_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_sprite.z_index = 1000
	cursor_sprite.scale = Vector2.ONE * CURSOR_SCALE
	add_child(cursor_sprite)
	_set_cursor_texture(DEFAULT_CURSOR_TEXTURE)
	set_process(true)
	if background != null:
		background.texture = START_SCENE_TEXTURE
	_configure_level_button(tutorial_button, "Tutorial", "res://test.tscn")
	_configure_level_button(level_1_button, "Level 1", "res://level_1.tscn")
	_configure_level_button(level_2_button, "Level 2", "res://level_2.tscn")
	_configure_credits_button()
	_configure_credits_overlay()

func _configure_level_button(button: TextureButton, button_text: String, scene_path: String) -> void:
	if button == null:
		return
	button.texture_normal = TALK_BUBBLE_TEXTURE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(_open_scene.bind(scene_path))
	button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_button_mouse_exited.bind(button))

	var label := button.get_node_or_null("Label") as Label
	if label != null:
		label.text = button_text
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _open_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func _configure_credits_button() -> void:
	if credits_button == null:
		return
	credits_button.texture_normal = TALK_BUBBLE_TEXTURE
	credits_button.ignore_texture_size = true
	credits_button.stretch_mode = TextureButton.STRETCH_SCALE
	credits_button.mouse_filter = Control.MOUSE_FILTER_STOP
	credits_button.pressed.connect(_open_credits)
	credits_button.mouse_entered.connect(_on_button_mouse_entered.bind(credits_button))
	credits_button.mouse_exited.connect(_on_button_mouse_exited.bind(credits_button))

	var label := credits_button.get_node_or_null("Label") as Label
	if label != null:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _configure_credits_overlay() -> void:
	if credits_overlay != null:
		credits_overlay.visible = false
	if credits_close_button != null:
		credits_close_button.pressed.connect(_close_credits)
		credits_close_button.mouse_entered.connect(_on_button_mouse_entered.bind(credits_close_button))
		credits_close_button.mouse_exited.connect(_on_button_mouse_exited.bind(credits_close_button))

func _open_credits() -> void:
	if credits_overlay != null:
		credits_overlay.visible = true

func _close_credits() -> void:
	if credits_overlay != null:
		credits_overlay.visible = false

func _process(_delta: float) -> void:
	if cursor_sprite == null:
		return
	var mouse_position := get_viewport().get_mouse_position()
	cursor_sprite.position = mouse_position - (CURSOR_HOTSPOT * CURSOR_SCALE)

func _on_button_mouse_entered(button: TextureButton) -> void:
	if button != null:
		button.modulate = HOVER_TINT
	_set_cursor_texture(OBJECT_CURSOR_TEXTURE)

func _on_button_mouse_exited(button: TextureButton) -> void:
	if button != null:
		button.modulate = DEFAULT_TINT
	_set_cursor_texture(DEFAULT_CURSOR_TEXTURE)

func _set_cursor_texture(texture: Texture2D) -> void:
	if cursor_sprite == null:
		return
	cursor_sprite.texture = texture
	cursor_sprite.custom_minimum_size = texture.get_size()
	cursor_sprite.size = texture.get_size()
