extends TextureButton

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _on_mouse_entered():
	if not disabled:
		Input.set_custom_mouse_cursor(load("res://Assets/cursors/curser_object.png"), Input.CURSOR_ARROW, Vector2(8, 0))

func _on_mouse_exited():
	Input.set_custom_mouse_cursor(load("res://Assets/cursors/resized_cursor_default.png"), Input.CURSOR_ARROW, Vector2(8, 0))

func _on_pressed():
	get_parent().on_glass_clicked()
