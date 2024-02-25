@tool
class_name WaitEffect
extends AttackEffect
## Represents an effect that waits for a set amount of time or a signal.


## The type of wait effect.
@export_enum('duration', 'signal') var type: String:
	set(value):
		type = value
		notify_property_list_changed()

## The amount of wait time in seconds.
var duration: float

## The signal object.
var signal_object_path: NodePath

## The signal to wait for.
var signal_name: StringName


func _get_property_list() -> Array[Dictionary]:
	var duration_usage := PROPERTY_USAGE_DEFAULT if type == 'duration' else PROPERTY_USAGE_NONE
	var signal_usage := PROPERTY_USAGE_DEFAULT if type == 'signal' else PROPERTY_USAGE_NONE
	
	return [
		{
			name = 'duration',
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = '0.001,60,or_greater',
			usage = duration_usage,
		},
		{
			name = 'signal_object_path',
			type = TYPE_NODE_PATH,
			usage = signal_usage,
		},
		{
			name = 'signal_name',
			type = TYPE_STRING_NAME,
			usage = signal_usage,
		},
	]