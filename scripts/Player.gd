extends Node2D

var bullet_scene = preload("res://scenes/Bullet.tscn")

onready var exhaust = $Exhaust
onready var speedup_timer = $Timer
onready var powerup_timer = $PowerupTimer
onready var lightout_timer = $PowerupTimer2
onready var powerup_label = $Position2D/PowerupLabel
onready var label_position = $Position2D
onready var shield_sprite = $ShieldSprite
onready var light = $Light2D


var velocity : Vector2
var speed : float = 0 setget set_speed
var current_max_speed : int = 350 setget set_max_speed
var brake_gauge : float = 2.0 setget set_brake_gauge
var acceleration : float = ACC
var rotation_speed : float = 0
var distance_travelled : float
var next_dist_threshold : int = 5000
var shield_equipped : bool = false
var reversed : bool = false


var LEFT = BUTTON_LEFT
var RIGHT = BUTTON_RIGHT

const steer_force : float = PI / 1.5
const MAX_ROTATION_SPEED : float =  PI / 10
const MAX_ROTATION : float = PI / 2
const MAX_SPEED := 1000
var rotation_dir : int = 0


const ACC : int = 200
const DECC : int = -150

var current_state

signal fired
signal brake_gauge_updated
signal speed_changed
signal lightout
signal lighton
signal reversed
signal lightout_time_updated
signal reverse_time_updated
signal died


enum States {
	ACCELERATE,
	BRAKE,
	IDLE,
	DEAD
}

func set_speed(value):
	speed = min(value, current_max_speed)
	emit_signal("speed_changed", speed)

func set_max_speed(value):
	current_max_speed = min(value, MAX_SPEED)

func set_brake_gauge(value):
	brake_gauge = value
	emit_signal("brake_gauge_updated", value)

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			die(true)
	if event is InputEventMouseButton:
		if current_state == States.DEAD:
			return
		if rotation_speed == 0 and event.pressed and event.button_index == LEFT:
			rotation_dir = -1
		elif rotation_speed == 0 and event.pressed and event.button_index == RIGHT:
			rotation_dir = 1
		elif !event.pressed:
			rotation_dir = 0
			rotation_speed = 0

func _unhandled_key_input(event):
	if event.pressed and event.scancode == KEY_SPACE:
		current_state = States.BRAKE
		acceleration = DECC
	elif !event.pressed and event.scancode == KEY_SPACE:
		current_state = States.ACCELERATE
		acceleration = ACC

func _ready():
	current_state = States.IDLE
	set_physics_process(false)
	self.brake_gauge = 2.0
	connect("fired", get_parent(), "spawn_bullet")
	connect("brake_gauge_updated", get_parent(), "brake_gauge_updated")
	
	
func _physics_process(delta):
	var rear = position - transform.x * 20
	var front = position + transform.x * 20
	rear += velocity * delta
	if rotation_dir != 0:
		rotation_speed = clamp(rotation_speed + steer_force * delta, 0, MAX_ROTATION_SPEED)
	front += velocity.rotated(rotation_speed * rotation_dir) * delta
	var new_heading = (front - rear).normalized()
	velocity = new_heading * velocity.length()
	rotation = clamp(new_heading.angle(), -MAX_ROTATION, MAX_ROTATION)

	if Input.is_action_just_pressed("Fire"):
		emit_signal("fired", bullet_scene, position + transform.x * 50, rotation)
	
	if current_state == States.ACCELERATE:
		self.brake_gauge = clamp(brake_gauge + 0.005 * delta, 0, 2.0)
	elif current_state == States.BRAKE:
		self.brake_gauge = clamp(brake_gauge - delta, 0, 2.0)
		if brake_gauge <= 0:
			current_state = States.ACCELERATE
			acceleration = ACC
			
	self.speed += acceleration * delta
	velocity = transform.x * speed
	position += velocity * delta
	label_position.global_rotation = 0
	if reversed:
		emit_signal("reverse_time_updated", powerup_timer.time_left * 10.0)
	if light.enabled == true:
		emit_signal("lightout_time_updated", lightout_timer.time_left * 10.0)

func collect_powerup(type):
	match type:
		0:
			self.current_max_speed -= 10
			if speed > current_max_speed:
				self.speed -= 10
			powerup_label.text = "speed down!"
			blink_label(powerup_label)
		1:
			self.current_max_speed += 20
			powerup_label.text = "speed up!"
			blink_label(powerup_label)
		2:
			LEFT = BUTTON_RIGHT
			RIGHT = BUTTON_LEFT
			reversed = true
			powerup_timer.start()
			powerup_label.text = "controls\nreversed!"
			blink_label(powerup_label)
			emit_signal("reversed")
		3:
			light.enabled = true
			lightout_timer.start()
			emit_signal("lightout")
		4:
			shield_equipped = true
			shield_sprite.show()
			powerup_label.text = "shield up!"
			blink_label(powerup_label)
		
func blink_label(object : Node):
	var tw = create_tween()
	tw.set_loops(2)
	tw.connect("finished", self, "_on_Label_tween_finished", [object])
	tw.tween_property(object, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(object, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN_OUT)	

func _on_Label_tween_finished(object):
	if object is Sprite:
		object.hide()
	else:
		powerup_label.text = ""

func _on_Area2D_area_entered(area):
	match area.collision_layer:
		2:
			die(false)
		4:
			if !shield_equipped:
				die(false)
			else:
				shield_equipped = false
				blink_label(shield_sprite)
				area.get_parent().explode(global_position)
		16:
			area.queue_free()
			collect_powerup(area.type)
		32:
			if !shield_equipped:
				die(false)
			else:
				shield_equipped = false
				blink_label(shield_sprite)
				area.get_parent().explode_barrier()		

func start():
	if current_state == States.DEAD:
		return
	set_physics_process(true)
	exhaust.emitting = true
	current_state = States.ACCELERATE
	acceleration = ACC
	speedup_timer.start()

func die(quit : bool):
	set_physics_process(false)
	camera_shake()
	self.speed = 0
	rotation_speed = 0
	current_state = States.DEAD
	$Sprite.hide()
	$CollisionBox/CollisionPolygon2D.set_deferred("disabled", true)
	$Explosion.emitting = true
	exhaust.hide()
	exhaust.emitting = false
	yield(get_tree().create_timer(1.5), "timeout")
	if quit:
		get_tree().quit()
	else:
		emit_signal("died")

func camera_shake():
	$Camera2D.shake()

func _on_Timer_timeout():
	self.current_max_speed += 1


func _on_PowerupTimer_timeout():
	LEFT = BUTTON_LEFT
	RIGHT = BUTTON_RIGHT
	reversed = false
	if rotation_dir != 0:
		rotation_dir *= -1
	powerup_label.text = "controls\nnormal!"
	emit_signal("reverse_time_updated", 0.0)
	blink_label(powerup_label)


func _on_PowerupTimer2_timeout():
	light.enabled = false
	emit_signal("lighton")
	emit_signal("lightout_time_updated", 0)
