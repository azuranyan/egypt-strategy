class_name UnitType
extends Resource

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

@export var character_info: CharacterInfo

@export var sprite_frames: SpriteFrames = preload("res://scenes/battle/unit/data/placeholder_sprite_frames.tres")

@export var behavior: Behavior

@export_group("Unit Stats")

@export var stats := {
	maxhp = 5,
	mov = 3,
	dmg = 2,
	rng = 1,
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


