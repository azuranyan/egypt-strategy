class_name UnitType
extends Resource


@export var unit_model: PackedScene

@export_group("Unit Stats")

@export var stats := {
	maxhp = 0,
	mov = 0,
	dmg = 0,
	rng = 0,
}

@export var stat_growth_1 := {
	maxhp = 0,
	mov = 0,
	dmg = 0,
	rng = 0,
}	

@export var stat_growth_2 := {
	maxhp = 0,
	mov = 0,
	dmg = 0,
	rng = 0,
}

@export var basic_attack: Attack

@export var special_attack: Attack


func _to_string() -> String:
	return '<UnitType#%s>' % self.get_instance_id()
 
