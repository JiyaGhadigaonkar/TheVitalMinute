extends Control

const HOME_MENU_SCENE_PATH = "res://home_menu.tscn"

@onready var background = $World/Background
@onready var portrait = $Portrait
@onready var speaker_box = get_node_or_null("SpeakerBox")
@onready var speaker_name = $SpeakerName
@onready var dialogue_box = $DialogueBox
@onready var dialogue_text = $DialogueText
@onready var choice_container = $ChoiceContainer
@onready var advance_trigger = $AdvanceTrigger
@onready var inventory_ui = $InventoryUI
@onready var inventory_button = $InventoryUI/InventoryButton
@onready var inventory_button_visual = $InventoryUI/InventoryButton/InventoryButtonVisual
@onready var inventory_popup_panel = $InventoryUI/InventoryPopup
@onready var inventory_popup_background = $InventoryUI/InventoryPopup/PopupBackground
@onready var inventory_close_button = $InventoryUI/InventoryPopup/CloseButton
@onready var inventory_items_container = $InventoryUI/InventoryPopup/ItemsContainer
@onready var gauze_row = $InventoryUI/InventoryPopup/ItemsContainer/GauzeRow
@onready var napkin_row = $InventoryUI/InventoryPopup/ItemsContainer/NapkinRow
@onready var phone_row = $InventoryUI/InventoryPopup/ItemsContainer/PhoneRow
@onready var glass = $World/Glass
@onready var healthpack = $World/Healthpack
@onready var chair = $World/Chair
@onready var knife = $"World/Knife"
@onready var world = $World

const DEFAULT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_default.png")
const OBJECT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_object.png")
const LEFT_ARROW_TEXTURE = preload("res://Assets/arrows/left_arrow.png")
const RIGHT_ARROW_TEXTURE = preload("res://Assets/arrows/right_arrow.png")
const DOWN_ARROW_TEXTURE = preload("res://Assets/arrows/down_arrow.png")
const UP_ARROW_TEXTURE = preload("res://Assets/arrows/up_arrow.png")
const FOOT_SCENE_TEXTURE = preload("res://Assets/Scene_Foot.png")
const FOOT_WRAPPED_SCENE_TEXTURE = preload("res://Assets/Scene_Foot_Wrapped.png")
const BANDAGE_MINIGAME_SCENE = preload("res://minigametest.tscn")
const TALK_BUBBLE_TEXTURE = preload("res://Assets/talk.png")
const INVENTORY_ICON_TEXTURE = preload("res://Assets/tutorial_inventory.png")
const INVENTORY_CLOSE_TEXTURE = preload("res://Assets/inventory_close.png")
const GAUZE_TEXTURE = preload("res://Assets/Item_Tutorial_Gauze.png")
const NAPKINS_TEXTURE = preload("res://Assets/Item_Tutorial_Napkins.png")
const FRANK_NORMAL_TEXTURE = preload("res://Assets/portraits/Frank_Normal.png")
const CURSOR_HOTSPOT = Vector2(8, 0)
const CURSOR_SCALE = 1.35
const DIALOGUE_TEXT_COLOR = "#1f3a5f"
const SPEAKER_NAME_FONT_SIZE = 50
const DEFAULT_PORTRAIT_TINT = Color(1.0, 1.0, 1.0, 1.0)
const HOVER_PORTRAIT_TINT = Color(1.0, 0.95, 0.8, 1.0)
const DEFAULT_ARROW_TINT = Color(1.0, 1.0, 1.0, 1.0)
const HOVER_ARROW_TINT = Color(1.0, 0.95, 0.8, 1.0)
const ARROW_SCALE = 0.65
const FRANK_ANIMATED_PORTRAIT_PATH = "res://Assets/portraits/Frank_Normal_Animated.png"
const FRANK_TALK_ANIMATION_INTERVAL = 0.32
const FRANK_TALK_BOUNCE_OFFSET = -10.0
const ENABLE_FRANK_TALK_ANIMATION = false
const LEFT1_BAG_LABEL = "left1 grab frank's bag"
const RIGHT1_SINK_LABEL = "right1 investigate sink"
const CENTER1_WOUND_LABEL = "center1 investigate wound"
const LEFT_BAG_LABEL = "left grab frank's bag"
const RIGHT_SINK_LABEL = "right investigate sink"
const CENTER_WOUND_LABEL = "center investigate wound"
const CENTER_TALK_LABEL = "center talk to frank"
const CLICK_CHAIR_LABEL = "click chair"
const INSPECT_WOUND_LABEL = "inspect wound"
const USE_GAUZE_LABEL = "use gauze"
const USE_NAPKINS_LABEL = "use napkins"
const OPEN_PHONE_LABEL = "open phone"
const WIN_GAME_LABEL = "win the game"
const MISTAKES_WERE_MADE_LABEL = "mistakes were made"
const TUTORIAL_LABEL = "tutorial"
const SKIP_TO_LEVEL_1_LABEL = "skip to level 1"
const ASK_FRIEND_FOR_ADDRESS_LABEL = "ask yout friend for the address"
const ADDRESS_OPTION_1_LABEL = "2012 chimney rock road"
const ADDRESS_OPTION_2_LABEL = "5492 gilbright street"
const ADDRESS_OPTION_3_LABEL = "2342 chimney road"
const MAIN_CHOICE_ELEMENT_ID = "126b988e-de6d-4ac7-bb37-8904d96075e1"
const BANDAGE_MINIGAME_TRIGGER_TEXT = "gauze wrapping microgame here."
const RETURN_TO_MAIN_SCENE_TEXT = "frank: ow, dammit! don't touch the knife!!"
const RETURN_HOME_TEXT = "911-operator: \"we’re sending a unit over right now. please stay in place."
const INVENTORY_UNLOCK_PROMPT_TEXT = "you got the supplies. check them out in the inventory. you can go back to frank, who is now sitting down on the floor, pressing his foot."
const FOOT_INCIDENT_TEXT = "suddenly, one of the knives falls down and impales frank's foot. you stand up with a jolt, knocking your water glass onto the ground."
const FALLEN_GLASS_POSITION = Vector2(1328.0, 936.0)
const FALLEN_GLASS_ROTATION_DEGREES = 86.0
const HEALTHPACK_HOTSPOT_SIZE = Vector2(150.0, 120.0)
const HEALTHPACK_HOTSPOT_CENTER_OFFSET = Vector2(-52.0, -34.0)
const CHAIR_HIT_PADDING = 48.0
const CHOICE_BUBBLE_LAYOUT_SIZE = Vector2(760.0, 120.0)
const CHOICE_BUBBLE_VISUAL_SCALE = Vector2(1.22, 1.28)

var arcweave_asset: ArcweaveAsset = preload("res://addons/arcweave/TutorialStory.tres")
var Story = load("res://addons/arcweave/Story.cs")
var story
var project_data: Dictionary
var cursor_sprite: TextureRect
var current_portrait_name := ""
var is_portrait_interactive := false
var default_background_texture: Texture2D
var default_background_position := Vector2.ZERO
var default_background_size := Vector2.ZERO
var default_world_position := Vector2.ZERO
var default_portrait_position := Vector2.ZERO
var default_speaker_name_position := Vector2.ZERO
var default_glass_position := Vector2.ZERO
var default_glass_rotation := 0.0
var default_knife_visible := true
var portrait_animation_offset := Vector2.ZERO
var arrow_buttons := {}
var active_arrow_paths := {}
var is_showing_wound_preview := false
var healthpack_hotspot: TextureButton
var chair_hotspot: TextureButton
var inventory_hotspot: Button
var pending_healthpack_path = null
var pending_chair_path = null
var pending_gauze_path = null
var pending_napkins_path = null
var pending_phone_path = null
var pending_bandage_success_path = null
var pending_bandage_fail_path = null
var is_healthpack_interactive := false
var is_chair_interactive := false
var is_wound_scene_active := false
var current_view := "center"
var was_left_mouse_down := false
var active_bandage_minigame_root: Node
var active_bandage_minigame: Node
var last_bandage_minigame_trigger_text := ""
var is_showing_linear_preview := false
var linear_preview_texts: Array[String] = []
var linear_preview_index := 0
var is_showing_foot_incident_cutaway := false
var has_seen_foot_incident_cutaway := false
var is_inventory_unlocked := false
var should_flash_inventory_button := false
var is_inventory_button_hovered := false
var frank_animated_texture: Texture2D
var frank_talk_animation_timer: Timer
var is_frank_talk_animating := false
var is_frank_talk_animation_frame_active := false

func _ready():
	world.position.x = -1080
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	default_background_texture = background.texture
	default_background_position = background.position
	default_background_size = background.size
	default_world_position = world.position
	default_portrait_position = portrait.position
	default_speaker_name_position = speaker_name.position
	default_glass_position = glass.position
	default_glass_rotation = glass.rotation_degrees
	default_knife_visible = knife.visible
	cursor_sprite = TextureRect.new()
	cursor_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_sprite.z_index = 1000
	cursor_sprite.scale = Vector2.ONE * CURSOR_SCALE
	add_child(cursor_sprite)
	_set_cursor_texture(DEFAULT_CURSOR_TEXTURE)
	_configure_frank_talk_animation()
	set_process(true)
	advance_trigger.pressed.connect(_on_continue_pressed)
	advance_trigger.flat = true
	advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.mouse_entered.connect(_on_portrait_mouse_entered)
	portrait.mouse_exited.connect(_on_portrait_mouse_exited)
	portrait.gui_input.connect(_on_portrait_gui_input)
	portrait.modulate = DEFAULT_PORTRAIT_TINT
	inventory_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_button.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	inventory_button.z_index = 250
	inventory_button.ignore_texture_size = true
	inventory_close_button.pressed.connect(_on_inventory_close_pressed)
	inventory_ui.z_index = 200
	inventory_popup_panel.z_index = 201
	inventory_popup_background.z_index = 202
	inventory_close_button.z_index = 203
	inventory_items_container.z_index = 203
	inventory_popup_panel.visible = false
	inventory_popup_background.visible = false
	inventory_close_button.visible = false
	inventory_items_container.visible = false
	inventory_popup_panel.modulate = Color(1, 1, 1, 1)
	inventory_popup_background.rotation_degrees = 90
	inventory_popup_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_configure_inventory_rows()
	_create_inventory_hotspot()
	_create_healthpack_hotspot()
	_create_chair_hotspot()
	_create_arrow_buttons()
	_update_arrow_positions()
	_configure_choice_container()
	glass.is_interactive = false  # not clickable by default
	dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	project_data = arcweave_asset.project_settings
	story = Story.new(project_data)
	repaint()

func _process(_delta):
	if cursor_sprite == null:
		return
	var mouse_position = get_viewport().get_mouse_position()
	cursor_sprite.position = mouse_position - (CURSOR_HOTSPOT * CURSOR_SCALE)
	portrait.position = default_portrait_position + (world.position - default_world_position) + portrait_animation_offset
	speaker_name.position = default_speaker_name_position
	_update_healthpack_hotspot()
	_update_chair_hotspot()
	_update_inventory_hotspot()
	_update_inventory_button_flash()
	_update_manual_hotspot_hover(mouse_position)
	var is_left_mouse_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if is_left_mouse_down and not was_left_mouse_down:
		_handle_manual_hotspot_click(mouse_position)
	was_left_mouse_down = is_left_mouse_down

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_arrow_positions()

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
		print("Speaker parse miss [test]: raw=", raw_text, " | plain=", plain_text, " | speaker_candidate=", speaker)
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

func repaint():
	_sync_scene_mode_with_story()
	var current_story_text: String = story.GetCurrentRuntimeContent()
	dialogue_text.bbcode_enabled = true
	dialogue_text.add_theme_color_override("default_color", Color.html(DIALOGUE_TEXT_COLOR))
	dialogue_text.text = _format_dialogue_text(current_story_text)
	_update_foot_incident_scene_state(current_story_text)
	_update_inventory_unlock_state(current_story_text)
	
	var comp_name = get_component_name_for_element()
	var portrait_path = "res://Assets/portraits/" + comp_name + ".png"
	if _should_use_component_for_portrait(comp_name) and ResourceLoader.exists(portrait_path):
		current_portrait_name = comp_name
		portrait.texture = load(portrait_path)
	_update_speaker_name_display(current_story_text)

	_update_frank_talk_animation_state(current_story_text)
	_apply_tutorial_incident_aftermath()
	
	add_options()
	_maybe_trigger_bandage_minigame()

func _configure_frank_talk_animation() -> void:
	if not ENABLE_FRANK_TALK_ANIMATION:
		return
	if ResourceLoader.exists(FRANK_ANIMATED_PORTRAIT_PATH):
		frank_animated_texture = load(FRANK_ANIMATED_PORTRAIT_PATH)
	frank_talk_animation_timer = Timer.new()
	frank_talk_animation_timer.wait_time = FRANK_TALK_ANIMATION_INTERVAL
	frank_talk_animation_timer.one_shot = false
	frank_talk_animation_timer.timeout.connect(_on_frank_talk_animation_timeout)
	add_child(frank_talk_animation_timer)

func _is_frank_current_speaker(raw_text: String) -> bool:
	var speaker_pattern := RegEx.new()
	speaker_pattern.compile("(?i)^frank\\s*:")
	return speaker_pattern.search(raw_text.strip_edges()) != null

func _update_frank_talk_animation_state(raw_text: String) -> void:
	if not ENABLE_FRANK_TALK_ANIMATION:
		is_frank_talk_animating = false
		is_frank_talk_animation_frame_active = false
		portrait_animation_offset = Vector2.ZERO
		if portrait != null and current_portrait_name == "Frank_Normal":
			portrait.texture = FRANK_NORMAL_TEXTURE
		return
	var should_animate := current_portrait_name == "Frank_Normal" and _is_frank_current_speaker(raw_text)
	if should_animate == is_frank_talk_animating:
		if should_animate:
			_apply_frank_talk_animation_frame()
		return

	is_frank_talk_animating = should_animate
	is_frank_talk_animation_frame_active = false
	portrait_animation_offset = Vector2.ZERO

	if should_animate:
		_apply_frank_talk_animation_frame()
		if frank_talk_animation_timer != null:
			frank_talk_animation_timer.start()
	else:
		if frank_talk_animation_timer != null:
			frank_talk_animation_timer.stop()
		if portrait != null and current_portrait_name == "Frank_Normal":
			portrait.texture = FRANK_NORMAL_TEXTURE

func _apply_frank_talk_animation_frame() -> void:
	if portrait == null or current_portrait_name != "Frank_Normal":
		return
	if is_frank_talk_animation_frame_active and frank_animated_texture != null:
		portrait.texture = frank_animated_texture
	else:
		portrait.texture = FRANK_NORMAL_TEXTURE
	portrait_animation_offset = Vector2(0.0, FRANK_TALK_BOUNCE_OFFSET if is_frank_talk_animation_frame_active else 0.0)

func _on_frank_talk_animation_timeout() -> void:
	if not is_frank_talk_animating:
		return
	is_frank_talk_animation_frame_active = not is_frank_talk_animation_frame_active
	_apply_frank_talk_animation_frame()

func _create_bubble_choice_button(button_text: String, index, paths) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = TALK_BUBBLE_TEXTURE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = CHOICE_BUBBLE_LAYOUT_SIZE
	button.size = CHOICE_BUBBLE_LAYOUT_SIZE
	button.scale = CHOICE_BUBBLE_VISUAL_SCALE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(_on_option_pressed.bind(index, paths))

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

func add_options():
	for option in choice_container.get_children():
		option.queue_free()

	_clear_active_arrows()
	_set_healthpack_interactive(false)
	_set_chair_interactive(false)
	pending_chair_path = null
	pending_gauze_path = null
	pending_napkins_path = null
	pending_phone_path = null
	pending_bandage_success_path = null
	pending_bandage_fail_path = null
	
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
	var use_bubble_choices = _should_use_bubble_choices(paths)
	for i in range(paths.size()):
		if _is_glass_path(paths[i]):
			has_object_paths = true
		if _is_frank_talk_path(paths[i]):
			has_frank_paths = true
		if _is_click_chair_path(paths[i]):
			pending_chair_path = paths[i]
		if _is_use_gauze_path(paths[i]):
			pending_gauze_path = paths[i]
		if _is_use_napkins_path(paths[i]):
			pending_napkins_path = paths[i]
		if _is_open_phone_path(paths[i]):
			pending_phone_path = paths[i]
		if _is_bandage_success_path(paths[i]):
			pending_bandage_success_path = paths[i]
		if _is_bandage_fail_path(paths[i]):
			pending_bandage_fail_path = paths[i]
		_register_arrow_path(paths[i])

	_set_portrait_interactive(has_frank_paths)
	
	if has_object_paths:
		choice_container.visible = true
		advance_trigger.visible = false
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glass.is_interactive = true
		# Only add buttons for non-glass paths
		for i in range(paths.size()):
			if paths[i].IsValid and not _is_glass_path(paths[i]) and not _is_frank_talk_path(paths[i]) and not _is_arrow_path(paths[i]) and not _is_click_chair_path(paths[i]) and not _is_inventory_item_path(paths[i]) and not _is_bandage_result_path(paths[i]):
				var button: BaseButton = _create_bubble_choice_button(_get_path_label_text(paths[i]), i, paths) if use_bubble_choices else Button.new()
				if not use_bubble_choices:
					button.text = _get_path_label_text(paths[i])
					button.pressed.connect(_on_option_pressed.bind(i, paths))
				choice_container.add_child(button)
		choice_container.visible = choice_container.get_child_count() > 0
	elif paths.size() > 1:
		glass.is_interactive = false
		advance_trigger.visible = false
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
		choice_container.visible = true
		for i in range(paths.size()):
			if paths[i].IsValid and not _is_frank_talk_path(paths[i]) and not _is_arrow_path(paths[i]) and not _is_click_chair_path(paths[i]) and not _is_inventory_item_path(paths[i]) and not _is_bandage_result_path(paths[i]):
				var button: BaseButton = _create_bubble_choice_button(_get_path_label_text(paths[i]), i, paths) if use_bubble_choices else Button.new()
				if not use_bubble_choices:
					button.text = _get_path_label_text(paths[i])
					button.pressed.connect(_on_option_pressed.bind(i, paths))
				choice_container.add_child(button)
		choice_container.visible = choice_container.get_child_count() > 0
	else:
		glass.is_interactive = false
		_set_portrait_interactive(false)
		choice_container.visible = false
		advance_trigger.visible = true
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP

	if pending_healthpack_path != null:
		choice_container.visible = false
		advance_trigger.visible = false
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_portrait_interactive(false)
		_set_healthpack_interactive(true)

	if pending_chair_path != null and current_view == "right":
		choice_container.visible = false
		advance_trigger.visible = false
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_portrait_interactive(false)
		_set_chair_interactive(true)

	if pending_gauze_path != null or pending_napkins_path != null or pending_phone_path != null:
		choice_container.visible = false
		advance_trigger.visible = false
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_portrait_interactive(false)

	_set_inventory_item_interactivity()
	_refresh_navigation_arrows()

func on_glass_clicked():
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	for i in range(paths.size()):
		if _is_glass_path(paths[i]):
			story.SelectPath(paths[i])
			repaint()
			break

func on_frank_clicked():
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	for i in range(paths.size()):
		if _is_frank_talk_path(paths[i]):
			story.SelectPath(paths[i])
			repaint()
			break

func _create_arrow_buttons():
	_create_arrow_button("left", LEFT_ARROW_TEXTURE)
	_create_arrow_button("right", RIGHT_ARROW_TEXTURE)
	_create_arrow_button("down", DOWN_ARROW_TEXTURE)
	_create_arrow_button("up", UP_ARROW_TEXTURE)

func _create_arrow_button(direction: String, texture: Texture2D):
	var button = TextureButton.new()
	button.name = direction.capitalize() + "Arrow"
	button.texture_normal = texture
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.scale = Vector2.ONE * ARROW_SCALE
	button.size = texture.get_size()
	button.visible = false
	button.modulate = DEFAULT_ARROW_TINT
	button.mouse_entered.connect(_on_arrow_mouse_entered.bind(direction))
	button.mouse_exited.connect(_on_arrow_mouse_exited.bind(direction))
	button.pressed.connect(_on_arrow_pressed.bind(direction))
	add_child(button)
	arrow_buttons[direction] = button

func _update_arrow_positions():
	if arrow_buttons.is_empty():
		return
	var viewport_size = get_viewport_rect().size
	if arrow_buttons.has("left"):
		arrow_buttons["left"].position = Vector2(50, (viewport_size.y * 0.42))
	if arrow_buttons.has("right"):
		arrow_buttons["right"].position = Vector2(viewport_size.x - 180, (viewport_size.y * 0.42))
	if arrow_buttons.has("down"):
		arrow_buttons["down"].position = Vector2((viewport_size.x * 0.5) - 56, viewport_size.y - 430)
	if arrow_buttons.has("up"):
		arrow_buttons["up"].position = Vector2((viewport_size.x * 0.5) - 56, 60)

func _register_arrow_path(path):
	var label = _normalize_label(path.label)
	if _is_sink_path(path):
		_set_arrow_path("right", path)
		return
	match label:
		LEFT1_BAG_LABEL:
			_set_arrow_path("left", path)
		LEFT_BAG_LABEL:
			_set_arrow_path("left", path)
		CENTER1_WOUND_LABEL:
			_set_arrow_path("down", path)
		CENTER_WOUND_LABEL:
			_set_arrow_path("down", path)
		INSPECT_WOUND_LABEL:
			_set_arrow_path("down", path)

func _set_arrow_path(direction: String, path):
	active_arrow_paths[direction] = path
	if arrow_buttons.has(direction):
		arrow_buttons[direction].visible = true

func _clear_active_arrows():
	active_arrow_paths.clear()
	for button in arrow_buttons.values():
		button.visible = false
		button.modulate = DEFAULT_ARROW_TINT

func _refresh_navigation_arrows():
	if arrow_buttons.is_empty():
		return
	if pending_chair_path != null:
		if active_arrow_paths.has("down") and arrow_buttons.has("down"):
			arrow_buttons["down"].visible = true
		if current_view == "center":
			if arrow_buttons.has("left"):
				arrow_buttons["left"].visible = true
			if arrow_buttons.has("right"):
				arrow_buttons["right"].visible = true
		elif current_view == "left":
			if arrow_buttons.has("left"):
				arrow_buttons["left"].visible = false
			if arrow_buttons.has("right"):
				arrow_buttons["right"].visible = true
		elif current_view == "right":
			if arrow_buttons.has("left"):
				arrow_buttons["left"].visible = true
				if arrow_buttons.has("right"):
					arrow_buttons["right"].visible = false
			return
	if active_arrow_paths.has("down"):
		if arrow_buttons.has("down"):
			arrow_buttons["down"].visible = true
		if current_view == "center":
			if arrow_buttons.has("left"):
				arrow_buttons["left"].visible = true
			if arrow_buttons.has("right"):
				arrow_buttons["right"].visible = true
		elif current_view == "left":
			if arrow_buttons.has("left"):
				arrow_buttons["left"].visible = false
			if arrow_buttons.has("right"):
				arrow_buttons["right"].visible = true
		elif current_view == "right":
			if arrow_buttons.has("left"):
				arrow_buttons["left"].visible = true
			if arrow_buttons.has("right"):
				arrow_buttons["right"].visible = false
		return
	if current_view == "left":
		if arrow_buttons.has("left"):
			arrow_buttons["left"].visible = false
		if arrow_buttons.has("right"):
			arrow_buttons["right"].visible = true

func _is_arrow_path(path) -> bool:
	var label = _normalize_label(path.label)
	return label == LEFT1_BAG_LABEL or _is_sink_path(path) or label == CENTER1_WOUND_LABEL or label == LEFT_BAG_LABEL or label == CENTER_WOUND_LABEL or label == INSPECT_WOUND_LABEL

func _is_click_chair_path(path) -> bool:
	return _normalize_label(path.label) == CLICK_CHAIR_LABEL

func _is_use_gauze_path(path) -> bool:
	return _normalize_label(path.label) == USE_GAUZE_LABEL

func _is_sink_path(path) -> bool:
	return "investigate sink" in _normalize_label(path.label)

func _is_use_napkins_path(path) -> bool:
	return _normalize_label(path.label) == USE_NAPKINS_LABEL

func _is_open_phone_path(path) -> bool:
	return _normalize_label(path.label) == OPEN_PHONE_LABEL

func _is_inventory_item_path(path) -> bool:
	return _is_use_gauze_path(path) or _is_use_napkins_path(path) or _is_open_phone_path(path)

func _is_bandage_success_path(path) -> bool:
	return _normalize_label(path.label) == WIN_GAME_LABEL

func _is_bandage_fail_path(path) -> bool:
	return _normalize_label(path.label) == MISTAKES_WERE_MADE_LABEL

func _is_bandage_result_path(path) -> bool:
	return _is_bandage_success_path(path) or _is_bandage_fail_path(path)

func _is_arrow_direction_clickable(direction: String) -> bool:
	if active_arrow_paths.has(direction):
		return true
	if active_arrow_paths.has("down"):
		if current_view == "center" and (direction == "left" or direction == "right"):
			return true
		if current_view == "left" and direction == "right":
			return true
		if current_view == "right" and direction == "left":
			return true
	if pending_chair_path != null:
		if current_view == "center" and (direction == "left" or direction == "right"):
			return true
		if current_view == "left" and direction == "right":
			return true
		if current_view == "right" and direction == "left":
			return true
	if pending_healthpack_path != null and current_view == "left" and direction == "right":
		return true
	return false

func _on_arrow_mouse_entered(direction: String):
	if not _is_arrow_direction_clickable(direction) or is_showing_wound_preview or is_showing_linear_preview:
		return
	arrow_buttons[direction].modulate = HOVER_ARROW_TINT
	set_object_cursor()

func _on_arrow_mouse_exited(direction: String):
	if not arrow_buttons.has(direction):
		return
	arrow_buttons[direction].modulate = DEFAULT_ARROW_TINT
	set_default_cursor()

func _on_arrow_pressed(direction: String):
	if not _is_arrow_direction_clickable(direction) or is_showing_wound_preview or is_showing_linear_preview:
		return
	if direction == "right" and active_arrow_paths.has("right") and _is_sink_path(active_arrow_paths["right"]) and current_view == "left":
		current_view = "center"
		world.position = default_world_position
		_refresh_navigation_arrows()
		set_default_cursor()
		repaint()
		return
	if active_arrow_paths.has(direction):
		var directed_path = active_arrow_paths[direction]
		var directed_label = _normalize_label(directed_path.label)
		if directed_label == LEFT1_BAG_LABEL or directed_label == LEFT_BAG_LABEL:
			_begin_healthpack_pan(directed_path)
			return
		if directed_label == RIGHT1_SINK_LABEL or directed_label == RIGHT_SINK_LABEL:
			_start_linear_preview_from_path(directed_path)
			return
		if directed_label == CENTER1_WOUND_LABEL:
			_preview_wound_path(directed_path)
			return
		if directed_label == CENTER_WOUND_LABEL or directed_label == INSPECT_WOUND_LABEL:
			story.SelectPath(directed_path)
			_enter_wound_scene()
			repaint()
			return
	if active_arrow_paths.has("down") and pending_chair_path == null:
		if current_view == "center" and direction == "left":
			current_view = "left"
			world.position = Vector2(0, default_world_position.y)
			_refresh_navigation_arrows()
			set_default_cursor()
			return
		if current_view == "center" and direction == "right":
			current_view = "right"
			world.position = Vector2(-2160, default_world_position.y)
			_refresh_navigation_arrows()
			set_default_cursor()
			return
		if current_view == "left" and direction == "right":
			current_view = "center"
			world.position = default_world_position
			_refresh_navigation_arrows()
			set_default_cursor()
			return
		if current_view == "right" and direction == "left":
			current_view = "center"
			world.position = default_world_position
			_refresh_navigation_arrows()
			set_default_cursor()
			return
	if pending_chair_path != null:
		if current_view == "center" and direction == "left":
			current_view = "left"
			world.position = Vector2(0, default_world_position.y)
			_refresh_navigation_arrows()
			set_default_cursor()
			return
		if current_view == "center" and direction == "right":
			current_view = "right"
			world.position = Vector2(-2160, default_world_position.y)
			_set_chair_interactive(true)
			_refresh_navigation_arrows()
			set_default_cursor()
			return
		if current_view == "left" and direction == "right":
			current_view = "center"
			world.position = default_world_position
			_refresh_navigation_arrows()
			set_default_cursor()
			repaint()
			return
		if current_view == "right" and direction == "left":
			current_view = "center"
			world.position = default_world_position
			_set_chair_interactive(false)
			_refresh_navigation_arrows()
			set_default_cursor()
			repaint()
			return
	if current_view == "left" and direction == "right" and pending_healthpack_path != null:
		_return_to_center_view()
		return
	if active_arrow_paths.has(direction):
		story.SelectPath(active_arrow_paths[direction])
		repaint()

func _start_linear_preview_from_path(path, max_steps: int = 8):
	if story == null or path == null or not path.IsValid:
		return
	var saved_story = story.GetSave()
	var preview_texts: Array[String] = []
	story.SelectPath(path)
	for _i in range(max_steps):
		var preview_text: String = story.GetCurrentRuntimeContent()
		if not preview_text.strip_edges().is_empty():
			preview_texts.append(preview_text)
		var options = story.GenerateCurrentOptions()
		var paths = options.Paths
		if paths == null or paths.size() != 1:
			break
		var next_path = paths[0]
		if next_path == null or not next_path.IsValid:
			break
		if _normalize_label(next_path.label) != "":
			break
		story.SelectPath(next_path)
	story.LoadSave(saved_story)
	if preview_texts.is_empty():
		return
	is_showing_linear_preview = true
	linear_preview_texts = preview_texts
	linear_preview_index = 0
	current_view = "center"
	world.position = default_world_position
	choice_container.visible = false
	advance_trigger.visible = true
	advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP
	glass.is_interactive = false
	_set_portrait_interactive(false)
	_set_healthpack_interactive(false)
	_set_chair_interactive(false)
	_clear_active_arrows()
	_show_linear_preview_text()

func _show_linear_preview_text():
	if linear_preview_texts.is_empty() or linear_preview_index >= linear_preview_texts.size():
		return
	var preview_text: String = linear_preview_texts[linear_preview_index]
	dialogue_text.text = _format_dialogue_text(preview_text)
	_update_speaker_name_display(preview_text)

func _end_linear_preview():
	is_showing_linear_preview = false
	linear_preview_texts.clear()
	linear_preview_index = 0
	repaint()

func _preview_wound_path(path):
	is_showing_wound_preview = true
	var saved_story = story.GetSave()
	var previous_background_texture = background.texture
	var previous_background_position = background.position
	var previous_background_size = background.size
	var previous_world_position = world.position
	var previous_portrait_visible = portrait.visible
	var previous_speaker_visible = speaker_name.visible
	story.SelectPath(path)
	_show_foot_background()
	world.position = Vector2.ZERO
	_set_world_objects_visible(false)
	portrait.visible = false
	choice_container.visible = false
	advance_trigger.visible = false
	advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.is_interactive = false
	_set_portrait_interactive(false)
	_clear_active_arrows()
	_play_foot_sound_once()
	var preview_text: String = story.GetCurrentRuntimeContent()
	dialogue_text.text = _format_dialogue_text(preview_text)
	_update_speaker_name_display(preview_text)
	await get_tree().create_timer(_get_preview_duration(preview_text)).timeout
	story.LoadSave(saved_story)
	background.texture = previous_background_texture
	background.position = previous_background_position
	background.size = previous_background_size
	world.position = previous_world_position
	_set_world_objects_visible(true)
	portrait.visible = previous_portrait_visible
	speaker_name.visible = previous_speaker_visible
	is_showing_wound_preview = false
	repaint()

func _enter_wound_scene():
	is_wound_scene_active = true
	_show_foot_background()
	world.position = Vector2.ZERO
	_set_world_objects_visible(false)
	portrait.visible = false
	glass.is_interactive = false
	_set_portrait_interactive(false)
	_set_healthpack_interactive(false)
	_clear_active_arrows()
	set_default_cursor()
	_play_foot_sound_once()

func _exit_wound_scene():
	is_wound_scene_active = false
	_restore_default_background()
	world.position = default_world_position
	current_view = "center"
	_set_world_objects_visible(true)
	portrait.visible = true
	_apply_tutorial_incident_aftermath()

func _show_foot_background():
	background.texture = FOOT_SCENE_TEXTURE
	background.position = Vector2.ZERO
	background.size = get_viewport_rect().size

func _show_wrapped_foot_background():
	background.texture = FOOT_WRAPPED_SCENE_TEXTURE
	background.position = Vector2.ZERO
	background.size = get_viewport_rect().size

func _restore_default_background():
	background.texture = default_background_texture
	background.position = default_background_position
	background.size = default_background_size

func _update_foot_incident_scene_state(raw_text: String) -> void:
	var plain_body_text := _get_dialogue_body_text(raw_text).to_lower()
	var is_incident_line := plain_body_text == FOOT_INCIDENT_TEXT
	if is_incident_line:
		_show_foot_background()
		world.position = Vector2.ZERO
		_set_world_objects_visible(false)
		portrait.visible = false
		is_showing_foot_incident_cutaway = true
		has_seen_foot_incident_cutaway = true
		return
	if is_showing_foot_incident_cutaway:
		_restore_default_background()
		world.position = default_world_position
		_set_world_objects_visible(true)
		portrait.visible = true
		is_showing_foot_incident_cutaway = false

func _apply_tutorial_incident_aftermath() -> void:
	if knife == null or glass == null:
		return
	if has_seen_foot_incident_cutaway:
		knife.visible = false
		glass.position = FALLEN_GLASS_POSITION
		glass.rotation_degrees = FALLEN_GLASS_ROTATION_DEGREES
	else:
		knife.visible = default_knife_visible
		glass.position = default_glass_position
		glass.rotation_degrees = default_glass_rotation

func _play_foot_sound_once():
	return

func _sync_scene_mode_with_story():
	if not is_wound_scene_active:
		return
	var current_text = story.GetCurrentRuntimeContent().strip_edges().to_lower()
	if story.GetCurrentElement().Id == MAIN_CHOICE_ELEMENT_ID or current_text == RETURN_TO_MAIN_SCENE_TEXT:
		_exit_wound_scene()

func _begin_healthpack_pan(path):
	pending_healthpack_path = path
	current_view = "left"
	choice_container.visible = false
	advance_trigger.visible = false
	advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.is_interactive = false
	_set_portrait_interactive(false)
	world.position = Vector2(0, default_world_position.y)
	_set_healthpack_interactive(true)
	_refresh_navigation_arrows()

func _return_to_center_view():
	current_view = "center"
	pending_healthpack_path = null
	world.position = default_world_position
	_set_healthpack_interactive(false)
	repaint()

func _create_healthpack_hotspot():
	healthpack_hotspot = TextureButton.new()
	healthpack_hotspot.modulate = Color(1, 1, 1, 0.01)
	healthpack_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	healthpack_hotspot.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	healthpack_hotspot.ignore_texture_size = true
	healthpack_hotspot.visible = false
	healthpack_hotspot.mouse_entered.connect(_on_healthpack_mouse_entered)
	healthpack_hotspot.mouse_exited.connect(_on_healthpack_mouse_exited)
	healthpack_hotspot.gui_input.connect(_on_healthpack_gui_input)
	healthpack_hotspot.pressed.connect(_on_healthpack_pressed)
	add_child(healthpack_hotspot)

func _create_chair_hotspot():
	chair_hotspot = TextureButton.new()
	chair_hotspot.texture_normal = chair.texture
	chair_hotspot.modulate = Color(1, 1, 1, 0.01)
	chair_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	chair_hotspot.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	chair_hotspot.visible = false
	chair_hotspot.mouse_entered.connect(_on_chair_mouse_entered)
	chair_hotspot.mouse_exited.connect(_on_chair_mouse_exited)
	chair_hotspot.gui_input.connect(_on_chair_gui_input)
	chair_hotspot.pressed.connect(_on_chair_pressed)
	add_child(chair_hotspot)

func _create_inventory_hotspot():
	inventory_hotspot = Button.new()
	inventory_hotspot.flat = true
	inventory_hotspot.focus_mode = Control.FOCUS_NONE
	inventory_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_hotspot.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	inventory_hotspot.modulate = Color(1, 1, 1, 0.01)
	inventory_hotspot.text = ""
	inventory_hotspot.z_index = 260
	inventory_hotspot.mouse_entered.connect(_on_inventory_hotspot_mouse_entered)
	inventory_hotspot.mouse_exited.connect(_on_inventory_hotspot_mouse_exited)
	inventory_hotspot.gui_input.connect(_on_inventory_hotspot_gui_input)
	inventory_hotspot.pressed.connect(_on_inventory_button_pressed)
	add_child(inventory_hotspot)

func _maybe_trigger_bandage_minigame():
	var current_text = story.GetCurrentRuntimeContent().strip_edges().to_lower()
	if current_text != BANDAGE_MINIGAME_TRIGGER_TEXT:
		if current_text != last_bandage_minigame_trigger_text:
			last_bandage_minigame_trigger_text = ""
		return
	if active_bandage_minigame_root != null or last_bandage_minigame_trigger_text == current_text:
		return
	last_bandage_minigame_trigger_text = current_text
	_start_bandage_minigame()

func _start_bandage_minigame():
	active_bandage_minigame_root = BANDAGE_MINIGAME_SCENE.instantiate()
	add_child(active_bandage_minigame_root)
	if active_bandage_minigame_root is CanvasItem:
		active_bandage_minigame_root.visible = true
		if "z_index" in active_bandage_minigame_root:
			active_bandage_minigame_root.z_index = 500
	active_bandage_minigame = active_bandage_minigame_root.get_node_or_null("Bandage MiniGame")
	if active_bandage_minigame != null:
		active_bandage_minigame.minigame_completed.connect(_on_bandage_minigame_completed)
		active_bandage_minigame.minigame_failed.connect(_on_bandage_minigame_failed)
	_set_main_scene_visible(false)
	cursor_sprite.visible = false

func _end_bandage_minigame():
	if active_bandage_minigame_root != null:
		active_bandage_minigame_root.queue_free()
	active_bandage_minigame_root = null
	active_bandage_minigame = null
	_set_main_scene_visible(true)
	cursor_sprite.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	set_default_cursor()

func _on_bandage_minigame_completed():
	_end_bandage_minigame()
	_show_wrapped_foot_background()
	if pending_bandage_success_path != null:
		story.SelectPath(pending_bandage_success_path)
		repaint()
	else:
		_on_continue_pressed()

func _on_bandage_minigame_failed():
	_end_bandage_minigame()
	_show_wrapped_foot_background()
	if pending_bandage_fail_path != null:
		story.SelectPath(pending_bandage_fail_path)
		repaint()
	else:
		_on_continue_pressed()

func _set_main_scene_visible(is_visible: bool):
	world.visible = is_visible
	portrait.visible = is_visible and not is_wound_scene_active
	speaker_name.visible = false if not is_visible else speaker_name.visible
	dialogue_text.visible = is_visible
	choice_container.visible = is_visible and choice_container.visible
	advance_trigger.visible = is_visible and advance_trigger.visible
	inventory_ui.visible = is_visible
	for button in arrow_buttons.values():
		button.visible = is_visible and button.visible
	if healthpack_hotspot != null:
		healthpack_hotspot.visible = is_visible and is_healthpack_interactive
	if chair_hotspot != null:
		chair_hotspot.visible = is_visible and is_chair_interactive
	if inventory_hotspot != null:
		inventory_hotspot.visible = is_visible

func _update_healthpack_hotspot():
	if healthpack_hotspot == null or healthpack.texture == null:
		return
	healthpack_hotspot.size = HEALTHPACK_HOTSPOT_SIZE
	healthpack_hotspot.position = healthpack.global_position + HEALTHPACK_HOTSPOT_CENTER_OFFSET - (HEALTHPACK_HOTSPOT_SIZE / 2.0)

func _update_chair_hotspot():
	if chair_hotspot == null or chair.texture == null:
		return
	var texture_size = chair.texture.get_size() * chair.scale
	chair_hotspot.size = texture_size + Vector2.ONE * CHAIR_HIT_PADDING * 2.0
	chair_hotspot.position = chair.global_position - (texture_size / 2.0) - Vector2.ONE * CHAIR_HIT_PADDING

func _update_inventory_hotspot():
	if inventory_hotspot == null or inventory_button == null:
		return
	var button_rect = inventory_button.get_global_rect()
	inventory_hotspot.position = button_rect.position
	inventory_hotspot.size = button_rect.size

func _update_manual_hotspot_hover(mouse_position: Vector2):
	var hovering_healthpack = is_healthpack_interactive and _control_contains_mouse(healthpack_hotspot, mouse_position)
	var hovering_chair = is_chair_interactive and _control_contains_mouse(chair_hotspot, mouse_position)
	if hovering_healthpack:
		healthpack.modulate = HOVER_PORTRAIT_TINT
		set_object_cursor()
	else:
		healthpack.modulate = Color.WHITE
	if hovering_chair:
		chair.modulate = HOVER_PORTRAIT_TINT
		set_object_cursor()
	else:
		chair.modulate = Color.WHITE

func _handle_manual_hotspot_click(mouse_position: Vector2):
	if inventory_popup_panel.visible and _control_contains_mouse(inventory_close_button, mouse_position):
		_on_inventory_close_pressed()
		return
	if _control_contains_mouse(inventory_hotspot, mouse_position):
		_on_inventory_button_pressed()
		return
	if is_healthpack_interactive and _control_contains_mouse(healthpack_hotspot, mouse_position):
		_on_healthpack_pressed()
		return
	if is_chair_interactive and _control_contains_mouse(chair_hotspot, mouse_position):
		_on_chair_pressed()

func _control_contains_mouse(control: Control, mouse_position: Vector2) -> bool:
	return control != null and control.visible and control.get_global_rect().has_point(mouse_position)

func _set_healthpack_interactive(value: bool):
	is_healthpack_interactive = value and pending_healthpack_path != null and not is_wound_scene_active
	if healthpack_hotspot == null:
		return
	healthpack_hotspot.visible = is_healthpack_interactive
	if not is_healthpack_interactive:
		healthpack.modulate = Color.WHITE
		set_default_cursor()

func _update_inventory_unlock_state(raw_text: String) -> void:
	var plain_body_text := _get_dialogue_body_text(raw_text).to_lower()
	if not is_inventory_unlocked and plain_body_text == INVENTORY_UNLOCK_PROMPT_TEXT:
		is_inventory_unlocked = true
	should_flash_inventory_button = plain_body_text == INVENTORY_UNLOCK_PROMPT_TEXT
	_apply_inventory_button_visibility()

func _apply_inventory_button_visibility() -> void:
	var should_show_inventory := is_inventory_unlocked
	inventory_button.visible = should_show_inventory
	inventory_button.mouse_filter = Control.MOUSE_FILTER_STOP if should_show_inventory else Control.MOUSE_FILTER_IGNORE
	if inventory_hotspot != null:
		inventory_hotspot.visible = should_show_inventory
		inventory_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP if should_show_inventory else Control.MOUSE_FILTER_IGNORE
	if not should_show_inventory:
		is_inventory_button_hovered = false
		inventory_button.modulate = Color.WHITE
		_set_inventory_button_highlighted(false)

func _update_inventory_button_flash() -> void:
	if inventory_button == null or not inventory_button.visible:
		return
	if not should_flash_inventory_button:
		inventory_button.modulate = Color.WHITE
		return
	var pulse := 0.82 + (0.18 * (sin(Time.get_ticks_msec() / 140.0) + 1.0))
	inventory_button.modulate = Color(1.0, pulse, pulse * 0.75, 1.0)

func _set_inventory_button_highlighted(is_highlighted: bool) -> void:
	is_inventory_button_hovered = is_highlighted
	if inventory_button_visual != null:
		inventory_button_visual.modulate = HOVER_PORTRAIT_TINT if is_highlighted else Color.WHITE

func _set_chair_interactive(value: bool):
	is_chair_interactive = value and pending_chair_path != null and current_view == "right" and not is_wound_scene_active
	if chair_hotspot == null:
		return
	chair_hotspot.visible = is_chair_interactive
	if not is_chair_interactive:
		chair.modulate = Color.WHITE

func _on_healthpack_mouse_entered():
	if not is_healthpack_interactive:
		return
	healthpack.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_healthpack_mouse_exited():
	healthpack.modulate = Color.WHITE
	set_default_cursor()

func _on_healthpack_pressed():
	if not is_healthpack_interactive or pending_healthpack_path == null:
		return
	var selected_path = pending_healthpack_path
	pending_healthpack_path = null
	current_view = "center"
	_set_healthpack_interactive(false)
	world.position = default_world_position
	story.SelectPath(selected_path)
	repaint()

func _on_healthpack_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		_on_healthpack_pressed()

func _on_chair_mouse_entered():
	if not is_chair_interactive:
		return
	chair.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_chair_mouse_exited():
	chair.modulate = Color.WHITE
	set_default_cursor()

func _on_chair_pressed():
	if not is_chair_interactive or pending_chair_path == null:
		return
	var selected_path = pending_chair_path
	pending_chair_path = null
	current_view = "center"
	world.position = default_world_position
	_set_chair_interactive(false)
	story.SelectPath(selected_path)
	repaint()

func _on_chair_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		_on_chair_pressed()

func _configure_inventory_rows():
	var gauze_icon = inventory_items_container.get_node("GauzeRow/Icon")
	var gauze_label = inventory_items_container.get_node("GauzeRow/Label")
	var napkin_icon = inventory_items_container.get_node("NapkinRow/Icon")
	var napkin_label = inventory_items_container.get_node("NapkinRow/Label")
	var phone_icon = inventory_items_container.get_node("PhoneRow/Icon")
	var phone_label = inventory_items_container.get_node("PhoneRow/Label")
	gauze_icon.texture = GAUZE_TEXTURE
	napkin_icon.texture = NAPKINS_TEXTURE
	gauze_label.text = "Gauze"
	napkin_label.text = "Napkin"
	phone_label.text = "Phone"
	for node in [gauze_icon, gauze_label, napkin_icon, napkin_label, phone_icon, phone_label]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauze_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	napkin_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauze_row.gui_input.connect(_on_gauze_row_gui_input)
	napkin_row.gui_input.connect(_on_napkin_row_gui_input)
	phone_row.gui_input.connect(_on_phone_row_gui_input)
	gauze_row.mouse_entered.connect(_on_gauze_row_mouse_entered)
	gauze_row.mouse_exited.connect(_on_inventory_row_mouse_exited)
	napkin_row.mouse_entered.connect(_on_napkin_row_mouse_entered)
	napkin_row.mouse_exited.connect(_on_inventory_row_mouse_exited)
	phone_row.mouse_entered.connect(_on_phone_row_mouse_entered)
	phone_row.mouse_exited.connect(_on_inventory_row_mouse_exited)

func _on_inventory_button_pressed():
	if not is_inventory_unlocked:
		return
	print("INVENTORY OPEN TRIGGERED")
	_set_inventory_open(true)

func _on_inventory_close_pressed():
	_set_inventory_open(false)

func _on_gauze_row_gui_input(event):
	if pending_gauze_path == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		var selected_path = pending_gauze_path
		_set_inventory_open(false)
		if not is_wound_scene_active:
			current_view = "center"
			world.position = default_world_position
			_set_chair_interactive(false)
			_set_healthpack_interactive(false)
		story.SelectPath(selected_path)
		repaint()

func _on_napkin_row_gui_input(event):
	if pending_napkins_path == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		var selected_path = pending_napkins_path
		_set_inventory_open(false)
		if not is_wound_scene_active:
			current_view = "center"
			world.position = default_world_position
			_set_chair_interactive(false)
			_set_healthpack_interactive(false)
		story.SelectPath(selected_path)
		repaint()

func _on_phone_row_gui_input(event):
	if pending_phone_path == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		var selected_path = pending_phone_path
		_set_inventory_open(false)
		current_view = "center"
		world.position = default_world_position
		_set_chair_interactive(false)
		_set_healthpack_interactive(false)
		story.SelectPath(selected_path)
		repaint()

func _on_gauze_row_mouse_entered():
	if pending_gauze_path == null:
		return
	gauze_row.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_napkin_row_mouse_entered():
	if pending_napkins_path == null:
		return
	napkin_row.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_phone_row_mouse_entered():
	if pending_phone_path == null:
		return
	phone_row.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_inventory_row_mouse_exited():
	gauze_row.modulate = Color.WHITE
	napkin_row.modulate = Color.WHITE
	phone_row.modulate = Color.WHITE
	set_default_cursor()

func _on_inventory_hotspot_mouse_entered():
	_set_inventory_button_highlighted(true)
	set_object_cursor()

func _on_inventory_hotspot_mouse_exited():
	_set_inventory_button_highlighted(false)
	set_default_cursor()

func _on_inventory_hotspot_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
		_on_inventory_button_pressed()

func _set_inventory_open(is_open: bool):
	print("SET INVENTORY OPEN: ", is_open)
	inventory_popup_panel.visible = is_open
	inventory_popup_background.visible = is_open
	inventory_close_button.visible = is_open
	inventory_items_container.visible = is_open
	inventory_popup_panel.modulate = Color(1, 1, 1, 1)
	inventory_popup_background.modulate = Color(1, 1, 1, 1)
	inventory_close_button.modulate = Color(1, 1, 1, 1)
	inventory_items_container.modulate = Color(1, 1, 1, 1)
	_set_inventory_item_interactivity()

func _set_inventory_item_interactivity():
	if not inventory_popup_panel.visible and pending_gauze_path == null and pending_napkins_path == null and pending_phone_path == null:
		gauze_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		napkin_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		phone_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		gauze_row.mouse_filter = Control.MOUSE_FILTER_STOP if pending_gauze_path != null else Control.MOUSE_FILTER_IGNORE
		napkin_row.mouse_filter = Control.MOUSE_FILTER_STOP if pending_napkins_path != null else Control.MOUSE_FILTER_IGNORE
		phone_row.mouse_filter = Control.MOUSE_FILTER_STOP if pending_phone_path != null else Control.MOUSE_FILTER_IGNORE
	gauze_row.modulate = Color.WHITE
	napkin_row.modulate = Color.WHITE
	phone_row.modulate = Color.WHITE

func _set_world_objects_visible(is_visible: bool):
	for child in world.get_children():
		if child == background:
			continue
		if child is CanvasItem:
			child.visible = is_visible

func _get_preview_duration(text: String) -> float:
	return clamp(4.9 + (text.length() / 65.0), 5.7, 7.5)

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
	return text in _normalize_label(path.label)

func _should_use_bubble_choices(paths) -> bool:
	if paths == null or paths.size() == 0:
		return false
	var normalized_labels := []
	for path in paths:
		if path == null or not path.IsValid:
			continue
		normalized_labels.append(_normalize_label(path.label))
	var is_start_menu = normalized_labels.has(TUTORIAL_LABEL) and normalized_labels.has(SKIP_TO_LEVEL_1_LABEL)
	var is_address_quiz = normalized_labels.has(ASK_FRIEND_FOR_ADDRESS_LABEL) and normalized_labels.has(ADDRESS_OPTION_1_LABEL) and normalized_labels.has(ADDRESS_OPTION_2_LABEL) and normalized_labels.has(ADDRESS_OPTION_3_LABEL)
	return is_start_menu or is_address_quiz

func _configure_choice_container():
	if choice_container == null:
		return
	choice_container.add_theme_constant_override("separation", -8)

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
	if _normalize_label(plain) == SKIP_TO_LEVEL_1_LABEL:
		return "Level 1"
	return plain.strip_edges()

func _should_use_component_for_portrait(comp_name: String) -> bool:
	if comp_name == "":
		return false
	var normalized = comp_name.to_lower()
	return "decoy" not in normalized

func _is_glass_path(path) -> bool:
	return _path_label_contains(path, "glass")

func _is_frank_talk_path(path) -> bool:
	return _normalize_label(path.label) == CENTER_TALK_LABEL or _path_label_contains(path, "talking to frank")

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
	var selected_path = paths[index]
	var selected_label = _normalize_label(selected_path.label)
	if selected_label == SKIP_TO_LEVEL_1_LABEL:
		get_tree().change_scene_to_file("res://level_1.tscn")
		return
	story.SelectPath(selected_path)
	repaint()

func _on_continue_pressed():
	if is_showing_linear_preview:
		linear_preview_index += 1
		if linear_preview_index >= linear_preview_texts.size():
			_end_linear_preview()
		else:
			_show_linear_preview_text()
		return
	var current_text = story.GetCurrentRuntimeContent().strip_edges().to_lower()
	if current_text == RETURN_HOME_TEXT:
		get_tree().change_scene_to_file(HOME_MENU_SCENE_PATH)
		return
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	if paths != null and paths.size() > 0:
		if not is_wound_scene_active:
			current_view = "center"
			world.position = default_world_position
			_set_chair_interactive(false)
			_set_healthpack_interactive(false)
		story.SelectPath(paths[0])
		repaint()
