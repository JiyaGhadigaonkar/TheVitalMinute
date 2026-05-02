extends Control

const HOME_MENU_SCENE_PATH = "res://home_menu.tscn"

@export var starting_focus_x := 2300.0
@export var inside_focus_x := 1200
@export var use_intro_portrait_lock := true
@export var intro_portrait_1_name := "Frank_Normal"
@export var intro_portrait_2_name := "Driver_Friend"
@export var use_inside_portrait_positions := true
@export var inside_portrait_1_position := Vector2(250.0, 142.0)
@export var inside_portrait_2_position := Vector2(1510.0, 142.0)
@export var portrait_hitbox_padding := Vector2(90.0, 120.0)
@export var bypass_cpr_minigame := false

@onready var world: Node2D = get_node_or_null("World")
@onready var background_outside: TextureRect = get_node_or_null("World/BackgroundOutside")
@onready var background_inside: TextureRect = get_node_or_null("World/BackgroundInside")
@onready var alcohol_sprite: Sprite2D = get_node_or_null("World/Alcohol")
@onready var water_heater_sprite: Sprite2D = get_node_or_null("World/WaterHeater")
@onready var hot_water_sprite: Sprite2D = get_node_or_null("World/HotWater")
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
@onready var inventory_button_visual: CanvasItem = get_node_or_null("InventoryUI/InventoryButton/InventoryButtonVisual")
@onready var inventory_popup_panel: Panel = get_node_or_null("InventoryUI/InventoryPopup")
@onready var inventory_popup_background: TextureRect = get_node_or_null("InventoryUI/InventoryPopup/PopupBackground")
@onready var inventory_close_button: TextureButton = get_node_or_null("InventoryUI/InventoryPopup/CloseButton")
@onready var inventory_items_container: VBoxContainer = get_node_or_null("InventoryUI/InventoryPopup/ItemsContainer")
@onready var gauze_row: HBoxContainer = get_node_or_null("InventoryUI/InventoryPopup/ItemsContainer/GauzeRow")
@onready var napkin_row: HBoxContainer = get_node_or_null("InventoryUI/InventoryPopup/ItemsContainer/NapkinRow")
@onready var phone_row: HBoxContainer = get_node_or_null("InventoryUI/InventoryPopup/ItemsContainer/PhoneRow")

const DEFAULT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_default.png")
const OBJECT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_object.png")
const MENU_BUTTON_TEXTURE = preload("res://Assets/Menu_Button.png")
const CPR_MINIGAME_SCENE = preload("res://CPRMinigame.tscn")
const PASSED_OUT_TEXTURE = preload("res://Assets/PassedOut.png")
const VICTORY_TEXTURE = preload("res://Assets/Victory.png")
const GAUZE_TEXTURE = preload("res://Assets/Item_Tutorial_Gauze.png")
const NAPKINS_TEXTURE = preload("res://Assets/Item_Tutorial_Napkins.png")
const TALK_BUBBLE_TEXTURE = preload("res://Assets/talk.png")
const CURSOR_HOTSPOT = Vector2(8, 0)
const CURSOR_SCALE = 1.35
const DIALOGUE_TEXT_COLOR = "#1f3a5f"
const SPEAKER_NAME_FONT_SIZE = 50
const DEFAULT_PORTRAIT_TINT = Color(1.0, 1.0, 1.0, 1.0)
const HOVER_PORTRAIT_TINT = Color(1.0, 0.95, 0.8, 1.0)
const MENU_BUTTON_SIZE = Vector2(110.0, 88.0)
const CHOICE_BUBBLE_LAYOUT_SIZE = Vector2(760.0, 120.0)
const CHOICE_BUBBLE_VISUAL_SCALE = Vector2(1.22, 1.28)
const ONLOOKER_CHOICE_CONTAINER_POSITION = Vector2(850.0, 40.0)
const ONLOOKER_CHOICE_CONTAINER_SIZE = Vector2(700.0, 400.0)
const ONLOOKER_CHOICE_BUBBLE_LAYOUT_SIZE = Vector2(700.0, 102.0)
const ONLOOKER_CHOICE_BUBBLE_VISUAL_SCALE = Vector2(1.0, 1.05)
const INSIDE_SCENE_VERTICAL_OFFSET = 1444.0
const TALK_TO_FRANK_LABEL = "center talk to frank"
const USE_GAUZE_LABEL = "use gauze"
const USE_NAPKINS_LABEL = "use napkins"
const OPEN_PHONE_LABEL = "open phone"
const CALL_911_LABEL = "time for you to call 911"
const GET_MORE_ALCOHOL_LABEL = "get more alcohol"
const GET_HOT_WATER_LABEL = "get hot water"
const PLAY_RHYTHM_GAME_LABEL = "play the rhythm game"
const GIVE_HOT_WATER_LABEL = "give hot water"
const MAKE_INSTANT_TEA_LABEL = "make instant tea"
const GIVE_HOT_TEA_LABEL = "give hot tea"
const CHECK_ON_OTHER_PERSON_LABEL = "check on the other person"
const DRANK_WATER_LABEL_FRAGMENT = "last time you drank water"
const LIV_TRY_BEST_TEXT = "Liv: Oh... oh god... ok... I'll try my best."
const LIV_TRY_BEST_TEXT_ALT = "Liv: Oh… oh god… ok… I’ll try my best."
const CALL_FOR_HELP_INSERT_TEXT = "Call for help!"
const INTRO_PORTRAIT_UNLOCK_TEXT = "You step outside and notice it's warm despite being dark outside. Everyone sounds like they're having a good time at the party."
const INSIDE_BACKGROUND_TRIGGER_TEXT = "Your friends go to party in some side room, so you can’t find them. Now you don't anyone and it's just awkward."
const OUTSIDE_BACKGROUND_RETURN_TEXT = "Vicky: Hrrgh… I don’t wanna… Ugh… My head… hehe… Livvy.."
const PASSED_OUT_BACKGROUND_TEXT = "Vicky vomits and passes out, collapsing on the floor. Liv catches them."
const PASSED_OUT_BACKGROUND_END_TEXT = "Liv is holding Vicky steady on her side."
const LEVEL_END_TRIGGER_TEXT = "Frank: What the heck happened here?!"
const TWO_EXHAUSTED_PEOPLE_TEXT = "Suddenly, you see two people who seem very exhausted. They both appear to have trouble walking. You don't know who they are. Who do you help?"
const ONLOOKER_ASSESSMENT_TEXT = "You have to assess whether they are just sleep deprived, or actually suffering from alcohol poisoning. Someone has just walked over."
const TALK_TO_ONLOOKER_LABEL = "talk to onlooker"

var arcweave_asset: ArcweaveAsset = preload("res://addons/arcweave/LevelOne.tres")
var Story = load("res://addons/arcweave/Story.cs")
var story
var project_data: Dictionary
var cursor_sprite: TextureRect
var menu_button: TextureButton
var current_portrait_names: Array[String] = []
var portrait_1_action_path = null
var portrait_2_action_path = null
var is_portrait_1_interactive := false
var is_portrait_2_interactive := false
var default_portrait_1_position := Vector2.ZERO
var default_portrait_2_position := Vector2.ZERO
var default_portrait_1_scale := Vector2.ONE
var default_portrait_2_scale := Vector2.ONE
var default_speaker_name_position := Vector2.ZERO
var default_world_position := Vector2.ZERO
var default_choice_container_position := Vector2.ZERO
var default_choice_container_size := Vector2.ZERO
var default_choice_container_offset_left := 0.0
var default_choice_container_offset_top := 0.0
var default_choice_container_offset_right := 0.0
var default_choice_container_offset_bottom := 0.0
var pending_gauze_path = null
var pending_napkins_path = null
var pending_phone_path = null
var pending_alcohol_path = null
var pending_hot_water_path = null
var pending_rhythm_game_path = null
var portraits_locked := false
var inside_background_active := false
var is_passed_out_background_active := false
var has_entered_vicky_outside_sequence := false
var has_seen_vicky_collapse := false
var default_background_size := Vector2.ZERO
var default_outside_background_texture: Texture2D
var portrait_1_hotspot: Button
var portrait_2_hotspot: Button
var alcohol_hotspot: Button
var hot_water_hotspot: Button
var is_alcohol_interactive := false
var is_hot_water_interactive := false
var inside_scene_default_positions := {}
var active_cpr_minigame_root: Node
var active_cpr_minigame: Node
var victory_overlay: TextureRect
var is_showing_victory_screen := false
var is_showing_inserted_call_for_help_line := false

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
		print("Speaker parse miss [level_1]: raw=", raw_text, " | plain=", plain_text, " | speaker_candidate=", speaker)
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
	_capture_inside_scene_default_positions()
	if portrait_1 != null:
		default_portrait_1_position = portrait_1.position
		default_portrait_1_scale = portrait_1.scale
	if portrait_2 != null:
		default_portrait_2_position = portrait_2.position
		default_portrait_2_scale = portrait_2.scale
	if speaker_name != null:
		default_speaker_name_position = speaker_name.position
	if choice_container != null:
		default_choice_container_position = choice_container.position
		default_choice_container_size = choice_container.size
		default_choice_container_offset_left = choice_container.offset_left
		default_choice_container_offset_top = choice_container.offset_top
		default_choice_container_offset_right = choice_container.offset_right
		default_choice_container_offset_bottom = choice_container.offset_bottom

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_create_cursor_sprite()
	_create_menu_button()
	_create_victory_overlay()
	_connect_ui()
	_configure_choice_container()
	_create_portrait_hotspots()
	_create_world_hotspots()
	_configure_inventory_rows()
	portraits_locked = use_intro_portrait_lock
	_set_inside_background_active(false)

	project_data = arcweave_asset.project_settings
	if project_data.get("startingElement", null) == null:
		push_error("Arcweave LevelOne export is missing a startingElement. Set a start element in Arcweave and re-export the JSON.")
		return

	story = Story.new(project_data)
	if story == null:
		push_error("Arcweave story failed to initialize from LevelOne.tres.")
		return
	repaint()
	set_process(true)

func _process(_delta: float) -> void:
	if cursor_sprite != null:
		var mouse_position = get_viewport().get_mouse_position()
		cursor_sprite.position = mouse_position - (CURSOR_HOTSPOT * CURSOR_SCALE)

	if portrait_1 != null and world != null:
		portrait_1.position = _get_active_portrait_position(default_portrait_1_position, inside_portrait_1_position)
	if portrait_2 != null and world != null:
		portrait_2.position = _get_active_portrait_position(default_portrait_2_position, inside_portrait_2_position)
	if portrait_1 != null:
		portrait_1.scale = default_portrait_1_scale
	if portrait_2 != null:
		portrait_2.scale = _get_active_portrait_2_scale()
	if speaker_name != null:
		speaker_name.position = default_speaker_name_position
	_update_choice_container_layout(_get_current_story_text())
	_update_portrait_hotspots()
	_update_world_hotspots()

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
	_maybe_unlock_portraits()
	_update_story_background()
	var current_story_text: String = story.GetCurrentRuntimeContent()
	if _should_show_call_for_help_insert(current_story_text):
		is_showing_inserted_call_for_help_line = true
		current_story_text = CALL_FOR_HELP_INSERT_TEXT
	else:
		is_showing_inserted_call_for_help_line = false
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
	if is_showing_inserted_call_for_help_line:
		for option in choice_container.get_children():
			option.queue_free()
		choice_container.visible = false
		advance_trigger.visible = true
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP
		_set_portrait_interactive(false, false)
		_set_world_interactive(false, false)
		_set_inventory_item_interactivity()
		return

	for option in choice_container.get_children():
		option.queue_free()

	portrait_1_action_path = null
	portrait_2_action_path = null
	pending_gauze_path = null
	pending_napkins_path = null
	pending_phone_path = null
	pending_alcohol_path = null
	pending_hot_water_path = null
	pending_rhythm_game_path = null
	var normal_choice_paths := []

	var options = story.GenerateCurrentOptions()
	var paths = options.Paths

	if paths == null or paths.size() == 0:
		choice_container.visible = false
		advance_trigger.visible = true
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP
		_set_portrait_interactive(false)
		_set_world_interactive(false, false)
		_set_inventory_item_interactivity()
		return

	var visible_choice_count := 0
	for i in range(paths.size()):
		var path = paths[i]
		if not path.IsValid:
			continue
		if _is_frank_talk_path(path):
			portrait_1_action_path = path
			continue
		if _is_use_gauze_path(path):
			pending_gauze_path = path
			continue
		if _is_use_napkins_path(path):
			pending_napkins_path = path
			continue
		if _is_open_phone_path(path):
			pending_phone_path = path
			continue
		if _is_get_more_alcohol_path(path):
			pending_alcohol_path = path
			continue
		if _is_get_hot_water_path(path):
			pending_hot_water_path = path
			continue
		if _is_play_rhythm_game_path(path):
			pending_rhythm_game_path = path
			continue
		if _is_tap_through_only_path(path):
			continue
		if _is_talk_to_onlooker_path(path):
			portrait_2_action_path = path
			continue

		normal_choice_paths.append(path)
		var button := _create_choice_button(_get_path_label_text(path), i, paths)
		choice_container.add_child(button)
		visible_choice_count += 1

	if normal_choice_paths.size() == 1 and not _should_keep_single_choice_button(normal_choice_paths[0]):
		for option in choice_container.get_children():
			option.queue_free()
		visible_choice_count = 0

	var current_text: String = story.GetCurrentRuntimeContent().strip_edges()
	_update_choice_container_layout(current_text)
	if _is_two_person_help_state(current_text) and normal_choice_paths.size() >= 2:
		for option in choice_container.get_children():
			option.queue_free()
		visible_choice_count = 0
		portrait_1_action_path = normal_choice_paths[0]
		portrait_2_action_path = normal_choice_paths[1]

	if pending_rhythm_game_path != null and active_cpr_minigame_root == null:
		if bypass_cpr_minigame:
			call_deferred("_advance_pending_rhythm_game_path")
			return
		for option in choice_container.get_children():
			option.queue_free()
		visible_choice_count = 0
		choice_container.visible = false
		advance_trigger.visible = false
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_portrait_interactive(false)
		_set_world_interactive(false, false)
		_set_inventory_item_interactivity()
		call_deferred("_start_cpr_minigame")
		return

	_set_portrait_interactive(portrait_1_action_path != null, portrait_2_action_path != null)
	if is_passed_out_background_active:
		_set_portrait_interactive(false, false)
	_set_world_interactive(pending_alcohol_path != null, pending_hot_water_path != null)
	choice_container.visible = visible_choice_count > 0

	var has_manual_interaction := portrait_1_action_path != null or portrait_2_action_path != null or pending_gauze_path != null or pending_napkins_path != null or pending_phone_path != null or pending_alcohol_path != null or pending_hot_water_path != null or pending_rhythm_game_path != null
	advance_trigger.visible = not choice_container.visible and not has_manual_interaction
	advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP if advance_trigger.visible else Control.MOUSE_FILTER_IGNORE

	_set_inventory_item_interactivity()

func _create_choice_button(button_text: String, index, paths) -> TextureButton:
	var is_onlooker_choice_state := _is_onlooker_assessment_state(_get_current_story_text())
	var layout_size := ONLOOKER_CHOICE_BUBBLE_LAYOUT_SIZE if is_onlooker_choice_state else CHOICE_BUBBLE_LAYOUT_SIZE
	var visual_scale := ONLOOKER_CHOICE_BUBBLE_VISUAL_SCALE if is_onlooker_choice_state else CHOICE_BUBBLE_VISUAL_SCALE
	var button := TextureButton.new()
	button.texture_normal = TALK_BUBBLE_TEXTURE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = layout_size
	button.size = layout_size
	button.scale = visual_scale
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if is_onlooker_choice_state else Control.SIZE_FILL
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
	label.add_theme_font_size_override("font_size", 26 if is_onlooker_choice_state else 30)
	label.position = Vector2(42.0, 18.0) if is_onlooker_choice_state else Vector2(55.0, 22.0)
	label.size = Vector2(layout_size.x - 68.0, layout_size.y - 22.0) if is_onlooker_choice_state else Vector2(layout_size.x - 80.0, layout_size.y - 28.0)
	button.add_child(label)

	return button

func _configure_choice_container() -> void:
	if choice_container == null:
		return
	choice_container.add_theme_constant_override("separation", -8)

func _update_choice_container_layout(current_text: String) -> void:
	if choice_container == null:
		return
	if _is_onlooker_assessment_state(current_text):
		choice_container.offset_left = ONLOOKER_CHOICE_CONTAINER_POSITION.x
		choice_container.offset_top = ONLOOKER_CHOICE_CONTAINER_POSITION.y
		choice_container.offset_right = ONLOOKER_CHOICE_CONTAINER_POSITION.x + ONLOOKER_CHOICE_CONTAINER_SIZE.x
		choice_container.offset_bottom = ONLOOKER_CHOICE_CONTAINER_POSITION.y + ONLOOKER_CHOICE_CONTAINER_SIZE.y
	else:
		choice_container.offset_left = default_choice_container_offset_left
		choice_container.offset_top = default_choice_container_offset_top
		choice_container.offset_right = default_choice_container_offset_right
		choice_container.offset_bottom = default_choice_container_offset_bottom

func _get_active_portrait_2_scale() -> Vector2:
	return default_portrait_2_scale

func _capture_inside_scene_default_positions() -> void:
	if world == null:
		return
	for child in world.get_children():
		if child is Sprite2D:
			inside_scene_default_positions[child.name] = child.position

func clean_name(raw_name: String) -> String:
	return raw_name.strip_edges()

func _on_portrait_action_selected(path) -> void:
	if path == null:
		return
	story.SelectPath(path)
	repaint()

func set_object_cursor() -> void:
	_set_cursor_texture(OBJECT_CURSOR_TEXTURE)

func set_default_cursor() -> void:
	_set_cursor_texture(DEFAULT_CURSOR_TEXTURE)

func set_world_focus_x(focus_x: float) -> void:
	_apply_world_focus(focus_x)
	default_world_position = world.position

func set_portrait_lock(enabled: bool) -> void:
	portraits_locked = enabled
	if not enabled:
		_update_portrait()

func unlock_portraits() -> void:
	set_portrait_lock(false)

func _maybe_unlock_portraits() -> void:
	if not portraits_locked or story == null:
		return
	var current_text: String = story.GetCurrentRuntimeContent().strip_edges()
	if current_text == INTRO_PORTRAIT_UNLOCK_TEXT:
		portraits_locked = false

func _update_story_background() -> void:
	if story == null:
		return
	var current_text: String = story.GetCurrentRuntimeContent().strip_edges()
	if _is_passed_out_background_start_state(current_text):
		has_entered_vicky_outside_sequence = true
		has_seen_vicky_collapse = true
		is_passed_out_background_active = true
	elif _is_passed_out_background_end_state(current_text):
		is_passed_out_background_active = false
	_reset_background_overrides()
	if is_passed_out_background_active:
		_set_inside_background_active(false)
		_apply_passed_out_background()
		return
	if current_text == OUTSIDE_BACKGROUND_RETURN_TEXT:
		has_entered_vicky_outside_sequence = true
		is_passed_out_background_active = false
		_set_inside_background_active(false)
		return
	if _is_passed_out_background_end_state(current_text):
		_set_inside_background_active(false)
		return
	if inside_background_active:
		_set_inside_background_active(true)
		return
	if current_text == INSIDE_BACKGROUND_TRIGGER_TEXT:
		_set_inside_background_active(true)

func _reset_background_overrides() -> void:
	if background_outside != null and default_outside_background_texture != null:
		background_outside.texture = default_outside_background_texture
		background_outside.position = Vector2.ZERO
		if default_background_size != Vector2.ZERO:
			background_outside.size = default_background_size

func _apply_passed_out_background() -> void:
	if background_outside == null:
		return
	background_outside.texture = PASSED_OUT_TEXTURE
	background_outside.position = Vector2.ZERO
	background_outside.size = PASSED_OUT_TEXTURE.get_size()
	if world != null:
		_apply_world_focus(PASSED_OUT_TEXTURE.get_size().x * 0.5)

func _is_passed_out_background_start_state(text: String) -> bool:
	var normalized_text := _normalize_label(text)
	return "vicky vomits and passes out" in normalized_text

func _is_passed_out_background_end_state(text: String) -> bool:
	return _normalize_label(text) == _normalize_label(PASSED_OUT_BACKGROUND_END_TEXT)

func _set_inside_background_active(is_inside: bool) -> void:
	inside_background_active = is_inside
	set_world_focus_x(inside_focus_x if is_inside else starting_focus_x)
	if background_outside != null:
		background_outside.visible = not is_inside
		background_outside.position = Vector2.ZERO
		if default_background_size != Vector2.ZERO:
			background_outside.size = default_background_size
	if background_inside != null:
		background_inside.visible = is_inside
		background_inside.position = Vector2.ZERO
		if default_background_size != Vector2.ZERO:
			background_inside.size = default_background_size
	_update_inside_scene_props()

func _update_inside_scene_props() -> void:
	if world == null:
		return
	for child in world.get_children():
		if child is Sprite2D and inside_scene_default_positions.has(child.name):
			var base_position: Vector2 = inside_scene_default_positions[child.name]
			child.position = base_position - Vector2(0, INSIDE_SCENE_VERTICAL_OFFSET) if inside_background_active else base_position

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

func _create_world_hotspots() -> void:
	alcohol_hotspot = _create_portrait_hotspot(_on_alcohol_mouse_entered, _on_alcohol_mouse_exited, _on_alcohol_gui_input)
	hot_water_hotspot = _create_portrait_hotspot(_on_hot_water_mouse_entered, _on_hot_water_mouse_exited, _on_hot_water_gui_input)

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

func _get_active_portrait_position(default_position: Vector2, inside_position: Vector2) -> Vector2:
	if inside_background_active and use_inside_portrait_positions:
		return inside_position
	return default_position

func _update_portrait_hotspots() -> void:
	_update_single_portrait_hotspot(portrait_1, portrait_1_hotspot, is_portrait_1_interactive)
	_update_single_portrait_hotspot(portrait_2, portrait_2_hotspot, is_portrait_2_interactive)

func _update_world_hotspots() -> void:
	_update_sprite_hotspot(alcohol_sprite, alcohol_hotspot, is_alcohol_interactive)
	_update_hot_water_hotspot()

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

func _update_sprite_hotspot(sprite: Sprite2D, hotspot: Button, is_interactive: bool) -> void:
	if sprite == null or hotspot == null:
		return
	if not sprite.visible or not is_interactive:
		hotspot.visible = false
		return
	var rect := _get_sprite_rect(sprite)
	hotspot.position = rect.position
	hotspot.size = rect.size
	hotspot.visible = true

func _update_hot_water_hotspot() -> void:
	if hot_water_hotspot == null:
		return
	if not is_hot_water_interactive or hot_water_sprite == null or water_heater_sprite == null:
		hot_water_hotspot.visible = false
		return
	if not hot_water_sprite.visible or not water_heater_sprite.visible:
		hot_water_hotspot.visible = false
		return
	var combined_rect := _get_sprite_rect(hot_water_sprite).merge(_get_sprite_rect(water_heater_sprite))
	hot_water_hotspot.position = combined_rect.position
	hot_water_hotspot.size = combined_rect.size
	hot_water_hotspot.visible = true

func _get_sprite_rect(sprite: Sprite2D) -> Rect2:
	if sprite == null or sprite.texture == null:
		return Rect2()
	var texture_size := sprite.texture.get_size() * sprite.scale.abs()
	return Rect2(sprite.global_position - (texture_size / 2.0), texture_size)

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

	if inventory_close_button != null:
		inventory_close_button.z_index = 203
		inventory_close_button.visible = false
		inventory_close_button.pressed.connect(_on_inventory_close_pressed)

	if inventory_items_container != null:
		inventory_items_container.z_index = 203
		inventory_items_container.visible = false

func _configure_inventory_rows() -> void:
	if inventory_items_container == null:
		return

	var gauze_icon = inventory_items_container.get_node_or_null("GauzeRow/Icon")
	var gauze_label = inventory_items_container.get_node_or_null("GauzeRow/Label")
	var napkin_icon = inventory_items_container.get_node_or_null("NapkinRow/Icon")
	var napkin_label = inventory_items_container.get_node_or_null("NapkinRow/Label")
	var phone_icon = inventory_items_container.get_node_or_null("PhoneRow/Icon")
	var phone_label = inventory_items_container.get_node_or_null("PhoneRow/Label")

	if gauze_icon != null:
		gauze_icon.texture = GAUZE_TEXTURE
		gauze_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if gauze_label != null:
		gauze_label.text = "Gauze"
		gauze_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if napkin_icon != null:
		napkin_icon.texture = NAPKINS_TEXTURE
		napkin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if napkin_label != null:
		napkin_label.text = "Napkin"
		napkin_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if phone_icon != null:
		phone_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if phone_label != null:
		phone_label.text = "Phone"
		phone_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if gauze_row != null:
		gauze_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gauze_row.gui_input.connect(_on_gauze_row_gui_input)
		gauze_row.mouse_entered.connect(_on_gauze_row_mouse_entered)
		gauze_row.mouse_exited.connect(_on_inventory_row_mouse_exited)
	if napkin_row != null:
		napkin_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		napkin_row.gui_input.connect(_on_napkin_row_gui_input)
		napkin_row.mouse_entered.connect(_on_napkin_row_mouse_entered)
		napkin_row.mouse_exited.connect(_on_inventory_row_mouse_exited)
	if phone_row != null:
		phone_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		phone_row.gui_input.connect(_on_phone_row_gui_input)
		phone_row.mouse_entered.connect(_on_phone_row_mouse_entered)
		phone_row.mouse_exited.connect(_on_inventory_row_mouse_exited)

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
	_set_inventory_item_interactivity()

func _set_inventory_item_interactivity() -> void:
	var is_open := inventory_popup_panel != null and inventory_popup_panel.visible
	var has_inventory_action := pending_gauze_path != null or pending_napkins_path != null or pending_phone_path != null

	if inventory_ui != null:
		inventory_ui.visible = true
	if not has_inventory_action and is_open:
		if inventory_popup_panel != null:
			inventory_popup_panel.visible = false
		if inventory_popup_background != null:
			inventory_popup_background.visible = false
		if inventory_close_button != null:
			inventory_close_button.visible = false
		if inventory_items_container != null:
			inventory_items_container.visible = false
		is_open = false

	if gauze_row != null:
		gauze_row.mouse_filter = Control.MOUSE_FILTER_STOP if is_open and pending_gauze_path != null else Control.MOUSE_FILTER_IGNORE
		gauze_row.modulate = Color.WHITE
	if napkin_row != null:
		napkin_row.mouse_filter = Control.MOUSE_FILTER_STOP if is_open and pending_napkins_path != null else Control.MOUSE_FILTER_IGNORE
		napkin_row.modulate = Color.WHITE
	if phone_row != null:
		phone_row.mouse_filter = Control.MOUSE_FILTER_STOP if is_open and pending_phone_path != null else Control.MOUSE_FILTER_IGNORE
		phone_row.modulate = Color.WHITE

func _set_cursor_texture(texture: Texture2D) -> void:
	if cursor_sprite == null:
		return
	cursor_sprite.texture = texture
	cursor_sprite.custom_minimum_size = texture.get_size()
	cursor_sprite.size = texture.get_size()

func _create_menu_button() -> void:
	menu_button = TextureButton.new()
	menu_button.texture_normal = MENU_BUTTON_TEXTURE
	menu_button.ignore_texture_size = true
	menu_button.stretch_mode = TextureButton.STRETCH_SCALE
	menu_button.custom_minimum_size = MENU_BUTTON_SIZE
	menu_button.size = MENU_BUTTON_SIZE
	menu_button.position = Vector2(36.0, 28.0)
	menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_button.z_index = 320
	menu_button.pressed.connect(_go_to_home_menu)
	menu_button.mouse_entered.connect(_on_menu_button_mouse_entered)
	menu_button.mouse_exited.connect(_on_menu_button_mouse_exited)
	add_child(menu_button)

func _go_to_home_menu() -> void:
	get_tree().change_scene_to_file(HOME_MENU_SCENE_PATH)

func _on_menu_button_mouse_entered() -> void:
	if menu_button != null:
		menu_button.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_menu_button_mouse_exited() -> void:
	if menu_button != null:
		menu_button.modulate = Color.WHITE
	set_default_cursor()

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

func _set_world_interactive(alcohol_value: bool, hot_water_value: bool) -> void:
	is_alcohol_interactive = alcohol_value and alcohol_sprite != null and pending_alcohol_path != null
	is_hot_water_interactive = hot_water_value and hot_water_sprite != null and water_heater_sprite != null and pending_hot_water_path != null
	if alcohol_hotspot != null:
		alcohol_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP if is_alcohol_interactive else Control.MOUSE_FILTER_IGNORE
	if hot_water_hotspot != null:
		hot_water_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP if is_hot_water_interactive else Control.MOUSE_FILTER_IGNORE
	if not is_alcohol_interactive and alcohol_sprite != null:
		alcohol_sprite.modulate = Color.WHITE
	if not is_hot_water_interactive:
		if hot_water_sprite != null:
			hot_water_sprite.modulate = Color.WHITE
		if water_heater_sprite != null:
			water_heater_sprite.modulate = Color.WHITE
	_update_world_hotspots()

func _update_portrait() -> void:
	if is_passed_out_background_active:
		if portrait_1 != null:
			portrait_1.visible = false
		if portrait_2 != null:
			portrait_2.visible = false
		if speaker_name != null:
			speaker_name.visible = false
		return
	if portraits_locked:
		_apply_locked_portraits()
		return

	var component_names := get_component_names_for_element()
	current_portrait_names.clear()

	var visible_names: Array[String] = []
	for component_name in component_names:
		var normalized_component_name := _normalize_label(component_name)
		if has_seen_vicky_collapse and normalized_component_name == "vicky sick":
			continue
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

	_apply_post_collapse_sticky_portrait(visible_names)

func _apply_locked_portraits() -> void:
	var visible_names: Array[String] = []
	current_portrait_names.clear()

	var portrait_1_path := _get_portrait_path(intro_portrait_1_name)
	var portrait_2_path := _get_portrait_path(intro_portrait_2_name)

	if portrait_1 != null:
		if portrait_1_path != "":
			portrait_1.texture = load(portrait_1_path)
			portrait_1.visible = true
			visible_names.append(intro_portrait_1_name)
			current_portrait_names.append(intro_portrait_1_name)
		else:
			portrait_1.visible = false

	if portrait_2 != null:
		if portrait_2_path != "":
			portrait_2.texture = load(portrait_2_path)
			portrait_2.visible = true
			visible_names.append(intro_portrait_2_name)
			current_portrait_names.append(intro_portrait_2_name)
		else:
			portrait_2.visible = false

func _apply_post_collapse_sticky_portrait(visible_names: Array[String]) -> void:
	if not _should_force_outside_vicky_portrait():
		return
	if has_seen_vicky_collapse:
		var onlooker_portrait_path := _get_portrait_path("Onlooker_Fear")
		if onlooker_portrait_path == "":
			return
		if portrait_2 != null:
			portrait_2.texture = load(onlooker_portrait_path)
			portrait_2.visible = true
		return
	if visible_names.has("Vicky_Sick") or visible_names.has("Vicky Sick"):
		return
	var vicky_portrait_path := _get_portrait_path("Vicky_Sick")
	if vicky_portrait_path == "":
		return
	if portrait_1 != null and not portrait_1.visible:
		portrait_1.texture = load(vicky_portrait_path)
		portrait_1.visible = true
	elif portrait_2 != null and not portrait_2.visible:
		portrait_2.texture = load(vicky_portrait_path)
		portrait_2.visible = true
func _should_force_outside_vicky_portrait() -> bool:
	return has_entered_vicky_outside_sequence and not inside_background_active and not is_passed_out_background_active

func _path_label_contains(path, text: String) -> bool:
	return text in _normalize_label(path.label)

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
	return component_name != ""

func _is_two_person_help_state(text: String) -> bool:
	var normalized_text := _normalize_label(text)
	var normalized_trigger := _normalize_label(TWO_EXHAUSTED_PEOPLE_TEXT)
	return normalized_trigger in normalized_text or (
		"who do you help" in normalized_text
		and "two people" in normalized_text
		and "trouble walking" in normalized_text
	)

func _get_portrait_path(component_name: String) -> String:
	if component_name == "":
		return ""

	var candidates := []
	var trimmed_name := component_name.strip_edges()
	var underscored_name := trimmed_name.replace(" ", "_")
	var dashed_name := trimmed_name.replace(" ", "-")

	candidates.append("res://Assets/portraits/%s.png" % trimmed_name)
	candidates.append("res://Assets/portraits/%s.png" % underscored_name)
	candidates.append("res://Assets/portraits/%s.png" % dashed_name)

	match trimmed_name.to_lower():
		"frank":
			candidates.append("res://Assets/portraits/Frank_Normal.png")
		"frank shock", "frank shocked":
			candidates.append("res://Assets/portraits/Frank_Shocked.png")
		"driver friend":
			candidates.append("res://Assets/portraits/Driver_Friend.png")
		"vicky happy":
			candidates.append("res://Assets/portraits/Vicky_Happy.png")
		"vicky sick":
			candidates.append("res://Assets/portraits/Vicky_Sick.png")
		"onlooker fear":
			candidates.append("res://Assets/portraits/Onlooker_Fear.png")

	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			return candidate

	return ""

func _is_frank_talk_path(path) -> bool:
	return _normalize_label(path.label) == TALK_TO_FRANK_LABEL or _path_label_contains(path, "talking to frank")

func _is_use_gauze_path(path) -> bool:
	return _normalize_label(path.label) == USE_GAUZE_LABEL

func _is_use_napkins_path(path) -> bool:
	return _normalize_label(path.label) == USE_NAPKINS_LABEL

func _is_open_phone_path(path) -> bool:
	var normalized_label := _normalize_label(path.label)
	return normalized_label == OPEN_PHONE_LABEL or normalized_label == CALL_911_LABEL

func _is_get_more_alcohol_path(path) -> bool:
	return _normalize_label(path.label) == GET_MORE_ALCOHOL_LABEL

func _is_get_hot_water_path(path) -> bool:
	return _normalize_label(path.label) == GET_HOT_WATER_LABEL

func _is_play_rhythm_game_path(path) -> bool:
	return _normalize_label(path.label) == PLAY_RHYTHM_GAME_LABEL

func _is_tap_through_only_path(path) -> bool:
	var normalized_label := _normalize_label(path.label)
	return normalized_label == GIVE_HOT_TEA_LABEL or normalized_label == CHECK_ON_OTHER_PERSON_LABEL

func _should_keep_single_choice_button(path) -> bool:
	if path == null:
		return false
	return DRANK_WATER_LABEL_FRAGMENT in _normalize_label(path.label)

func _is_talk_to_onlooker_path(path) -> bool:
	return _normalize_label(path.label) == TALK_TO_ONLOOKER_LABEL

func _get_current_story_text() -> String:
	if story == null:
		return ""
	return story.GetCurrentRuntimeContent().strip_edges()

func _is_onlooker_assessment_state(text: String) -> bool:
	var normalized_text := _normalize_label(text)
	var normalized_trigger := _normalize_label(ONLOOKER_ASSESSMENT_TEXT)
	return normalized_trigger in normalized_text or (
		"alcohol poisoning" in normalized_text
		and ("someone has just walked over" in normalized_text or "danny has just walked over" in normalized_text)
	)

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
	if _is_play_rhythm_game_path(selected_path):
		pending_rhythm_game_path = selected_path
		_start_cpr_minigame()
		return
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

func _on_alcohol_mouse_entered() -> void:
	if not is_alcohol_interactive or alcohol_sprite == null:
		return
	alcohol_sprite.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_alcohol_mouse_exited() -> void:
	if alcohol_sprite != null:
		alcohol_sprite.modulate = Color.WHITE
	set_default_cursor()

func _on_alcohol_gui_input(event) -> void:
	if not is_alcohol_interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		_on_alcohol_pressed()

func _on_alcohol_pressed() -> void:
	if not is_alcohol_interactive or pending_alcohol_path == null:
		return
	var selected_path = pending_alcohol_path
	pending_alcohol_path = null
	_set_world_interactive(false, is_hot_water_interactive)
	story.SelectPath(selected_path)
	repaint()

func _on_hot_water_mouse_entered() -> void:
	if not is_hot_water_interactive:
		return
	if hot_water_sprite != null:
		hot_water_sprite.modulate = HOVER_PORTRAIT_TINT
	if water_heater_sprite != null:
		water_heater_sprite.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_hot_water_mouse_exited() -> void:
	if hot_water_sprite != null:
		hot_water_sprite.modulate = Color.WHITE
	if water_heater_sprite != null:
		water_heater_sprite.modulate = Color.WHITE
	set_default_cursor()

func _on_hot_water_gui_input(event) -> void:
	if not is_hot_water_interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		_on_hot_water_pressed()

func _on_hot_water_pressed() -> void:
	if not is_hot_water_interactive or pending_hot_water_path == null:
		return
	var selected_path = pending_hot_water_path
	pending_hot_water_path = null
	_set_world_interactive(is_alcohol_interactive, false)
	story.SelectPath(selected_path)
	repaint()

func _on_continue_pressed() -> void:
	if is_showing_victory_screen:
		get_tree().change_scene_to_file(HOME_MENU_SCENE_PATH)
		return
	if is_showing_inserted_call_for_help_line:
		is_showing_inserted_call_for_help_line = false
		var options = story.GenerateCurrentOptions()
		var paths = options.Paths
		if paths != null and paths.size() > 0:
			story.SelectPath(paths[0])
			repaint()
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

func _should_show_call_for_help_insert(current_story_text: String) -> bool:
	var normalized_text := _normalize_label(_strip_dialogue_markup(current_story_text))
	var normalized_default := _normalize_label(LIV_TRY_BEST_TEXT)
	var normalized_alt := _normalize_label(LIV_TRY_BEST_TEXT_ALT)
	return normalized_text == normalized_default or normalized_text == normalized_alt

func _advance_pending_rhythm_game_path() -> void:
	if pending_rhythm_game_path == null:
		return
	var selected_path = pending_rhythm_game_path
	pending_rhythm_game_path = null
	story.SelectPath(selected_path)
	repaint()

func _start_cpr_minigame() -> void:
	if active_cpr_minigame_root != null:
		return
	active_cpr_minigame_root = CPR_MINIGAME_SCENE.instantiate()
	add_child(active_cpr_minigame_root)
	if active_cpr_minigame_root is CanvasItem:
		active_cpr_minigame_root.visible = true
		if "z_index" in active_cpr_minigame_root:
			active_cpr_minigame_root.z_index = 500
	active_cpr_minigame = active_cpr_minigame_root.get_node_or_null("CPRMinigame")
	if active_cpr_minigame == null and active_cpr_minigame_root.name == "CPRMinigame":
		active_cpr_minigame = active_cpr_minigame_root
	if active_cpr_minigame != null and active_cpr_minigame.has_signal("minigame_completed"):
		active_cpr_minigame.minigame_completed.connect(_on_cpr_minigame_completed)
	_set_main_scene_visible(false)
	_set_main_scene_input_enabled(false)
	if cursor_sprite != null:
		cursor_sprite.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _end_cpr_minigame() -> void:
	if active_cpr_minigame_root != null:
		active_cpr_minigame_root.queue_free()
	active_cpr_minigame_root = null
	active_cpr_minigame = null
	_set_main_scene_visible(true)
	_set_main_scene_input_enabled(true)
	if cursor_sprite != null:
		cursor_sprite.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	set_default_cursor()

func _on_cpr_minigame_completed(_score: float) -> void:
	_end_cpr_minigame()
	if pending_rhythm_game_path != null:
		var selected_path = pending_rhythm_game_path
		pending_rhythm_game_path = null
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
	if inventory_ui != null:
		inventory_ui.visible = is_visible
	if portrait_1_hotspot != null:
		portrait_1_hotspot.visible = is_visible and is_portrait_1_interactive
	if portrait_2_hotspot != null:
		portrait_2_hotspot.visible = is_visible and is_portrait_2_interactive
	if alcohol_hotspot != null:
		alcohol_hotspot.visible = is_visible and is_alcohol_interactive
	if hot_water_hotspot != null:
		hot_water_hotspot.visible = is_visible and is_hot_water_interactive

func _set_victory_screen_visible(is_visible: bool) -> void:
	is_showing_victory_screen = is_visible
	if victory_overlay != null:
		victory_overlay.visible = is_visible
	if world != null:
		world.visible = not is_visible
	if portrait_1 != null:
		portrait_1.visible = false if is_visible else portrait_1.visible
		if is_visible:
			portrait_1.texture = null
	if portrait_2 != null:
		portrait_2.visible = false if is_visible else portrait_2.visible
		if is_visible:
			portrait_2.texture = null
	if dialogue_box != null:
		dialogue_box.visible = not is_visible
	if dialogue_text != null:
		dialogue_text.visible = not is_visible
	if speaker_name != null:
		speaker_name.visible = not is_visible and speaker_name.visible
	if choice_container != null and is_visible:
		choice_container.visible = false
	if inventory_ui != null and is_visible:
		inventory_ui.visible = false
	if advance_trigger != null:
		advance_trigger.visible = true if is_visible else advance_trigger.visible
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP if advance_trigger.visible else Control.MOUSE_FILTER_IGNORE
	if portrait_1_hotspot != null and is_visible:
		portrait_1_hotspot.visible = false
	if portrait_2_hotspot != null and is_visible:
		portrait_2_hotspot.visible = false
	if alcohol_hotspot != null and is_visible:
		alcohol_hotspot.visible = false
	if hot_water_hotspot != null and is_visible:
		hot_water_hotspot.visible = false

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
	if alcohol_hotspot != null:
		alcohol_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled and is_alcohol_interactive else Control.MOUSE_FILTER_IGNORE
	if hot_water_hotspot != null:
		hot_water_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled and is_hot_water_interactive else Control.MOUSE_FILTER_IGNORE
	if inventory_button != null:
		inventory_button.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled else Control.MOUSE_FILTER_IGNORE
	if gauze_row != null:
		gauze_row.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled and inventory_popup_panel != null and inventory_popup_panel.visible and pending_gauze_path != null else Control.MOUSE_FILTER_IGNORE
	if napkin_row != null:
		napkin_row.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled and inventory_popup_panel != null and inventory_popup_panel.visible and pending_napkins_path != null else Control.MOUSE_FILTER_IGNORE
	if phone_row != null:
		phone_row.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled and inventory_popup_panel != null and inventory_popup_panel.visible and pending_phone_path != null else Control.MOUSE_FILTER_IGNORE

func _on_inventory_button_pressed() -> void:
	_set_inventory_open(true)

func _on_inventory_close_pressed() -> void:
	_set_inventory_open(false)

func _on_gauze_row_gui_input(event) -> void:
	if pending_gauze_path == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		var selected_path = pending_gauze_path
		_set_inventory_open(false)
		story.SelectPath(selected_path)
		repaint()

func _on_napkin_row_gui_input(event) -> void:
	if pending_napkins_path == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		var selected_path = pending_napkins_path
		_set_inventory_open(false)
		story.SelectPath(selected_path)
		repaint()

func _on_phone_row_gui_input(event) -> void:
	if pending_phone_path == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		var selected_path = pending_phone_path
		_set_inventory_open(false)
		story.SelectPath(selected_path)
		repaint()

func _on_gauze_row_mouse_entered() -> void:
	if pending_gauze_path == null or gauze_row == null:
		return
	gauze_row.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_napkin_row_mouse_entered() -> void:
	if pending_napkins_path == null or napkin_row == null:
		return
	napkin_row.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_phone_row_mouse_entered() -> void:
	if pending_phone_path == null or phone_row == null:
		return
	phone_row.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_inventory_row_mouse_exited() -> void:
	if gauze_row != null:
		gauze_row.modulate = Color.WHITE
	if napkin_row != null:
		napkin_row.modulate = Color.WHITE
	if phone_row != null:
		phone_row.modulate = Color.WHITE
	set_default_cursor()

func _on_inventory_hotspot_mouse_entered() -> void:
	_set_inventory_button_highlighted(true)
	set_object_cursor()

func _on_inventory_hotspot_mouse_exited() -> void:
	_set_inventory_button_highlighted(false)
	set_default_cursor()

func _set_inventory_button_highlighted(is_highlighted: bool) -> void:
	if inventory_button_visual != null:
		inventory_button_visual.modulate = HOVER_PORTRAIT_TINT if is_highlighted else Color.WHITE
