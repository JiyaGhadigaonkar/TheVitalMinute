extends Node2D

# --- Signals ---
signal minigame_completed
signal minigame_failed

# --- Configuration ---
var required_wraps = 4.0
var hit_radius = 300.0
var time_limit = 8.0
@export var open_hand_scale = Vector2(2, 2)
@export var closed_hand_scale = Vector2(.3, .3)
@export var success_texture: Texture2D
@export var failure_texture: Texture2D

# --- Internal state ---
var wound_center = Vector2.ZERO
var total_rotation = 0.0
var last_angle = 0.0
var is_complete = false
var is_failed = false
var in_zone = false
var time_remaining = 8.0
var timer_started = false
var last_delta_angle = 0.0

# --- Shake state ---
var shake_timer = 0.0
var shake_intensity = 3.0
var shake_speed = 20.0
var sprite_origin = Vector2()

# --- Arrow state ---
var arrow_angle = 0.0
var arrow_pulse_timer = 0.0
var arrow_nodes = []

# --- Popup state ---
var popup_sprite: Sprite2D
var popup_tween: Tween
var try_again_button: Button
var popup_active = false

# --- UI Nodes ---
var label: Label
var sub_label: Label
var bar_bg: ColorRect
var bar_fill: ColorRect
var bar_label: Label
var wound_sprite: Sprite2D
var timer_label: Label
var timer_bar_bg: ColorRect
var timer_bar_fill: ColorRect
var timer_bar_text: Label

# --- Cursor ---
var cursor_sprite: Sprite2D
var cursor_in_zone: bool = false
var cursor_is_grabbing: bool = false
var open_hand_texture: Texture2D
var closed_hand_texture: Texture2D

# --- Background ---
var background_sprite: Sprite2D

# -------------------------------------------------------

func _ready():
	var vp = get_viewport().get_visible_rect().size
	wound_center = vp / 2
	time_remaining = time_limit

	_setup_background()
	_setup_sprite()
	_setup_cursor()
	_setup_arrows()
	_setup_ui()
	_setup_popup()

	last_angle = wound_center.angle_to_point(get_global_mouse_position())

func _setup_background():
	background_sprite = $WoundSprite

func _setup_sprite():
	wound_sprite = $WoundSprite
	wound_sprite.position = wound_center
	sprite_origin = wound_sprite.position

func _setup_cursor():
	open_hand_texture = load("res://Assets/UI_Hand_Open.png")
	closed_hand_texture = load("res://Assets/UI_Hand_Gauze.png")
	cursor_sprite = Sprite2D.new()
	cursor_sprite.texture = open_hand_texture
	cursor_sprite.scale = open_hand_scale
	cursor_sprite.visible = false
	add_child(cursor_sprite)

func _setup_arrows():
	for i in range(2):
		var arrow = Node2D.new()
		arrow.name = "Arrow" + str(i)

		var shaft = Line2D.new()
		shaft.name = "Shaft"
		shaft.width = 16
		shaft.default_color = Color(1, 1, 1, 1)
		shaft.begin_cap_mode = Line2D.LINE_CAP_ROUND
		shaft.end_cap_mode = Line2D.LINE_CAP_NONE
		arrow.add_child(shaft)

		var glow = Line2D.new()
		glow.name = "Glow"
		glow.width = 18.0
		glow.default_color = Color(1.0, 0.9, 0.1, 0.25)
		glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
		glow.end_cap_mode = Line2D.LINE_CAP_NONE
		arrow.add_child(glow)

		var head = Polygon2D.new()
		head.name = "Head"
		head.color = Color(1.0, 0.9, 0.2, 1.0)
		arrow.add_child(head)

		add_child(arrow)
		arrow_nodes.append(arrow)

func _setup_ui():
	var vp = get_viewport().get_visible_rect().size

	label = Label.new()
	label.text = "Circle the wound\nCLOCKWISE!"
	label.position = Vector2(30, vp.y / 2 - 80)
	label.size = Vector2(380, 80)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(label)

	sub_label = Label.new()
	sub_label.text = "Hold LEFT CLICK and\nspin around the wound"
	sub_label.position = Vector2(30, vp.y / 2 + 20)
	sub_label.size = Vector2(380, 70)
	sub_label.add_theme_font_size_override("font_size", 20)
	sub_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	add_child(sub_label)

	timer_bar_text = Label.new()
	timer_bar_text.text = "Timer — click to start!"
	timer_bar_text.position = Vector2(20, 14)
	timer_bar_text.size = Vector2(400, 30)
	timer_bar_text.add_theme_font_size_override("font_size", 20)
	timer_bar_text.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(timer_bar_text)

	timer_bar_bg = ColorRect.new()
	timer_bar_bg.color = Color(0.1, 0.1, 0.1, 0.85)
	timer_bar_bg.size = Vector2(380, 40)
	timer_bar_bg.position = Vector2(20, 46)
	add_child(timer_bar_bg)

	timer_bar_fill = ColorRect.new()
	timer_bar_fill.color = Color(0.144, 0.144, 0.144, 1.0)
	timer_bar_fill.size = Vector2(380, 40)
	timer_bar_fill.position = Vector2(20, 46)
	add_child(timer_bar_fill)

	timer_label = Label.new()
	timer_label.text = "- - -"
	timer_label.position = Vector2(20, 46)
	timer_label.size = Vector2(380, 40)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(timer_label)

	bar_bg = ColorRect.new()
	bar_bg.color = Color(0.144, 0.144, 0.144, 1.0)
	bar_bg.size = Vector2(800, 60)
	bar_bg.position = Vector2(vp.x / 2 - 400, vp.y - 100)
	add_child(bar_bg)

	bar_fill = ColorRect.new()
	bar_fill.color = Color(1.0, 0.498, 0.0, 1.0)
	bar_fill.size = Vector2(0, 60)
	bar_fill.position = bar_bg.position
	add_child(bar_fill)

	bar_label = Label.new()
	bar_label.text = "Wrapping Progress"
	bar_label.position = bar_bg.position
	bar_label.size = Vector2(800, 60)
	bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_label.add_theme_font_size_override("font_size", 22)
	bar_label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(bar_label)

func _setup_popup():
	# The image sprite — hidden until needed
	popup_sprite = Sprite2D.new()
	popup_sprite.visible = false
	popup_sprite.scale = Vector2.ZERO   # Starts at zero for pop-in animation
	popup_sprite.position = wound_center
	add_child(popup_sprite)

	# Try Again button — only shown on failure
	try_again_button = Button.new()
	try_again_button.text = "Try Again"
	try_again_button.visible = false
	try_again_button.add_theme_font_size_override("font_size", 28)
	# Position it below center
	try_again_button.size = Vector2(220, 60)
	try_again_button.position = Vector2(wound_center.x - 110, wound_center.y + 180)
	try_again_button.pressed.connect(_on_try_again_pressed)
	add_child(try_again_button)

func _process(delta):
	if is_complete or is_failed:
		wound_sprite.position = sprite_origin
		_show_system_cursor()
		_hide_arrows()
		return

	arrow_angle += delta * 2.5
	arrow_pulse_timer += delta

	var mouse_pos = get_global_mouse_position()
	var dist = mouse_pos.distance_to(wound_center)
	in_zone = dist < hit_radius
	var current_angle = wound_center.angle_to_point(mouse_pos)

	cursor_sprite.position = mouse_pos

	if in_zone:
		if not cursor_in_zone:
			_show_bandage_cursor()
		var is_clicking = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if is_clicking and not cursor_is_grabbing:
			cursor_sprite.texture = closed_hand_texture
			cursor_sprite.scale = closed_hand_scale
			cursor_is_grabbing = true
		elif not is_clicking and cursor_is_grabbing:
			cursor_sprite.texture = open_hand_texture
			cursor_sprite.scale = open_hand_scale
			cursor_is_grabbing = false
	elif cursor_in_zone:
		_show_system_cursor()

	if not timer_started:
		_update_arrows(delta)
	else:
		_hide_arrows()

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
			sub_label.text = "Hold LEFT CLICK and\nspin around the wound"
			sub_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
			if not in_zone:
				label.text = "Move cursor CLOSER\nto the wound!"
			else:
				label.text = "Circle the wound\nCLOCKWISE!"
		else:
			if not in_zone:
				label.text = "Move cursor\nCLOSER!"
				sub_label.text = "You are outside\nthe wound area"
				sub_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
			else:
				label.text = "Keep circling\nCLOCKWISE!"
				sub_label.text = "Don't stop —\nkeep spinning!"
				sub_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))

	last_angle = current_angle

func _show_success_popup():
	if success_texture == null:
		return

	popup_sprite.texture = success_texture
	popup_sprite.scale = Vector2.ZERO
	popup_sprite.modulate = Color(1, 1, 1, 0)
	popup_sprite.visible = true

	# Kill any existing tween
	if popup_tween:
		popup_tween.kill()

	popup_tween = create_tween()
	popup_tween.set_parallel(true)   # Run scale and fade at the same time

	# Overshoot past target scale then settle — gives a bouncy feel
	popup_tween.tween_property(popup_sprite, "scale", Vector2(1.15, 1.15), 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	popup_tween.tween_property(popup_sprite, "modulate", Color(1, 1, 1, 1), 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# After the initial pop, settle back to exactly 1.0
	popup_tween.chain().tween_property(popup_sprite, "scale", Vector2(1.0, 1.0), 0.15) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _show_failure_popup():
	if failure_texture == null:
		return

	popup_sprite.texture = failure_texture
	popup_sprite.scale = Vector2(1.1, 1.1)   # Starts slightly large
	popup_sprite.modulate = Color(1, 1, 1, 0)
	popup_sprite.visible = true

	if popup_tween:
		popup_tween.kill()

	popup_tween = create_tween()
	popup_tween.set_parallel(true)

	# Droops in — shrinks down to size with no bounce, feels heavy
	popup_tween.tween_property(popup_sprite, "scale", Vector2(1.0, 1.0), 0.45) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	popup_tween.tween_property(popup_sprite, "modulate", Color(1, 1, 1, 1), 0.4) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

	# Show the try again button after the popup finishes fading in
	popup_tween.chain().tween_callback(func():
		try_again_button.visible = true
		# Fade the button in too
		try_again_button.modulate = Color(1, 1, 1, 0)
		var btn_tween = create_tween()
		btn_tween.tween_property(try_again_button, "modulate", Color(1, 1, 1, 1), 0.3)
	)

func _on_try_again_pressed():
	# Reset everything back to starting state
	is_failed = false
	is_complete = false
	total_rotation = 0.0
	time_remaining = time_limit
	timer_started = false
	last_delta_angle = 0.0
	shake_timer = 0.0

	# Hide popup and button
	popup_sprite.visible = false
	try_again_button.visible = false

	# Reset UI text and colors
	label.text = "Circle the wound\nCLOCKWISE!"
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	sub_label.text = "Hold LEFT CLICK and\nspin around the wound"
	sub_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	timer_bar_text.text = "Timer — click to start!"
	timer_label.text = "- - -"
	timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_bar_fill.size.x = 380.0
	timer_bar_fill.color = Color(0.144, 0.144, 0.144, 1.0)
	bar_fill.size.x = 0
	bar_fill.color = Color(1.0, 0.498, 0.0, 1.0)
	bar_label.text = "Wrapping Progress"

	last_angle = wound_center.angle_to_point(get_global_mouse_position())

func _update_arrows(delta):
	var pulse = 0.55 + 0.45 * sin(arrow_pulse_timer * 3.5)
	var guide_radius = hit_radius * 0.72
	var arc_span = deg_to_rad(110.0)
	var num_points = 24
	var num_arrows = arrow_nodes.size()

	for i in range(num_arrows):
		var arrow = arrow_nodes[i]
		arrow.visible = true
		arrow.position = Vector2.ZERO

		var start_angle = arrow_angle + (TAU / num_arrows) * float(i)

		var points = PackedVector2Array()
		for j in range(num_points):
			var t = float(j) / float(num_points - 1)
			var a = start_angle + t * arc_span
			points.append(wound_center + Vector2(cos(a), sin(a)) * guide_radius)

		var shaft = arrow.get_node("Shaft")
		shaft.clear_points()
		for p in points:
			shaft.add_point(p)
		shaft.default_color = Color(1, 1, 1, pulse)

		var glow = arrow.get_node("Glow")
		glow.clear_points()
		for p in points:
			glow.add_point(p)
		glow.default_color = Color(1.0, 0.9, 0.1, pulse * 0.3)

		var tip = points[points.size() - 1]
		var before_tip = points[points.size() - 2]
		var tip_dir = (tip - before_tip).normalized()
		var tip_perp = Vector2(-tip_dir.y, tip_dir.x)
		var head_size = 40.0

		var head = arrow.get_node("Head")
		head.polygon = PackedVector2Array([
			tip + tip_dir * head_size,
			tip - tip_dir * 6 + tip_perp * 20,
			tip - tip_dir * 6 - tip_perp * 20,
		])
		head.color = Color(1.0, 0.9, 0.2, pulse)

func _hide_arrows():
	for arrow in arrow_nodes:
		arrow.visible = false

func _draw():
	if wound_center == Vector2.ZERO:
		return
	var ring_color = Color(0.2, 1.0, 0.3, 0.5) if in_zone else Color(1.0, 0.3, 0.3, 0.4)
	draw_arc(wound_center, hit_radius, 0, TAU, 128, ring_color, 4.0)
	draw_circle(wound_center, hit_radius, Color(ring_color.r, ring_color.g, ring_color.b, 0.06))
	draw_circle(wound_center, 10, Color(1, 1, 1, 0.9))

func _show_bandage_cursor():
	cursor_in_zone = true
	cursor_is_grabbing = false
	cursor_sprite.texture = open_hand_texture
	cursor_sprite.scale = open_hand_scale
	cursor_sprite.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _show_system_cursor():
	cursor_in_zone = false
	cursor_is_grabbing = false
	cursor_sprite.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _shake_sprite(delta, progress):
	var current_intensity = shake_intensity * (0.5 + progress * 1.5)
	var current_speed = shake_speed * (1.0 + progress * 1.0)
	var offset_x = sin(shake_timer * current_speed) * current_intensity
	var offset_y = sin(shake_timer * current_speed * 1.3) * current_intensity * 0.7
	wound_sprite.position = sprite_origin + Vector2(offset_x, offset_y)

func _update_timer_ui():
	var ratio = time_remaining / time_limit
	timer_bar_fill.size.x = 380.0 * ratio

	if ratio > 0.5:
		timer_bar_fill.color = Color(0.2, 0.7, 1.0)
	elif ratio > 0.25:
		timer_bar_fill.color = Color(0.95, 0.75, 0.1)
	else:
		timer_bar_fill.color = Color(0.95, 0.2, 0.2)

	timer_label.text = "%.1fs" % max(time_remaining, 0.0)

	if time_remaining <= 3.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		var pulse_size = 24 + int(sin(time_remaining * 10) * 4)
		timer_label.add_theme_font_size_override("font_size", pulse_size)
	else:
		timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
		timer_label.add_theme_font_size_override("font_size", 24)

func _update_ui():
	var wraps_done = total_rotation / TAU
	var progress = wraps_done / required_wraps

	bar_fill.size.x = 800.0 * progress
	bar_fill.size.y = 60

	if last_delta_angle < 0:
		bar_fill.color = Color(0.886, 0.102, 0.192, 1.0)
		label.text = "Wrong way!\nGo CLOCKWISE!"
		sub_label.text = "Counter-clockwise\nundoes progress!"
		sub_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	elif progress < 0.5:
		bar_fill.color = Color(1.0, 0.498, 0.0, 1.0)
		label.text = "Keep going\nCLOCKWISE!"
		sub_label.text = "%.0f%% wrapped!" % (progress * 100)
		sub_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	elif progress < 0.85:
		bar_fill.color = Color(0.9, 0.75, 0.1)
		label.text = "Looking good —\nkeep spinning!"
		sub_label.text = "%.0f%% wrapped!" % (progress * 100)
		sub_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	else:
		bar_fill.color = Color(0.2, 0.85, 0.35)
		label.text = "Almost done —\nfinish it!"
		sub_label.text = "%.0f%% — one more spin!" % (progress * 100)
		sub_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))

func _on_complete():
	is_complete = true
	bar_fill.size.x = 800
	bar_fill.color = Color(0.1, 0.9, 0.3)
	label.text = "Bandage\napplied!"
	sub_label.text = "Great job!"
	sub_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	bar_label.text = "Complete!"
	background_sprite.texture = load("res://Assets/Scene_Foot_Wrapped.png")
	_show_system_cursor()
	_hide_arrows()
	_show_success_popup()
	emit_signal("minigame_completed")

func _on_fail():
	is_failed = true
	wound_sprite.position = sprite_origin
	bar_fill.color = Color(0.8, 0.1, 0.1)
	timer_bar_fill.size.x = 0
	timer_label.text = "0.0s"
	timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	label.text = "Too slow!"
	label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	sub_label.text = "Wound not\nwrapped in time."
	sub_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	_show_system_cursor()
	_hide_arrows()
	_show_failure_popup()
	emit_signal("minigame_failed")
