@tool
extends CanvasLayer


const SubsettingScene := preload('res://scenes/common/subsetting.tscn')


@export var settings_group: Control
@export var settings_group_container_path: NodePath


func _ready() -> void:
	settings_group.hide()
	if Engine.is_editor_hint() or Util.is_scene_root(self):
		var settings := Settings.new()
		Game.setting_changed.connect(func(name: String, value: Variant): print('%s: %s' % [name, value]))
		initialize.call_deferred(settings)


## Dynamically generates settings screen.
func initialize(resource: Resource) -> void:
	var skip_group: bool
	var last_group: Control
	var container: Control

	for prop in resource.get_property_list():
		if prop.usage & PROPERTY_USAGE_GROUP:
			if prop.name == 'Resource':
				skip_group = true
			else:
				last_group = settings_group.duplicate()
				last_group.show()
				last_group.name = prop.name
				container = last_group.get_node(settings_group_container_path)
				%SettingsContainer.add_child(last_group)
				skip_group = false

		elif prop.usage & PROPERTY_USAGE_SUBGROUP:
			if skip_group:
				continue
			var subsetting = SubsettingScene.instantiate()
			subsetting.name = prop.name
			subsetting.title = prop.name
			last_group.get_node(settings_group_container_path).add_child(subsetting)
			container = subsetting

		elif prop.usage & PROPERTY_USAGE_DEFAULT:
			if skip_group:
				continue
			var value = resource.get(prop.name)
			var control := create_control_for(resource, prop, value)

			if control:
				# create the container and the label
				var control_container := HBoxContainer.new()
				var control_label := Label.new()
				control_label.text = prop.name.capitalize()
				control_container.add_child(control_label)
				control_container.add_child(control)
				
				# setup layout
				control_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				control.custom_minimum_size = last_group.size * Vector2(0.3, 0) + Vector2(0, 32)
			
				container.add_child(control_container)


## Creates a control for a property.
func create_control_for(object: Object, prop: Dictionary, value: Variant) -> Control:
	if prop.type == TYPE_BOOL:
		return create_toggle_for(object, prop, value)

	elif prop.type == TYPE_FLOAT:
		return create_range_for(object, prop, value)
	
	elif prop.type == TYPE_INT:
		if prop.hint == PROPERTY_HINT_ENUM:
			return create_dropdown_for(object, prop, value)
		else:
			return create_range_for(object, prop, value)

	elif prop.type == TYPE_STRING:
		if prop.hint == PROPERTY_HINT_ENUM:
			return create_dropdown_for(object, prop, value)
		else:
			return create_text_input_for(object, prop, value)
	else:
		return null
		

## Creates a toggle setting for a boolean property.
func create_toggle_for(object: Object, prop: Dictionary, value: bool) -> Button:
	var button := CheckButton.new()
	button.button_pressed = value
	button.toggled.connect(func(v: bool):
		object.set(prop.name, v)
		Game.setting_changed.emit(prop.name, v)
	)
	return button
	

## Creates a range setting for a float or int property.
func create_range_for(object: Object, prop: Dictionary, value: Variant) -> Range:
	if prop.hint == PROPERTY_HINT_RANGE:
		var slider := HSlider.new()
		var strs: PackedStringArray = prop.hint_string.split(',')
		slider.min_value = strs[0].to_float()
		slider.max_value = strs[1].to_float()
		if strs.size() > 2:
			slider.step = strs[2].to_float()
		else:
			slider.step = 0.005 if prop.type == TYPE_FLOAT else 1.0
		slider.value = value
		slider.value_changed.connect(func(v: float):
			object.set(prop.name, v)
			Game.setting_changed.emit(prop.name, v)
		)
		return slider
	else:
		var spinbox := SpinBox.new()
		spinbox.value = value
		spinbox.value_changed.connect(func(v: float):
			object.set(prop.name, v)
			Game.setting_changed.emit(prop.name, v)
		)
		return spinbox


## Creates an dropdown setting for an enum property.
func create_dropdown_for(object: Object, prop: Dictionary, value: Variant) -> OptionButton:
	var option := OptionButton.new()
	var enum_map := {}

	for opt: String in prop.hint_string.split(','):
		var kv := opt.split(':')

		if kv.size() == 2:
			enum_map[kv[0]] = kv[1].to_int()
		else:
			enum_map[kv[0]] = option.item_count
			
		option.add_item(kv[0], enum_map[kv[0]])

	if value is int:
		# if value is int, values are id's
		option.selected = option.get_item_index(value)
		option.item_selected.connect(func(idx: int):
			var item: int = option.get_item_id(idx)
			object.set(prop.name, item)
			Game.setting_changed.emit(prop.name, item)
		)
	else:
		# if value is string, values are names
		assert(value, 'cannot have empty value string enum')
		option.selected = option.get_item_index(enum_map[value])
		option.item_selected.connect(func(idx: int):
			var item: String = enum_map.find_key(option.get_item_id(idx))
			object.set(prop.name, item)
			Game.setting_changed.emit(prop.name, item)
		)

	return option


## Creates a input setting for a string property.
func create_text_input_for(object: Object, prop: Dictionary, value: String) -> LineEdit:
	var line_edit := LineEdit.new()
	line_edit.text = value
	line_edit.text_changed.connect(func(v: String):
		object.set(prop.name, v)
		Game.setting_changed.emit(prop.name, v)
	)
	return line_edit