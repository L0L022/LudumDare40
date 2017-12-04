extends Control

var money = 0
var mood = 0
var game_finished = false

var text_intro = ""
var stage_win_money = 0
var stage_lose_money = 0
var text_end_win = ""
var text_end_lose = ""
var final_question = ""

var start_time = OS.get_unix_time()

var questions = []
var questions_id = {}
var questions_random = []
var questions_pending = []
var available_questions = []

onready var timer_next_question = get_node("next_question")

onready var money_l = get_node("MarginContainer/VBoxContainer/header/money")
onready var mood_l = get_node("MarginContainer/VBoxContainer/header/mood")

onready var q_dialog = get_node("dialog")
onready var q_illustration = get_node("dialog/question/illustration")
onready var q_description = get_node("dialog/question/description")
onready var q_comment = get_node("dialog/question/description")
onready var q_answers = get_node("dialog/question/answers")

onready var b_anim = get_node("Background/anim")

var my_button = preload("../control/Button.tscn")

func error(message):
	print(message)

func get_v(key, t):
	if not t.has(key):
		error("Miss: "+key)
	else:
		return t[key]

func load_data():
	var file = File.new()
	file.open("user://data.json", file.READ)
	if not file.is_open():
		file.open("/data.json", file.READ)
	if not file.is_open():
		file.open("res://data_FR.json", file.READ)
	var text = file.get_as_text()
	var data = {}
	data.parse_json(text)
	money = get_v("money", data)
	mood = get_v("mood", data)
	stage_win_money = get_v("win_money", data)
	stage_lose_money = get_v("lose_money", data)
	text_intro = get_v("intro", data)
	text_end_win = get_v("end_win", data)
	text_end_lose = get_v("end_lose", data)
	final_question = get_v("final_question", data)
	questions = get_v("questions", data)
	file.close()
	
	for i in range(questions.size()):
		var q = questions[i]
		for k in ["id", "description", "illustration"]:
			if not q.has(k):
				q[k] = ""
				print("Miss key ", k, " in the question n°", i)
		for k in ["availableTime", "preparationTime"]:
			if not q.has(k):
				q[k] = 0
				print("Miss key ", k, " in the question n°", i)
		if not q.has("random"):
			q["random"] = false
			print("Miss key ", "random", " in the question n°", i)
		if not q.has("answers"):
			q["answers"] = []
			print("Miss key ", "answers", " in the question n°", i)
		else:
			for a in q["answers"]:
				for k in ["label", "question", "comment"]:
					if not a.has(k):
						a[k] = ""
						print("Miss key ", k, " in the question n°", i)
				for k in ["money", "mood"]:
					if not a.has(k):
						a[k] = 0
						print("Miss key ", k, " in the question n°", i)

		if q["id"] != "":
			questions_id[q["id"]] = i
		if q["random"]:
			questions_random.append(i)
	
	available_questions = questions_random

func start_timer_next_question():
	var wait_time = 5 # utiliser une var. al. entre deux nombres
	timer_next_question.set_wait_time(wait_time)
	timer_next_question.start() # utile ?

func hide_all():
	q_dialog.hide()
	q_illustration.hide()
	q_description.hide()
	q_comment.hide()
	q_answers.hide()

func clear_answers():
	while(q_answers.get_child_count() != 0):
		q_answers.remove_child(q_answers.get_child(0))

func disp_question(q):
	hide_all()
	q_description.set_text(q["description"])
	#q_illustration
	clear_answers()
	for a in q["answers"]:
		var b = my_button.instance()
		b.set_text(a["label"])
		b.connect("pressed", self, "answer_question", [q, a])
		q_answers.add_child(b)
	
	q_dialog.show()
	q_description.show()
	q_illustration.show()
	q_answers.show()

func disp_comment(a):
	hide_all()
	q_comment.set_text(a["comment"])
	clear_answers()
	var b = my_button.instance()
	b.set_text("Close")
	b.connect("pressed", self, "close_comment")
	q_answers.add_child(b)
	q_dialog.show()
	q_comment.show()
	q_answers.show()

func close_comment():
	hide_all()
	start_timer_next_question()

func disp_message(message):
	disp_comment({ "comment": message })

func disp_intro():
	#utiliser pending question
	disp_message(text_intro)

func update_gui():
	money_l.set_text(String(money))
	mood_l.set_text(String(mood))

func add_pending_question(q):
	if q["preparationTime"] == 0:
		print("Add pending question : ", q)
		questions_pending.append(q)
	else:
		print("New pending question : ", q)
		var t = Timer.new()
		add_child(t)
		t.set_one_shot(true)
		t.set_wait_time(q["preparationTime"])
		t.connect("timeout", self, "preparation_timeout", [q, t])
		t.start()

func preparation_timeout(q, t):
	questions_pending.append(q)
	remove_child(t)
	print("Question timeout : ", q)

func answer_question(q, a):
	money += a["money"]
	mood += a["mood"]
	if questions_id.has(a["question"]):
		add_pending_question(questions[questions_id[a["question"]]])
	
	hide_all()
	update_gui()
	if a["comment"] != "":
		disp_comment(a)
	else:
		start_timer_next_question()

func get_rand_question():
	var q = {}
	if not available_questions.empty():
		var i_q = -1
		while not q.has("availableTime") or q["availableTime"] > OS.get_unix_time() - start_time:
			i_q = randi() % available_questions.size()
			q = questions[available_questions[i_q]]
		available_questions.remove(i_q)
	return q

func get_pending_question():
	var q = {}
	if not questions_pending.empty():
		q = questions_pending[0]
		questions_pending.pop_front()
	return q

func show_question():
	var q = get_rand_question() if questions_pending.empty() else get_pending_question()
	print("Disp question : ", q)
	disp_question(q)

func check_game_state():
	if not game_finished:
		if available_questions.empty() and questions_pending.empty():
			if questions_id.has(final_question):
				add_pending_question(questions[questions_id[final_question]])
				final_question = ""
		
		if money <= stage_win_money:
			game_finished = true
			disp_message(text_end_win)
		elif money >= stage_lose_money:
			game_finished = true
			disp_message(text_end_lose)

func _ready():
	b_anim.set_speed(0.05)
	b_anim.play("life")
	
	load_data()
	update_gui()
	disp_intro()

func _on_next_question_timeout():
	show_question()
