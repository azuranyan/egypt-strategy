extends Control

@onready var character_info_panel := $CharacterInfoPanel as CharacterInfoPanel
@onready var unit_type_panel := $UnitTypePanel as UnitTypePanel


func _ready():
	$ItemList.clear()
		
	var dir := DirAccess.open('res://units/')
	if not dir:
		push_error('cannot open units folder')
		return
		
	dir.list_dir_begin()
	var filename := dir.get_next()
	var i := 0
	while filename != '':
		if dir.current_is_dir():
			var unit := Game.load_unit(filename, str(i))
			$ItemList.add_item(unit.display_name)
		else:
			pass
		i += 1
		filename = dir.get_next()
	dir.list_dir_end()
	set_minimized(true)
	
	
func set_minimized(minimized: bool):
	$ShowButton.visible = minimized
	$HideButton.visible = not minimized
	$UnitTypePanel.visible = not minimized
	$CharacterInfoPanel.visible = not minimized
	$ItemList.visible = not minimized
	
	
func _on_item_list_item_selected(index):
	var unit := Game.get_unit_by_tag(str(index))
	character_info_panel.initialize(unit.chara) 
	unit_type_panel.initialize(unit.unit_type)


func _on_show_button_pressed():
	set_minimized(false)
	
	
func _on_hide_button_pressed():
	set_minimized(true)
