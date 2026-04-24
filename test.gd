extends Control

@onready var background = $World/Background
@onready var portrait = $Portrait
@onready var speaker_name = $SpeakerName
@onready var dialogue_text = $DialogueText
@onready var choice_container = $ChoiceContainer
@onready var advance_trigger = $AdvanceTrigger
@onready var glass = $World/Glass
@onready var world = $World

const DEFAULT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_default.png")
const OBJECT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_object.png")
const CURSOR_HOTSPOT = Vector2(8, 0)
const DEFAULT_PORTRAIT_TINT = Color(1.0, 1.0, 1.0, 1.0)
const HOVER_PORTRAIT_TINT = Color(1.0, 0.95, 0.8, 1.0)

var arcweave_asset: ArcweaveAsset = preload("res://addons/arcweave/TutorialStory.tres")
var Story = load("res://addons/arcweave/Story.cs")
var story
var project_data: Dictionary
var cursor_sprite: TextureRect
var current_portrait_name := ""
var is_portrait_interactive := false

func _ready():
	world.position.x = -1080
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	cursor_sprite = TextureRect.new()
	cursor_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_sprite.z_index = 100
	add_child(cursor_sprite)
	_set_cursor_texture(DEFAULT_CURSOR_TEXTURE)
	set_process(true)
	advance_trigger.pressed.connect(_on_continue_pressed)
	advance_trigger.flat = true
	advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.mouse_entered.connect(_on_portrait_mouse_entered)
	portrait.mouse_exited.connect(_on_portrait_mouse_exited)
	portrait.gui_input.connect(_on_portrait_gui_input)
	portrait.modulate = DEFAULT_PORTRAIT_TINT
	glass.is_interactive = false  # not clickable by default
	project_data = arcweave_asset.project_settings
	story = Story.new(project_data)
	repaint()

func _process(_delta):
	if cursor_sprite == null:
		return
	cursor_sprite.position = get_viewport().get_mouse_position() - CURSOR_HOTSPOT

func get_component_name_for_element() -> String:
	var element = story.GetCurrentElement()
	var element_id = element.Id
	var elements = project_data.get("elements", {})
	if elements.has(element_id):
		var el_data = elements[element_id]
		var component_id = el_data.get("components", [])
		if component_id.size() > 0:
			var components = project_data.get("components", {})
			if components.has(component_id[0]):
				return components[component_id[0]].get("name", "")
	return ""

func clean_name(raw_name: String) -> String:
	if "_" in raw_name:
		return raw_name.split("_")[0]
	return raw_name

func repaint():
	dialogue_text.bbcode_enabled = true
	dialogue_text.add_theme_color_override("default_color", Color.BLACK)
	dialogue_text.text = story.GetCurrentRuntimeContent().strip_edges()
	
	var comp_name = get_component_name_for_element()
	if comp_name != "" and comp_name != "Decoy":
		current_portrait_name = comp_name
		speaker_name.text = comp_name
		var portrait_path = "res://Assets/portraits/" + comp_name + ".png"
		if ResourceLoader.exists(portrait_path):
			portrait.texture = load(portrait_path)
		else:
			portrait.texture = null
	else:
		speaker_name.text = current_portrait_name
	
	add_options()

func add_options():
	for option in choice_container.get_children():
		option.queue_free()
	
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	
	if paths == null or paths.size() == 0:
		choice_container.visible = false
		advance_trigger.visible = true
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP
		glass.is_interactive = false
		_set_portrait_interactive(false)
		return
	
	var has_object_paths = false
	var has_frank_paths = false
	for i in range(paths.size()):
		if _path_label_contains(paths[i], "glass"):
			has_object_paths = true
		if _path_label_contains(paths[i], "frank"):
			has_frank_paths = true

	_set_portrait_interactive(has_frank_paths)
	
	if has_object_paths:
		choice_container.visible = true
		advance_trigger.visible = false
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glass.is_interactive = true
		# Only add buttons for non-glass paths
		for i in range(paths.size()):
			if paths[i].IsValid and not _path_label_contains(paths[i], "glass") and not _path_label_contains(paths[i], "frank"):
				var button = Button.new()
				button.text = paths[i].label
				button.pressed.connect(_on_option_pressed.bind(i, paths))
				choice_container.add_child(button)
	elif paths.size() > 1:
		glass.is_interactive = false
		advance_trigger.visible = false
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
		choice_container.visible = true
		for i in range(paths.size()):
			if paths[i].IsValid and not _path_label_contains(paths[i], "frank"):
				var button = Button.new()
				button.text = paths[i].label
				button.pressed.connect(_on_option_pressed.bind(i, paths))
				choice_container.add_child(button)
	else:
		glass.is_interactive = false
		_set_portrait_interactive(false)
		choice_container.visible = false
		advance_trigger.visible = true
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP

func on_glass_clicked():
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	for i in range(paths.size()):
		if paths[i].label != null and "glass" in paths[i].label.to_lower():
			story.SelectPath(paths[i])
			repaint()
			break

func on_frank_clicked():
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	for i in range(paths.size()):
		if _path_label_contains(paths[i], "frank"):
			story.SelectPath(paths[i])
			repaint()
			break

func set_object_cursor():
	_set_cursor_texture(OBJECT_CURSOR_TEXTURE)

func set_default_cursor():
	_set_cursor_texture(DEFAULT_CURSOR_TEXTURE)

func _set_cursor_texture(texture: Texture2D):
	if cursor_sprite == null:
		return
	cursor_sprite.texture = texture
	cursor_sprite.custom_minimum_size = texture.get_size()
	cursor_sprite.size = texture.get_size()

func _set_portrait_interactive(value: bool):
	is_portrait_interactive = value
	portrait.mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE
	portrait.modulate = DEFAULT_PORTRAIT_TINT
	if not value:
		set_default_cursor()

func _path_label_contains(path, text: String) -> bool:
	return path.label != null and text in path.label.to_lower()

func _on_portrait_mouse_entered():
	if not is_portrait_interactive:
		return
	portrait.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_portrait_mouse_exited():
	portrait.modulate = DEFAULT_PORTRAIT_TINT
	set_default_cursor()

func _on_portrait_gui_input(event):
	if not is_portrait_interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		on_frank_clicked()

func _on_option_pressed(index, paths):
	story.SelectPath(paths[index])
	repaint()

func _on_continue_pressed():
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	if paths != null and paths.size() > 0:
		story.SelectPath(paths[0])
		repaint()
