@tool
class_name HealEffect
extends AttackEffect
## Represents an effect that heals the target.


## Flat heal amount.
@export var amount: int

## The stat to use.
@export_enum('none', 'maxhp', 'hp', 'move', 'damage', 'range', 'bond') var stat: String = "none":
	set(value):
		stat = value
		if stat == 'none':
			stat_multiplier = 0
		elif stat_multiplier == 0:
			stat_multiplier = 1
		notify_property_list_changed()

## Stat multiplier.
var stat_multiplier: float


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			name = 'stat_multiplier',
			type = TYPE_FLOAT,
			usage = PROPERTY_USAGE_DEFAULT if stat != 'none' else PROPERTY_USAGE_NO_EDITOR,
		}
	]