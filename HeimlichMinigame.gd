extends Node2D

@export var bar_width: float = 600.0
@export var indicator_speed: float = 300.0
@export var target_zone_width: float = 120.0
@export var thrusts_required: int = 8

var indicator_pos: float = 0.0
var direction: float = 1.0
var thrusts_done: int = 0
var can_press: bool = true
var game_active: bool = true

@onready var indicator = $ThrustBar/Indicator
@onready var target_zone = $ThrustBar/TargetZone
@onready var bar_bg = $ThrustBar/BarBackground
@onready var result_label = $ResultLabel
@onready var thrust_counter = $ThrustCounter
@onready var camera = $Camera2D  # Add a Camera2D node to your scene

signal minigame_completed(success: bool)

func _ready():
	var center = bar_width / 2.0
	target_zone.position.x = center - (target_zone_width / 2.0)
	target_zone.size.x = target_zone_width
	result_label.visible = false

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

func _input(event):
	if not game_active or not can_press:
		return
	if event.is_action_pressed("ui_accept") or event is InputEventMouseButton and event.pressed:
		attempt_thrust()

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
		screen_shake()
		if thrusts_done >= thrusts_required:
			end_game(true)
	else:
		show_result("MISS!", Color.RED)

	await get_tree().create_timer(0.4).timeout
	result_label.visible = false
	can_press = true

func screen_shake():
	var tween = create_tween()
	for i in 6:
		tween.tween_property(camera, "offset", Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func show_result(text: String, color: Color):
	result_label.text = text
	result_label.modulate = color
	result_label.visible = true

func end_game(success: bool):
	game_active = false
	if success:
		show_result("AIRWAY CLEAR!", Color.CYAN)
		emit_signal("minigame_completed", true)
	else:
		show_result("FAILED...", Color.RED)
		emit_signal("minigame_completed", false)
