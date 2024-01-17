extends Node2D
class_name Chunk

var obstacle_scene = preload("res://scenes/Obstacle.tscn")
var flying_obstacle_scene = preload("res://scenes/FlyingObstacle.tscn")
var powerup_scene = preload("res://scenes/Powerup.tscn")


onready var upper_border = $BorderUp
onready var bottom_border = $BorderDown
onready var upper_ground = $GroundUp
onready var bottom_ground = $GroundDown
onready var collision_up = $Area2D/CollisionUp
onready var collision_down = $Area2D/CollisionDown
onready var player_detector = $PlayerDetector
onready var player_detector_collision_shape = $PlayerDetector/CollisionShape2D


const MAX_LENGTH = 2048

const avg_segment_length : int = 100
var max_deviation_horiz : int = 25
var min_deviation_vert : int = -50
var max_deviation_vert : int = 50

const max_segments : int = 35
var last_x : float = 0
var last_y : float = 0
var last_y_bottom :float = last_y + 350

var highest_y : float
var lowest_y : float

var max_gap : int = 500
var min_gap : int = 250

var last_obstacle_type : int = Obstacle_Type.UPPER
var segments_since_last_powerup : int = 0

const MIN_TERRAIN_CHANGE_CHANCE = 0.6
const MIN_OBSTACLE_CHANCE = 0.6
const MIN_POWERUP_INTERVAL = 75
const MAX_POWERUP_INTERVAL = 250
const MIN_OBSTACLE_FREQUENCY = 6
const MAX_OBSTACLE_FREQUENCY = 9

var segment_count : int = 0
var total_segment_count : int
var terrain_change_frequency : int = 11
var terrain_change_chance : float = MIN_TERRAIN_CHANGE_CHANCE
var obstacle_frequency : int = 9
var obstacle_chance : float = MIN_OBSTACLE_CHANCE
var difficulty_factor : int = 0
var powerup_chance = 0.05

var terrain_type : int
var last_terrain_type : int = INF
var lightout : bool = false

signal created
signal difficulty_up
signal close_to_end
signal obstacle_destroyed

enum Terrain_Type {
	ASCEND,
	DESCEND,
	FLAT
}

enum Obstacle_Type {
	UPPER,
	LOWER,
	BOTH,
	MIDDLE
}

const possible_types = {
	Terrain_Type.ASCEND : [Terrain_Type.DESCEND, Terrain_Type.FLAT],
	Terrain_Type.DESCEND : [Terrain_Type.ASCEND, Terrain_Type.FLAT],
	Terrain_Type.FLAT : [Terrain_Type.ASCEND, Terrain_Type.DESCEND]
}

func initialize(count, _last_y, _last_y_bottom, _last_terrain_type, _last_segment_count, _last_difficulty, _last_obstacle_type, _segments_since_last_powerup, _lightout : bool):
	position.x = count * MAX_LENGTH
	last_y = _last_y
	last_y_bottom = _last_y_bottom
	last_terrain_type = _last_terrain_type
	total_segment_count = _last_segment_count
	difficulty_factor = _last_difficulty
	last_obstacle_type = _last_obstacle_type
	segments_since_last_powerup = _segments_since_last_powerup
	lightout = _lightout


func _ready():
	connect("close_to_end", get_parent(), "_on_Close_to_end")
	connect("created", get_parent(), "_on_Chunk_created")
	connect("difficulty_up", get_parent(), "_on_Difficulty_up")
	connect("obstacle_destroyed", get_parent(), "_on_Obstacle_destroyed")
	if lightout:
		upper_ground.modulate = Color.black
		bottom_ground.modulate = Color.black
	else:
		upper_ground.modulate = Color.white
		bottom_ground.modulate = Color.white
		
	if last_terrain_type < 10:
		terrain_type = Terrain_Type.FLAT
	else:
		terrain_type = last_terrain_type
	
	adjust_terrain_type()
	adjust_difficulty()
	generate()

func set_detector_position():
	var idx = int(segment_count * 0.35)
	var gap = bottom_border.points[idx].y - upper_border.points[idx].y
	player_detector.position = Vector2(bottom_border.points[idx].x, upper_border.points[idx].y + gap * 0.5)
	player_detector_collision_shape.disabled = false
	player_detector_collision_shape.shape.extents.y = gap * 0.5
	
func generate():
	var first_one = total_segment_count < 5
	upper_border.add_point(Vector2(last_x, last_y))
	bottom_border.add_point(Vector2(last_x, last_y_bottom))
	highest_y = last_y
	lowest_y = last_y_bottom
	while last_x < MAX_LENGTH:
		var obstacle_added : bool = false
		get_new_coords()	
		upper_border.add_point(Vector2(last_x, last_y))
		bottom_border.add_point(Vector2(last_x, last_y_bottom))
		segment_count += 1
		total_segment_count += 1
		segments_since_last_powerup += 1

		if total_segment_count % terrain_change_frequency == 0 and randf() < terrain_change_chance:
			terrain_type = possible_types[terrain_type][randi() % possible_types[terrain_type].size()]
			adjust_terrain_type()
			
		if total_segment_count > 10 and total_segment_count % obstacle_frequency == 0 and randf() < obstacle_chance:
			add_obstacle()
			obstacle_added = true

		if total_segment_count % 20 == 0:
			difficulty_factor += 1
			emit_signal("difficulty_up")
			adjust_difficulty()
		
		if (!obstacle_added and randf() < powerup_chance and segments_since_last_powerup > MIN_POWERUP_INTERVAL) or segments_since_last_powerup > MAX_POWERUP_INTERVAL:
			segments_since_last_powerup = 0
			add_powerup()		
			
	if last_x - MAX_LENGTH < avg_segment_length * 0.25:
		upper_border.points[segment_count].x = MAX_LENGTH
		bottom_border.points[segment_count].x = MAX_LENGTH
			
	else:
		upper_border.remove_point(segment_count)
		bottom_border.remove_point(segment_count)
		upper_border.points[segment_count - 1].x = MAX_LENGTH
		bottom_border.points[segment_count - 1].x = MAX_LENGTH
		last_y = upper_border.points[segment_count - 1].y
		last_y_bottom = bottom_border.points[segment_count - 1].y

	create_polygon(upper_ground, collision_up, upper_border, "up")
	create_polygon(bottom_ground, collision_down, bottom_border, "bottom")
	var occ : OccluderPolygon2D = OccluderPolygon2D.new()
	occ.polygon = upper_ground.polygon


	if !first_one:
		set_detector_position()

	emit_signal("created", self, last_y, last_y_bottom, total_segment_count, difficulty_factor, terrain_type, last_obstacle_type, segments_since_last_powerup)
				
func get_new_coords():
	last_x += avg_segment_length + rand_range(-max_deviation_horiz, max_deviation_horiz)
	last_y += rand_range(min_deviation_vert, max_deviation_vert)
	var new_last_y_bottom = last_y_bottom + rand_range(min_deviation_vert, max_deviation_vert)		
	if new_last_y_bottom - last_y > max_gap:
		new_last_y_bottom = last_y + max_gap - rand_range(0, (max_gap - min_gap) * 0.15)
	elif new_last_y_bottom - last_y < min_gap:
		new_last_y_bottom = last_y + min_gap + rand_range(0, (max_gap - min_gap) * 0.15)
#	while new_last_y_bottom - last_y > max_gap or new_last_y_bottom - last_y < min_gap:
#		new_last_y_bottom = last_y_bottom + rand_range(min_deviation_vert, max_deviation_vert)		

	last_y_bottom = new_last_y_bottom
	
	if last_y_bottom > lowest_y:
		lowest_y = last_y_bottom
	if highest_y > last_y:
		highest_y = last_y		

func create_polygon(polygon: Polygon2D, collision: CollisionPolygon2D, base_line : Line2D, _type : String):		
	var points = base_line.points
	var num_points = points.size()
	var y : float
	if _type == "up":
		y = highest_y - 800
	elif _type == "bottom":
		y = lowest_y + 800
	points.append(Vector2(points[num_points - 1].x, y))
	points.append(Vector2(points[0].x, y))
	polygon.set_polygon(points)
	collision.call_deferred("set_polygon", points)

func add_obstacle():
	if last_x > MAX_LENGTH:
		return
	var gap = abs(last_y_bottom - last_y)
	if gap > 175:
		if randf() < 0.15:
			var obstacle = flying_obstacle_scene.instance()
			call_deferred("add_child", obstacle)
			obstacle.initialize(last_x, last_y, last_y_bottom, difficulty_factor)
		else:
			var obstacle = obstacle_scene.instance()
			var obstacle_type = set_obstacle_type()
			while obstacle_type == last_obstacle_type:
				obstacle_type = set_obstacle_type()
			last_obstacle_type = obstacle_type
			call_deferred("add_child", obstacle)
			obstacle.call_deferred("initialize", obstacle_type, last_x, last_y, last_y_bottom, difficulty_factor)

func add_powerup():	
	var gap = last_y_bottom - last_y
	var powerup = powerup_scene.instance()
	powerup.position = Vector2(last_x, last_y + gap * 0.5 + rand_range(-25, 25))
	call_deferred("add_child", powerup)

	
func set_obstacle_type():
	var roll : float = randf()
	var obstacle_type : int 
	if roll < 0.25:
		obstacle_type = Obstacle_Type.UPPER
	elif roll < 0.50: 
		obstacle_type = Obstacle_Type.LOWER
	elif roll < 0.75:
		obstacle_type = Obstacle_Type.BOTH
	else: 
		obstacle_type = Obstacle_Type.MIDDLE
			
	return obstacle_type

func adjust_terrain_type():
	if terrain_type == Terrain_Type.ASCEND:
		min_deviation_vert = clamp(20 + difficulty_factor, 20, 40)
		max_deviation_vert = clamp(60 + difficulty_factor, 60, 110)
	elif terrain_type == Terrain_Type.FLAT:
		min_deviation_vert = clamp(-50 - difficulty_factor, -50, -85)
		max_deviation_vert = clamp(50 + difficulty_factor, 50, 85)
	else:
		max_deviation_vert = clamp(-20 - difficulty_factor, -40, -20)
		min_deviation_vert = clamp(-60 - difficulty_factor, -110, -60)

func adjust_difficulty():
	max_deviation_horiz = clamp(max_deviation_horiz + difficulty_factor, 25, 40)
	max_gap = clamp(max_gap - 5, 300, 400)
	min_gap = clamp(min_gap - 5, 150, 225)
	terrain_change_chance = clamp(MIN_TERRAIN_CHANGE_CHANCE + difficulty_factor * 0.025,MIN_TERRAIN_CHANGE_CHANCE, 0.95)
	terrain_change_frequency = clamp(11 - int(difficulty_factor / 3), 5, 11)
	obstacle_chance = clamp(MIN_OBSTACLE_CHANCE + difficulty_factor * 0.05, MIN_OBSTACLE_CHANCE, 0.95)
	obstacle_frequency = clamp(MAX_OBSTACLE_FREQUENCY - int(difficulty_factor / 5), MIN_OBSTACLE_FREQUENCY, MAX_OBSTACLE_FREQUENCY)
	

func _on_PlayerDetector_area_entered(area):
	emit_signal("close_to_end")
