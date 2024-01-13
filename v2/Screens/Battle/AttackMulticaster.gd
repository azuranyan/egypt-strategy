class_name AttackMulticaster
extends Node

signal done

@export var battle: Battle

var counter := 0


## TODO Non-reentrant!
func use_attack_multicast(unit: Unit, attack: Attack, targets: Array[Vector2], rotations: Array[float]):
	var uuid := 'AttackMulticaster%s_%s' % [self.get_instance_id(), randi()]
	for i in targets.size():
		var seq := func():
			await battle._apply_attack_effects(unit, attack, targets[i], rotations[i])
			_decrement()
		seq.call_deferred()
		
		
func _decrement():
	counter -= 1
	if counter <= 0:
		done.emit()
	
