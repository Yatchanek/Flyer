extends Camera2D

export var shake_force : float = 40.0
export var damp : float = 0.05

func _ready():
	shake_force = rand_range(90.0, 140.0)
	set_process(false)
	EventBus.connect("obstacle_destroyed", self, "shake", [false])

func _process(_delta):
	if shake_force > 1:
		do_the_shake()
	else:
		offset = Vector2(500, -50)
		rotation = 0

		set_process(false)

func do_the_shake():
	var displacement = Vector2(shake_force * rand_range(-1, 1), shake_force * rand_range(-1, 1))
	rotation = 0.75 * shake_force * rand_range(-1, 1)
	offset = Vector2(500, -50) + displacement
	shake_force = move_toward(shake_force, 0, damp)

func shake(big : bool = true):
	shake_force = rand_range(75.0, 100.0)
	if !big:
		shake_force *= 0.2
	damp = shake_force / 45
	if !big:
		damp *= 2
	set_process(true)
