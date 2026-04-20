extends Control
@onready var background = $Background
@onready var portrait = $Portrait
@onready var speaker_name = $SpeakerName
@onready var dialogue_text = $DialogueText
@onready var choice_container = $ChoiceContainer
var arcweave_asset: ArcweaveAsset = preload("res://addons/arcweave/TutorialStory.tres")
var Story = load("res://addons/arcweave/Story.cs")
var story
var project_data: Dictionary

func _ready():
	project_data = arcweave_asset.project_settings
	story = Story.new(project_data)
	repaint()

func get_component_name_for_element() -> String:
	var element = story.GetCurrentElement()
	var element_id = element.Id
	var elements = project_data.get("elements", {})
	if elements.has(element_id):
		var el_data = elements[element_id]
		var component_id = el_data.get("components", [])
		if component_id.size() > 0:
			var components = project_data.get("components", {})
			if components.has(component_id[0]):
				return components[component_id[0]].get("name", "")
	return ""

func repaint():
	dialogue_text.text = story.GetCurrentRuntimeContent()
	dialogue_text.add_theme_color_override("font_color", Color.WHITE)
	
	var comp_name = get_component_name_for_element()
	
	if comp_name != "" and comp_name != "Decoy":
		speaker_name.text = clean_name(comp_name)
		var portrait_path = "res://Assets/portraits/" + comp_name + ".png"
		if ResourceLoader.exists(portrait_path):
			portrait.texture = load(portrait_path)
		else:
			portrait.texture = null
	else:
		speaker_name.text = ""
		portrait.texture = null
	
	add_options()

func add_options():
	for option in choice_container.get_children():
		choice_container.remove_child(option)
		option.queue_free()
	
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	
	if paths == null or paths.size() == 0:
		var button = Button.new()
		button.text = "Continue"
		button.pressed.connect(_on_continue_pressed)
		choice_container.add_child(button)
	else:
		for i in range(paths.size()):
			if paths[i].IsValid:
				var button = Button.new()
				button.text = paths[i].label
				button.pressed.connect(_on_option_pressed.bind(i, paths))
				choice_container.add_child(button)


func _on_option_pressed(index, paths):
	story.SelectPath(paths[index])
	repaint()

func _on_continue_pressed():
	var options = story.GenerateCurrentOptions()
	var paths = options.Paths
	if paths != null and paths.size() > 0:
		story.SelectPath(paths[0])
		repaint()

func clean_name(raw_name: String) -> String:
	if "_" in raw_name:
		return raw_name.split("_")[0]
	return raw_name
