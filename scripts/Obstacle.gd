extends Node2D

onready var upper_line = $Up
onready var bottom_line = $Down

onready var upper_collision = $Area2D/Upper
onready var bottom_collision = $Area2D/Lower
onready var barrier = $Barrier
onready var barrier_collision_shape = $Barrier/BarrierCollision/BarrierCollisionShape
onready var explosion = $Explosion

var initial_x : float

var initial_upper_y : float
var initial_lower_y : float

var max_upper_movement : float
var max_lower_movement : float
var max_joint_movement : float

var minimal_gap : int = 100

var type : int
var speed : float
var gap : float
var barrier_size : float


enum Types {
	UPPER,
	LOWER,
	BOTH,
	MIDDLE
}

var tick : float = 0

func initialize(_type, _x, _upper_y, _lower_y, difficulty):
	initial_x = _x
	type = _type
	gap = abs(_lower_y - _upper_y)
	var longest_spike = gap - minimal_gap
	
	if type == Types.UPPER:
		position = Vector2(initial_x, _upper_y)
		upper_line.add_point(Vector2(0, -25))
		upper_line.add_point(Vector2(0, rand_range(min(gap * 0.65, longest_spike), longest_spike)))
		upper_collision.disabled = false
		upper_collision.position = Vector2(0, upper_line.points[1].y * 0.5)
		upper_collision.shape.extents.y = upper_line.points[1].y * 0.45
		initial_upper_y = upper_line.points[1].y
		max_upper_movement = max(gap - upper_line.points[1].y - minimal_gap, 0)
		if randf() < min(0.025 + difficulty * 0.015, 0.25):
			create_barrier(upper_line.points[1].y, gap)
			
	elif type == Types.LOWER:
		position = Vector2(initial_x, _lower_y)
		bottom_line.add_point(Vector2(0, 25))
		bottom_line.add_point(Vector2(0, -rand_range(min(gap * 0.65, longest_spike), longest_spike)))
		bottom_collision.disabled = false
		bottom_collision.position = Vector2(0, bottom_line.points[1].y * 0.5)
		bottom_collision.shape.extents.y = bottom_line.points[1].y * 0.45

		initial_lower_y = bottom_line.points[1].y
		max_lower_movement = max(gap + bottom_line.points[1].y - minimal_gap, 0)
		if randf() < min(0.025 + difficulty * 0.015, 0.25):
			create_barrier(-gap, bottom_line.points[1].y)
			
	elif type == Types.BOTH:
		position = Vector2(initial_x, _upper_y)
		upper_line.add_point(Vector2(0, -25))
		upper_line.add_point(Vector2(0, rand_range(0, longest_spike * 0.5)))
		bottom_line.add_point(Vector2(0, gap + 25))
		bottom_line.add_point(Vector2(0, upper_line.points[1].y + rand_range(minimal_gap, 2 * minimal_gap)))
		upper_collision.disabled = false
		bottom_collision.disabled = false
		upper_collision.position = Vector2(0, upper_line.points[1].y * 0.5)
		bottom_collision.position = Vector2(0, gap - (gap - bottom_line.points[1].y) * 0.5)
		upper_collision.shape.extents.y = upper_line.points[1].y * 0.5
		bottom_collision.shape.extents.y = (gap - bottom_line.points[1].y) * 0.45
		initial_upper_y = upper_line.points[1].y
		initial_lower_y = bottom_line.points[1].y
		max_joint_movement = min(min(upper_line.points[1].y - upper_line.points[0].y, minimal_gap), min(bottom_line.points[0].y - bottom_line.points[1].y, minimal_gap))
		if randf() < min(0.025 + difficulty * 0.015, 0.25):
			create_barrier(initial_upper_y, initial_lower_y)
			
	else:
		position = Vector2(initial_x, _upper_y + gap * 0.5)
		longest_spike = gap * 0.6 - minimal_gap
		upper_line.add_point(Vector2(0, 0))
		bottom_line.add_point(Vector2(0, 0))
		bottom_line.add_point(Vector2(0, rand_range(longest_spike * 0.5, longest_spike)))
		upper_line.add_point(Vector2(0, rand_range(-longest_spike * 0.5, -longest_spike)))
		upper_collision.disabled = false
		bottom_collision.disabled = false
		upper_collision.position = Vector2(0, upper_line.points[1]. y * 0.5)
		bottom_collision.position = Vector2(0, bottom_line.points[1].y * 0.5)
		upper_collision.shape.extents.y = upper_line.points[1]. y * 0.5
		bottom_collision.shape.extents.y = bottom_line.points[1].y * 0.5
	
	if randf() < difficulty * 0.01 and _type != Types.MIDDLE:
		speed = rand_range(0.0025, min(0.0075, difficulty * 0.0001 + 0.0025))
		set_process(true)

func _ready():
	set_process(false)

func _process(_delta):
	tick += 0.006
	if type == Types.UPPER:
		upper_line.points[1].y = initial_upper_y + max_upper_movement * ((sin(tick * TAU) + 1 ) * 0.5)
		upper_collision.position.y = upper_line.points[1].y * 0.5
		upper_collision.shape.extents.y = upper_line.points[1].y * 0.5
		barrier.position.y = upper_line.points[1].y
	elif type == Types.LOWER:
		bottom_line.points[1].y = initial_lower_y - max_lower_movement * ((sin(tick * TAU) + 1 ) * 0.5)
		bottom_collision.position.y = bottom_line.points[1].y * 0.5
		bottom_collision.shape.extents.y = bottom_line.points[1].y * 0.5
		barrier.position.y = bottom_line.points[1].y - barrier_size
	else:
		upper_line.points[1].y = initial_upper_y + max_joint_movement * ((sin(tick * TAU) + 1 ) * 0.5)
		upper_collision.position.y = upper_line.points[1].y * 0.5
		upper_collision.shape.extents.y = upper_line.points[1].y * 0.5		
		bottom_line.points[1].y = initial_lower_y + max_joint_movement * ((sin(tick * TAU) + 1 ) * 0.5)
		bottom_collision.position = Vector2(0, gap - (gap - bottom_line.points[1].y) * 0.5)
		bottom_collision.shape.extents.y = (gap - bottom_line.points[1].y) * 0.45
		barrier.position.y = upper_line.points[1].y


func _on_BarrierCollision_area_entered(area):
	explode_barrier()

func create_barrier(upper_y : float, bottom_y : float):
	var points : PoolVector2Array
	barrier_size = bottom_y - upper_y
	barrier.position = Vector2(0, upper_y)
	points.append(Vector2(-10, 0))
	points.append(Vector2(10, 0))
	points.append(Vector2(10, barrier_size))
	points.append(Vector2(-10, barrier_size))

	barrier.set_polygon(points)
	barrier_collision_shape.disabled = false
	barrier_collision_shape.position = Vector2(0, 0.5 * barrier_size)
	barrier_collision_shape.shape.extents = Vector2(5, 0.5 * barrier_size)


func explode_barrier():
	explosion.position = barrier.position + Vector2(0, 0.5 * barrier_size)
	explosion.emitting = true
	barrier_collision_shape.set_deferred("disabled", true)
	barrier.hide()
	EventBus.emit_signal("obstacle_destroyed")


func explode(_pos):
	var pos = to_local(_pos)

	explosion.position = Vector2(0, pos.y)
	explosion.emitting = true
	match type:
		Types.UPPER:
			upper_line.hide()
			EventBus.emit_signal("obstacle_destroyed")
		Types.LOWER:
			bottom_line.hide()
			EventBus.emit_signal("obstacle_destroyed")
		Types.BOTH:
			if pos.y < upper_line.points[1].y:
				upper_line.hide()
			else:
				bottom_line.hide()
			EventBus.emit_signal("obstacle_destroyed")
		Types.MIDDLE:
			if pos.y > upper_line.points[1].y and pos.y < bottom_line.points[0].y:
				upper_line.hide()
			else:
				bottom_line.hide()
			if barrier.polygon.size() > 0:
				explode_barrier()
	
