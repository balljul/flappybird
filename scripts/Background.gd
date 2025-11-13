extends Node2D

var sky_speed = 100
var ground_speed = 100
var stopped = false
var screen_size

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	sky_speed = screen_size.x * 0.04
	ground_speed = screen_size.x * 0.08

	var ground_collision = $GroundCollision/CollisionShape2D
	ground_collision.position = Vector2(screen_size.x * 0.5, screen_size.y + 50)
	print("Ground collision positioned at: ", ground_collision.position, " (screen height: ", screen_size.y, ")")

	create_sky_sprites()
	create_ground_sprites()

func create_sky_sprites():
	var sky_texture = load("res://assets/sprites/background-day.png")
	var sky_width = 288
	var sky_height = 512

	var screen_width = screen_size.x + 600
	var screen_height = screen_size.y + 400

	var sprites_needed_x = int(screen_width / sky_width) + 3
	var sprites_needed_y = int(screen_height / sky_height) + 3

	for x in sprites_needed_x:
		for y in sprites_needed_y:
			var sky = Sprite2D.new()
			sky.texture = sky_texture
			sky.position = Vector2(x * sky_width - 144, y * sky_height - 256)
			sky.name = "Sky" + str(x) + "_" + str(y)
			add_child(sky)

func create_ground_sprites():
	var ground_texture = load("res://assets/sprites/base.png")
	var ground_width = 336

	var screen_width = screen_size.x + 600
	var sprites_needed = int(screen_width / ground_width) + 3

	for i in sprites_needed:
		var ground = Sprite2D.new()
		ground.texture = ground_texture
		ground.position = Vector2((i * ground_width) - ground_width, screen_size.y - 34)
		ground.name = "Ground" + str(i)
		add_child(ground)

func _physics_process(delta):
	if stopped:
		return

	for child in get_children():
		if child.name.begins_with("Sky"):
			child.position.x -= sky_speed * delta
			if child.position.x <= -288:
				child.position.x += 288 * 8

	for child in get_children():
		if child.name.begins_with("Ground"):
			child.position.x -= ground_speed * delta
			if child.position.x <= -336:
				child.position.x += 336 * 5

func stop():
	stopped = true
