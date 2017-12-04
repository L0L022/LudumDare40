extends Control

onready var b_anim = get_node("Background/anim")

func _ready():
#	b_anim.set_speed(0.3)
#	b_anim.queue("day")
	b_anim.queue("start_button")

func _on_startButton_pressed():
	get_tree().change_scene("res://scenes/game.tscn")
