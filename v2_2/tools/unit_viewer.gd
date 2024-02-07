extends Control

@onready var character_info_panel := $CharacterInfoPanel as CharacterInfoPanel
@onready var unit_type_panel := $UnitTypePanel as UnitTypePanel


var _index_to_tag: Array

func _ready():
	add_to_group('game_event_listeners')
		
	#var dir := DirAccess.open('res://units/')
	#if not dir:
		#push_error('cannot open units folder')
		#return
		#
	#dir.list_dir_begin()
	#var filename := dir.get_next()
	#var i := 0
	#while filename != '':
		#if dir.current_is_dir():
			#var unit := Game.load_unit(filename, str(i))
			#$ItemList.add_item(unit.display_name)
		#else:
			#pass
		#i += 1
		#filename = dir.get_next()
	#dir.list_dir_end()
	$ItemList.clear() # remove samples

	set_minimized(true)
	
	
func on_load(save: SaveState):
	$ItemList.clear()
	_index_to_tag.clear()
	for u in save.units:
		$ItemList.add_item(u.display_name)
		_index_to_tag.append(Game.get_unit_tag(u))
	
	
func set_minimized(minimized: bool):
	$ShowButton.visible = minimized
	$HideButton.visible = not minimized
	$UnitTypePanel.visible = not minimized
	$CharacterInfoPanel.visible = not minimized
	$ItemList.visible = not minimized
	
	
func _on_item_list_item_selected(index):
	var unit := Game.get_unit_by_tag(_index_to_tag[index])
	character_info_panel.initialize(unit.chara) 
	unit_type_panel.initialize(unit.unit_type)


func _on_show_button_pressed():
	set_minimized(false)
	
	
func _on_hide_button_pressed():
	set_minimized(true)
