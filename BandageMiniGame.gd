extends Node2D

# --- Signals ---
signal minigame_completed

# --- Configuration ---
var wound_center = Vector2(400, 300)
var required_wraps = 4.0
var min_radius = 80.0
var max_radius = 300.0

# --- Internal state ---
var total_rotation = 0.0
var last_angle = 0.0
var is_complete = false
var in_zone = false

# --- Shake state ---
var shake_timer = 0.0
var shake_intensity = 3.0      # How many pixels it moves when shaking
var shake_speed = 20.0         # How fast it shakes
var sprite_origin = Vector2()  # The sprite's resting position

# --- UI Nodes ---
var label: Label
var bar_bg: ColorRect
var bar_fill: ColorRect
var wound_sprite: Sprite2D

# -------------------------------------------------------

func _ready():
	wound_center = get_viewport().get_visible_rect().size / 2
	_setup_sprite()
	_setup_ui()
	last_angle = wound_center.angle_to_point(get_global_mouse_position())

func _setup_sprite():
	# Grab the sprite and store its resting position
	wound_sprite = $WoundSprite
	wound_sprite.position = wound_center
	sprite_origin = wound_sprite.position

func _setup_ui():
	label = Label.new()
	label.text = "Hold and circle the wound to wrap the bandage!"
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)

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
	if is_complete:
		wound_sprite.position = sprite_origin  # Snap back when done
		return

	var mouse_pos = get_global_mouse_position()
	var dist = mouse_pos.distance_to(wound_center)
	in_zone = dist > min_radius and dist < max_radius
	var current_angle = wound_center.angle_to_point(mouse_pos)

	queue_redraw()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and in_zone:
		var delta_angle = current_angle - last_angle

		if delta_angle > PI:
			delta_angle -= TAU
		elif delta_angle < -PI:
			delta_angle += TAU

		if delta_angle > 0:
			total_rotation += delta_angle

		# Shake faster and more intensely as progress increases
		var progress = total_rotation / TAU / required_wraps
		shake_timer += delta
		_shake_sprite(delta, progress)

		_update_ui()

		if total_rotation / TAU >= required_wraps:
			_on_complete()

	else:
		# Smoothly return sprite to resting position when not wrapping
		wound_sprite.position = wound_sprite.position.lerp(sprite_origin, delta * 10.0)
		shake_timer = 0.0

		if dist < min_radius:
			label.text = "Too close! Move cursor outward."
		elif dist > max_radius:
			label.text = "Too far! Move cursor closer to the wound."
		else:
			label.text = "Hold left click and circle the wound!"

	last_angle = current_angle

func _shake_sprite(delta, progress):
	# Scale up shake intensity and speed as the player makes progress
	var current_intensity = shake_intensity * (0.5 + progress * 1.5)
	var current_speed = shake_speed * (1.0 + progress * 1.2)

	# Use sine waves on both axes with slightly different speeds for organic feel
	var offset_x = sin(shake_timer * current_speed) * current_intensity
	var offset_y = sin(shake_timer * current_speed * 1.3) * current_intensity * 0.7

	wound_sprite.position = sprite_origin + Vector2(offset_x, offset_y)

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

	if progress < 0.4:
		bar_fill.color = Color(0.888, 0.0, 0.0, 1.0)
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
	emit_signal("minigame_completed")
