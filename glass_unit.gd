extends TextureButton

const HOVER_TINT = Color(1.0, 0.95, 0.8, 1.0)
const DEFAULT_TINT = Color(1.0, 1.0, 1.0, 1.0)

var is_interactive := false:
	set(value):
		if is_interactive == value:
			return
		is_interactive = value
		mouse_filter = Control.MOUSE_FILTER_STOP if is_interactive else Control.MOUSE_FILTER_IGNORE
		if not is_interactive:
			modulate = DEFAULT_TINT
			_set_default_cursor()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)
	modulate = DEFAULT_TINT
	_set_default_cursor()

func _on_mouse_entered():
	if is_interactive:
		modulate = HOVER_TINT
		get_parent().get_parent().set_object_cursor()

func _on_mouse_exited():
	modulate = DEFAULT_TINT
	_set_default_cursor()

func _on_pressed():
	if is_interactive:
		get_parent().get_parent().on_glass_clicked()

func _has_point(point: Vector2) -> bool:
	var hit_rect = Rect2(Vector2(-18, -18), size + Vector2(36, 36))
	return hit_rect.has_point(point)

func _set_default_cursor():
	get_parent().get_parent().set_default_cursor()
