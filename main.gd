extends Control

@onready var jupiter: CharacterBody2D = $Jupiter
@onready var left_paddle: AnimatableBody2D = $LeftPaddle
@onready var right_paddle: AnimatableBody2D = $RightPaddle
@onready var left_score: Label = $MarginContainer/HBoxContainer/LeftScore
@onready var right_score: Label = $MarginContainer/HBoxContainer/RightScore

const ROTATION_RANGE = 1
const PADDLE_SPEED = 400
const JUPITER_SPEED_INCREMENT: float = 215.0 / 200
const MAX_PERTURB_ANGLE: float = PI / 4
var jupiter_speed: float
var jupiter_direction: Vector2
var rotation_velocity: float
var next_speed_boost: Node2D

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
	jupiter_direction = Vector2(1, 0)
	next_speed_boost = right_paddle
	#if r == 0:
		#jupiter_direction = Vector2(1, 0)
		#next_speed_boost = right_paddle
	#else:
		#jupiter_direction = Vector2(-1, 0)
		#next_speed_boost = left_paddle

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
			var perturb: float = 0
			if collider == left_paddle:
				var raw_offset = (left_paddle.global_position - collision.get_position()).y
				var paddle_height = left_paddle.get_node("CollisionShape2D").shape.get_rect().size.y / 2
				var normalized_offset = raw_offset / paddle_height
				perturb = -normalized_offset * MAX_PERTURB_ANGLE
			if collider == right_paddle:
				var raw_offset = (right_paddle.global_position - collision.get_position()).y
				var paddle_height = right_paddle.get_node("CollisionShape2D").shape.get_rect().size.y / 2
				var normalized_offset = raw_offset / paddle_height
				perturb = normalized_offset * MAX_PERTURB_ANGLE
			jupiter_direction = jupiter_direction.bounce(collision.get_normal())
			jupiter_direction = jupiter_direction.rotated(perturb)
			if collider == left_paddle:
				jupiter_direction = clamp_vector2_to_angle_range(jupiter_direction, -PI / 4, PI / 4)
			if collider == right_paddle:
				jupiter_direction = clamp_vector2_to_angle_range(jupiter_direction, 3 * PI / 4, -3 * PI / 4)
			_randomize_rotation()
			if collider == left_paddle and next_speed_boost == left_paddle:
				jupiter_speed *= JUPITER_SPEED_INCREMENT
				next_speed_boost = right_paddle
			if collider == right_paddle and next_speed_boost == right_paddle:
				jupiter_speed *= JUPITER_SPEED_INCREMENT
				next_speed_boost = left_paddle
				
	if jupiter.position.y > get_viewport_rect().size.y or jupiter.position.y < 0:
		_reset_jupiter()

func clamp_vector2_to_angle_range(vector: Vector2, min_angle: float, max_angle: float) -> Vector2:
	# Normalize the angles to ensure the range is valid
	min_angle = wrapf(min_angle, -PI, PI)
	max_angle = wrapf(max_angle, -PI, PI)
	
	# Handle cases where the range crosses the -PI to PI boundary
	var angle = vector.angle()
	if min_angle > max_angle:
		# The range spans the boundary; check both segments
		if angle < min_angle and angle > max_angle:
			# Determine which side of the range to clamp to
			var dist_to_min = abs(angle - min_angle)
			var dist_to_max = abs(angle - max_angle)
			if dist_to_min < dist_to_max:
				angle = min_angle
			else:
				angle = max_angle
	else:
		# Normal case; just clamp within the range
		angle = clamp(angle, min_angle, max_angle)
	
	# Reconstruct the vector with clamped angle and original length
	return Vector2(vector.length(), 0).rotated(angle)
