extends Control

enum STATE {IDLE, BUSY}
var state = STATE.IDLE

var money = 0
var mood = 0

var questions = []
var questions_id = {}
var questions_random = []
var questions_pending = []
var available_questions = []

var rand_question = {}
onready var timer_rand_question = get_node("timer_rand_question")

onready var money_l = get_node("header/money")
onready var mood_l = get_node("header/mood")

onready var q_illustration = get_node("center/question/illustration")
onready var q_description = get_node("center/question/description")
onready var q_comment = get_node("center/question/description")
onready var q_answers = get_node("center/question/answers")

func load_questions():
	var file = File.new()
	file.open("res://data.json", file.READ)
	var text = file.get_as_text()
	var data = {}
	data.parse_json(text)
	questions = data["questions"]
	file.close()
	
	for i in range(questions.size()):
		var q = questions[i]
		if q["id"] != "": 
			questions_id[q["id"]] = i
		if q.has("random") and q["random"]:
			questions_random.append(i)
	
	available_questions = questions_random

func hide_all():
	q_illustration.hide()
	q_description.hide()
	q_comment.hide()
	q_answers.hide()

func clear_answers():
	while(q_answers.get_child_count() != 0):
		q_answers.remove_child(q_answers.get_child(0))

func disp_question(q):
	state = STATE.BUSY
	hide_all()
	q_description.set_text(q["description"])
	#q_illustration
	clear_answers()
	for a in q["answers"]:
		var b = Button.new()
		b.set_text(a["label"])
		b.connect("pressed", self, "answer_question", [q, a])
		q_answers.add_child(b)
	
	q_description.show()
	q_illustration.show()
	q_answers.show()

func disp_pending_questions():
	if state == STATE.IDLE and not questions_pending.empty():
		var q = questions_pending[0]
		questions_pending.pop_front()
		disp_question(q)

func do_nothing():
	state = STATE.IDLE
	disp_pending_questions()

func disp_comment(a):
	if a["comment"] == "":
		return
	state = STATE.BUSY
	hide_all()
	q_comment.set_text(a["comment"])
	clear_answers()
	var b = Button.new()
	b.set_text("Close")
	b.connect("pressed", self, "close_comment")
	q_answers.add_child(b)
	q_comment.show()
	q_answers.show()

func close_comment():
	hide_all()
	do_nothing()

func disp_intro():
	# regarder si on affiche toujours le contexte
	disp_comment({ "comment": "Il était une fois un homme complètement fou !" })

func update_gui():
	money_l.set_text(String(money))
	mood_l.set_text(String(mood))

func add_question(q):
	if not q.has("preparationTime") or q["preparationTime"] == 0:
		questions_pending.append(q)
	else:
		var t = Timer.new()
		add_child(t)
		t.set_wait_time(q["preparationTime"])
		t.set_one_shot(true)
		t.connect("timeout", self, "preparation_timeout", [q, t])
	#disp_pending_questions()

func preparation_timeout(q, t):
	questions_pending.append(q)
	remove_child(t)

func answer_question(q, a):
	if a.has("money"):
		money += a["money"]
	if a.has("mood"):
		mood += a["mood"]
	update_gui()
	disp_comment(a)

	if a.has("question") and questions_id.has(a["question"]):
		add_question(questions[questions_id[a["question"]]])
	
	do_nothing()

func set_timer_rand_question():
	var wait_time = 5 # utiliser une var. al. entre deux nombres
	timer_rand_question.set_wait_time(wait_time)
	timer_rand_question.start() # utile ?

func set_rand_question():
	if available_questions.empty():
		return
	var i_q = randi() % available_questions.size()
	rand_question = questions[available_questions[i_q]]
	available_questions.remove(i_q)
	set_timer_rand_question()

func try_rand_question():
	if state != STATE.IDLE:
		set_timer_rand_question()
	else:
		disp_question(rand_question)
		rand_question = {}
		set_rand_question()

func _ready():
	load_questions()
	disp_intro()
	set_rand_question()

func _on_timer_rand_question_timeout():
	try_rand_question()
