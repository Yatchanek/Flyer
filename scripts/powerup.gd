extends Area2D

onready var sprite = $Sprite

export (Array, Texture) var textures

var initial_position : Vector2
var angle : float = 0
var color_h : float = 0

var type : int


const data = {
	0 : [0.5, Color.green],
	1 : [0.3, Color.red],
	2 : [0.1, Color.magenta],
	3 : [0.05, Color.yellow],
	4 : [0.05, Color.springgreen]
}


# Called when the node enters the scene tree for the first time.
func _ready():
	var total_chance : float = 0
	var roll = randf()
	for key in data.keys():
		total_chance += data[key][0]
		if roll < total_chance:
			type = key
			sprite.modulate = data[key][1]
			sprite.texture = textures[key]
			break
	initial_position = position
	
func _process(delta):
	angle += delta
	position.y = initial_position.y + 10 * sin(angle)
