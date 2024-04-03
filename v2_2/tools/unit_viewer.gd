extends Control


@onready var character_info_panel := $CharacterInfoPanel as CharacterInfoPanel
@onready var unit_type_panel := $UnitTypePanel as UnitTypePanel
@onready var unit_list := $ItemList as ItemList

var _index_to_unit: Array[Unit]


func _ready():
	#add_to_group('game_event_listeners')
	# remove samples
	$ItemList.clear()

	UnitEvents.created.connect(add_unit)
	UnitEvents.destroying.connect(remove_unit)
	UnitEvents.empire_changed.connect(render_unit.unbind(2))
	UnitEvents.state_changed.connect(render_unit.unbind(2))
	UnitEvents.fielded.connect(render_unit)
	UnitEvents.unfielded.connect(render_unit)
	# TODO this signal doesn't exist
	# UnitEvents.selectable_changed.connect(render_unit)

	set_minimized(true)
	

func add_unit(unit: Unit) -> void:
	var idx := unit_list.add_item(unit.chara().name)
	_index_to_unit.insert(idx, unit)


func remove_unit(unit: Unit) -> void:
	var idx: int = _index_to_unit.find(unit)
	_index_to_unit.remove_at(idx)
	unit_list.remove_item(idx)
	
	
func set_minimized(minimized: bool):
	$ShowButton.visible = minimized
	$HideButton.visible = not minimized
	$UnitTypePanel.visible = not minimized
	$CharacterInfoPanel.visible = not minimized
	$ItemList.visible = not minimized
	$VBoxContainer.visible = not minimized
	

func render_unit(unit: Unit) -> void:
	%IDLabel.value = str(unit.id())
	%CurrentOwnerLabel.value = str(unit.get_empire().leader) if unit.get_empire() else 'none'
	%StateLabel.value = Unit.State.keys()[unit.state()]
	%FieldedLabel.value = str(unit.is_fielded())
	%SelectableLabel.value = str(unit.is_selectable())

	
func _on_item_list_item_selected(index: int):
	var unit: Unit = _index_to_unit[index]
	character_info_panel.initialize(unit.chara()) 
	unit_type_panel.initialize(unit.unit_type())
	render_unit(unit)


func _on_show_button_pressed():
	set_minimized(false)
	
	
func _on_hide_button_pressed():
	set_minimized(true)
