extends Resource
class_name AttackEffect


## Convenience function to convert stat property name to standardized strings.
static func stat_to_str(stat: String) -> String:
	match stat:
		'maxhp':
			return 'MaxHP'
		'bond':
			return 'Bond'
		_:
			return stat.capitalize()


## The target of this effect.
@export_enum('Enemy', 'Ally', 'Self') var target: int

## A custom description for this effect.
@export var custom_description: String

## A custom animation for this effect.
@export var custom_animation: String


## Returns a detailed description of the effect.
func get_description() -> String:
	if custom_description == '':
		return _default_description()
	else:
		return custom_description
	
	
## Returns the effect that will be spawned on target.
func get_animation() -> String:
	if custom_animation == '':
		return _default_animation()
	else:
		return custom_animation
		

## Applies the attack effect.
func apply(battle: Battle, user: Unit, attack: Attack, target_cell: Vector2i, target_unit: Unit) -> void:
	attack.effect_completed(self)
	
	
## Type of effect hint for the engine.
func get_effect_hint() -> String:
	return 'attack'
	
	
## Returns a default description if custom description is not provided.
func _default_description() -> String:
	return ''


## Returns a default effect string if no custom effect string is given.
func _default_animation() -> String:
	return ''
