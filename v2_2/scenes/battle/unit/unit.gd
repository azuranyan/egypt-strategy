class_name Unit
extends MapObject

## Dictates how his unit chooses its actions.
enum Behavior {
	## UnitState is controlled by player.
	PLAYER_CONTROLLED,
	
	## Always advances towards nearest target and attacks.
	NORMAL_MELEE,
	
	## Always attacks nearest target, flees adjacent attackers.
	NORMAL_RANGED,
	
	## Always advances and tries to attack target with lowest HP.
	EXPLOITATIVE_MELEE,
	
	## Always tries to attack targets that would not be able to retaliate.
	EXPLOITATIVE_RANGED,
	
	## Holds 1 spot and attacks any who approach.
	DEFENSIVE_MELEE,
	
	## Holds 1 spot and attacks any who approach, flees adjacent attackers.
	DEFENSIVE_RANGED,
	
	## Heals allies and self, runs away from attackers.
	SUPPORT_HEALER,
	
	## Aims to inflict as many enemies with negative status as possible, will choose different target if already afflicted.
	STATUS_APPLIER,
}


@export var unit_type: UnitType


func _to_string() -> String:
	return str(unit_type.character_info)
