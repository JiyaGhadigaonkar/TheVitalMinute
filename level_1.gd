extends Control

@export var starting_focus_x := 2300.0

@onready var world: Node2D = get_node_or_null("World")
@onready var background: TextureRect = get_node_or_null("World/Background")
@onready var portrait: TextureRect = get_node_or_null("Portrait")
@onready var dialogue_box: TextureRect = get_node_or_null("DialogueBox")
@onready var speaker_name: RichTextLabel = get_node_or_null("SpeakerName")
@onready var dialogue_text: RichTextLabel = get_node_or_null("DialogueText")
@onready var choice_container: VBoxContainer = get_node_or_null("ChoiceContainer")
@onready var advance_trigger: Button = get_node_or_null("AdvanceTrigger")
@onready var inventory_ui: Control = get_node_or_null("InventoryUI")
@onready var inventory_button: TextureButton = get_node_or_null("InventoryUI/InventoryButton")
@onready var inventory_popup_panel: Panel = get_node_or_null("InventoryUI/InventoryPopup")
@onready var inventory_popup_background: TextureRect = get_node_or_null("InventoryUI/InventoryPopup/PopupBackground")
@onready var inventory_close_button: TextureButton = get_node_or_null("InventoryUI/InventoryPopup/CloseButton")
@onready var inventory_items_container: VBoxContainer = get_node_or_null("InventoryUI/InventoryPopup/ItemsContainer")
@onready var gauze_row: HBoxContainer = get_node_or_null("InventoryUI/InventoryPopup/ItemsContainer/GauzeRow")
@onready var napkin_row: HBoxContainer = get_node_or_null("InventoryUI/InventoryPopup/ItemsContainer/NapkinRow")
@onready var phone_row: HBoxContainer = get_node_or_null("InventoryUI/InventoryPopup/ItemsContainer/PhoneRow")

const DEFAULT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_default.png")
const OBJECT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_object.png")
const GAUZE_TEXTURE = preload("res://Assets/Item_Tutorial_Gauze.png")
const NAPKINS_TEXTURE = preload("res://Assets/Item_Tutorial_Napkins.png")
const CURSOR_HOTSPOT = Vector2(8, 0)
const CURSOR_SCALE = 1.35
const DEFAULT_PORTRAIT_TINT = Color(1.0, 1.0, 1.0, 1.0)
const HOVER_PORTRAIT_TINT = Color(1.0, 0.95, 0.8, 1.0)
const TALK_TO_FRANK_LABEL = "center talk to frank"
const USE_GAUZE_LABEL = "use gauze"
const USE_NAPKINS_LABEL = "use napkins"
const OPEN_PHONE_LABEL = "open phone"

var arcweave_asset: ArcweaveAsset = preload("res://addons/arcweave/LevelOne.tres")
var Story = load("res://addons/arcweave/Story.cs")
var story
var project_data: Dictionary
var cursor_sprite: TextureRect
var current_portrait_name := ""
var current_portrait_talk_path = null
var is_portrait_interactive := false
var default_portrait_position := Vector2.ZERO
var default_speaker_name_position := Vector2.ZERO
var default_world_position := Vector2.ZERO
var pending_gauze_path = null
var pending_napkins_path = null
var pending_phone_path = null

func _ready() -> void:
	if world != null:
		_apply_world_focus(starting_focus_x)
		default_world_position = world.position
	if portrait != null:
		default_portrait_position = portrait.position
	if speaker_name != null:
		default_speaker_name_position = speaker_name.position

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_create_cursor_sprite()
	_connect_ui()
	_configure_inventory_rows()

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

	if portrait != null and world != null:
		portrait.position = default_portrait_position + (world.position - default_world_position)
	if speaker_name != null:
		speaker_name.position = default_speaker_name_position

func get_component_name_for_element() -> String:
	var element = story.GetCurrentElement()
	var element_id = element.Id
	var elements = project_data.get("elements", {})
	if elements.has(element_id):
		var element_data = elements[element_id]
		var component_ids = element_data.get("components", [])
		if component_ids.size() > 0:
			var components = project_data.get("components", {})
			if components.has(component_ids[0]):
				return components[component_ids[0]].get("name", "")
	return ""

func repaint() -> void:
	if story == null:
		return
	if dialogue_text != null:
		dialogue_text.bbcode_enabled = true
		dialogue_text.add_theme_color_override("default_color", Color.BLACK)
		dialogue_text.text = story.GetCurrentRuntimeContent().strip_edges()

	_update_portrait()
	add_options()

func add_options() -> void:
	if story == null:
		return
	if choice_container == null or advance_trigger == null:
		return

	for option in choice_container.get_children():
		option.queue_free()

	current_portrait_talk_path = null
	pending_gauze_path = null
	pending_napkins_path = null
	pending_phone_path = null
	var normal_choice_paths := []

	var options = story.GenerateCurrentOptions()
	var paths = options.Paths

	if paths == null or paths.size() == 0:
		choice_container.visible = false
		advance_trigger.visible = true
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP
		_set_portrait_interactive(false)
		_set_inventory_item_interactivity()
		return

	var visible_choice_count := 0
	for i in range(paths.size()):
		var path = paths[i]
		if not path.IsValid:
			continue
		if _is_frank_talk_path(path):
			current_portrait_talk_path = path
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

		normal_choice_paths.append(path)
		var button := Button.new()
		button.text = _get_path_label_text(path)
		button.pressed.connect(_on_option_pressed.bind(i, paths))
		choice_container.add_child(button)
		visible_choice_count += 1

	if normal_choice_paths.size() == 1:
		for option in choice_container.get_children():
			option.queue_free()
		visible_choice_count = 0

	_set_portrait_interactive(current_portrait_talk_path != null)
	choice_container.visible = visible_choice_count > 0

	var has_manual_interaction := current_portrait_talk_path != null or pending_gauze_path != null or pending_napkins_path != null or pending_phone_path != null
	advance_trigger.visible = not choice_container.visible and not has_manual_interaction
	advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP if advance_trigger.visible else Control.MOUSE_FILTER_IGNORE

	_set_inventory_item_interactivity()

func clean_name(raw_name: String) -> String:
	if "_" in raw_name:
		return raw_name.split("_")[0]
	return raw_name

func on_frank_clicked() -> void:
	if current_portrait_talk_path == null:
		return
	story.SelectPath(current_portrait_talk_path)
	repaint()

func set_object_cursor() -> void:
	_set_cursor_texture(OBJECT_CURSOR_TEXTURE)

func set_default_cursor() -> void:
	_set_cursor_texture(DEFAULT_CURSOR_TEXTURE)

func set_world_focus_x(focus_x: float) -> void:
	_apply_world_focus(focus_x)
	default_world_position = world.position

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

func _connect_ui() -> void:
	if advance_trigger != null:
		advance_trigger.flat = true
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_STOP
		advance_trigger.pressed.connect(_on_continue_pressed)

	if portrait != null:
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.mouse_entered.connect(_on_portrait_mouse_entered)
		portrait.mouse_exited.connect(_on_portrait_mouse_exited)
		portrait.gui_input.connect(_on_portrait_gui_input)
		portrait.modulate = DEFAULT_PORTRAIT_TINT

	if dialogue_box != null:
		dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if dialogue_text != null:
		dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if speaker_name != null:
		speaker_name.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if inventory_ui != null:
		inventory_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inventory_ui.z_index = 200

	if inventory_button != null:
		inventory_button.mouse_filter = Control.MOUSE_FILTER_STOP
		inventory_button.ignore_texture_size = true
		inventory_button.z_index = 250
		inventory_button.pressed.connect(_on_inventory_button_pressed)
		inventory_button.mouse_entered.connect(_on_inventory_hotspot_mouse_entered)
		inventory_button.mouse_exited.connect(_on_inventory_hotspot_mouse_exited)

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

func _set_portrait_interactive(value: bool) -> void:
	is_portrait_interactive = value and portrait != null and current_portrait_talk_path != null
	if portrait != null:
		portrait.mouse_filter = Control.MOUSE_FILTER_STOP if is_portrait_interactive else Control.MOUSE_FILTER_IGNORE
		portrait.modulate = DEFAULT_PORTRAIT_TINT
	if not is_portrait_interactive:
		set_default_cursor()

func _update_portrait() -> void:
	if portrait == null:
		return

	var component_name = clean_name(get_component_name_for_element())
	var portrait_path = "res://Assets/portraits/" + component_name + ".png"

	if _should_use_component_for_portrait(component_name) and ResourceLoader.exists(portrait_path):
		current_portrait_name = component_name
		portrait.texture = load(portrait_path)
		portrait.visible = true
		if speaker_name != null:
			speaker_name.text = component_name
			speaker_name.visible = true
	else:
		portrait.visible = false
		if speaker_name != null:
			speaker_name.text = current_portrait_name
			speaker_name.visible = false

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
	if component_name == "":
		return false
	return "decoy" not in component_name.to_lower()

func _is_frank_talk_path(path) -> bool:
	return _normalize_label(path.label) == TALK_TO_FRANK_LABEL or _path_label_contains(path, "talking to frank")

func _is_use_gauze_path(path) -> bool:
	return _normalize_label(path.label) == USE_GAUZE_LABEL

func _is_use_napkins_path(path) -> bool:
	return _normalize_label(path.label) == USE_NAPKINS_LABEL

func _is_open_phone_path(path) -> bool:
	return _normalize_label(path.label) == OPEN_PHONE_LABEL

func _on_portrait_mouse_entered() -> void:
	if not is_portrait_interactive:
		return
	portrait.modulate = HOVER_PORTRAIT_TINT
	set_object_cursor()

func _on_portrait_mouse_exited() -> void:
	if portrait != null:
		portrait.modulate = DEFAULT_PORTRAIT_TINT
	set_default_cursor()

func _on_portrait_gui_input(event) -> void:
	if not is_portrait_interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		on_frank_clicked()

func _on_option_pressed(index, paths) -> void:
	story.SelectPath(paths[index])
	repaint()

func _on_continue_pressed() -> void:
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	if paths != null and paths.size() > 0:
		story.SelectPath(paths[0])
		repaint()

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
	set_object_cursor()

func _on_inventory_hotspot_mouse_exited() -> void:
	set_default_cursor()
