class_name UnitList
extends Control
## An interactible widget that holds a list of units.


## Emitted when a unit is selected.
signal unit_selected(unit: Unit)

## Emitted when a unit is released.
signal unit_released(unit: Unit)

## Emitted when selected unit is dragged.
signal unit_dragged(unit: Unit, position: Vector2)

## Emitted when interaction is cancelled and no [signal unit_released] signal to emit.
signal cancelled(unit: Unit)


var _unit_buttons := {}
var _active_unit: Unit


@onready var unit_item_sample = %UnitItemSample
@onready var item_container = %ItemContainer


func _ready():
	unit_item_sample.visible = false
	

func _input(event):
	if not _active_unit:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			cancel()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			set_selected_unit(null)
			
	elif event is InputEventMouseMotion:	
		var pos: Vector2 = get_viewport().canvas_transform.affine_inverse() * event.position
		
		unit_dragged.emit(_active_unit, pos)
		
	
## Adds a unit to the list.
func add_unit(unit: Unit):
	if unit in _unit_buttons:
		return
	var item := unit_item_sample.duplicate()
	item.get_node('ColorRect/Portrait').texture = unit.display_icon()
	item.get_node('NameLabel').text = unit.display_name()
	item.get_node('TitleLabel').text = unit.chara().title
	item.visible = true
	
	var btn: Button = item.get_node('Button')
	btn.button_down.connect(_on_button_down.bind(btn, unit))
	btn.button_up.connect(_on_button_up.bind(btn, unit))
	btn.toggled.connect(_on_button_toggle.bind(btn, unit))
	
	item_container.add_child(item)
	_unit_buttons[unit] = btn
	_sort_buttons()
	
	
func _sort_buttons():
	var units := _unit_buttons.keys()
	units.sort_custom(func(a, b): return a.display_name() < b.display_name())
	
	for i in units.size():
		item_container.move_child(_unit_buttons[units[i]].get_parent(), i)
	
	
## Removes a unit from the list.
func remove_unit(unit: Unit):
	if unit not in _unit_buttons:
		return
	if unit == _active_unit:
		cancel()
	item_container.remove_child(_unit_buttons[unit].get_parent())
	_unit_buttons[unit].get_parent().queue_free()
	_unit_buttons.erase(unit)
	
	
## Sets the selected unit.
func set_selected_unit(unit: Unit):
	if unit == null:
		if _active_unit:
			_unit_buttons[_active_unit].button_pressed = false
			_active_unit = null
	else:
		_unit_buttons[unit].button_pressed = true
	
	
## Cancels interaction.
func cancel():
	if not _active_unit:
		return
	_unit_buttons[_active_unit].set_pressed_no_signal(false)
	_unit_buttons[_active_unit].release_focus()
	var old_unit = _active_unit
	_active_unit = null
	cancelled.emit(old_unit)
	
	
## Returns the selected unit.
func get_selected_unit() -> Unit:
	return _active_unit

	
func _set_selected_unit(unit: Unit):
	if _active_unit == unit:
		return
	var old_active_unit := _active_unit
	_active_unit = unit
	if _active_unit:
		unit_selected.emit(_active_unit)
	else:
		unit_released.emit(old_active_unit)
	
	
func _on_button_down(button: Button, unit: Unit):
	for u in _unit_buttons:
		if _unit_buttons[u] != button:
			_unit_buttons[u].button_pressed = false
	button.grab_focus()
	_set_selected_unit(unit)
	
	
func _on_button_up(button: Button, _unit: Unit):
	if button.button_pressed:
		return
	button.release_focus()
	_set_selected_unit(null)

	
func _on_button_toggle(toggle: bool, _button: Button, unit: Unit):
	_set_selected_unit(unit if toggle else null)

