class_name BattleResultScreen
extends CanvasLayer


signal _resumed


@export var win_color := Color(0.2, 0.565, 0.525)

@export var lose_color := Color(0.537, 0.169, 0.224)


var _continue := false

@onready var animation_player = $AnimationPlayer
@onready var texture_rect = $Control/Banner/TextureRect
@onready var label = $Control/Banner/Label


## Shows the result screen.
static func show_result(text: String, won: bool, parent: Node = null):
	if not is_instance_valid(parent):
		parent = Game.get_tree().root
	var node := preload("res://scenes/battle/battle_result_screen.tscn").instantiate()
	parent.add_child(node)
	await node._show_result(text, won)
	

func _ready():
	hide()
	set_process_unhandled_input(false)
	

func _show_result(text: String, won: bool):
	set_process_unhandled_input(true)
	_continue = false
	label.text = text
	texture_rect.modulate = win_color if won else lose_color
	animation_player.play("show")
	show()
	await animation_player.animation_finished
	if not _continue:
		await _resumed
	animation_player.play("hide")
	await animation_player.animation_finished
	queue_free()
	
	
func _unhandled_input(event):
	if event is InputEventMouseButton or event is InputEventKey:
		_continue = true
		_resumed.emit()
	# block while this is on screen
	get_viewport().set_input_as_handled()
