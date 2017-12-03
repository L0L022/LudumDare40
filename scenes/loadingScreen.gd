extends Control

onready var blink = get_node("blink")

func _ready():
	blink.play("blink")

func _on_next_timeout():
	get_tree().change_scene("res://scenes/welcome.tscn")
