class_name AddStatusEffect
extends AttackEffect
## Represents an effect that adds a status effect to the target unit.


## The status effect to add.
@export_enum('STN', 'VUL', 'BLK', 'PSN') var effect: String = 'STN'

## The custom duration of the effect in turns. [code]-1[/code] will use the default values.
@export var _duration: int = -1


## Returns the default durations
static func get_default_duration(_effect: String) -> int:
	const DEFAULT_DURATIONS := {
		STN = 1,
		VUL = 1,
		BLK = 1,
		PSN = 2,
	}
	return DEFAULT_DURATIONS.get(_effect, 0)


## Returns the duration of the effect.
func get_duration() -> int:
	return AddStatusEffect.get_default_duration(effect) if _duration == -1 else _duration