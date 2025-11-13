extends RigidBody2D

@export var jump_force = -350
var wing_sound = preload("res://assets/audio/wing.ogg")
var screen_size

signal died

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	print("Bird screen size: ", screen_size)
	jump_force = -screen_size.y * 0.32
	gravity_scale = 0.8
	contact_monitor = true
	max_contacts_reported = 10
	body_entered.connect(_on_body_entered)

	apply_bird_color()

	linear_velocity = Vector2.ZERO

func apply_bird_color():
	var sprite = $AnimatedSprite2D
	sprite.modulate = GameData.selected_bird_color

func jump():
	linear_velocity.y = jump_force
	$AudioStreamPlayer2D.stream = wing_sound
	$AudioStreamPlayer2D.play()

func _on_body_entered(body):
	print("Bird collided with: ", body.name)
	died.emit()

func _physics_process(delta):
	var bottom_bound = screen_size.y * 0.9
	var top_bound = screen_size.y * 0.05

	if position.y > bottom_bound or position.y < top_bound:
		print("Bird died at position: ", position.y, " screen bounds: ", top_bound, " to ", bottom_bound, " (screen height: ", screen_size.y, ")")
		died.emit()
