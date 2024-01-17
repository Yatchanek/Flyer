extends Node2D

onready var player = $Player
onready var hud = $HUD
onready var veil_rect = $Veil/ColorRect
onready var anim_player = $AnimationPlayer

var score : int = 0
var quit_pressed : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.connect("asteroid_destroyed", self, "_on_Asteroid_destroyed")
	randomize()
	anim_player.play("VeilUp")
	
func raise_veil():
	var tw = create_tween()
	tw.tween_property(veil_rect, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tw.connect("finished", self, "_on_Veil_up")	

func spawn_bullet(bullet_scene, pos, rot):
	var bullet = bullet_scene.instance()
	bullet.speed = max(player.speed + 600, 1150)
	bullet.position = pos
	bullet.rotation = rot
	bullet.velocity = bullet.transform.x * (player.speed + bullet.speed)
	call_deferred("add_child", bullet)

func brake_gauge_updated(value):
	hud.update_brake_gauge(value)

func _on_Asteroid_destroyed():
	score += 25
	hud.update_score(score)

func _on_Countdown_finished():
	player.current_max_speed = 350
	$Timer.start()
	player.start()

func _on_Timer_timeout():
	score += 5
	hud.update_score(score)

func _on_First_chunk_ready(_chunk : Chunk):
	player.position.x = _chunk.upper_border.points[2].x
	player.position.y = _chunk.upper_border.points[2].y + (_chunk.bottom_border.points[2].y - _chunk.upper_border.points[2].y) * 0.5

func _on_Reset_origin(offset : int):
	player.position.x -= offset



func _on_Player_lightout():
	var tw = create_tween()
	tw.set_parallel()
	tw.tween_property($CanvasModulate, "color", Color.black, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property($ParallaxBackground/CanvasModulate, "color", Color.black, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	$ChunkControl.light_off()
#	$CanvasModulate.color = Color.black
#	$ParallaxBackground/CanvasModulate.color = Color.black

func _on_Player_lighton():
	var tw = create_tween()
	tw.set_parallel()
	tw.tween_property($CanvasModulate, "color", Color.white, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property($ParallaxBackground/CanvasModulate, "color", Color.white, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	$ChunkControl.light_on()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "VeilUp":
		hud.anim_player.play("Countdown")
	else:
		if quit_pressed:
			get_tree().quit()
		else:
			get_tree().reload_current_scene()


func _on_HUD_replay_pressed():
	anim_player.play("VeilDown")


func _on_HUD_quit_pressed():
	quit_pressed = true
	anim_player.play("VeilDown")
