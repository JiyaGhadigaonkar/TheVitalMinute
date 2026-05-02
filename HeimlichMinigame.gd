extends Node2D
@export var bar_width: float = 700.0
@export var indicator_speed: float = 300.0
@export var target_zone_width: float = 120.0
@export var thrusts_required: int = 8

@export var success_texture: Texture2D

var indicator_pos: float = 0.0
var direction: float = 1.0
var thrusts_done: int = 0
var can_press: bool = true
var game_active: bool = false
var showing_prompt: bool = true

@onready var indicator = $ThrustBar/Indicator
@onready var target_zone = $ThrustBar/TargetZone
@onready var bar_bg = $ThrustBar/BarBackground
@onready var result_label = $ResultLabel
@onready var thrust_counter = $ThrustCounter
@onready var background = $Background
@onready var prompt_screen = $PromptScreen
@onready var prompt_label = $PromptScreen/Label
@onready var start_label = $PromptScreen/StartLabel

signal minigame_completed(success: bool)

func _ready():
	var center = 350
	target_zone.position.x = center - (target_zone_width / 2.0)
	target_zone.size.x = target_zone_width
	result_label.visible = false

	prompt_label.text = """HOW TO PLAY

The indicator moves back and forth across the bar.

Click (or press SPACE) when the indicator
is inside the GREEN TARGET ZONE.

Land %d successful compressions in a row
to clear the airway!

Miss once and you start over!""" % thrusts_required

	start_label.text = "[ CLICK ANYWHERE TO BEGIN ]"

	$ThrustBar.visible = false
	thrust_counter.visible = false
	result_label.visible = false
	prompt_screen.visible = true

func _input(event):
	if showing_prompt:
		if event is InputEventMouseButton and event.pressed:
			dismiss_prompt()
		elif event.is_action_pressed("ui_accept"):
			dismiss_prompt()
		return

	if not game_active or not can_press:
		return
	if event.is_action_pressed("ui_accept") or event is InputEventMouseButton and event.pressed:
		attempt_thrust()

func dismiss_prompt():
	showing_prompt = false
	game_active = true

	var tween = create_tween()
	tween.tween_property(prompt_screen, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): prompt_screen.visible = false)

	$ThrustBar.modulate.a = 0.0
	thrust_counter.modulate.a = 0.0
	$ThrustBar.visible = true
	thrust_counter.visible = true

	var tween2 = create_tween()
	tween2.tween_property($ThrustBar, "modulate:a", 1.0, 0.4)
	tween2.parallel().tween_property(thrust_counter, "modulate:a", 1.0, 0.4)

func _process(delta):
	if not game_active:
		return
	indicator_pos += direction * indicator_speed * delta
	if indicator_pos >= bar_width - indicator.size.x:
		indicator_pos = bar_width - indicator.size.x
		direction = -1.0
	elif indicator_pos <= 0:
		indicator_pos = 0
		direction = 1.0
	indicator.position.x = indicator_pos

func attempt_thrust():
	can_press = false
	var ind_left = indicator_pos
	var ind_right = indicator_pos + indicator.size.x
	var zone_left = target_zone.position.x
	var zone_right = zone_left + target_zone_width
	var overlap = ind_left < zone_right and ind_right > zone_left

	if overlap:
		thrusts_done += 1
		show_result("THRUST!", Color.GREEN)
		thrust_counter.text = "Thrusts: %d / %d" % [thrusts_done, thrusts_required]
		background_shake()
		if thrusts_done >= thrusts_required:
			end_game(true)
			return
	else:
		show_result("MISS! Starting over...", Color.RED)
		await get_tree().create_timer(0.8).timeout  # 👈 slightly longer pause so they can read it
		reset_progress()
		return

	await get_tree().create_timer(0.4).timeout
	result_label.visible = false
	can_press = true

func reset_progress():
	thrusts_done = 0
	thrust_counter.text = "Thrusts: 0 / %d" % thrusts_required
	result_label.visible = false
	can_press = true

func background_shake():
	var original_pos = background.position
	var tween = create_tween()
	for i in 6:
		tween.tween_property(background, "position", original_pos + Vector2(randf_range(-10, 10), randf_range(-8, 8)), 0.04)
	tween.tween_property(background, "position", original_pos, 0.05)

func swap_background():
	if success_texture == null:
		return
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		if background is Sprite2D:
			background.texture = success_texture
		elif background is TextureRect:
			background.texture = success_texture
	)
	tween.tween_property(background, "modulate:a", 1.0, 0.3)

func show_result(text: String, color: Color):
	result_label.text = text
	result_label.modulate = color
	result_label.visible = true

func end_game(success: bool):
	game_active = false
	if success:
		swap_background()
		show_result("AIRWAY CLEAR!", Color.CYAN)
		emit_signal("minigame_completed", true)
	else:
		show_result("FAILED...", Color.RED)
		emit_signal("minigame_completed", false)
