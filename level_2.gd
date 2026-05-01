extends Control

const HOME_MENU_SCENE_PATH = "res://home_menu.tscn"

@export var starting_focus_x := 2300.0
@export var portrait_hitbox_padding := Vector2(90.0, 120.0)
@export var level_complete_scene_path := HOME_MENU_SCENE_PATH

@onready var world: Node2D = get_node_or_null("World")
@onready var background_outside: TextureRect = get_node_or_null("World/BackgroundOutside")
@onready var portrait_1: TextureRect = get_node_or_null("Portrait1")
@onready var portrait_2: TextureRect = get_node_or_null("Portrait2")
@onready var dialogue_box: TextureRect = get_node_or_null("DialogueBox")
@onready var speaker_box: TextureRect = get_node_or_null("SpeakerBox")
@onready var speaker_name: RichTextLabel = get_node_or_null("SpeakerName")
@onready var dialogue_text: RichTextLabel = get_node_or_null("DialogueText")
@onready var choice_container: VBoxContainer = get_node_or_null("ChoiceContainer")
@onready var advance_trigger: Button = get_node_or_null("AdvanceTrigger")
@onready var inventory_ui: Control = get_node_or_null("InventoryUI")
@onready var inventory_button: TextureButton = get_node_or_null("InventoryUI/InventoryButton")
@onready var inventory_button_visual: CanvasItem = get_node_or_null("InventoryUI/InventoryButton/InventoryButtonVisual2")
@onready var inventory_popup_panel: Panel = get_node_or_null("InventoryUI/InventoryPopup")
@onready var inventory_popup_background: TextureRect = get_node_or_null("InventoryUI/InventoryPopup/PopupBackground")
@onready var inventory_close_button: TextureButton = get_node_or_null("InventoryUI/InventoryPopup/CloseButton")
@onready var inventory_items_container: VBoxContainer = get_node_or_null("InventoryUI/InventoryPopup/ItemsContainer")
@onready var phone_row: HBoxContainer = get_node_or_null("InventoryUI/InventoryPopup/ItemsContainer/PhoneRow")

const DEFAULT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_default.png")
const OBJECT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_object.png")
const HEIMLICH_MINIGAME_SCENE = preload("res://HeimlichMinigame.tscn")
const VICTORY_TEXTURE = preload("res://Assets/Victory.png")
const TALK_BUBBLE_TEXTURE = preload("res://Assets/talk.png")
const CURSOR_HOTSPOT = Vector2(8, 0)
const CURSOR_SCALE = 1.35
const DIALOGUE_TEXT_COLOR = "#1f3a5f"
const SPEAKER_NAME_FONT_SIZE = 50
const DEFAULT_PORTRAIT_TINT = Color(1.0, 1.0, 1.0, 1.0)
const HOVER_PORTRAIT_TINT = Color(1.0, 0.95, 0.8, 1.0)
const CHOICE_BUBBLE_LAYOUT_SIZE = Vector2(760.0, 120.0)
const CHOICE_BUBBLE_VISUAL_SCALE = Vector2(1.22, 1.28)
const PLAY_HEIMLICH_GAME_LABEL = "play the heimlich microgame"
const LEVEL_END_TRIGGER_TEXT = "You receive a text on their phone from Frank, inviting you to a picnic in the woods."

var arcweave_asset: ArcweaveAsset = preload("res://addons/arcweave/LevelTwo.tres")
var Story = load("res://addons/arcweave/Story.cs")
var story
var project_data: Dictionary
var cursor_sprite: TextureRect
var current_portrait_names: Array[String] = []
var portrait_1_action_path = null
var portrait_2_action_path = null
var pending_heimlich_path = null
var is_portrait_1_interactive := false
var is_portrait_2_interactive := false
var default_portrait_1_position := Vector2.ZERO
var default_portrait_2_position := Vector2.ZERO
var default_portrait_1_scale := Vector2.ONE
var default_portrait_2_scale := Vector2.ONE
var default_speaker_name_position := Vector2.ZERO
var default_world_position := Vector2.ZERO
var default_background_size := Vector2.ZERO
var default_outside_background_texture: Texture2D
var portrait_1_hotspot: Button
var portrait_2_hotspot: Button
var active_heimlich_minigame_root: Node
var active_heimlich_minigame: Node
var victory_overlay: TextureRect
var is_showing_victory_screen := false

func _sanitize_dialogue_text(raw_text: String) -> String:
	return raw_text.strip_edges().replace(char(8), "").replace("\\b", "")

func _strip_dialogue_markup(raw_text: String) -> String:
	var sanitized_text := _sanitize_dialogue_text(raw_text)
	var markup_pattern := RegEx.new()
	markup_pattern.compile("<[^>]+>")
	var plain_text := markup_pattern.sub(sanitized_text, "", true)
	var bbcode_pattern := RegEx.new()
	bbcode_pattern.compile("\\[/?(?:b|i|u|s|center|left|right|fill|indent|url|code|kbd|p|br|color|bgcolor|fgcolor|font_size|font|img|table|cell|wave|tornado|shake|fade|rainbow)(?:=[^\\]]+)?\\]")
	plain_text = bbcode_pattern.sub(plain_text, "", true)
	plain_text = plain_text.replace("&nbsp;", " ").replace(char(160), " ")
	var whitespace_pattern := RegEx.new()
	whitespace_pattern.compile("\\s+")
	return whitespace_pattern.sub(plain_text, " ", true).strip_edges()

func _is_likely_speaker_name(candidate: String) -> bool:
	var trimmed := candidate.strip_edges()
	if trimmed.is_empty() or trimmed.length() > 40:
		return false
	if trimmed.begins_with("\"") and trimmed.ends_with("\"") and trimmed.length() >= 2:
		trimmed = trimmed.substr(1, trimmed.length() - 2).strip_edges()
	for character in trimmed:
		var is_text_character = (character >= "A" and character <= "Z") or (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == " " or character == "_" or character == "-" or character == "'" or character == "." or character == "\"" or character == "(" or character == ")"
		if not is_text_character:
			return false
	return true

func _parse_dialogue_speaker(raw_text: String) -> Dictionary:
	var plain_text := _strip_dialogue_markup(raw_text)
	var colon_index := plain_text.find(":")
	if colon_index <= 0:
		return {
			"speaker": "",
			"body": plain_text,
		}

	var speaker := plain_text.substr(0, colon_index).strip_edges()
	var body := plain_text.substr(colon_index + 1).strip_edges()
	if speaker.begins_with("[") and speaker.ends_with("]") and speaker.length() >= 2:
		speaker = speaker.substr(1, speaker.length() - 2).strip_edges()
	if speaker.begins_with("\"") and speaker.ends_with("\"") and speaker.length() >= 2:
		speaker = speaker.substr(1, speaker.length() - 2).strip_edges()
	if not _is_likely_speaker_name(speaker):
		print("Speaker parse miss [level_2]: raw=", raw_text, " | plain=", plain_text, " | speaker_candidate=", speaker)
		return {
			"speaker": "",
			"body": plain_text,
		}
	return {
		"speaker": speaker,
		"body": body,
	}

func _has_dialogue_speaker_prefix(text: String) -> bool:
	return not str(_parse_dialogue_speaker(text).get("speaker", "")).is_empty()

func _get_dialogue_speaker_name(raw_text: String) -> String:
	return str(_parse_dialogue_speaker(raw_text).get("speaker", ""))

func _get_dialogue_body_text(raw_text: String) -> String:
	return str(_parse_dialogue_speaker(raw_text).get("body", ""))

func _update_speaker_name_display(raw_text: String) -> void:
	if speaker_name == null:
		return
	var speaker := _get_dialogue_speaker_name(raw_text)
	speaker_name.bbcode_enabled = true
	speaker_name.add_theme_color_override("default_color", Color.html(DIALOGUE_TEXT_COLOR))
	if speaker.is_empty():
		speaker_name.text = ""
		speaker_name.visible = false
		if speaker_box != null:
			speaker_box.visible = false
		return
	speaker_name.text = "[center][font_size=%d][color=%s][b]%s[/b][/color][/font_size][/center]" % [SPEAKER_NAME_FONT_SIZE, DIALOGUE_TEXT_COLOR, speaker]
	speaker_name.visible = true
	if speaker_box != null:
		speaker_box.visible = true

func _format_dialogue_text(raw_text: String) -> String:
	var body_text := _get_dialogue_body_text(raw_text)
	if body_text.is_empty():
		return ""
	if _has_dialogue_speaker_prefix(raw_text):
		return "[font_size=35][color=%s]%s[/color][/font_size]" % [DIALOGUE_TEXT_COLOR, body_text]
	return "[font_size=35][color=%s][i]%s[/i][/color][/font_size]" % [DIALOGUE_TEXT_COLOR, body_text]

func _ready() -> void:
	if world != null:
		_apply_world_focus(starting_focus_x)
		default_world_position = world.position
	if background_outside != null:
		default_background_size = background_outside.size
		default_outside_background_texture = background_outside.texture
	if portrait_1 != null:
		default_portrait_1_position = portrait_1.position
		default_portrait_1_scale = portrait_1.scale
	if portrait_2 != null:
		default_portrait_2_position = portrait_2.position
		default_portrait_2_scale = portrait_2.scale
	if speaker_name != null:
		default_speaker_name_position = speaker_name.position

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_create_cursor_sprite()
	_create_victory_overlay()
	_connect_ui()
	_configure_choice_container()
	_create_portrait_hotspots()

	project_data = arcweave_asset.project_settings
	if project_data.get("startingElement", null) == null:
		push_error("Arcweave LevelTwo export is missing a startingElement. Set a start element in Arcweave and re-export the JSON.")
		return

	story = Story.new(project_data)
	if story == null:
		push_error("Arcweave story failed to initialize from LevelTwo.tres.")
		return
	repaint()
	set_process(true)

func _process(_delta: float) -> void:
	if cursor_sprite != null:
		var mouse_position = get_viewport().get_mouse_position()
		cursor_sprite.position = mouse_position - (CURSOR_HOTSPOT * CURSOR_SCALE)

	if portrait_1 != null:
		portrait_1.position = default_portrait_1_position
		portrait_1.scale = default_portrait_1_scale
	if portrait_2 != null:
		portrait_2.position = default_portrait_2_position
		portrait_2.scale = default_portrait_2_scale
	if speaker_name != null:
		speaker_name.position = default_speaker_name_position

	_update_portrait_hotspots()

func get_component_names_for_element() -> Array[String]:
	var names: Array[String] = []
	var element = story.GetCurrentElement()
	var element_id = element.Id
	var elements = project_data.get("elements", {})
	if elements.has(element_id):
		var element_data = elements[element_id]
		var component_ids = element_data.get("components", [])
		var components = project_data.get("components", {})
		for component_id in component_ids:
			if components.has(component_id):
				var component_name := clean_name(str(components[component_id].get("name", "")))
				if component_name != "" and _should_use_component_for_portrait(component_name) and not names.has(component_name):
					names.append(component_name)
	return names

func repaint() -> void:
	if story == null:
		return

	_update_story_background()
	var current_story_text: String = story.GetCurrentRuntimeContent()
	if dialogue_text != null:
		dialogue_text.bbcode_enabled = true
		dialogue_text.add_theme_color_override("default_color", Color.html(DIALOGUE_TEXT_COLOR))
		dialogue_text.text = _format_dialogue_text(current_story_text)

	_update_portrait()
	_update_speaker_name_display(current_story_text)
	add_options()

func add_options() -> void:
	if story == null:
		return
	if choice_container == null or advance_trigger == null:
		return

	for option in choice_container.get_children():
		option.queue_free()

	portrait_1_action_path = null
	portrait_2_action_path = null
	pending_heimlich_path = null

	var options = story.GenerateCurrentOptions()
	var paths = options.Paths

	if paths == null or paths.size() == 0:
		choice_container.visible = false
		advance_trigger.visible = true
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP
		_set_portrait_interactive(false)
		return

	var visible_choice_count := 0
	for i in range(paths.size()):
		var path = paths[i]
		if not path.IsValid:
			continue
		if _is_play_heimlich_game_path(path):
			pending_heimlich_path = path
			continue

		var button := _create_choice_button(_get_path_label_text(path), i, paths)
		choice_container.add_child(button)
		visible_choice_count += 1

	if visible_choice_count == 1:
		for option in choice_container.get_children():
			option.queue_free()
		visible_choice_count = 0

	if pending_heimlich_path != null and active_heimlich_minigame_root == null:
		for option in choice_container.get_children():
			option.queue_free()
		choice_container.visible = false
		advance_trigger.visible = false
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_portrait_interactive(false)
		call_deferred("_start_heimlich_minigame")
		return

	_set_portrait_interactive(false)
	choice_container.visible = visible_choice_count > 0
	advance_trigger.visible = not choice_container.visible
	advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP if advance_trigger.visible else Control.MOUSE_FILTER_IGNORE

func _create_choice_button(button_text: String, index, paths) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = TALK_BUBBLE_TEXTURE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = CHOICE_BUBBLE_LAYOUT_SIZE
	button.size = CHOICE_BUBBLE_LAYOUT_SIZE
	button.scale = CHOICE_BUBBLE_VISUAL_SCALE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(_on_option_pressed.bind(index, paths))
	button.mouse_entered.connect(_on_choice_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_choice_button_mouse_exited.bind(button))

	var label := Label.new()
	label.text = button_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 30)
	label.position = Vector2(55.0, 22.0)
	label.size = Vector2(CHOICE_BUBBLE_LAYOUT_SIZE.x - 80.0, CHOICE_BUBBLE_LAYOUT_SIZE.y - 28.0)
	button.add_child(label)

	return button

func _configure_choice_container() -> void:
	if choice_container == null:
		return
	choice_container.add_theme_constant_override("separation", -8)

func clean_name(raw_name: String) -> String:
	return raw_name.strip_edges()

func _update_story_background() -> void:
	if background_outside == null:
		return
	background_outside.texture = default_outside_background_texture
	background_outside.position = Vector2.ZERO
	if default_background_size != Vector2.ZERO:
		background_outside.size = default_background_size

func _apply_world_focus(focus_x: float) -> void:
	if world == null:
		return
	var viewport_center_x := get_viewport_rect().size.x * 0.5
	world.position.x = viewport_center_x - focus_x

func _create_cursor_sprite() -> void:
	cursor_sprite = TextureRect.new()
	cursor_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_sprite.z_index = 1000
	cursor_sprite.scale = Vector2.ONE * CURSOR_SCALE
	add_child(cursor_sprite)
	_set_cursor_texture(DEFAULT_CURSOR_TEXTURE)

func _create_victory_overlay() -> void:
	victory_overlay = TextureRect.new()
	victory_overlay.texture = VICTORY_TEXTURE
	victory_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	victory_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	victory_overlay.anchor_right = 1.0
	victory_overlay.anchor_bottom = 1.0
	victory_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	victory_overlay.visible = false
	victory_overlay.z_index = 900
	add_child(victory_overlay)

func _create_portrait_hotspots() -> void:
	portrait_1_hotspot = _create_portrait_hotspot(_on_portrait_mouse_entered, _on_portrait_mouse_exited, _on_portrait_1_gui_input)
	portrait_2_hotspot = _create_portrait_hotspot(_on_portrait_2_mouse_entered, _on_portrait_2_mouse_exited, _on_portrait_2_gui_input)

func _create_portrait_hotspot(entered_handler: Callable, exited_handler: Callable, input_handler: Callable) -> Button:
	var hotspot := Button.new()
	hotspot.flat = true
	hotspot.focus_mode = Control.FOCUS_NONE
	hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hotspot.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	hotspot.modulate = Color(1, 1, 1, 0.01)
	hotspot.text = ""
	hotspot.z_index = 50
	hotspot.mouse_entered.connect(entered_handler)
	hotspot.mouse_exited.connect(exited_handler)
	hotspot.gui_input.connect(input_handler)
	add_child(hotspot)
	return hotspot

func _update_portrait_hotspots() -> void:
	_update_single_portrait_hotspot(portrait_1, portrait_1_hotspot, is_portrait_1_interactive)
	_update_single_portrait_hotspot(portrait_2, portrait_2_hotspot, is_portrait_2_interactive)

func _update_single_portrait_hotspot(portrait_node: TextureRect, hotspot: Button, is_interactive: bool) -> void:
	if portrait_node == null or hotspot == null:
		return
	if not portrait_node.visible or not is_interactive:
		hotspot.visible = false
		return
	var rect := portrait_node.get_global_rect()
	hotspot.position = rect.position - portrait_hitbox_padding
	hotspot.size = rect.size + (portrait_hitbox_padding * 2.0)
	hotspot.visible = true

func _connect_ui() -> void:
	if advance_trigger != null:
		advance_trigger.flat = true
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP
		advance_trigger.pressed.connect(_on_continue_pressed)

	if portrait_1 != null:
		portrait_1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_1.modulate = DEFAULT_PORTRAIT_TINT

	if portrait_2 != null:
		portrait_2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_2.modulate = DEFAULT_PORTRAIT_TINT

	if dialogue_box != null:
		dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if dialogue_text != null:
		dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if speaker_name != null:
		speaker_name.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if inventory_ui != null:
		inventory_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inventory_ui.z_index = 200
		inventory_ui.visible = true

	if inventory_button != null:
		inventory_button.mouse_filter = Control.MOUSE_FILTER_STOP
		inventory_button.ignore_texture_size = true
		inventory_button.z_index = 250
		inventory_button.visible = true
		inventory_button.modulate = Color.WHITE
		inventory_button.pressed.connect(_on_inventory_button_pressed)
		inventory_button.mouse_entered.connect(_on_inventory_hotspot_mouse_entered)
		inventory_button.mouse_exited.connect(_on_inventory_hotspot_mouse_exited)
	if inventory_button_visual != null:
		inventory_button_visual.visible = true
		inventory_button_visual.modulate = Color.WHITE

	if inventory_popup_panel != null:
		inventory_popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inventory_popup_panel.z_index = 201
		inventory_popup_panel.visible = false
		inventory_popup_panel.modulate = Color.WHITE

	if inventory_popup_background != null:
		inventory_popup_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inventory_popup_background.z_index = 202
		inventory_popup_background.visible = false
		inventory_popup_background.rotation_degrees = 90
		inventory_popup_background.modulate = Color.WHITE

	if inventory_close_button != null:
		inventory_close_button.z_index = 203
		inventory_close_button.visible = false
		inventory_close_button.modulate = Color.WHITE
		inventory_close_button.pressed.connect(_on_inventory_close_pressed)

	if inventory_items_container != null:
		inventory_items_container.z_index = 203
		inventory_items_container.visible = false
		inventory_items_container.modulate = Color.WHITE

	if phone_row != null:
		phone_row.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_cursor_texture(texture: Texture2D) -> void:
	if cursor_sprite == null:
		return
	cursor_sprite.texture = texture
	cursor_sprite.custom_minimum_size = texture.get_size()
	cursor_sprite.size = texture.get_size()

func _set_portrait_interactive(primary_value: bool, secondary_value: bool = false) -> void:
	is_portrait_1_interactive = primary_value and portrait_1 != null and portrait_1_action_path != null
	is_portrait_2_interactive = secondary_value and portrait_2 != null and portrait_2_action_path != null
	if portrait_1 != null:
		portrait_1.modulate = DEFAULT_PORTRAIT_TINT
	if portrait_2 != null:
		portrait_2.modulate = DEFAULT_PORTRAIT_TINT
	if portrait_1_hotspot != null:
		portrait_1_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP if is_portrait_1_interactive else Control.MOUSE_FILTER_IGNORE
	if portrait_2_hotspot != null:
		portrait_2_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP if is_portrait_2_interactive else Control.MOUSE_FILTER_IGNORE
	_update_portrait_hotspots()
	if not is_portrait_1_interactive and not is_portrait_2_interactive:
		set_default_cursor()

func _update_portrait() -> void:
	var component_names := get_component_names_for_element()
	current_portrait_names.clear()

	var visible_names: Array[String] = []
	for component_name in component_names:
		var portrait_path := _get_portrait_path(component_name)
		if portrait_path != "":
			visible_names.append(component_name)
			current_portrait_names.append(component_name)
			if visible_names.size() == 1 and portrait_1 != null:
				portrait_1.texture = load(portrait_path)
				portrait_1.visible = true
			elif visible_names.size() == 2 and portrait_2 != null:
				portrait_2.texture = load(portrait_path)
				portrait_2.visible = true

	if portrait_1 != null and visible_names.is_empty():
		portrait_1.visible = false
	if portrait_2 != null:
		portrait_2.visible = visible_names.size() > 1
	elif portrait_1 != null and visible_names.size() == 1:
		portrait_1.visible = true

	if portrait_1 != null and visible_names.size() >= 1:
		portrait_1.visible = true
	if portrait_2 != null and visible_names.size() < 2:
		portrait_2.visible = false

func _normalize_label(label) -> String:
	if label == null:
		return ""
	var plain = str(label).to_lower()
	var cleaned = ""
	var previous_was_space = false
	for character in plain:
		var is_text_character = (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "'"
		if is_text_character:
			cleaned += character
			previous_was_space = false
		elif not previous_was_space:
			cleaned += " "
			previous_was_space = true
	return cleaned.strip_edges()

func _get_path_label_text(path) -> String:
	var plain = str(path.label)
	plain = plain.replace("<p>", "")
	plain = plain.replace("</p>", "")
	plain = plain.replace("<br>", " ")
	plain = plain.replace("<br/>", " ")
	plain = plain.replace("<br />", " ")
	return plain.strip_edges()

func _should_use_component_for_portrait(component_name: String) -> bool:
	return component_name.to_lower() != "steak"

func _get_portrait_path(component_name: String) -> String:
	if component_name == "":
		return ""

	var trimmed_name := component_name.strip_edges()
	var candidates := [
		"res://Assets/portraits/%s.png" % trimmed_name,
		"res://Assets/portraits/%s.png" % trimmed_name.replace(" ", "_"),
		"res://Assets/portraits/%s.png" % trimmed_name.replace(" ", "-"),
	]

	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			return candidate

	return ""

func _is_play_heimlich_game_path(path) -> bool:
	return _normalize_label(path.label) == PLAY_HEIMLICH_GAME_LABEL

func _on_portrait_action_selected(path) -> void:
	if path == null:
		return
	story.SelectPath(path)
	repaint()

func _on_portrait_mouse_entered() -> void:
	if not is_portrait_1_interactive:
		return
	if portrait_1 != null:
		portrait_1.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_portrait_mouse_exited() -> void:
	if portrait_1 != null:
		portrait_1.modulate = DEFAULT_PORTRAIT_TINT
	if not is_portrait_2_interactive or portrait_2 == null or portrait_2.modulate == DEFAULT_PORTRAIT_TINT:
		set_default_cursor()

func _on_portrait_1_gui_input(event) -> void:
	if not is_portrait_1_interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_portrait_action_selected(portrait_1_action_path)

func _on_portrait_2_mouse_entered() -> void:
	if not is_portrait_2_interactive:
		return
	if portrait_2 != null:
		portrait_2.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_portrait_2_mouse_exited() -> void:
	if portrait_2 != null:
		portrait_2.modulate = DEFAULT_PORTRAIT_TINT
	if not is_portrait_1_interactive or portrait_1 == null or portrait_1.modulate == DEFAULT_PORTRAIT_TINT:
		set_default_cursor()

func _on_portrait_2_gui_input(event) -> void:
	if not is_portrait_2_interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_portrait_action_selected(portrait_2_action_path)

func _on_option_pressed(index, paths) -> void:
	var selected_path = paths[index]
	story.SelectPath(selected_path)
	repaint()

func _on_choice_button_mouse_entered(button: TextureButton) -> void:
	if button != null:
		button.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_choice_button_mouse_exited(button: TextureButton) -> void:
	if button != null:
		button.modulate = Color.WHITE
	set_default_cursor()

func _on_continue_pressed() -> void:
	if is_showing_victory_screen:
		get_tree().change_scene_to_file(level_complete_scene_path)
		return

	var current_text := _normalize_label(_get_current_story_text())
	if current_text == _normalize_label(LEVEL_END_TRIGGER_TEXT):
		_set_victory_screen_visible(true)
		return

	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	if paths != null and paths.size() > 0:
		story.SelectPath(paths[0])
		repaint()

func _get_current_story_text() -> String:
	if story == null:
		return ""
	return story.GetCurrentRuntimeContent().strip_edges()

func _start_heimlich_minigame() -> void:
	if active_heimlich_minigame_root != null:
		return
	active_heimlich_minigame_root = HEIMLICH_MINIGAME_SCENE.instantiate()
	add_child(active_heimlich_minigame_root)
	if active_heimlich_minigame_root is CanvasItem:
		active_heimlich_minigame_root.visible = true
		if "z_index" in active_heimlich_minigame_root:
			active_heimlich_minigame_root.z_index = 500
	active_heimlich_minigame = active_heimlich_minigame_root
	if active_heimlich_minigame != null and active_heimlich_minigame.has_signal("minigame_completed"):
		active_heimlich_minigame.minigame_completed.connect(_on_heimlich_minigame_completed)
	_set_main_scene_visible(false)
	_set_main_scene_input_enabled(false)
	if cursor_sprite != null:
		cursor_sprite.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _end_heimlich_minigame() -> void:
	if active_heimlich_minigame_root != null:
		active_heimlich_minigame_root.queue_free()
	active_heimlich_minigame_root = null
	active_heimlich_minigame = null
	_set_main_scene_visible(true)
	_set_main_scene_input_enabled(true)
	if cursor_sprite != null:
		cursor_sprite.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	set_default_cursor()

func _on_heimlich_minigame_completed(_success: bool) -> void:
	_end_heimlich_minigame()
	if pending_heimlich_path != null:
		var selected_path = pending_heimlich_path
		pending_heimlich_path = null
		story.SelectPath(selected_path)
		repaint()
	else:
		_on_continue_pressed()

func _set_main_scene_visible(is_visible: bool) -> void:
	if world != null:
		world.visible = is_visible
	if portrait_1 != null:
		portrait_1.visible = is_visible and portrait_1.visible
	if portrait_2 != null:
		portrait_2.visible = is_visible and portrait_2.visible
	if speaker_name != null:
		speaker_name.visible = false if not is_visible else speaker_name.visible
	if dialogue_box != null:
		dialogue_box.visible = is_visible
	if dialogue_text != null:
		dialogue_text.visible = is_visible
	if choice_container != null:
		choice_container.visible = is_visible and choice_container.visible
	if advance_trigger != null:
		advance_trigger.visible = is_visible and advance_trigger.visible
	if portrait_1_hotspot != null:
		portrait_1_hotspot.visible = is_visible and is_portrait_1_interactive
	if portrait_2_hotspot != null:
		portrait_2_hotspot.visible = is_visible and is_portrait_2_interactive
	if inventory_ui != null:
		inventory_ui.visible = is_visible

func _set_victory_screen_visible(is_visible: bool) -> void:
	is_showing_victory_screen = is_visible
	if victory_overlay != null:
		victory_overlay.visible = is_visible
	if world != null:
		world.visible = not is_visible
	if portrait_1 != null:
		portrait_1.visible = not is_visible and portrait_1.visible
	if portrait_2 != null:
		portrait_2.visible = not is_visible and portrait_2.visible
	if dialogue_box != null:
		dialogue_box.visible = not is_visible
	if dialogue_text != null:
		dialogue_text.visible = not is_visible
	if speaker_name != null:
		speaker_name.visible = not is_visible and speaker_name.visible
	if choice_container != null and is_visible:
		choice_container.visible = false
	if advance_trigger != null:
		advance_trigger.visible = true if is_visible else advance_trigger.visible
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP if advance_trigger.visible else Control.MOUSE_FILTER_IGNORE
	if portrait_1_hotspot != null and is_visible:
		portrait_1_hotspot.visible = false
	if portrait_2_hotspot != null and is_visible:
		portrait_2_hotspot.visible = false
	if inventory_ui != null:
		inventory_ui.visible = not is_visible

func _set_main_scene_input_enabled(is_enabled: bool) -> void:
	if advance_trigger != null:
		if is_enabled:
			advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP if advance_trigger.visible else Control.MOUSE_FILTER_IGNORE
		else:
			advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if portrait_1_hotspot != null:
		portrait_1_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled and is_portrait_1_interactive else Control.MOUSE_FILTER_IGNORE
	if portrait_2_hotspot != null:
		portrait_2_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled and is_portrait_2_interactive else Control.MOUSE_FILTER_IGNORE
	if inventory_button != null:
		inventory_button.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled else Control.MOUSE_FILTER_IGNORE

func set_object_cursor() -> void:
	_set_cursor_texture(OBJECT_CURSOR_TEXTURE)

func set_default_cursor() -> void:
	_set_cursor_texture(DEFAULT_CURSOR_TEXTURE)

func _on_inventory_button_pressed() -> void:
	_set_inventory_open(true)

func _on_inventory_close_pressed() -> void:
	_set_inventory_open(false)

func _set_inventory_open(is_open: bool) -> void:
	if inventory_popup_panel != null:
		inventory_popup_panel.visible = is_open
		inventory_popup_panel.modulate = Color.WHITE
	if inventory_popup_background != null:
		inventory_popup_background.visible = is_open
		inventory_popup_background.modulate = Color.WHITE
	if inventory_close_button != null:
		inventory_close_button.visible = is_open
		inventory_close_button.modulate = Color.WHITE
	if inventory_items_container != null:
		inventory_items_container.visible = is_open
		inventory_items_container.modulate = Color.WHITE

func _on_inventory_hotspot_mouse_entered() -> void:
	_set_inventory_button_highlighted(true)
	set_object_cursor()

func _on_inventory_hotspot_mouse_exited() -> void:
	_set_inventory_button_highlighted(false)
	set_default_cursor()

func _set_inventory_button_highlighted(is_highlighted: bool) -> void:
	if inventory_button_visual != null:
		inventory_button_visual.modulate = HOVER_PORTRAIT_TINT if is_highlighted else Color.WHITE
