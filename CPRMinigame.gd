extends Node2D

# ─────────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────────
signal minigame_completed(score: float)

# ─────────────────────────────────────────────
#  CONFIG
# ─────────────────────────────────────────────
const TARGET_BPM          := 110.0
const TARGET_INTERVAL     := 60.0 / TARGET_BPM  # ~0.545 seconds
const TOLERANCE_PERFECT   := 0.08
const TOLERANCE_GOOD      := 0.15
const COMPRESSIONS_NEEDED := 30

# Rhythm lane settings
const DOT_SPEED           := 300.0   # pixels per second the dots travel left
const DOT_SPAWN_X         := 800.0   # where dots spawn (right side of lane)
const HIT_ZONE_X          := 80.0    # x position of the target ring inside the lane node
const DOT_Y               := 0.0     # vertical centre inside lane (lane is centred)
const DOT_RADIUS          := 28.0

# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────
var last_click_time   := -1.0
var compression_count := 0
var quality_score     := 0.0
var is_active         := true
var first_click_done  := false
var dots: Array = []

# ─────────────────────────────────────────────
#  NODE REFERENCES
# ─────────────────────────────────────────────
@onready var feedback_label : Label       = $FeedbackLabel
@onready var quality_meter  : ProgressBar = $QualityMeter
@onready var count_label    : Label       = $CompressionCount
@onready var beat_timer     : Timer       = $BeatTimer
@onready var chest_area     : Area2D      = $Patient/ChestArea
@onready var patient_sprite : Node2D      = $Patient
@onready var chest_prompt   : Label       = $ChestPrompt
@onready var rhythm_lane    : Node2D      = $RhythmLane

var tick_sound : AudioStreamPlayer = null
var good_sound : AudioStreamPlayer = null
var bad_sound  : AudioStreamPlayer = null

# ─────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────
func _ready() -> void:
	# Optional audio
	tick_sound = get_node_or_null("TickSound") as AudioStreamPlayer
	good_sound = get_node_or_null("GoodSound") as AudioStreamPlayer
	bad_sound  = get_node_or_null("BadSound")  as AudioStreamPlayer

	# Beat timer — spawns dots
	beat_timer.wait_time = TARGET_INTERVAL
	beat_timer.one_shot  = false
	beat_timer.timeout.connect(_on_beat_timer_timeout)
	beat_timer.start()

	# Quality meter
	quality_meter.min_value = 0
	quality_meter.max_value = 100
	quality_meter.value     = 0

	# UI defaults
	feedback_label.text = "Press to the heartbeat!"
	count_label.text    = "Compressions: 0 / %d" % COMPRESSIONS_NEEDED

	# Chest prompt
	chest_prompt.text    = "Click Here!"
	chest_prompt.visible = true

	# Connect chest click
	chest_area.input_pickable = true
	chest_area.input_event.connect(_on_chest_clicked)

# ─────────────────────────────────────────────
#  PROCESS — move dots each frame
# ─────────────────────────────────────────────
func _process(delta: float) -> void:
	for dot in dots:
		if is_instance_valid(dot):
			dot.position.x -= DOT_SPEED * delta
			if dot.position.x < HIT_ZONE_X - 120:
				dot.queue_free()
	dots = dots.filter(func(d): return is_instance_valid(d))

# ─────────────────────────────────────────────
#  BEAT TIMER — spawn a new dot
# ─────────────────────────────────────────────
func _on_beat_timer_timeout() -> void:
	_play(tick_sound)
	_spawn_dot()

func _spawn_dot() -> void:
	var panel      := Panel.new()
	panel.size     = Vector2(DOT_RADIUS * 2, DOT_RADIUS * 2)
	panel.position = Vector2(DOT_SPAWN_X - DOT_RADIUS, DOT_Y - DOT_RADIUS)
	var pstyle     := StyleBoxFlat.new()
	pstyle.bg_color                    = Color(0.85, 0.85, 0.85, 1.0)
	pstyle.corner_radius_top_left      = int(DOT_RADIUS)
	pstyle.corner_radius_top_right     = int(DOT_RADIUS)
	pstyle.corner_radius_bottom_left   = int(DOT_RADIUS)
	pstyle.corner_radius_bottom_right  = int(DOT_RADIUS)
	panel.add_theme_stylebox_override("panel", pstyle)
	rhythm_lane.add_child(panel)
	dots.append(panel)

# ─────────────────────────────────────────────
#  CHEST INPUT
# ─────────────────────────────────────────────
func _on_chest_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_press()
	elif event is InputEventScreenTouch and event.pressed:
		_handle_press()

func _handle_press() -> void:
	if not first_click_done:
		first_click_done     = true
		chest_prompt.visible = false
	do_compression()

# ─────────────────────────────────────────────
#  CORE COMPRESSION LOGIC
# ─────────────────────────────────────────────
func do_compression() -> void:
	var now := Time.get_ticks_msec() / 1000.0

	# Chest-press animation
	patient_sprite.position.y += 6
	await get_tree().create_timer(0.08).timeout
	patient_sprite.position.y -= 6

	# First press — start tracking only
	if last_click_time < 0.0:
		last_click_time = now
		show_feedback("Keep the rhythm!", Color.WHITE)
		_flash_nearest_dot(false)
		return

	var interval := now - last_click_time
	last_click_time   = now
	compression_count += 1
	count_label.text  = "Compressions: %d / %d" % [compression_count, COMPRESSIONS_NEEDED]

	var diff: float = abs(interval - TARGET_INTERVAL)

	if diff <= TOLERANCE_PERFECT:
		quality_score = clamp(quality_score + 8.0, 0.0, 100.0)
		show_feedback("Perfect! 🎯", Color.GREEN)
		_flash_nearest_dot(true)
		_play(good_sound)
	elif diff <= TOLERANCE_GOOD:
		quality_score = clamp(quality_score + 4.0, 0.0, 100.0)
		show_feedback("Good! 👍", Color.YELLOW)
		_flash_nearest_dot(true)
		_play(good_sound)
	elif interval < TARGET_INTERVAL - TOLERANCE_GOOD:
		quality_score = clamp(quality_score - 5.0, 0.0, 100.0)
		show_feedback("Too fast!", Color.ORANGE_RED)
		_flash_nearest_dot(false)
		_play(bad_sound)
	else:
		quality_score = clamp(quality_score - 5.0, 0.0, 100.0)
		show_feedback("Too slow!", Color.ORANGE)
		_flash_nearest_dot(false)
		_play(bad_sound)

	quality_meter.value = quality_score

	if compression_count >= COMPRESSIONS_NEEDED:
		end_minigame()

# ─────────────────────────────────────────────
#  FLASH DOT NEAREST THE HIT ZONE
# ─────────────────────────────────────────────
func _flash_nearest_dot(good: bool) -> void:
	var best_dot  : Panel = null
	var best_dist := 9999.0
	for dot in dots:
		if is_instance_valid(dot):
			var d: float = absf(dot.position.x + DOT_RADIUS - HIT_ZONE_X)
			if d < best_dist:
				best_dist = d
				best_dot  = dot

	if best_dot == null:
		return

	var flash_color: Color = Color.GREEN if good else Color.RED
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color                    = flash_color
	pstyle.corner_radius_top_left      = int(DOT_RADIUS)
	pstyle.corner_radius_top_right     = int(DOT_RADIUS)
	pstyle.corner_radius_bottom_left   = int(DOT_RADIUS)
	pstyle.corner_radius_bottom_right  = int(DOT_RADIUS)
	best_dot.add_theme_stylebox_override("panel", pstyle)

	var tween := create_tween()
	tween.tween_property(best_dot, "scale", Vector2(0.1, 0.1), 0.2)
	tween.tween_callback(best_dot.queue_free)

# ─────────────────────────────────────────────
#  FEEDBACK LABEL
# ─────────────────────────────────────────────
func show_feedback(text: String, color: Color) -> void:
	feedback_label.text     = text
	feedback_label.modulate = color

# ─────────────────────────────────────────────
#  END GAME
# ─────────────────────────────────────────────
func end_minigame() -> void:
	is_active = false
	beat_timer.stop()

	var grade := ""
	if   quality_score >= 80: grade = "Excellent!"
	elif quality_score >= 55: grade = "Good job!"
	elif quality_score >= 35: grade = "Needs work"
	else:                     grade = "Keep practising"

	feedback_label.text     = "%s  (Score: %.0f%%)" % [grade, quality_score]
	feedback_label.modulate = Color.WHITE

	emit_signal("minigame_completed", quality_score)

# ─────────────────────────────────────────────
#  HELPER – safe audio play
# ─────────────────────────────────────────────
func _play(player: AudioStreamPlayer) -> void:
	if player and not player.playing:
		player.play()
