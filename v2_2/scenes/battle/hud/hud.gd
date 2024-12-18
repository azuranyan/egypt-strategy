class_name BattleHUD
extends Control


var _selected_unit: Unit
var _selected_attack: Attack


# top panel
@onready var menu_button: Button = $Control/MenuButton
@onready var undo_button: Button = $Control/UndoButton
@onready var end_button: Button = $Control/EndButton
@onready var action_order_button: Button = $Control/ActionOrderButton
@onready var character_panel = $Control/CharacterPanel
@onready var message_box = $Control/MessageBox
@onready var objectives_panel = $Control/ObjectivesPanel
@onready var prep_unit_list: UnitList = $Control/PrepUnitList
@onready var action_order_list: UnitList = $Control/ActionOrderList
@onready var turn_banner = %TurnBanner
@onready var attack_banner = %AttackBanner

# bottom panel
@onready var rest_button: Button = %RestButton
@onready var fight_button: Button = %FightButton
@onready var deify_button: Button = %DeifyButton

@onready var _focused_action_button: Button
@onready var _action_show: Dictionary = {
	rest_button: show_info_box_rest,
	fight_button: show_info_box_basic,
	deify_button: show_info_box_special,
}


func _ready():
	$TestMapMockupV8Hd.hide()
	message_box.hide()
	%MissionSample.hide()
	%BonusGoalSample.hide()
	%AttackInfoPanel.hide()
	hide()
	character_panel.hide()
	action_order_button.toggled.connect(_toggle_right_panel_visibility)
	# TODO auto hide when losing focus, but not when losing focus to action order list
	
	BattleEvents.prep_phase_started.connect(_on_prep_phase_started)
	BattleEvents.turn_started.connect(_on_turn_started)
	BattleEvents.objective_updated.connect(func(_objective: Objective):
		set_missions(Battle.instance().missions())
		set_bonus_goals(Battle.instance().bonus_goals())
	)

	UnitEvents.selected.connect(_on_unit_selected)
	
	
func _on_prep_phase_started(empire: Empire):
	if not empire.is_player_owned():
		return
	for u in Game.get_empire_units(Game.battle.player(), Game.ALL_UNITS_MASK):
		prep_unit_list.add_unit(u)
	update()


func _on_turn_started(_empire: Empire):
	action_order_button.button_pressed = false
	update()


func update():
	show()
	# mock test
	var battle_phase := Battle.instance().is_battle_phase()
	var is_player_turn := Battle.instance().on_turn().is_player_owned()
	var is_training := Battle.instance().is_training_battle()
	var missions := Battle.instance().missions()
	var bonus_goals := Battle.instance().bonus_goals()
	
	# top left panel
	if battle_phase:
		undo_button.get_node('Label').text = 'UNDO\nMOVE'
		end_button.get_node('Label').text = 'END\nTURN'
	else:
		undo_button.get_node('Label').text = 'UNDO\nPLACE'
		end_button.get_node('Label').text = 'END\nPREP'
	menu_button.visible = true
	undo_button.visible = is_player_turn
	end_button.visible = is_player_turn
	
	# top right panel
	_toggle_right_panel_visibility(action_order_button.button_pressed)
	%MissionPanel.visible = true
	set_missions(missions)
	%BonusGoalPanel.visible = battle_phase and not is_training
	set_bonus_goals(bonus_goals)
	action_order_button.visible = battle_phase and is_player_turn


func _toggle_right_panel_visibility(action_order_mode: bool) -> void:
	var battle_phase := Battle.instance().is_battle_phase()
	prep_unit_list.visible = not battle_phase
	objectives_panel.visible = battle_phase and not action_order_mode
	action_order_list.visible = battle_phase and action_order_mode


## Returns the selected unit.
func get_selected_unit() -> Unit:
	return _selected_unit

	
## Sets the selected unit. This will call [method clear_selected_unit] if null.
func set_selected_unit(unit: Unit):
	if not unit:
		clear_selected_unit()
		return
		
	character_panel.show()
	_selected_unit = unit
	%CharacterNameLabel.text = unit.display_name().to_upper()
	%CharacterPortraitRect.texture = unit.display_icon()
	
	var show_buttons := Game.battle.is_battle_phase() and unit.get_empire() == Game.battle.on_turn()
	rest_button.visible = show_buttons
	rest_button.disabled = not unit.can_act()
	
	fight_button.visible = show_buttons and unit.basic_attack() != null
	fight_button.disabled = not unit.can_attack()
	
	deify_button.visible = show_buttons and unit.special_attack() != null
	deify_button.disabled = not unit.can_attack() or not unit.is_special_unlocked()

	
## Clears the selected unit and hides the character panel.
func clear_selected_unit():
	character_panel.hide()
	_selected_unit = null
	

## Sets the selected attack.
func set_selected_attack(attack: Attack):
	clear_selected_attack()
	if not attack:
		return
	# TODO finish this function:
	# - attack button must be toggleable
	# - selecting attack toggles it
	# - once toggled, will show attack info and lock it
	# - quick info via focusing still works, but should not change attack info once toggled
	var button := get_attack_button(_selected_unit, attack)
	if button:
		button.grab_focus()
	_selected_attack = null
		

## Clears the selected attack.
func clear_selected_attack():
	deify_button.release_focus()
	fight_button.release_focus()
	rest_button.release_focus()
	hide_info_box()
	_selected_attack = null


## Returns the attack button.
func get_attack_button(unit: Unit, attack: Attack) -> Button:
	if attack == unit.special_attack():
		return deify_button
	elif attack != unit.basic_attack():
		return fight_button
	else:
		return null

	
## Shows the turn banner for a certain duration.
func show_turn_banner(duration: float = 1):
	$Control.hide()
	turn_banner.show()
	%OnTurnLabel.text = 'PLAYER TURN' if Game.battle.on_turn().is_player_owned() else 'ENEMY TURN'
	await get_tree().create_timer(duration).timeout
	turn_banner.hide()
	$Control.show()
	
	
## Shows the attack banner.
func show_attack_banner(attack: Attack):
	if $AnimationPlayer.is_playing():
		push_error('still playing')
	Util.bb_big_caps(%AttackLabel, attack.name, {
		font_size = 40,
		font = preload("res://scenes/data/fonts/Rakkas-Regular.ttf"),
		big_font_size = 50,
	})
	attack_banner.modulate = Color.TRANSPARENT
	$Control.modulate = Color.WHITE
	$AnimationPlayer.play('show_attack_banner')
	attack_banner.show()
	await $AnimationPlayer.animation_finished
	$Control.hide()
	
	
## Hides the attack banner.
func hide_attack_banner():
	if not attack_banner.visible:
		return
	attack_banner.modulate = Color.WHITE
	$Control.modulate = Color.TRANSPARENT
	$AnimationPlayer.play_backwards('show_attack_banner')
	$Control.show()
	await $AnimationPlayer.animation_finished
	attack_banner.hide()
	
	
## Shows message.
func show_message(message: String, duration: float = -1):
	%MessageLabel.text = message
	if message.is_empty():
		message_box.hide()
	else:
		message_box.show()
		if duration != -1:
			await get_tree().create_timer(duration).timeout
			message_box.hide()


## Displays the list of missions.
func set_missions(missions: Array[Objective]):
	clear_missions()
	_set_objective_list(%MissionContainer, %MissionSample, missions)
	
	
## Clears the list of missions.
func clear_missions():
	_clear_objective_list(%MissionContainer, %MissionSample)
			
			
## Displays the list of bonus goals.
func set_bonus_goals(bonus_goals: Array[Objective]):
	clear_bonus_goals()
	_set_objective_list(%BonusGoalContainer, %BonusGoalSample, bonus_goals)
	if bonus_goals.is_empty():
		%BonusGoalPanel.hide()
	

## Clears the list of bonus goals.
func clear_bonus_goals():
	_clear_objective_list(%BonusGoalContainer, %BonusGoalSample)
			
			
func _set_objective_list(container: Control, sample: Control, objectives: Array[Objective]):
	for objective in objectives:
		if objective.hidden:
			continue

		var label: Label = sample.duplicate()

		# set the description
		label.text = objective.description()

		# set the active state
		if objective.is_active():
			label.modulate = Color.WHITE
		else:
			label.modulate = Color(1, 1, 1, 0.33)

		# set the status
		if objective.objective_type == 'Bonus Objective':
			if objective.status() == Objective.Status.NONE:
				label.get_node("Mark").hide()
			else:
				label.get_node("Mark").text = "✓" if objective.status() == Objective.Status.COMPLETED else "✗"

		label.show()
		container.add_child(label)
		
		
func _clear_objective_list(container: Control, sample: Control):
	for child in container.get_children():
		if child != sample:
			child.queue_free()
		
		
## Shows rest description in the info box.
func show_info_box_rest():
	%AttackInfoPanel.show()
	$HideAttackInfoTimer.stop()
	%AttackInfoLabel.text = 'Rest and recover 1 HP.'
		
		
## Shows basic attack description in the info box.
func show_info_box_basic():
	%AttackInfoPanel.show()
	$HideAttackInfoTimer.stop()
	%AttackInfoLabel.text = _selected_unit.basic_attack().description
		
		
## Shows special attack description in the info box.
func show_info_box_special():
	%AttackInfoPanel.show()
	$HideAttackInfoTimer.stop()
	%AttackInfoLabel.text = _selected_unit.special_attack().description
		
		
## Hides the info box.
func hide_info_box():
	$HideAttackInfoTimer.start(0.1)
		
		
func _exit_info_button():
	if _focused_action_button:
		_action_show[_focused_action_button].call()
	else:
		hide_info_box()
		
		
# Rest Button Signals


func _on_rest_button_focus_entered():
	_focused_action_button = rest_button
	show_info_box_rest()


func _on_rest_button_focus_exited():
	_focused_action_button = null
	hide_info_box()


func _on_rest_button_mouse_entered():
	show_info_box_rest()


func _on_rest_button_mouse_exited():
	_exit_info_button()


# Fight Button Signals


func _on_fight_button_focus_entered():
	_focused_action_button = fight_button
	show_info_box_basic()


func _on_fight_button_focus_exited():
	_focused_action_button = null
	hide_info_box()


func _on_fight_button_mouse_entered():
	show_info_box_basic()


func _on_fight_button_mouse_exited():
	_exit_info_button()


# Deify Button Signals


func _on_deify_button_focus_entered():
	_focused_action_button = deify_button
	show_info_box_special()


func _on_deify_button_focus_exited():
	_focused_action_button = null
	hide_info_box()


func _on_deify_button_mouse_entered():
	show_info_box_special()


func _on_deify_button_mouse_exited():
	_exit_info_button()
	

func _on_hide_attack_info_timer_timeout():
	%AttackInfoPanel.hide()


func _on_unit_selected(unit: Unit, is_selected: bool):
	if is_selected:
		set_selected_unit(unit)
	else:
		set_selected_unit(null)
	
