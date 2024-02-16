class_name BattleScene
extends GameScene


signal _ctc


@onready var level := %Level
@onready var hud: BattleHUD = $HUDVisibilityControl/HUD
@onready var hud_visibility_control := $HUDVisibilityControl
@onready var battle_start_banner := $BattleStartBanner
@onready var pause_menu := $PauseMenu
@onready var battle_result_screen = $BattleResultScreen

@onready var viewport: Viewport = %Viewport
@onready var camera: Camera2D = %Camera2D


func _ready():
	viewport.canvas_cull_mask &= ~(1 << 9)
	pause_menu.forfeit_button.pressed.connect(Game.battle.show_forfeit_dialog)
		

func _unhandled_input(event):
	if event.is_action_pressed('ui_accept'):
		show_battle_results()
		
	if event.is_action_pressed('back'):
		if Game.battle.is_battle_phase():
			pause_menu.show()
		else:
			Game.battle.show_forfeit_dialog()
		get_viewport().set_input_as_handled()
	

func scene_enter(_kwargs := {}):
	level.load_map(Game.battle.territory().maps[Game.battle.map_id()])
	
	
func scene_exit():
	level.unload_map()
	
	
## Sets the camera target.
func set_camera_target(target: Variant):
	clear_camera_target()
	if target is Unit:
		_set_camera_target(target.get_map_object())
	elif target is Node2D:
		_set_camera_target(target)
	elif target is Vector2 or target is Vector2i:
		camera.position = target
		

func _set_camera_target(target: Node2D):
	var remote := RemoteTransform2D.new()
	remote.remote_path = camera.get_path()
	remote.update_rotation = false
	remote.update_scale = false
	target.add_child(remote)
	remote.force_update_transform()
	camera.set_meta('target', weakref(remote))
		
		
## Clears the camera target.
func clear_camera_target(reset_position: bool = false):
	if camera.has_meta('target'):
		var target: WeakRef = camera.get_meta('target')
		if target.get_ref():
			target.get_ref().queue_free()
		camera.remove_meta('target')
	if reset_position:
		camera.position = Game.get_viewport_size()/2
	

## Displays the battle start banner.
func show_battle_start():
	battle_start_banner.show()
	var anim: AnimationPlayer = battle_start_banner.get_node('AnimationPlayer')
	anim.play('show')
	await anim.animation_finished
	anim.play('hide')
	await anim.animation_finished
	battle_start_banner.hide()

	
## Displays the battle result.
func show_battle_results():
	var result := Game.battle.get_battle_result()
	var message := battle_result_message(result)
	var won := result.player_won()
	if message == '':
		return
	battle_result_screen.show()
	await battle_result_screen.show_result(message, won)
	battle_result_screen.hide()


## Returns the message to display for given the given result.
func battle_result_message(result: BattleResult) -> String:
	if result.attacker.is_player_owned():
		match result.value:
			BattleResult.ATTACKER_VICTORY:
				return 'Territory Taken!'
			BattleResult.DEFENDER_VICTORY:
				return 'Conquest Failed.'
			BattleResult.ATTACKER_WITHDRAW:
				return 'Battle Forfeited.'
			BattleResult.DEFENDER_WITHDRAW:
				return 'Enemy Withdraw!'
	else:
		match result.value:
			BattleResult.ATTACKER_VICTORY:
				return 'Territory Lost.'
			BattleResult.DEFENDER_VICTORY:
				return 'Defense Success!'
			BattleResult.ATTACKER_WITHDRAW:
				return 'Enemy Withdraw!'
			BattleResult.DEFENDER_WITHDRAW:
				return 'Territory Surrendered.'
	return ''
	
