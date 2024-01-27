@tool
class_name Unit
extends MapObject

## New turn.
const TURN_NEW := 0

## Unit moved bitflag.
const TURN_MOVED := 1 << 0

## Unit attacked bitflag.
const TURN_ATTACKED := 1 << 1

## Unit attacked bitflag.
const TURN_DONE := 1 << 2


## Default walk (phase friendly units).
const PHASE_NONE = 0
	
## Ignores enemies.
const PHASE_ENEMIES = 1 << 0
	
## Ignores doodads.
const PHASE_DOODADS = 1 << 1
	
## Ignores terrain.
const PHASE_TERRAIN = 1 << 2
	
## Ignores all pathing and placement restrictions.
const PHASE_NO_CLIP = 1 << 3


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

@export_group("Editor")
@export var unit_type: UnitType
@export var display_name: String
@export var display_icon: Texture
@export var heading: Map.Heading
@export var owner_name: String

var _state: UnitState

func _to_string() -> String:
	return display_name
	
	

