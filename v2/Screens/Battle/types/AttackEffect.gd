extends Resource
class_name AttackEffect


static func stat_to_str(stat: String) -> String:
	match stat:
		'maxhp':
			return 'MaxHP'
		'bond':
			return 'Bond'
		_:
			return stat.capitalize()


@export var target: NeoAttack.Target

@export var custom_description: String

@export var custom_animation: String

		
func execute(battle: Battle, user: Unit, attack: Attack, target_cell: Vector2i, target_units: Array[Unit]) -> void:
	for u in target_units:
		_apply(battle, user, attack, target_cell, u)
	
	
func get_description() -> String:
	if custom_description == '':
		return _default_description()
	else:
		return custom_description
	
	
func get_animation() -> String:
	if custom_animation == '':
		return _default_animation()
	else:
		return custom_animation
		

func _apply(battle: Battle, user: Unit, attack: Attack, target_cell: Vector2i, target_unit: Unit) -> void:
	pass
	
	
func _default_description() -> String:
	return ''


func _default_animation() -> String:
	return ''
