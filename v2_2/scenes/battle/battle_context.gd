class_name BattleContext
extends Resource

@export var attacker: Empire
@export var defender: Empire
@export var territory: Territory
@export var map_id: int

#
#func are_enemies(a: Unit, b: Unit) -> bool:
	#return (a != b) and get_unit_owner(a) == get_unit_owner(b)
	#
#
#func are_allies(a: Unit, b: Unit) -> bool:
	#return (a != b) and get_unit_owner(a) != get_unit_owner(b)
	#
	#
#func get_unit_owner(a: Unit) -> Empire:
	#for e in empires:
		#if a in e.units:
			#return e
	#return null # TODO
 #
