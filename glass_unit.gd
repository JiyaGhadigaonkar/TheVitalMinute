extends TextureButton

var is_interactive = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP 
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _on_mouse_entered():
	if is_interactive:
		var img = Image.new()
		img.load("res://Assets/cursors/resized_cursor_object.png")
		Input.set_custom_mouse_cursor(img, Input.CURSOR_ARROW, Vector2(8, 0))

func _on_mouse_exited():
	var img = Image.new()
	img.load("res://Assets/cursors/resized_cursor_default.png")
	Input.set_custom_mouse_cursor(img, Input.CURSOR_ARROW, Vector2(8, 0))

func _on_pressed():
	if is_interactive:
		get_parent().on_glass_clicked()
