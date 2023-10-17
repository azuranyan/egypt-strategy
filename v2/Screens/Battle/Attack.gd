extends Resource
class_name Attack2


signal attack_sequence_started(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit])


enum Target {
	ENEMY,
	ALLY,
	SELF,
}


## Data when attack is used.
class AttackInfo:
	
	## The user of the attack.
	var user: Unit
	
	## The attack used.
	var attack: Attack
	
	## The exact cell the attack targetted.
	var target_cell: Vector2i
	
	## The list of cells in the target aoe.
	var target_cells: Array[Vector2i]
	
	## The list of units in the target aoe.
	var target_units: Array[Unit]
	

## Effect of an attack.
class AttackEffect:
	
	func execute(battle: Battle, att: AttackInfo) -> void:
		for u in att.target_units:
			apply(battle, att, u)
		
	
	func apply(battle: Battle, att: AttackInfo, target: Unit) -> void:
		pass
		
		
## Damages a unit by the specified amount.
class DamageEffect extends AttackEffect:
	var amount: int
	
	
	func _init(amount: int):
		self.amount = amount
	
	
	func apply(battle: Battle, att: AttackInfo, target: Unit) -> void:
		battle.damage_unit(target, att.user, amount)
	
	
## Heals a unit by the specified amount.
class HealEffect extends AttackEffect:
	var amount: int
	
	
	func _init(amount: int):
		self.amount = amount
	
	
	func apply(battle: Battle, att: AttackInfo, target: Unit) -> void:
		battle.damage_unit(target, att.user, -amount)
	

## Instantly moves the unit to a given pos.
class MoveEffect extends AttackEffect:
	var pos_provider: Callable
	
	
	func _init(pos_provider: Callable):
		self.pos_provider = pos_provider
	
	
	func apply(battle: Battle, att: AttackInfo, target: Unit) -> void:
		var new_pos: Vector2i = pos_provider.call(battle, att, target)
		target.map_pos = new_pos
	
	
## User charges into the target.
class ChargeEffect extends AttackEffect:
	func execute(battle: Battle, att: AttackInfo) -> void:
		pass
	
	
class GiveStatusEffectEffect extends AttackEffect:
	func execute(battle: Battle, att: AttackInfo) -> void:
		pass
	

class RemoveStatusEffectEffect extends AttackEffect:
	func execute(battle: Battle, att: AttackInfo) -> void:
		pass
	

class ChanceEffect extends AttackEffect:
	func execute(battle: Battle, att: AttackInfo) -> void:
		pass
	

class ConditionEffect extends AttackEffect:
	func execute(battle: Battle, att: AttackInfo) -> void:
		pass
		
	
class FilteredEffect extends AttackEffect:
	func execute(battle: Battle, att: AttackInfo) -> void:
		pass
