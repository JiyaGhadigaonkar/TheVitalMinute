extends Node2D

# ─────────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────────
signal minigame_completed(score: float)

# ─────────────────────────────────────────────
#  CONFIG
# ─────────────────────────────────────────────
const TARGET_BPM         := 110.0
const TARGET_INTERVAL    := 60.0 / TARGET_BPM  # ~0.545 seconds
const TOLERANCE_PERFECT  := 0.08               # ±80ms  = "Perfect"
const TOLERANCE_GOOD     := 0.15               # ±150ms = "Good"
const COMPRESSIONS_NEEDED := 30                # presses required to finish

# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────
var last_click_time   := -1.0
var compression_count := 0
var quality_score     := 0.0    # 0–100
var is_active         := true

# ─────────────────────────────────────────────
#  NODE REFERENCES  (adjust paths if your scene tree differs)
# ─────────────────────────────────────────────
@onready var feedback_label : Label       = $FeedbackLabel
@onready var quality_meter  : ProgressBar = $QualityMeter
@onready var count_label    : Label       = $CompressionCount
@onready var beat_light     : ColorRect   = $RhythmIndicator/BeatLight
@onready var beat_timer     : Timer       = $BeatTimer
@onready var chest_area     : Area2D      = $Patient/ChestArea
@onready var chest_collision: CollisionShape2D = $Patient/ChestArea/CollisionShape2D
@onready var patient_sprite : Node2D      = $Patient
@onready var tick_sound     : AudioStreamPlayer = get_node_or_null("TickSound") as AudioStreamPlayer
@onready var good_sound     : AudioStreamPlayer = get_node_or_null("GoodSound") as AudioStreamPlayer
@onready var bad_sound      : AudioStreamPlayer = get_node_or_null("BadSound") as AudioStreamPlayer

# ─────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────
func _ready() -> void:
	# Metronome timer
	beat_timer.wait_time = TARGET_INTERVAL
	beat_timer.one_shot  = false
	beat_timer.timeout.connect(_on_beat_timer_timeout)
	beat_timer.start()

	# Quality meter
	quality_meter.min_value = 0
	quality_meter.max_value = 100
	quality_meter.value     = 0

	# UI defaults
	feedback_label.text = "Click the chest to the beat!"
	count_label.text    = "Compressions: 0 / %d" % COMPRESSIONS_NEEDED

	# Make sure beat light starts white
	beat_light.color = Color.WHITE

	# Connect chest click
	chest_area.input_pickable = true
	chest_area.input_event.connect(_on_chest_clicked)

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_event_on_chest(event.position):
			do_compression()
	elif event is InputEventScreenTouch and event.pressed:
		if _is_event_on_chest(event.position):
			do_compression()

# ─────────────────────────────────────────────
#  METRONOME PULSE  (visual guide for the player)
#  Uses a Tween instead of await — more reliable
# ─────────────────────────────────────────────
func _on_beat_timer_timeout() -> void:
	if tick_sound and not tick_sound.playing:
		tick_sound.play()

	beat_light.color = Color.RED
	var tween := create_tween()
	tween.tween_property(beat_light, "color", Color.WHITE, 0.25)

# ─────────────────────────────────────────────
#  CHEST CLICK INPUT
# ─────────────────────────────────────────────
func _on_chest_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		do_compression()
	elif event is InputEventScreenTouch and event.pressed:
		do_compression()

func _is_event_on_chest(screen_position: Vector2) -> bool:
	if chest_collision == null or chest_collision.shape == null or chest_collision.disabled:
		return false

	var local_position := chest_collision.global_transform.affine_inverse() * screen_position

	if chest_collision.shape is RectangleShape2D:
		var rect_shape := chest_collision.shape as RectangleShape2D
		return abs(local_position.x) <= rect_shape.size.x * 0.5 and abs(local_position.y) <= rect_shape.size.y * 0.5

	if chest_collision.shape is CircleShape2D:
		var circle_shape := chest_collision.shape as CircleShape2D
		return local_position.length() <= circle_shape.radius

	return false

# ─────────────────────────────────────────────
#  CORE COMPRESSION LOGIC
# ─────────────────────────────────────────────
func do_compression() -> void:
	var now := Time.get_ticks_msec() / 1000.0

	# Chest-press animation (simple position bump)
	patient_sprite.position.y += 6
	await get_tree().create_timer(0.08).timeout
	patient_sprite.position.y -= 6

	# First press just starts tracking; no score yet
	if last_click_time < 0.0:
		last_click_time = now
		show_feedback("Keep the rhythm!", Color.WHITE)
		return

	var interval := now - last_click_time
	last_click_time   = now
	compression_count += 1
	count_label.text  = "Compressions: %d / %d" % [compression_count, COMPRESSIONS_NEEDED]

	# ── Evaluate timing ──────────────────────
	var diff: float = abs(interval - TARGET_INTERVAL)

	if diff <= TOLERANCE_PERFECT:
		quality_score = clamp(quality_score + 8.0, 0.0, 100.0)
		show_feedback("Perfect! 🎯", Color.GREEN)
		_play(good_sound)
	elif diff <= TOLERANCE_GOOD:
		quality_score = clamp(quality_score + 4.0, 0.0, 100.0)
		show_feedback("Good! 👍", Color.YELLOW)
		_play(good_sound)
	elif interval < TARGET_INTERVAL - TOLERANCE_GOOD:
		quality_score = clamp(quality_score - 5.0, 0.0, 100.0)
		show_feedback("Too fast! Slow down", Color.ORANGE_RED)
		_play(bad_sound)
	else:
		quality_score = clamp(quality_score - 5.0, 0.0, 100.0)
		show_feedback("Too slow! Speed up", Color.ORANGE)
		_play(bad_sound)

	quality_meter.value = quality_score

	# ── Check completion ─────────────────────
	if compression_count >= COMPRESSIONS_NEEDED:
		end_minigame()

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
