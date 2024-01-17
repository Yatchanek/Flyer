extends Area2D


var velocity : Vector2 = Vector2()

var speed = 650

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _physics_process(delta):
	position += velocity * delta


func _on_Bullet_area_entered(_area):
	queue_free()
