extends Node2D

onready var border = $Border

var speed : float
var velocity : Vector2
var direction : int
var rotation_dir : int
var rotation_speed : float
var radius : float
var gap : float
var tick : int = 0
var initial_pos_y : float
var movement_range : float
var difficilty : int

func initialize(_x : float, _upper_y : float, _bottom_y : float, _difficulty : int):
	gap = abs(_bottom_y - _upper_y)
	position = Vector2(_x, _upper_y + gap * 0.5)
	initial_pos_y = _upper_y + gap * 0.5
	difficilty = _difficulty

func _ready():
	speed = rand_range(90, 130) + rand_range(0, min(difficilty * 5, 100))
	rotation_speed = rand_range(PI / 2, PI / 4)
	direction = pow(-1, randi() % 2)
	rotation_dir = pow(-1, randi() % 2)
	velocity = Vector2.UP * direction * speed
	radius = rand_range(35, 50)
	$Area2D/CollisionShape2D.shape.radius = radius
	var ratio = radius / (gap * 0.5)

	movement_range = gap * (0.5 - ratio * 1.1)
	#prints(gap, radius, ratio, movement_range)
	var vertices = 12 + randi() % 9
	var angle = TAU / vertices
	var points : PoolVector2Array
	for i in vertices:
		points.append(Vector2((radius + rand_range(-10, 10)) * cos(i * angle), radius * sin(i * angle)))
	
	$Polygon2D.set_polygon(points)
	border.points = points
	border.add_point(border.points[0])

func _physics_process(delta):
	rotation += rotation_dir * rotation_speed * delta
	position.y = initial_pos_y + movement_range * sin(tick * delta)
	tick += 1
	


func _on_Area2D_area_entered(area):
	if area.collision_layer != 1:
		explode(Vector2())
		
func explode(_pos : Vector2):
	set_physics_process(false)
	$AnimationPlayer.play("Explode")
	EventBus.emit_signal("obstacle_destroyed")
	EventBus.emit_signal("asteroid_destroyed")
