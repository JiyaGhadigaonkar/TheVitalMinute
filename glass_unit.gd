extends TextureButton

var is_interactive = false

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _on_mouse_entered():
	print("Mouse entered glass, is_interactive: ", is_interactive)
	if is_interactive:
		Input.set_custom_mouse_cursor(load("res://Assets/cursors/resized_cursor_object.png"), Input.CURSOR_ARROW, Vector2(8, 0))

func _on_mouse_exited():
	Input.set_custom_mouse_cursor(load("res://Assets/cursors/resized_cursor_default.png"), Input.CURSOR_ARROW, Vector2(8, 0))

func _on_pressed():
	print("Glass pressed, is_interactive: ", is_interactive)
	if is_interactive:
		get_parent().on_glass_clicked()
	else:
		# Visual debug - change glass color to confirm click is registering
		modulate = Color.RED
