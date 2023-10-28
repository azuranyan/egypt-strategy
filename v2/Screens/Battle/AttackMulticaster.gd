extends Node
class_name AttackMulticaster


signal done


var counter := 0


## Non-reentrant!
func use_attack_multicast(unit: Unit, attack: Attack, target_cells: Array[Vector2i], target_rotation: float):
	var uuid := 'AttackMulticaster%s_%s' % [self.get_instance_id(), randi()]
	for target_cell in target_cells:
		var seq := func():
			await Globals.battle.use_attack(unit, attack, target_cell, target_rotation)
			_decrement()
		seq.call_deferred()
		
		
func _decrement():
	counter -= 1
	if counter <= 0:
		done.emit()
	
