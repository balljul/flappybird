extends Node2D

var pipe_scene = preload("res://scenes/Pipe.tscn")
var score = 0
var game_over = false
var game_paused = false

@onready var bird = $Bird
@onready var score_label = $UI/ScoreLabel
@onready var game_over_ui = $UI/GameOverUI
@onready var pause_ui = $UI/PauseUI
@onready var pause_score_display = $UI/PauseUI/PausePanel/VBoxContainer/ScoreDisplay
@onready var resume_button = $UI/PauseUI/PausePanel/VBoxContainer/ResumeButton
@onready var restart_button = $UI/PauseUI/PausePanel/VBoxContainer/RestartButton
@onready var home_button = $UI/PauseUI/PausePanel/VBoxContainer/HomeButton
@onready var pipe_timer = $PipeTimer
@onready var background = $Background

var screen_size

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	screen_size = get_viewport().get_visible_rect().size
	print("Game screen size: ", screen_size)

	bird.position = Vector2(screen_size.x * 0.2, screen_size.y * 0.5)
	print("Bird positioned at: ", bird.position)

	bird.died.connect(_on_bird_died)
	pipe_timer.timeout.connect(_spawn_pipe)

	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	home_button.pressed.connect(_on_home_pressed)

	pause_ui.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	start_game()

	print("Game started automatically")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not game_over:
			toggle_pause()
		return

	if not game_over and not game_paused:
		if Input.is_action_just_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
			bird.jump()

	elif game_over:
		if Input.is_action_just_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
			return_to_home()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
			restart_game()

func start_game():
	pipe_timer.start()
	game_over = false
	print("Game starting with pipes...")

func restart_game():
	get_tree().reload_current_scene()

func return_to_home():
	print("Returning to home screen...")
	get_tree().change_scene_to_file("res://scenes/HomeScreen.tscn")

func _spawn_pipe():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + 50
	pipe.position.y = screen_size.y * 0.5
	pipe.scored.connect(_on_pipe_scored)
	add_child(pipe)

func _on_pipe_scored():
	score += 1
	score_label.text = str(score)

func toggle_pause():
	game_paused = !game_paused

	if game_paused:
		pause_game()
	else:
		resume_game()

func pause_game():
	print("Game paused")
	get_tree().paused = true
	pause_ui.show()
	pause_score_display.text = "Score: " + str(score)

func resume_game():
	print("Game resumed")
	get_tree().paused = false
	pause_ui.hide()

func _on_resume_pressed():
	toggle_pause()

func _on_restart_pressed():
	resume_game()
	restart_game()

func _on_home_pressed():
	resume_game()
	return_to_home()

func _on_bird_died():
	if score > GameData.high_score:
		GameData.high_score = score
		GameData.save_game_data()

	game_over = true
	pipe_timer.stop()
	background.stop()
	for pipe in get_children():
		if pipe.has_method("stop"):
			pipe.stop()
	game_over_ui.show()
