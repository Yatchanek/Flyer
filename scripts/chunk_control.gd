extends Node2D

var chunk_scene = preload("res://scenes/chunk.tscn")

var active_chunks = []

var current_segment_count : int = 0
var current_terrain_type : int = 0
var current_difficulty : int = 0
var chunk_count : int = 0
var last_y : float
var last_y_bottom : float
var last_obstacle_type : int
var segments_since_last_powerup : int = 0
var lightout : bool = false

signal difficulty_up
signal first_chunk_created
signal reset_origin
signal obstacle_destroyed

func _ready():
	randomize()
	connect("difficulty_up", get_parent(), "_on_Difficulty_up")
	connect("first_chunk_created", get_parent(), "_on_First_chunk_ready")
	connect("reset_origin", get_parent(), "_on_Reset_origin")
	var chunk = chunk_scene.instance()
	chunk.initialize(chunk_count, 0, 400, INF, 0, 0, 0, segments_since_last_powerup, lightout)
	call_deferred("add_child", chunk)
	
func _on_Chunk_created(_chunk, _last_y, _last_y_bottom, _segment_count, _difficulty_factor, _terrain_type, _obstacle_type, _segments_since_last_powerup):
	if active_chunks.size() == 0:
		emit_signal("first_chunk_created", _chunk)
	active_chunks.append(_chunk)
	chunk_count += 1
	last_y = _last_y
	last_y_bottom = _last_y_bottom
	current_segment_count = _segment_count
	current_difficulty = _difficulty_factor
	current_terrain_type = _terrain_type
	last_obstacle_type = _obstacle_type
	segments_since_last_powerup = _segments_since_last_powerup
	if active_chunks.size() < 2:
		var chunk = chunk_scene.instance()
		chunk.initialize(chunk_count, last_y, last_y_bottom, current_terrain_type, current_segment_count, current_difficulty, last_obstacle_type, segments_since_last_powerup, lightout)
		call_deferred("add_child", chunk)
	if active_chunks.size() > 2:
		var trash = active_chunks.pop_front()
		trash.queue_free()
	if chunk_count > 1000:
		reset_origin()

func reset_origin():
	var offset = Chunk.MAX_LENGTH * (chunk_count - 2)
	chunk_count = 2
	active_chunks[0].position.x = 0
	active_chunks[1].position.x = Chunk.MAX_LENGTH
	emit_signal("reset_origin", offset)

func light_off():
	lightout = true
	for chunk in active_chunks:
		chunk.upper_ground.modulate = Color.black
		chunk.bottom_ground.modulate = Color.black

func light_on():
	lightout = false
	for chunk in active_chunks:
		chunk.upper_ground.modulate = Color.white
		chunk.bottom_ground.modulate = Color.white

func _on_Close_to_end():
	var chunk = chunk_scene.instance()
	chunk.initialize(chunk_count, last_y, last_y_bottom, current_terrain_type, current_segment_count, current_difficulty, last_obstacle_type, segments_since_last_powerup, lightout)
	call_deferred("add_child", chunk)		
	
func _on_Difficulty_up():
	current_difficulty += 1
