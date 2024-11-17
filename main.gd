extends Control

@onready var jupiter: CharacterBody2D = $Jupiter
@onready var left_paddle: AnimatableBody2D = $LeftPaddle
@onready var right_paddle: AnimatableBody2D = $RightPaddle
@onready var left_score: Label = $MarginContainer/HBoxContainer/LeftScore
@onready var right_score: Label = $MarginContainer/HBoxContainer/RightScore

const ROTATION_RANGE = 1
const PADDLE_SPEED = 400
const JUPITER_SPEED_INCREMENT: float = 215.0 / 200
var jupiter_speed: float
var jupiter_direction: Vector2
var rotation_velocity: float

var score_left: int = 0
var score_right: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	left_paddle.position = Vector2(get_viewport_rect().size.x * 1/8, get_viewport_rect().get_center().y)
	right_paddle.position = Vector2(get_viewport_rect().size.x * 7/8, get_viewport_rect().get_center().y)
	_reset_jupiter()
	_randomize_rotation()

func _reset_jupiter() -> void:
	jupiter.position = get_viewport_rect().get_center()
	var r: int = randi_range(0, 1)
	jupiter_speed = 200
	if r == 0:
		jupiter_direction = Vector2(1, -1)
	else:
		jupiter_direction = Vector2(-1, -1)

func _randomize_rotation() -> void:
	rotation_velocity = randf_range(-ROTATION_RANGE, ROTATION_RANGE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	jupiter.rotation += delta * rotation_velocity
	
	if Input.is_key_pressed(KEY_W):
		left_paddle.move_and_collide(delta * PADDLE_SPEED * Vector2(0, -1))
	if Input.is_key_pressed(KEY_S):
		left_paddle.move_and_collide(delta * PADDLE_SPEED * Vector2(0, 1))
	
	if Input.is_key_pressed(KEY_UP):
		right_paddle.move_and_collide(delta * PADDLE_SPEED * Vector2(0, -1))
	if Input.is_key_pressed(KEY_DOWN):
		right_paddle.move_and_collide(delta * PADDLE_SPEED * Vector2(0, 1))
	
	var collision = jupiter.move_and_collide(delta * jupiter_speed * jupiter_direction)
	if collision:
		var collider = collision.get_collider()
		if collider is EndZone:
			if collider.side == EndZone.Player.LEFT:
				score_right += 1
				right_score.text = str(score_right)
			if collider.side == EndZone.Player.RIGHT:
				score_left += 1
				left_score.text = str(score_left)
			_reset_jupiter()
		else:
			jupiter_direction = jupiter_direction.bounce(collision.get_normal())
			_randomize_rotation()
			if collider is Paddle:
				jupiter_speed *= JUPITER_SPEED_INCREMENT
				
	if jupiter.position.y > get_viewport_rect().size.y or jupiter.position.y < 0:
		_reset_jupiter()
