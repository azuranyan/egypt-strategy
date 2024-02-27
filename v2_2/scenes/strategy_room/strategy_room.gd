extends GameScene


var selected_unit: Unit
var units: Dictionary


@onready var strategy_room_label = %StrategyRoomLabel
@onready var unit_list: ItemList = %UnitList
@onready var character_portrait := %CharacterPortrait
@onready var unit_info_card := %UnitInfoCard
@onready var attack_card := %AttackCard


# Called when the node enters the scene tree for the first time.
func _ready():
	Util.bb_big_caps(strategy_room_label, 'Strategy Room', {
		font_size = 56,
		font_color = Color('#efe6de'),
		outline_size = 36,
	})
	
	attack_card.hide()

	unit_list.clear()
	unit_list.item_selected.connect(_on_unit_list_item_selected)
	unit_list.item_activated.connect(_on_unit_list_item_activated)

	unit_info_card.basic_attack_button_toggled.connect(_on_unit_info_card_basic_attack_button_toggled)
	unit_info_card.special_attack_button_toggled.connect(_on_unit_info_card_special_attack_button_toggled)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		scene_return()

	
func scene_enter(_kwargs := {}) -> void:
	print('enter strategy room')
	unit_list.clear()
	for unit in Game.get_empire_units(Game.overworld.player_empire(), Game.ALL_UNITS_MASK):
		print(unit)
		var icon := load('res://scenes/data/exclamation_mark.svg') if DialogueEvents.instance().has_new_character_event(unit.chara()) else null
		var idx := unit_list.add_item(unit.display_name(), icon)
		units[idx] = unit


func change_unit(unit: Unit) -> void:
	if selected_unit == unit:
		return
	if selected_unit:
		close_unit()
		await $AnimationPlayer.animation_finished
	selected_unit = unit
	if unit:
		open_unit(selected_unit)
		await $AnimationPlayer.animation_finished

		if unit_info_card.basic_attack_button.is_pressed() and selected_unit.basic_attack():
			unit_info_card.basic_attack_button.set_pressed_no_signal(false)
			unit_info_card.basic_attack_button.set_pressed(true)

		if unit_info_card.special_attack_button.is_pressed() and selected_unit.special_attack():
			unit_info_card.special_attack_button.set_pressed_no_signal(false)
			unit_info_card.special_attack_button.set_pressed(true)


func open_unit(unit: Unit) -> void:
	unit_info_card.render_unit(unit, DialogueEvents.instance().has_new_character_event(unit.chara()))
	character_portrait.texture = unit.chara().portrait
	$AnimationPlayer.play('show')
	

func close_unit() -> void:
	attack_card.hide()
	$AnimationPlayer.play_backwards('show')

	
func _on_unit_list_item_selected(idx: int) -> void:
	change_unit(units[idx])


func _on_unit_list_item_activated(idx: int) -> void:
	change_unit(units[idx])
	var chara := selected_unit.chara()

	if not DialogueEvents.instance().has_character_events(chara):
		return

	var should_play := false
	if DialogueEvents.instance().has_new_character_event(chara):
		should_play = await Game.create_pause_dialog("View %s's\nlatest scene?" % chara, 'Confirm', 'Cancel').closed
	else:
		should_play = await Game.create_pause_dialog("%s has no\nnew scenes." % chara, 'View Anyway', 'Cancel').closed
		
	if should_play:
		DialogueEvents.instance().play_character_event(chara)

	
func _on_unit_info_card_basic_attack_button_toggled(toggle: bool) -> void:
	if toggle:
		attack_card.render_attack(selected_unit, selected_unit.basic_attack())
	attack_card.visible = toggle


func _on_unit_info_card_special_attack_button_toggled(toggle: bool) -> void:
	if toggle:
		attack_card.render_attack(selected_unit, selected_unit.special_attack())
	attack_card.visible = toggle


func _on_back_button_pressed() -> void:
	scene_return()
