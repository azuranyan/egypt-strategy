extends Control

signal advanced


var _value := false
var _done := false


func _ready():
	Util.bb_big_caps(%StrategyRoomLabel, 'STRATEGY ROOM', {font_size = 20})
	Util.bb_big_caps(%ContinueLabel, 'CONTINUE', {font_size = 20})
	hide()

	%ContinueButton.pressed.connect(_on_continue_button_pressed)
	%StrategyRoomButton.pressed.connect(_on_strategy_room_button_pressed)
	
	
func show_parsed_result(result: BattleResult, allow_strategy_room: bool) -> bool:
	var header: String
	var message: String

	if result.attacker_won():
		if result.is_player_participating() and not result.player_won():
			header = 'Region Lost.'
		else:
			header = 'Region Conquered!'
		if result.territory == result.loser().home_territory:
			if Game.settings.defeat_if_home_territory_captured:
				message = "%s has claimed all of %s's territory!" % [result.winner().leader_name(), result.loser().leader_name()]
			else:
				message = "%s has claimed %s's home territory!" % [result.winner().leader_name(), result.loser().leader_name()]
		else:
			message = '%s has captured the lands of %s!' % [result.winner().leader_name(), result.territory.name]
	else:
		header = 'Region Defended!'
		message = '%s has successfully defended %s' % [result.defender.leader_name(), result.territory.name]

	return await show_result(header, message, allow_strategy_room)
	

func show_result(header: String, message: String, allow_strategy_room: bool) -> bool:
	_done = false
	Util.bb_big_caps($Control/RichTextLabel, header, {font_size = 40, call_caps = true})
	$Control/Label.text = message
	%StrategyRoomButton.visible = allow_strategy_room
	%ContinueButton.grab_focus()
	modulate = Color.TRANSPARENT # prevent flicker
	show()
	$AnimationPlayer.play('show')
	await $AnimationPlayer.animation_finished
	if not _done:
		await advanced
	$AnimationPlayer.play_backwards('show')
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play('RESET')
	if %ContinueButton.has_focus():
		%ContinueButton.release_focus()
	queue_free()
	return _value
	
	
func done():
	_done = true
	advanced.emit()
	
	
func _gui_input(event):
	if not visible:
		return
	if event.is_pressed():
		done()
	get_viewport().set_input_as_handled()


func _on_continue_button_pressed():
	%ContinueButton.release_focus()
	done()


func _on_strategy_room_button_pressed():
	_value = true
	%StrategyRoomButton.release_focus()
	done()

