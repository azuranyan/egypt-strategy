@tool
class_name PlaySoundEffect
extends AttackEffect
## Represents an effect that plays a sound effect.


enum Type {
	## Plays a preset sound effect.
	PRESET,

	## Plays an audio stream.
	CUSTOM,
}


## The type of the sound effect.
@export var type := Type.PRESET:
	set(value):
		type = value
		preset = ''
		audio_stream = null
		notify_property_list_changed()

		
## The preset name.
var preset: StringName

## The audio stream.
var audio_stream: AudioStream


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			name = 'preset',
			type = TYPE_STRING_NAME,
			usage = PROPERTY_USAGE_DEFAULT if type == Type.PRESET else PROPERTY_USAGE_NONE,
		},
		{
			name = 'audio_stream',
			type = TYPE_OBJECT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			hint_string = 'AudioStream',
			usage = PROPERTY_USAGE_DEFAULT if type == Type.CUSTOM else PROPERTY_USAGE_NONE,
		}
	]