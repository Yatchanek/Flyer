extends Node2D

export var max_stars : int
export var star_texture : StreamTexture

var colors = [Color.white, Color.red, Color.green, Color.yellow, Color.lightblue]


# Called when the node enters the scene tree for the first time.
func _ready():
	var noise : OpenSimplexNoise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20.0
	noise.persistence = 0.8
	var stars_created : int = 0

	while stars_created < max_stars:
		var x = 10 + randi() % 2038
		var y = 10 + randi() % 2038
		
		var n = noise.get_noise_2d(x * 0.1, y * 0.1)
		if n > 0.15:
			var size = 2 + randi() % 6
			var color = colors[randi() % 3]
			var star = Sprite.new()
			star.position = Vector2(x, y)
			star.texture = star_texture
			star.region_enabled = true
			star.region_rect = Rect2(Vector2(), Vector2(64, 64))
			star.region_rect.position.x = randi() % 6 * 64
			star.scale = 0.1 * Vector2(size, size)
			star.modulate = color
			call_deferred("add_child", star)
			
			stars_created += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
