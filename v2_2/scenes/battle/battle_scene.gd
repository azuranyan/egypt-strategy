class_name BattleScene
extends GameScene


signal _ctc


@onready var level := %Level
@onready var pause_menu := $PauseMenu
@onready var forfeit_dialog := $ForfeitDialog


func _ready():
	pause_menu.forfeit_button.pressed.connect(forfeit_dialog.show)
	

func _input(event) -> void:
	if not is_active():
		return
		
		
	if event.is_action_pressed('ui_accept') or event is InputEventMouseButton and event.is_pressed():
		Game.battle.stop_battle()
		
		
func _unhandled_input(event):
	if event.is_action_pressed('back'):
		pause_menu.show()
		get_viewport().set_input_as_handled()
	
