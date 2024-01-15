class_name PrepUnitButton
extends Control


@export var highlighted: bool:
	set(value):
		if highlighted == value:
			return
		highlighted = value
		if is_node_ready():
			update_highlighted()


@export var unit: Unit:
	set(value):
		if unit == value:
			return
		unit = value
		if is_node_ready():
			update_unit()


var prep_unit_list: PrepUnitList

var selected: bool:
	set(value):
		if selected == value:
			return
		selected = value
		if is_node_ready():
			update_selected()


func _ready():
	update_unit()
	update_highlighted()
	#update_selected()


func update_highlighted():
	$Selection.visible = highlighted


func update_unit():
	if unit:
		$Control2/Control/ColorRect2/TextureRect.texture = unit.display_icon
		$Control2/Control/Label.text = unit.display_name
		$Control2/Control/Label2.text = unit.unit_type.chara.title
		$Control2/Control/ColorRect3.modulate = unit.unit_type.chara.map_color
	else:
		$Control2/Control/ColorRect2/TextureRect.texture = null
		$Control2/Control/Label.text = ""
		$Control2/Control/Label2.text = ""
		$Control2/Control/ColorRect3.modulate = Color.WHITE


func update_selected():
	prep_unit_list.button_selected(self, selected)


func _on_button_button_down():
	highlighted = true
	selected = true


func _on_button_button_up():
	highlighted = false
	selected = false
	
