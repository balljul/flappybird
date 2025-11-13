extends StaticBody2D

var speed = 150
var moving = true
var screen_size

@onready var score_area = $ScoreArea

signal scored

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	
	# Scale speed based on screen width
	speed = screen_size.x * 0.13  # Speed relative to screen width
	
	score_area.body_entered.connect(_on_score_area_body_entered)
	
	# Get screen height and adjust pipe range dynamically
	var max_variation = screen_size.y * 0.15  # 15% of screen height variation
	var gap_y = randf_range(-max_variation, max_variation)
	var gap_size = screen_size.y * 0.35  # Gap size is 35% of screen height
	
	$PipeTop.position.y = gap_y - gap_size
	$PipeBottom.position.y = gap_y + gap_size
	$CollisionTop.position.y = gap_y - gap_size
	$CollisionBottom.position.y = gap_y + gap_size
	$ScoreArea/ScoreShape.position.y = gap_y

func _physics_process(delta):
	if moving:
		position.x -= speed * delta
		if position.x < -screen_size.x * 0.1:  # Delete when off screen dynamically
			queue_free()

func _on_score_area_body_entered(body):
	if body.name == "Bird":
		scored.emit()
		score_area.monitoring = false

func stop():
	moving = false