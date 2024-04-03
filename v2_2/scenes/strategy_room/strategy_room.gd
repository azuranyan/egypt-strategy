@tool
extends GameScene


## Only allows unit inspection and doesn't play scenes and show new events.
@export var inspect_mode: bool


var selected_unit: Unit
var units: Dictionary
var play_event_id: StringName


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
		font = preload("res://scenes/data/fonts/Rakkas-Regular.ttf"),
		outline_size = 36,
	})

	if Engine.is_editor_hint():
		return

	attack_card.hide()

	unit_list.clear()
	unit_list.item_selected.connect(_on_unit_list_item_selected)
	unit_list.item_activated.connect(_on_unit_list_item_activated)

	unit_info_card.basic_attack_button_toggled.connect(_on_unit_info_card_basic_attack_button_toggled)
	unit_info_card.special_attack_button_toggled.connect(_on_unit_info_card_special_attack_button_toggled)


func _unhandled_input(event)-> void:
	if Engine.is_editor_hint():
		return

	if event.is_action_pressed("ui_cancel"):
		scene_return()

	
func scene_enter(kwargs := {}) -> void:
	inspect_mode = kwargs.inspect_mode
	unit_list.clear()
	%TooltipLabel.text = 'Inspect units.' if inspect_mode else 'View unit scenes.'
	for unit in Game.get_empire_units(Game.overworld.player_empire(), Game.ALL_UNITS_MASK):
		var icon: Texture2D 
		if not inspect_mode and Dialogue.instance().has_new_character_event(unit.chara()):
			icon = load('res://scenes/data/exclamation_mark.svg')
		else:
			icon = null
		var idx := unit_list.add_item(unit.display_name(), icon)
		units[idx] = unit
	OverworldEvents.strategy_room_opened.emit(inspect_mode)
	play_event_id = ''


func scene_exit() -> void:
	OverworldEvents.strategy_room_closed.emit(play_event_id)


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
	var show_unit_growth := not inspect_mode and Dialogue.instance().has_new_character_event(unit.chara())
	unit_info_card.render_unit(unit, show_unit_growth)
	character_portrait.texture = unit.chara().portrait
	$AnimationPlayer.play('show')
	

func close_unit() -> void:
	attack_card.hide()
	$AnimationPlayer.play_backwards('show')

	
func _on_unit_list_item_selected(idx: int) -> void:
	change_unit(units[idx])


func _on_unit_list_item_activated(idx: int) -> void:
	change_unit(units[idx])
	if inspect_mode:
		return
		
	var chara := selected_unit.chara()

	if not Dialogue.instance().has_character_events(chara):
		return

	var available_events := Dialogue.instance().get_available_events(chara)

	if available_events:
		var should_play: bool = await Game.create_pause_dialog("View %s's\nlatest scene?" % chara, 'Confirm', 'Cancel').closed
		if should_play:
			play_event_id = available_events[0]
			scene_return()
	else:
		Game.create_pause_dialog("%s has no\nnew scenes." % chara, 'Confirm', '')
		
	
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
