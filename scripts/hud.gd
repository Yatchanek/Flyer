extends CanvasLayer

export var score_display_node : NodePath
export var brake_gauge_node : NodePath
export var speed_display_node : NodePath
export var lightout_bar_node : NodePath
export var reverse_bar_node : NodePath

onready var score_display = get_node(score_display_node)
onready var brake_gauge = get_node(brake_gauge_node)
onready var speed_display = get_node(speed_display_node)
onready var lightout_bar = get_node(lightout_bar_node)
onready var reverse_bar = get_node(reverse_bar_node)
onready var anim_player = $AnimationPlayer

onready var buttons = $Buttons.get_children()

signal countdown_finished
signal replay_pressed
signal quit_pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("countdown_finished", get_parent(), "_on_Countdown_finished")
	update_score(0)
	update_brake_gauge(2.0)
	update_speed(0)
	update_progress_bar(lightout_bar, 0)
	update_progress_bar(reverse_bar, 0)
	for button in buttons:
		button.disabled = true

func update_speed(value):
	speed_display.text = "%d" % value

func update_score(score):
	score_display.text = "%d" % score

func start_game():
	emit_signal("countdown_finished")

func update_brake_gauge(value):
	brake_gauge.text = "%.2fs" % value

func update_progress_bar(bar : TextureProgress, _value : float):
	bar.value = _value
	bar.tint_progress = Color.green
	if _value < 33:
		bar.tint_progress = Color.red
	elif _value < 66:
		bar.tint_progress = Color.yellow
	if _value == 0:
		bar.get_parent().modulate.a = 0


func _on_Player_lightout_time_updated(value):
	update_progress_bar(lightout_bar, value)


func _on_Player_reverse_time_updated(value):
	update_progress_bar(reverse_bar, value)


func _on_Player_lightout():
	$HBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer.modulate.a = 1.0


func _on_Player_reversed():
	$HBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer2.modulate.a = 1.0


func _on_Replay_pressed():
	for button in buttons:
		button.disabled = true
	emit_signal("replay_pressed")


func _on_Quit_pressed():
	for button in buttons:
		button.disabled = true
	emit_signal("quit_pressed")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "GameOver":
		for button in buttons:
			button.disabled = false


func _on_Player_died():
	anim_player.play("GameOver")
