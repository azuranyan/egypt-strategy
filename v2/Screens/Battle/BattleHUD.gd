class_name BattleHUD
extends CanvasLayer


signal undo_place_pressed
signal start_battle_pressed
signal undo_move_pressed
signal end_turn_pressed
signal pass_pressed(unit: Unit)
signal attack_pressed(unit: Unit, attack: Attack)


@export var battle: Battle

var _selected_unit: Unit
var _selected_attack: Attack


@onready var prep_unit_list := $PrepUnitList as PrepUnitList


func _ready():
	set_selected_unit(null)
	set_selected_attack(null)


func set_selected_unit(unit: Unit):
	if unit:
		$CharacterPortrait/TextureRect.texture = unit.display_icon
		$CharacterPortrait/Label.text = unit.display_name.to_upper()
		$CharacterPortrait.visible = true
		$RestButton.visible = unit.is_player_owned() and unit.can_act()
		$FightButton.visible = unit.is_player_owned() and unit.can_attack()
		$DiefyButton.visible = unit.is_player_owned() and unit.can_attack()
		$DiefyButton.disabled = not unit.is_special_unlocked()
	else:
		$CharacterPortrait.visible = false
		$RestButton.visible = false
		$FightButton.visible = false
		$DiefyButton.visible = false
	_selected_unit = unit
		
		
func set_selected_attack(attack: Attack):
	if attack:
		$InformationBox/DescriptionLabel.text = attack.description
		$InformationBox.visible = true
	else:
		$InformationBox.visible = false
	_selected_attack = attack
	

func show_ui(_show: bool):
	$UndoMoveButton.visible = battle._battle_phase
	$EndTurnButton.visible = battle._battle_phase
	$ActionOrderButton.visible = battle._battle_phase
	$MissionBox.visible = battle._battle_phase
	$BonusGoalBox.visible = battle._battle_phase
	$PrepUnitList.visible = not battle._battle_phase
	$UndoPlaceButton.visible = not battle._battle_phase
	$StartBattleButton.visible = not battle._battle_phase
	visible = _show
	

func _on_fight_button_focus_entered():
	set_selected_attack(_selected_unit.basic_attack if _selected_unit else null)


func _on_fight_button_focus_exited():
	set_selected_attack(null)
	

func _on_fight_button_mouse_entered():
	set_selected_attack(_selected_unit.basic_attack if _selected_unit else null)


func _on_fight_button_mouse_exited():
	set_selected_attack(null)


func _on_diefy_button_focus_entered():
	set_selected_attack(_selected_unit.special_attack if _selected_unit else null)


func _on_diefy_button_focus_exited():
	set_selected_attack(null)


func _on_diefy_button_mouse_entered():
	set_selected_attack(_selected_unit.special_attack if _selected_unit else null)


func _on_diefy_button_mouse_exited():
	set_selected_attack(null)


func _on_battle_manager_empire_turn_started():
	battle.show_hud(battle.on_turn.is_player_owned())


func _on_battle_manager_empire_turn_ended():
	battle.show_hud(false)


func _on_undo_move_button_pressed():
	undo_move_pressed.emit()


func _on_end_turn_button_pressed():
	end_turn_pressed.emit()


func _on_rest_button_pressed():
	if _selected_unit:
		pass_pressed.emit(_selected_unit)
		

func _on_fight_button_pressed():
	if _selected_unit:
		attack_pressed.emit(_selected_unit, _selected_unit.basic_attack)


func _on_diefy_button_pressed():
	if _selected_unit:
		attack_pressed.emit(_selected_unit, _selected_unit.special_attack)


func _on_undo_place_button_pressed():
	undo_place_pressed.emit()


func _on_start_battle_button_pressed():
	start_battle_pressed.emit()
