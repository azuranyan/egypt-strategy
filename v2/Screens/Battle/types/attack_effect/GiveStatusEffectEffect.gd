extends AttackEffect
class_name GiveStatusEffectEffect


@export_enum('PSN', 'STN', 'VUL', 'BLK') var effect: String

@export var duration: int


func apply(_battle: Battle, _user: Unit, _attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	target_unit.add_status_effect(Globals.status_effect[effect], duration)
	
	
func _default_description() -> String:
	match effect:
		'BLK':
			return 'Grants %s.' % effect
		_:
			return 'Inflicts %s.' % effect


func _default_animation() -> String:
	return 'none'
