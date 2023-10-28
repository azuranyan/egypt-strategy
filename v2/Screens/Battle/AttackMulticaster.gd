extends Node
class_name AttackMulticaster


signal done


var counter := 0


func use_attack_multicast(unit: Unit, attack: Attack, target_cells: Array[Vector2i], target_rotation: float):
	var uuid := 'AttackMulticaster%s_%s' % [self.get_instance_id(), randi()]
	for target_cell in target_cells:
		var p := ParallelAttack.new(unit, attack, target_cell, target_rotation)
		add_child(p, true)
		p.add_to_group(uuid)
		p.finished.connect(_on_parallel_attack_finished)
	counter = target_cells.size()
	
	get_tree().call_group(uuid, 'use')
	get_tree().call_group(uuid, 'queue_free')
		
		
func _on_parallel_attack_finished():
	counter -= 1
	if counter <= 0:
		done.emit()
	
		
class ParallelAttack extends Node:
	signal finished
	var unit: Unit
	var attack: Attack
	var target_cell: Vector2i
	var target_rotation: float
	
	func _init(unit: Unit, attack: Attack, target_cell: Vector2i, target_rotation: float):
		self.unit = unit
		self.attack = attack
		self.target_cell = target_cell
		self.target_rotation = target_rotation
		
	func use():
		await Globals.battle.use_attack(unit, attack, target_cell, target_rotation)
		finished.emit()
