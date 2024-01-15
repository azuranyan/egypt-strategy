class_name RandomEffect
extends AttackEffect


@export var effects: Array[AttackEffect]
@export var weights: Array[float]


func apply(battle: Battle, user: Unit, attack: Attack, target_cell: Vector2i, target_unit: Unit) -> void:
	if effects.size() <= 0:
		return
	
	var chances := PackedVector2Array()
	var sum: float = 0
	for weight in weights:
		var low: float = sum
		var high: float = sum + weight
		chances.append(Vector2(low, high))
		sum += weight
	
	var roll := randf_range(0, sum)
	var eff := effects[0] # will use 0 if not found, in case of some fp error
	for i in chances.size():
		if roll >= chances[i].x and roll < chances[i].y:
			eff = effects[i]
	
	eff.apply(battle, user, attack, target_cell, target_unit)
