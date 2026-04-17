extends Node2D

# --- Signals ---
signal minigame_completed
signal minigame_failed

# --- Configuration ---
var wound_center = Vector2(400, 300)
var required_wraps = 4.0
var min_radius = 80.0
var max_radius = 300.0
var time_limit = 8.0

# --- Internal state ---
var total_rotation = 0.0
var last_angle = 0.0
var is_complete = false
var is_failed = false
var in_zone = false
var time_remaining = 10.0
var timer_started = false
var last_delta_angle = 0.0

# --- Shake state ---
var shake_timer = 0.0
var shake_intensity = 3.0
var shake_speed = 20.0
var sprite_origin = Vector2()

# --- UI Nodes ---
var label: Label
var bar_bg: ColorRect
var bar_fill: ColorRect
var wound_sprite: Sprite2D
var timer_label: Label
var timer_bar_bg: ColorRect
var timer_bar_fill: ColorRect
var timer_bar_text: Label

# --- Cursor ---
var cursor_sprite: Sprite2D
var cursor_in_zone: bool = false

# -------------------------------------------------------

func _ready():
	wound_center = get_viewport().get_visible_rect().size / 2
	time_remaining = time_limit
	_setup_sprite()
	_setup_cursor()
	_setup_ui()
	last_angle = wound_center.angle_to_point(get_global_mouse_position())

func _setup_sprite():
	wound_sprite = $WoundSprite
	wound_sprite.position = wound_center
	sprite_origin = wound_sprite.position

func _setup_cursor():
	cursor_sprite = Sprite2D.new()

	# --- Load your bandage texture here ---
	# Replace this path with wherever your bandage image is in your project
	cursor_sprite.texture = load("res://Assets/Item_Tutorial_Gauze.png")

	# Scale it down to a reasonable cursor size
	cursor_sprite.scale = Vector2(0.3, 0.3)

	# Hide it by default — only shows when in the zone
	cursor_sprite.visible = false

	# Add it last so it draws on top of everything else
	add_child(cursor_sprite)

func _setup_ui():
	label = Label.new()
	label.text = "Hold and circle the wound to start wrapping!"
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)

	timer_bar_text = Label.new()
	timer_bar_text.text = "Time Remaining — Click to start!"
	timer_bar_text.position = Vector2(20, 55)
	timer_bar_text.add_theme_font_size_override("font_size", 14)
	add_child(timer_bar_text)

	timer_bar_bg = ColorRect.new()
	timer_bar_bg.color = Color(0.2, 0.2, 0.2)
	timer_bar_bg.size = Vector2(300, 22)
	timer_bar_bg.position = Vector2(20, 75)
	add_child(timer_bar_bg)

	timer_bar_fill = ColorRect.new()
	timer_bar_fill.color = Color(0.5, 0.5, 0.5)
	timer_bar_fill.size = Vector2(300, 22)
	timer_bar_fill.position = Vector2(20, 75)
	add_child(timer_bar_fill)

	timer_label = Label.new()
	timer_label.text = "- - -"
	timer_label.position = Vector2(20, 75)
	timer_label.size = Vector2(300, 22)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 14)
	timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(timer_label)

	bar_bg = ColorRect.new()
	bar_bg.color = Color(0.2, 0.2, 0.2)
	bar_bg.size = Vector2(400, 30)
	bar_bg.position = Vector2(wound_center.x - 200, wound_center.y + 160)
	add_child(bar_bg)

	bar_fill = ColorRect.new()
	bar_fill.color = Color(0.2, 0.8, 0.3)
	bar_fill.size = Vector2(0, 30)
	bar_fill.position = bar_bg.position
	add_child(bar_fill)

	var bar_label = Label.new()
	bar_label.text = "Bandage Progress"
	bar_label.position = Vector2(bar_bg.position.x, bar_bg.position.y + 34)
	bar_label.add_theme_font_size_override("font_size", 14)
	add_child(bar_label)

func _process(delta):
	if is_complete or is_failed:
		wound_sprite.position = sprite_origin
		_show_system_cursor()
		return

	var mouse_pos = get_global_mouse_position()
	var dist = mouse_pos.distance_to(wound_center)
	in_zone = dist > min_radius and dist < max_radius
	var current_angle = wound_center.angle_to_point(mouse_pos)

	# --- Update cursor sprite position every frame ---
	cursor_sprite.position = mouse_pos

	# --- Rotate the cursor sprite to point away from the wound center ---
	# This makes the bandage sprite angle naturally as you orbit the wound

	# --- Swap cursor when entering or leaving the zone ---
	if in_zone and not cursor_in_zone:
		_show_bandage_cursor()
	elif not in_zone and cursor_in_zone:
		_show_system_cursor()

	queue_redraw()

	if timer_started:
		time_remaining -= delta
		_update_timer_ui()

		if time_remaining <= 0:
			_on_fail()
			return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and in_zone:

		if not timer_started:
			timer_started = true
			timer_bar_text.text = "Time Remaining"

		var delta_angle = current_angle - last_angle

		if delta_angle > PI:
			delta_angle -= TAU
		elif delta_angle < -PI:
			delta_angle += TAU

		last_delta_angle = delta_angle

		if delta_angle > 0:
			total_rotation += delta_angle
		elif delta_angle < 0:
			total_rotation = max(0.0, total_rotation + delta_angle)

		var progress = total_rotation / TAU / required_wraps
		shake_timer += delta
		_shake_sprite(delta, progress)
		_update_ui()

		if total_rotation / TAU >= required_wraps:
			_on_complete()

	else:
		last_delta_angle = 0.0
		wound_sprite.position = wound_sprite.position.lerp(sprite_origin, delta * 10.0)
		shake_timer = 0.0

		if not timer_started:
			if dist < min_radius:
				label.text = "Too close! Move cursor outward."
			elif dist > max_radius:
				label.text = "Too far! Move cursor closer to the wound."
			else:
				label.text = "Hold left click inside the ring to start!"
		else:
			if dist < min_radius:
				label.text = "Too close! Move cursor outward."
			elif dist > max_radius:
				label.text = "Too far! Move cursor closer to the wound."
			else:
				label.text = "Keep holding and circling!"

	last_angle = current_angle

func _show_bandage_cursor():
	cursor_in_zone = true
	cursor_sprite.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)  # Hide the system cursor

func _show_system_cursor():
	cursor_in_zone = false
	cursor_sprite.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Restore the system cursor

func _shake_sprite(delta, progress):
	var current_intensity = shake_intensity * (0.5 + progress * 1.5)
	var current_speed = shake_speed * (1.0 + progress * 1.0)
	var offset_x = sin(shake_timer * current_speed) * current_intensity
	var offset_y = sin(shake_timer * current_speed * 1.3) * current_intensity * 0.7
	wound_sprite.position = sprite_origin + Vector2(offset_x, offset_y)

func _update_timer_ui():
	var ratio = time_remaining / time_limit

	timer_bar_fill.size.x = 300.0 * ratio

	if ratio > 0.5:
		timer_bar_fill.color = Color(0.2, 0.7, 1.0)
	elif ratio > 0.25:
		timer_bar_fill.color = Color(0.95, 0.75, 0.1)
	else:
		timer_bar_fill.color = Color(0.95, 0.2, 0.2)

	timer_label.text = "%.1fs" % max(time_remaining, 0.0)

	if time_remaining <= 3.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		var pulse = 14 + int(sin(time_remaining * 10) * 3)
		timer_label.add_theme_font_size_override("font_size", pulse)
	else:
		timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
		timer_label.add_theme_font_size_override("font_size", 14)

func _draw():
	var ring_color = Color(0.2, 1.0, 0.3, 0.5) if in_zone else Color(1.0, 0.3, 0.3, 0.4)

	draw_arc(wound_center, min_radius, 0, TAU, 64, ring_color, 3.0)
	draw_arc(wound_center, max_radius, 0, TAU, 64, ring_color, 3.0)

	for r in range(int(min_radius), int(max_radius), 6):
		draw_arc(wound_center, r, 0, TAU, 64, Color(ring_color.r, ring_color.g, ring_color.b, 0.04), 6.0)

	draw_circle(wound_center, 8, Color(1, 1, 1, 0.8))

func _update_ui():
	var wraps_done = total_rotation / TAU
	var progress = wraps_done / required_wraps

	bar_fill.size.x = 400.0 * progress

	if last_delta_angle < 0:
		bar_fill.color = Color(0.886, 0.102, 0.192, 1.0)
	elif progress < 0.5:
		bar_fill.color = Color(1.0, 0.498, 0.0, 1.0)
	elif progress < 0.85:
		bar_fill.color = Color(0.9, 0.75, 0.1)
	else:
		bar_fill.color = Color(0.2, 0.85, 0.35)

	label.text = "Wraps: %.1f / %d — Keep going!" % [wraps_done, int(required_wraps)]

func _on_complete():
	is_complete = true
	bar_fill.size.x = 400.0
	bar_fill.color = Color(0.1, 0.9, 0.3)
	label.text = "Great job! Bandage applied correctly!"
	_show_system_cursor()
	emit_signal("minigame_completed")

func _on_fail():
	is_failed = true
	wound_sprite.position = sprite_origin
	bar_fill.color = Color(0.8, 0.1, 0.1)
	timer_bar_fill.size.x = 0
	timer_label.text = "0.0s"
	timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	label.text = "Too slow! The wound wasn't wrapped in time."
	label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	_show_system_cursor()
	emit_signal("minigame_failed")
