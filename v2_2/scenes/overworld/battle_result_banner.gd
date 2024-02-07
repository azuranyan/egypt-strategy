extends Control

signal advanced

var _done := false


func _ready():
	Util.bb_big_caps($Button/VBoxContainer/RichTextLabel, 'Continue', {font_size = 20})
	hide()
	
	
func show_parsed_result(result: BattleResult):
	var header: String = 'Region Lost.' if result.is_player_participating() and not result.player_won() else 'Region Conquered!' 
	var message: String
	if result.territory == result.loser().home_territory:
		if Preferences.defeat_if_home_territory_captured:
			message = "%s has claimed all of %s's territory!" % [result.winner().leader_name(), result.loser().leader_name()]
		else:
			message = "%s has claimed %s's home territory!" % [result.winner().leader_name(), result.loser().leader_name()]
	else:
		message = '%s has laid claim to the lands of %s!' % [result.winner().leader_name(), result.territory.name]
	await show_result(header, message)
	

func show_result(header: String, message: String):
	_done = false
	Util.bb_big_caps($RichTextLabel, header, {font_size = 40, call_caps = true})
	$Label.text = message
	show()
	$AnimationPlayer.play('show')
	await $AnimationPlayer.animation_finished
	if not _done:
		await advanced
	$AnimationPlayer.play_backwards('show')
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play('RESET')
	queue_free()
	
	
func done():
	_done = true
	advanced.emit()
	
	
func _unhandled_input(event):
	if not visible:
		return
	if event.is_pressed():
		done()
	get_viewport().set_input_as_handled()


func _on_button_pressed():
	$Button.release_focus()
	done()
