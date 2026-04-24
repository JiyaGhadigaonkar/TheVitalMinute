extends Control

@onready var background = $World/Background
@onready var portrait = $Portrait
@onready var speaker_name = $SpeakerName
@onready var dialogue_text = $DialogueText
@onready var choice_container = $ChoiceContainer
@onready var advance_trigger = $AdvanceTrigger
@onready var inventory_ui = $InventoryUI
@onready var inventory_button = $InventoryUI/InventoryButton
@onready var inventory_popup_panel = $InventoryUI/InventoryPopup
@onready var inventory_popup_background = $InventoryUI/InventoryPopup/PopupBackground
@onready var inventory_close_button = $InventoryUI/InventoryPopup/CloseButton
@onready var inventory_items_container = $InventoryUI/InventoryPopup/ItemsContainer
@onready var glass = $World/Glass
@onready var healthpack = $World/Healthpack
@onready var chair = $World/Chair
@onready var world = $World

const DEFAULT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_default.png")
const OBJECT_CURSOR_TEXTURE = preload("res://Assets/cursors/resized_cursor_object.png")
const LEFT_ARROW_TEXTURE = preload("res://Assets/arrows/left_arrow.png")
const RIGHT_ARROW_TEXTURE = preload("res://Assets/arrows/right_arrow.png")
const DOWN_ARROW_TEXTURE = preload("res://Assets/arrows/down_arrow.png")
const UP_ARROW_TEXTURE = preload("res://Assets/arrows/up_arrow.png")
const FOOT_SCENE_TEXTURE = preload("res://Assets/Scene_Foot.png")
const FOOT_PREVIEW_SOUND_PATH = "res://Assets/audio/foot_reveal.ogg"
const INVENTORY_ICON_TEXTURE = preload("res://Assets/tutorial_inventory.png")
const INVENTORY_CLOSE_TEXTURE = preload("res://Assets/inventory_close.png")
const GAUZE_TEXTURE = preload("res://Assets/Item_Tutorial_Gauze.png")
const NAPKINS_TEXTURE = preload("res://Assets/Item_Tutorial_Napkins.png")
const CURSOR_HOTSPOT = Vector2(8, 0)
const CURSOR_SCALE = 1.35
const DEFAULT_PORTRAIT_TINT = Color(1.0, 1.0, 1.0, 1.0)
const HOVER_PORTRAIT_TINT = Color(1.0, 0.95, 0.8, 1.0)
const DEFAULT_ARROW_TINT = Color(1.0, 1.0, 1.0, 1.0)
const HOVER_ARROW_TINT = Color(1.0, 0.95, 0.8, 1.0)
const ARROW_SCALE = 0.22
const LEFT1_BAG_LABEL = "left1 grab frank's bag"
const RIGHT1_SINK_LABEL = "right1 investigate sink"
const CENTER1_WOUND_LABEL = "center1 investigate wound"
const LEFT_BAG_LABEL = "left grab frank's bag"
const RIGHT_SINK_LABEL = "right investigate sink"
const CENTER_WOUND_LABEL = "center investigate wound"
const CENTER_TALK_LABEL = "center talk to frank"
const CLICK_CHAIR_LABEL = "click chair"
const INSPECT_WOUND_LABEL = "inspect wound"
const MAIN_CHOICE_ELEMENT_ID = "126b988e-de6d-4ac7-bb37-8904d96075e1"
const HEALTHPACK_HIT_PADDING = 36.0
const CHAIR_HIT_PADDING = 48.0

var arcweave_asset: ArcweaveAsset = preload("res://addons/arcweave/TutorialStory.tres")
var Story = load("res://addons/arcweave/Story.cs")
var story
var project_data: Dictionary
var cursor_sprite: TextureRect
var current_portrait_name := ""
var is_portrait_interactive := false
var default_background_texture: Texture2D
var default_background_size := Vector2.ZERO
var default_world_position := Vector2.ZERO
var default_portrait_position := Vector2.ZERO
var default_speaker_name_position := Vector2.ZERO
var arrow_buttons := {}
var active_arrow_paths := {}
var is_showing_wound_preview := false
var foot_preview_player: AudioStreamPlayer
var healthpack_hotspot: TextureButton
var chair_hotspot: TextureButton
var pending_healthpack_path = null
var pending_chair_path = null
var is_healthpack_interactive := false
var is_chair_interactive := false
var is_wound_scene_active := false
var current_view := "center"
var inventory_click_area: Button

func _ready():
	world.position.x = -1080
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	default_background_texture = background.texture
	default_background_size = background.size
	default_world_position = world.position
	default_portrait_position = portrait.position
	default_speaker_name_position = speaker_name.position
	cursor_sprite = TextureRect.new()
	cursor_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_sprite.z_index = 1000
	cursor_sprite.scale = Vector2.ONE * CURSOR_SCALE
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
	inventory_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_button.z_index = 250
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
	inventory_popup_panel.modulate = Color(1, 1, 1, 0)
	inventory_popup_background.rotation_degrees = 90
	inventory_popup_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_inventory_click_area()
	_layout_inventory_ui()
	_configure_inventory_rows()
	foot_preview_player = AudioStreamPlayer.new()
	add_child(foot_preview_player)
	if ResourceLoader.exists(FOOT_PREVIEW_SOUND_PATH):
		foot_preview_player.stream = load(FOOT_PREVIEW_SOUND_PATH)
	_create_healthpack_hotspot()
	_create_chair_hotspot()
	_create_arrow_buttons()
	_update_arrow_positions()
	glass.is_interactive = false  # not clickable by default
	project_data = arcweave_asset.project_settings
	story = Story.new(project_data)
	repaint()

func _process(_delta):
	if cursor_sprite == null:
		return
	cursor_sprite.position = get_viewport().get_mouse_position() - (CURSOR_HOTSPOT * CURSOR_SCALE)
	portrait.position = default_portrait_position + (world.position - default_world_position)
	speaker_name.position = default_speaker_name_position
	_update_healthpack_hotspot()
	_update_chair_hotspot()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_arrow_positions()
		_layout_inventory_ui()

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
	_sync_scene_mode_with_story()
	dialogue_text.bbcode_enabled = true
	dialogue_text.add_theme_color_override("default_color", Color.BLACK)
	dialogue_text.text = story.GetCurrentRuntimeContent().strip_edges()
	
	var comp_name = get_component_name_for_element()
	var portrait_path = "res://Assets/portraits/" + comp_name + ".png"
	if _should_use_component_for_portrait(comp_name) and ResourceLoader.exists(portrait_path):
		current_portrait_name = comp_name
		speaker_name.text = comp_name
		portrait.texture = load(portrait_path)
	else:
		speaker_name.text = current_portrait_name
	
	add_options()

func add_options():
	for option in choice_container.get_children():
		option.queue_free()

	_clear_active_arrows()
	_set_healthpack_interactive(false)
	_set_chair_interactive(false)
	pending_chair_path = null
	
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
		if _is_glass_path(paths[i]):
			has_object_paths = true
		if _is_frank_talk_path(paths[i]):
			has_frank_paths = true
		if _is_click_chair_path(paths[i]):
			pending_chair_path = paths[i]
		_register_arrow_path(paths[i])

	_set_portrait_interactive(has_frank_paths)
	
	if has_object_paths:
		choice_container.visible = true
		advance_trigger.visible = false
		advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glass.is_interactive = true
		# Only add buttons for non-glass paths
		for i in range(paths.size()):
			if paths[i].IsValid and not _is_glass_path(paths[i]) and not _is_frank_talk_path(paths[i]) and not _is_arrow_path(paths[i]) and not _is_click_chair_path(paths[i]):
				var button = Button.new()
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
			if paths[i].IsValid and not _is_frank_talk_path(paths[i]) and not _is_arrow_path(paths[i]) and not _is_click_chair_path(paths[i]):
				var button = Button.new()
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
	match label:
		LEFT1_BAG_LABEL:
			_set_arrow_path("left", path)
		LEFT_BAG_LABEL:
			_set_arrow_path("left", path)
		RIGHT1_SINK_LABEL:
			_set_arrow_path("right", path)
		RIGHT_SINK_LABEL:
			_set_arrow_path("right", path)
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
	return label == LEFT1_BAG_LABEL or label == RIGHT1_SINK_LABEL or label == CENTER1_WOUND_LABEL or label == LEFT_BAG_LABEL or label == RIGHT_SINK_LABEL or label == CENTER_WOUND_LABEL or label == INSPECT_WOUND_LABEL

func _is_click_chair_path(path) -> bool:
	return _normalize_label(path.label) == CLICK_CHAIR_LABEL

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
	if not _is_arrow_direction_clickable(direction) or is_showing_wound_preview:
		return
	arrow_buttons[direction].modulate = HOVER_ARROW_TINT
	set_object_cursor()

func _on_arrow_mouse_exited(direction: String):
	if not arrow_buttons.has(direction):
		return
	arrow_buttons[direction].modulate = DEFAULT_ARROW_TINT
	set_default_cursor()

func _on_arrow_pressed(direction: String):
	if not _is_arrow_direction_clickable(direction) or is_showing_wound_preview:
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
	var path = active_arrow_paths[direction]
	var label = _normalize_label(path.label)
	if label == CENTER1_WOUND_LABEL:
		_preview_wound_path(path)
		return
	if label == CENTER_WOUND_LABEL or label == INSPECT_WOUND_LABEL:
		story.SelectPath(path)
		_enter_wound_scene()
		repaint()
		return
	if label == LEFT_BAG_LABEL:
		_begin_healthpack_pan(path)
		return
	story.SelectPath(path)
	repaint()

func _preview_wound_path(path):
	is_showing_wound_preview = true
	var saved_story = story.GetSave()
	var previous_background_texture = background.texture
	var previous_background_size = background.size
	var previous_world_position = world.position
	var previous_portrait_visible = portrait.visible
	var previous_speaker_visible = speaker_name.visible
	story.SelectPath(path)
	background.texture = FOOT_SCENE_TEXTURE
	background.size = FOOT_SCENE_TEXTURE.get_size()
	world.position = Vector2.ZERO
	_set_world_objects_visible(false)
	portrait.visible = false
	speaker_name.visible = false
	choice_container.visible = false
	advance_trigger.visible = false
	advance_trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.is_interactive = false
	_set_portrait_interactive(false)
	_clear_active_arrows()
	if foot_preview_player.stream != null:
		foot_preview_player.play()
	dialogue_text.text = story.GetCurrentRuntimeContent().strip_edges()
	await get_tree().create_timer(_get_preview_duration(dialogue_text.text)).timeout
	story.LoadSave(saved_story)
	background.texture = previous_background_texture
	background.size = previous_background_size
	world.position = previous_world_position
	_set_world_objects_visible(true)
	portrait.visible = previous_portrait_visible
	speaker_name.visible = previous_speaker_visible
	is_showing_wound_preview = false
	repaint()

func _enter_wound_scene():
	is_wound_scene_active = true
	background.texture = FOOT_SCENE_TEXTURE
	background.size = FOOT_SCENE_TEXTURE.get_size()
	world.position = Vector2.ZERO
	_set_world_objects_visible(false)
	portrait.visible = false
	glass.is_interactive = false
	_set_portrait_interactive(false)
	_set_healthpack_interactive(false)
	_clear_active_arrows()
	set_default_cursor()
	if foot_preview_player.stream != null:
		foot_preview_player.play()

func _exit_wound_scene():
	is_wound_scene_active = false
	background.texture = default_background_texture
	background.size = default_background_size
	world.position = default_world_position
	current_view = "center"
	_set_world_objects_visible(true)
	portrait.visible = true

func _sync_scene_mode_with_story():
	if is_wound_scene_active and story.GetCurrentElement().Id == MAIN_CHOICE_ELEMENT_ID:
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
	healthpack_hotspot.texture_normal = healthpack.texture
	healthpack_hotspot.modulate = Color(1, 1, 1, 0.01)
	healthpack_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	healthpack_hotspot.visible = false
	healthpack_hotspot.mouse_entered.connect(_on_healthpack_mouse_entered)
	healthpack_hotspot.mouse_exited.connect(_on_healthpack_mouse_exited)
	healthpack_hotspot.pressed.connect(_on_healthpack_pressed)
	add_child(healthpack_hotspot)

func _create_chair_hotspot():
	chair_hotspot = TextureButton.new()
	chair_hotspot.texture_normal = chair.texture
	chair_hotspot.modulate = Color(1, 1, 1, 0.01)
	chair_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	chair_hotspot.visible = false
	chair_hotspot.mouse_entered.connect(_on_chair_mouse_entered)
	chair_hotspot.mouse_exited.connect(_on_chair_mouse_exited)
	chair_hotspot.pressed.connect(_on_chair_pressed)
	add_child(chair_hotspot)

func _update_healthpack_hotspot():
	if healthpack_hotspot == null or healthpack.texture == null:
		return
	var texture_size = healthpack.texture.get_size() * healthpack.scale
	healthpack_hotspot.size = texture_size + Vector2.ONE * HEALTHPACK_HIT_PADDING * 2.0
	healthpack_hotspot.position = healthpack.global_position - (texture_size / 2.0) - Vector2.ONE * HEALTHPACK_HIT_PADDING

func _update_chair_hotspot():
	if chair_hotspot == null or chair.texture == null:
		return
	var texture_size = chair.texture.get_size() * chair.scale
	chair_hotspot.size = texture_size + Vector2.ONE * CHAIR_HIT_PADDING * 2.0
	chair_hotspot.position = chair.global_position - (texture_size / 2.0) - Vector2.ONE * CHAIR_HIT_PADDING

func _set_healthpack_interactive(value: bool):
	is_healthpack_interactive = value and pending_healthpack_path != null and not is_wound_scene_active
	if healthpack_hotspot == null:
		return
	healthpack_hotspot.visible = is_healthpack_interactive
	if not is_healthpack_interactive:
		healthpack.modulate = Color.WHITE
		set_default_cursor()

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

func _configure_inventory_rows():
	var gauze_icon = inventory_items_container.get_node("GauzeRow/Icon")
	var gauze_label = inventory_items_container.get_node("GauzeRow/Label")
	var napkin_icon = inventory_items_container.get_node("NapkinRow/Icon")
	var napkin_label = inventory_items_container.get_node("NapkinRow/Label")
	gauze_icon.texture = GAUZE_TEXTURE
	napkin_icon.texture = NAPKINS_TEXTURE
	gauze_label.text = "Gauze"
	napkin_label.text = "Napkin"
	gauze_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	napkin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gauze_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	napkin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gauze_icon.custom_minimum_size = Vector2(54, 54)
	napkin_icon.custom_minimum_size = Vector2(54, 54)

func _create_inventory_click_area():
	inventory_click_area = Button.new()
	inventory_click_area.flat = true
	inventory_click_area.focus_mode = Control.FOCUS_NONE
	inventory_click_area.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_click_area.modulate = Color(1, 1, 1, 0.01)
	inventory_click_area.text = ""
	inventory_click_area.z_index = 260
	inventory_click_area.pressed.connect(_on_inventory_button_pressed)
	inventory_ui.add_child(inventory_click_area)

func _layout_inventory_ui():
	if inventory_ui == null or inventory_button == null or inventory_popup_panel == null or inventory_popup_background == null or inventory_close_button == null or inventory_items_container == null or inventory_click_area == null:
		return
	var viewport_size = get_viewport_rect().size
	inventory_ui.position = Vector2.ZERO
	inventory_ui.size = viewport_size
	inventory_button.position = Vector2(viewport_size.x - 150, 24)
	inventory_button.size = Vector2(108, 144)
	inventory_button.scale = Vector2.ONE
	inventory_button.pivot_offset = Vector2.ZERO
	inventory_button.rotation_degrees = 0
	inventory_button.ignore_texture_size = true
	inventory_click_area.position = inventory_button.position
	inventory_click_area.size = Vector2(108, 144)
	inventory_popup_panel.position = Vector2.ZERO
	inventory_popup_panel.size = viewport_size
	inventory_popup_background.position = Vector2(1717, 133)
	inventory_popup_background.size = Vector2(648, 800)
	inventory_popup_background.scale = Vector2(1.7, 1.7)
	inventory_popup_background.rotation_degrees = 90
	inventory_popup_background.pivot_offset = Vector2.ZERO
	inventory_close_button.position = Vector2(1518, 210)
	inventory_close_button.size = Vector2(982, 982)
	inventory_close_button.scale = Vector2(0.1, 0.1)
	inventory_close_button.rotation_degrees = 0
	inventory_items_container.position = Vector2(500, 180)
	inventory_items_container.size = Vector2(643, 1044)
	inventory_items_container.scale = Vector2(0.43, 0.43)
	inventory_popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_inventory_button_pressed():
	_set_inventory_open(true)

func _on_inventory_close_pressed():
	_set_inventory_open(false)

func _set_inventory_open(is_open: bool):
	inventory_popup_panel.visible = is_open
	inventory_popup_background.visible = is_open
	inventory_close_button.visible = is_open
	inventory_items_container.visible = is_open

func _set_world_objects_visible(is_visible: bool):
	for child in world.get_children():
		if child == background:
			continue
		if child is CanvasItem:
			child.visible = is_visible

func _get_preview_duration(text: String) -> float:
	return clamp(2.4 + (text.length() / 65.0), 3.2, 5.0)

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
	story.SelectPath(paths[index])
	repaint()

func _on_continue_pressed():
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	if paths != null and paths.size() > 0:
		story.SelectPath(paths[0])
		repaint()
