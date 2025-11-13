extends Control

var shop_scene = preload("res://scenes/Shop.tscn")
var game_scene = preload("res://scenes/Main.tscn")

@onready var start_button = $UI/CenterContainer/VBoxContainer/StartButton
@onready var shop_button = $UI/CenterContainer/VBoxContainer/ShopButton
@onready var high_score_label = $UI/CenterContainer/VBoxContainer/HighScoreLabel
@onready var game_title = $UI/CenterContainer/VBoxContainer/GameTitle

func _ready():
	# Connect buttons
	start_button.pressed.connect(_on_start_game)
	shop_button.pressed.connect(_on_open_shop)
	
	# Update high score display
	update_high_score_display()
	
	# Style the title
	style_title()
	
	print("Home screen ready")

func update_high_score_display():
	if GameData.high_score > 0:
		high_score_label.text = "Best Score: " + str(GameData.high_score)
	else:
		high_score_label.text = "Best Score: 0"

func style_title():
	# Make the title larger and more prominent
	game_title.add_theme_font_size_override("font_size", 48)

func _on_start_game():
	print("Starting game...")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_open_shop():
	print("Opening shop...")
	var shop = shop_scene.instantiate()
	add_child(shop)
	shop.shop_closed.connect(_on_shop_closed)
	
	# Hide menu buttons while in shop
	$UI/CenterContainer.hide()

func _on_shop_closed():
	print("Shop closed, returning to home screen")
	$UI/CenterContainer.show()
	# Refresh high score in case it changed
	update_high_score_display()

func _input(event):
	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER, KEY_SPACE:
				_on_start_game()
			KEY_S:
				_on_open_shop()
			KEY_ESCAPE:
				get_tree().quit()