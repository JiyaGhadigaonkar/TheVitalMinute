extends Control

signal cpr_success
signal cpr_failed
signal cpr_completed(score: int, grade: String)

@export var total_beats     : int   = 30
@export var bpm             : float = 100.0
@export var max_misses      : int   = 5
@export var window_perfect  : float = 0.08
@export var window_good     : float = 0.15
@export var window_ok       : float = 0.22

@onready var background    : TextureRect = $Background
@onready var lane          : ColorRect   = $Lane
@onready var target_ring   : Control     = $Lane/TargetRing
@onready var beat_container: Control     = $Lane/BeatContainer
@onready var score_lbl     : Label       = $HUD/ScoreLabel
@onready var combo_lbl     : Label       = $HUD/ComboLabel
@onready var lives_lbl     : Label       = $HUD/LivesLabel
@onready var progress_bar  : ProgressBar = $ProgressBar
@onready var feedback_lbl  : Label       = $FeedbackLabel
@onready var result_panel  : Panel       = $ResultPanel
@onready var result_title  : Label       = $ResultPanel/VBox/TitleLabel
@onready var result_grade  : Label       = $ResultPanel/VBox/GradeLabel
@onready var result_stats  : Label       = $ResultPanel/VBox/StatsLabel
@onready var btn_retry     : Button      = $ResultPanel/VBox/Buttons/RetryBtn
@onready var btn_continue  : Button      = $ResultPanel/VBox/Buttons/ContinueBtn
@onready var prompt_panel  : Control     = $PromptPanel
@onready var prompt_lbl    : Label       = $PromptPanel/PromptLabel

@onready var hit_sound      : AudioStreamPlayer2D = $HitSound
@onready var miss_sound     : AudioStreamPlayer2D = $MissSound
@onready var metronome      : AudioStreamPlayer2D = $MetronomeSound

var beat_interval  : float
var travel_time    : float
var time_accum     : float = 0.0
var beats_spawned  : int   = 0
var beats_hit      : int   = 0
var misses         : int   = 0
var score          : int   = 0
var combo          : int   = 0
var max_combo      : int   = 0
var active         : bool  = false
var finished       : bool  = false
var feedback_timer : float = 0.0
var pulse_timer    : float = 0.0

var shake_timer    : float   = 0.0
var shake_strength : float   = 0.0
var bg_origin      : Vector2 = Vector2.ZERO

var dots: Array = []  # [{ node, ring_node, spawn_time, hit }]

var extra_ticks_remaining : int = 0
var tick_accum : float = 0.0  # add with your other vars at the top

const C_PERFECT := Color(1.00, 0.92, 0.20)
const C_GOOD    := Color(0.40, 0.90, 0.40)
const C_OK      := Color(0.40, 0.70, 1.00)
const C_MISS    := Color(1.00, 0.30, 0.30)
const C_DOT     := Color(0.88, 0.88, 0.88)

# How many times larger the outermost ring starts relative to the dot
const RING_START_SCALE : float = 3.2
# Ring begins appearing when the dot is this far through its travel (0–1)
const RING_APPEAR_FROM : float = 0.55

func _ready() -> void:
	beat_interval = 60.0 / bpm
	travel_time   = beat_interval * 4.0
	progress_bar.max_value = total_beats
	result_panel.hide()
	btn_retry.pressed.connect(_on_retry)
	btn_continue.pressed.connect(_on_continue)
	bg_origin = background.position
	_update_hud()
	prompt_panel.show()
	prompt_lbl.text = "Press SPACE to begin"
	hit_sound.stream  = load("res://Assets/audio/799276__sadiquecat__vocal-soft-thump.wav")
	miss_sound.stream = load("res://Assets/audio/632281__robinhood76__11004-broken-string-bounce.wav")
	metronome.stream  = load("res://Assets/audio/566888__lennartgreen__click-metronome-atonal-high.wav")


func start() -> void:
	beats_spawned = 0
	beats_hit     = 0
	misses        = 0
	score         = 0
	combo         = 0
	max_combo     = 0
	time_accum    = beat_interval * 0.5
	finished      = false
	active        = true
	for d in dots:
		if is_instance_valid(d.node): d.node.queue_free()
		if is_instance_valid(d.ring_node): d.ring_node.queue_free()
	dots.clear()
	result_panel.hide()
	prompt_panel.hide()
	_update_hud()
	
	extra_ticks_remaining = 0
	tick_accum = 0.0

func _process(delta: float) -> void:
	if not active:
		if not finished:
			pulse_timer += delta
			prompt_lbl.modulate.a = 0.5 + 0.5 * sin(pulse_timer * TAU / beat_interval)
		return
		

	# ── Spawn ──
	time_accum += delta
	if time_accum >= beat_interval and beats_spawned < total_beats:
		time_accum -= beat_interval
		_spawn_dot()
		
	if extra_ticks_remaining > 0:
		tick_accum += delta
		if tick_accum >= beat_interval:
			tick_accum -= beat_interval
			metronome.play()
			extra_ticks_remaining -= 1

	# ── Sort unhit dots by proximity to target (furthest along = index 0) ──
	var now    : float = Time.get_ticks_msec() / 1000.0
	var lane_w : float = lane.size.x
	var ring_x : float = target_ring.position.x + target_ring.size.x * 0.5

	var leading_dots : Array = []
	for d in dots:
		if d.hit or not is_instance_valid(d.node): continue
		leading_dots.append(d)
	# Sort so index 0 = closest to target (highest elapsed time)
	leading_dots.sort_custom(func(a, b):
		return (now - a.spawn_time) > (now - b.spawn_time))

	# ── Move dots + update stationary rings ──
	var stale: Array = []
	for d in dots:
		if not is_instance_valid(d.node):
			stale.append(d); continue

		var elapsed  : float = now - d.spawn_time
		var progress : float = elapsed / travel_time
		var dot_x    : float = lerpf(lane_w - 25.0, ring_x, progress)
		d.node.position.x = dot_x - 25.0

		# ── Stationary ring, parented to target_ring ──
		if is_instance_valid(d.ring_node):
			var ring_idx : int = leading_dots.find(d)
			if ring_idx < 0 or d.hit:
				# Not a leading dot — hide its ring
				d.ring_node.modulate.a = 0.0
			else:
				# ring_idx 0 = current (shrinks to 1×), ring_idx 1 = next (stays larger)
				var t_raw : float = clampf(
					(progress - RING_APPEAR_FROM) / (1.0 - RING_APPEAR_FROM), 0.0, 1.0)

				var ring_scale : float
				var ring_alpha : float
				var warmth     : float

				if ring_idx == 0:
					# Current: shrinks from RING_START_SCALE toward 1×
					ring_scale = lerpf(RING_START_SCALE, 1.0, t_raw)
					ring_alpha = clampf(t_raw * 4.0, 0.0, 1.0)
					warmth     = clampf((t_raw - 0.6) / 0.4, 0.0, 1.0)
				else:
					# Next: show at a fixed large scale as a preview ring
					# It starts appearing faintly, stays large until it becomes idx 0
					var next_progress : float = (now - d.spawn_time) / travel_time
					var appear_t : float = clampf(
						(next_progress - RING_APPEAR_FROM) / (1.0 - RING_APPEAR_FROM), 0.0, 1.0)
					ring_scale = lerpf(RING_START_SCALE, RING_START_SCALE * 0.7, appear_t)
					ring_alpha = clampf(appear_t * 2.0, 0.0, 0.45)
					warmth     = 0.0

				d.ring_node.scale    = Vector2(ring_scale, ring_scale)
				d.ring_node.modulate = Color(
					1.0,
					lerpf(1.0, 0.85, warmth),
					lerpf(1.0, 0.1,  warmth),
					ring_alpha
				)

		# ── Auto-miss ──
		if not d.hit and progress > 1.0 + window_ok / travel_time:
			_do_miss(d)
			stale.append(d)
		elif progress > 1.6:
			stale.append(d)

	for d in stale:
		dots.erase(d)
		if is_instance_valid(d.node):     d.node.queue_free()
		if is_instance_valid(d.ring_node): d.ring_node.queue_free()

	# ── Feedback fade ──
	if feedback_timer > 0.0:
		feedback_timer -= delta
		feedback_lbl.modulate.a = clampf(feedback_timer / 0.15, 0.0, 1.0)

	# ── Background shake ──
	if shake_timer > 0.0:
		shake_timer -= delta
		var t : float = shake_timer / 0.25
		var offset_x : float = sin(shake_timer * 55.0) * shake_strength * t
		var offset_y : float = abs(sin(shake_timer * 30.0)) * shake_strength * t * 0.6
		background.position = bg_origin + Vector2(offset_x, offset_y)
	else:
		background.position = bg_origin

	# ── Finished? ──
	if beats_spawned >= total_beats and dots.is_empty():
		_end(false)

func _input(event: InputEvent) -> void:
	if finished: return
	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = event.keycode in [KEY_SPACE, KEY_ENTER, KEY_Z, KEY_X]
	elif event is InputEventMouseButton and event.pressed:
		pressed = event.button_index == MOUSE_BUTTON_LEFT
	if pressed:
		if not active: start()
		else: _attempt_hit()

func _spawn_dot() -> void:
	beats_spawned += 1
	metronome.play()   # ← fires every beat_interval, already called on tempo
	# ... rest of spawn logic
	
	if beats_spawned >= total_beats:
		extra_ticks_remaining = 4
		

	# Dot — child of beat_container, travels left → right
	var dot := Panel.new()
	dot.size         = Vector2(120, 120)
	dot.position     = Vector2(lane.size.x - 50.0, 15)
	dot.pivot_offset = Vector2(25, 25)
	var sty := StyleBoxFlat.new()
	sty.bg_color = C_DOT
	sty.set_corner_radius_all(25)
	dot.add_theme_stylebox_override("panel", sty)
	beat_container.add_child(dot)

	# Ring — child of target_ring so it stays stationary at the hit zone
	var ring := Panel.new()
	ring.size         = Vector2(120, 120)
	ring.position     = Vector2.ZERO      # centred on target_ring's origin
	ring.pivot_offset = Vector2(25, 25)
	ring.scale        = Vector2(RING_START_SCALE, RING_START_SCALE)
	ring.modulate.a   = 0.0
	var ring_sty := StyleBoxFlat.new()
	ring_sty.bg_color            = Color(0, 0, 0, 0)
	ring_sty.border_color        = Color(1, 1, 1, 1)
	ring_sty.border_width_top    = 3
	ring_sty.border_width_bottom = 3
	ring_sty.border_width_left   = 3
	ring_sty.border_width_right  = 3
	ring_sty.set_corner_radius_all(25)
	ring.add_theme_stylebox_override("panel", ring_sty)
	target_ring.add_child(ring)   # <-- stationary, not parented to the dot

	dots.append({
		"node":       dot,
		"ring_node":  ring,
		"spawn_time": Time.get_ticks_msec() / 1000.0,
		"hit":        false
	})

func _attempt_hit() -> void:
	var now     : float      = Time.get_ticks_msec() / 1000.0
	var best    : Dictionary = {}
	var best_dt : float      = INF
	

	for d in dots:
		if d.hit: continue
		var dt : float = absf((now - d.spawn_time) / travel_time - 1.0) * travel_time
		if dt < best_dt and dt <= window_ok:
			best_dt = dt
			best = d

	if best.is_empty():
		_show_feedback("EARLY", C_MISS)
		_trigger_shake(5.0)
		return

	best.hit = true
	beats_hit += 1
	combo     += 1
	max_combo  = max(max_combo, combo)
	
	# Pitch-shift based on timing quality for extra feel
	if best_dt <= window_perfect:
		hit_sound.pitch_scale = 1.2
	elif best_dt <= window_good:
		hit_sound.pitch_scale = 1.0
	else:
		hit_sound.pitch_scale = 0.85

	hit_sound.play()

	if is_instance_valid(best.ring_node):
		best.ring_node.hide()

	var pts : int
	var lbl : String
	var col : Color
	if best_dt <= window_perfect:
		lbl = "PERFECT"; col = C_PERFECT; pts = 300
		_trigger_shake(16.0)
	elif best_dt <= window_good:
		lbl = "GOOD";    col = C_GOOD;    pts = 200
		_trigger_shake(10.0)
	else:
		lbl = "OK";      col = C_OK;      pts = 100
		_trigger_shake(5.0)

	score += pts * (1 + combo / 5)
	_show_feedback(lbl, col)

	if is_instance_valid(best.node):
		best.node.modulate = col
		var tw := create_tween()
		tw.tween_property(best.node, "modulate:a", 0.0, 0.3)

	progress_bar.value = beats_hit + misses
	_update_hud()

func _do_miss(d: Dictionary) -> void:
	d.hit  = true
	misses += 1
	combo  = 0
	score  = max(0, score - 50)
	_show_feedback("MISS", C_MISS)
	_trigger_shake(8.0)
	progress_bar.value = beats_hit + misses
	_update_hud()
	if misses >= max_misses:
		active = false
		await get_tree().create_timer(0.4).timeout
		_end(true)
	miss_sound.play()

func _trigger_shake(strength: float) -> void:
	shake_strength = strength
	shake_timer    = 0.25

func _end(failed: bool) -> void:
	active   = false
	finished = true
	for d in dots:
		if is_instance_valid(d.node):     d.node.queue_free()
		if is_instance_valid(d.ring_node): d.ring_node.queue_free()
	dots.clear()

	var grade := _grade()
	if failed:
		result_title.text = "PATIENT LOST"
		result_title.add_theme_color_override("font_color", C_MISS)
		cpr_failed.emit()
	else:
		result_title.text = "CPR COMPLETE"
		result_title.add_theme_color_override("font_color", C_GOOD)
		cpr_success.emit()

	result_grade.text = grade
	result_grade.add_theme_color_override("font_color", _grade_color(grade))
	result_stats.text = "Score: %d   Best Combo: ×%d   Hits: %d/%d" \
		% [score, max_combo, beats_hit, total_beats]
	result_panel.show()
	cpr_completed.emit(score, grade)

func _show_feedback(text: String, color: Color) -> void:
	feedback_lbl.text = text
	feedback_lbl.add_theme_color_override("font_color", color)
	feedback_lbl.modulate.a = 1.0
	feedback_timer = 0.55

func _update_hud() -> void:
	score_lbl.text = "Score  %d" % score
	combo_lbl.text = "×%d" % combo
	var h := ""
	for i in max_misses: h += ("♥ " if i >= misses else "✕ ")
	lives_lbl.text = h.strip_edges()

func _grade() -> String:
	var r : float = float(beats_hit) / float(total_beats)
	if r >= 0.95 and misses == 0: return "S"
	if r >= 0.90: return "A"
	if r >= 0.75: return "B"
	if r >= 0.60: return "C"
	return "F"

func _grade_color(g: String) -> Color:
	match g:
		"S": return Color(1.0, 0.92, 0.2)
		"A": return Color(0.4, 0.9, 0.4)
		"B": return Color(0.4, 0.7, 1.0)
		"C": return Color(1.0, 0.65, 0.2)
	return C_MISS

func _on_retry()    -> void: start()
func _on_continue() -> void: cpr_completed.emit(score, _grade())
