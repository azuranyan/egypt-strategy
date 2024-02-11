extends Control

@onready var character_info_panel := $CharacterInfoPanel as CharacterInfoPanel
@onready var unit_type_panel := $UnitTypePanel as UnitTypePanel


var _index_to_tag: Array

func _ready():
	add_to_group('game_event_listeners')
	# remove samples
	$ItemList.clear()

	set_minimized(true)
	
	
func on_load(save: SaveState):
	$ItemList.clear()
	_index_to_tag.clear()
	for u in save.units.values():
		$ItemList.add_item(u.chara.name) # TODO
		_index_to_tag.append(u.id)
	
	
func set_minimized(minimized: bool):
	$ShowButton.visible = minimized
	$HideButton.visible = not minimized
	$UnitTypePanel.visible = not minimized
	$CharacterInfoPanel.visible = not minimized
	$ItemList.visible = not minimized
	
	
func _on_item_list_item_selected(index):
	var unit := Game.load_unit(_index_to_tag[index])
	character_info_panel.initialize(unit.chara()) 
	unit_type_panel.initialize(unit.unit_type())


func _on_show_button_pressed():
	set_minimized(false)
	
	
func _on_hide_button_pressed():
	set_minimized(true)
