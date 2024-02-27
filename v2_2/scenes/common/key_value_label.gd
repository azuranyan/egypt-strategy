@tool
class_name KeyValueLabel
extends HBoxContainer


@export var key: String:
	set(value):
		key = value
		if not is_node_ready():
			await ready
		key_label.text = key
		key_label.queue_redraw()

@export var value: String:
	set(_value):
		value = _value
		if not is_node_ready():
			await ready
		value_label.text = _value
		key_label.queue_redraw()


@onready var key_label: Label = %KeyLabel
@onready var value_label: Label = %ValueLabel