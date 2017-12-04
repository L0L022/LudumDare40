extends Control

onready var b_anim = get_node("Background/anim")

func _ready():
	b_anim.set_speed(0.3)
	b_anim.queue("night")
	b_anim.queue("loading_screen")

func _on_next_timeout():
	get_tree().change_scene("res://scenes/welcome.tscn")
