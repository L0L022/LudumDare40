extends Control

export(String, MULTILINE) var text setget set_text

onready var button = get_node("Button")
onready var label = get_node("Label")

signal pressed

func update():
	if text != null and label != null:
		label.set_text(text)
		set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing"))*label.get_line_count()))

func set_text(t):
	text = t
	update()

func _ready():
	button.connect("pressed", self, "emit_signal", ["pressed"])
	update()
