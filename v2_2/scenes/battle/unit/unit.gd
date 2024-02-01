@tool # tool so it runs _init
class_name Unit
extends Resource
## The saveable unit state resource and controller.

# Turn flags

## New turn.
const TURN_NEW := 0

## Unit moved bitflag.
const TURN_MOVED := 1 << 0

## Unit attacked bitflag.
const TURN_ATTACKED := 1 << 1

## Unit attacked bitflag.
const TURN_DONE := 1 << 2

# Phase flags

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

## The state of a unit.
enum State {INVALID, IDLE, WALKING, ATTACKING, HURT, DYING, DEAD}

@export_group("Character")

## The character representing this unit.
@export var chara: CharacterInfo

## The blueprint unit type of this unit.
@export var unit_type: UnitType

## Custom display name. If set, will override the name from character info.
@export var display_name: String

## Custom display icon. If set, will override the portrait from character info.
@export var display_icon: Texture

## The scale of the unit model.
@export var model_scale: Vector2 = Vector2.ONE

@export_group("State")

## Unit behavior.
@export var behavior: Behavior

## The unit state.
@export var state: State

## Action flags made on the turn.
@export_flags('Moved:1', 'Attacked:2', 'Done:4') var turn_flags: int

## Whether unit is selectable or not.
@export var selectable: bool = true

@export_subgroup("Stats")

## UnitState stats. Not meant to be changed directly.
@export var stats := {
	maxhp = 1,
	hp = 1,
	mov = 1,
	dmg = 1,
	rng = 1,
}

## Bond level.
@export var bond: int

## Overrides bond level and unlocks special.
@export var _special_unlocked: bool

## List of buffs and debuffs.
@export var status_effects: Dictionary

@export_subgroup("Movement")

## The direction this unit is facing.
@export var heading: Map.Heading

## The map position.
@export var map_position: Vector2

## This unit's walk speed.
@export var walk_speed: float = 200

## Objects this unit can phase through.
@export_flags('Enemies:1', 'Doodads:2', 'Terrain:4') var phase_flags: int
			

func _to_string() -> String:
	return '<Unit#%s>' % self.get_instance_id()
 

func _init(_chara: CharacterInfo = null, _unit_type: UnitType = null, prop := {}):
	chara = _chara
	unit_type = _unit_type
	display_name = prop.get('display_name', chara.name if display_name == "" and chara else display_name)
	display_icon = prop.get('display_icon', chara.portrait if display_icon == null and chara else display_icon)
	model_scale = prop.get('model_scale', Vector2.ONE)
	behavior = prop.get('behavior', Behavior.PLAYER_CONTROLLED)
	
	stats.maxhp = prop.get('maxhp', unit_type.stats.maxhp if unit_type else 1)
	stats.hp = prop.get('hp', stats.maxhp)
	stats.mov = prop.get('mov', unit_type.stats.mov if unit_type else 1)
	stats.dmg = prop.get('dmg', unit_type.stats.dmg if unit_type else 1)
	stats.rng = prop.get('rng', unit_type.stats.rng if unit_type else 1)
	bond = prop.get('bond', 0)
	_special_unlocked = prop.get('special_unlocked', false)
	status_effects = prop.get('status_effects', {})
	
	heading = prop.get('heading', Map.Heading.EAST)
	map_position = prop.get('map_position', Map.OUT_OF_BOUNDS if not Engine.is_editor_hint() else Vector2.ZERO)
	walk_speed = prop.get('heading', 200)
	phase_flags = prop.get('phase_flags', PHASE_NONE)
	
	turn_flags = prop.get('turn_flags', TURN_NEW)
	selectable = prop.get('selectable', true)
	state = prop.get('state', State.INVALID)
	
	
## Returns the base stats.
func base_stats() -> Dictionary:
	return unit_type.stats


## Returns the cell position.
func cell() -> Vector2:
	return Vector2(roundf(map_position.x), roundf(map_position.y))


## Returns true if special is unlocked.
func is_special_unlocked() -> bool:
	return _special_unlocked or bond >= 2
	

## Returns true if this unit can move.
func can_move() -> bool:
	return turn_flags & (Unit.TURN_DONE | Unit.TURN_ATTACKED | Unit.TURN_MOVED) == 0
	
	
## Returns true if this unit can attack.
func can_attack() -> bool:
	return turn_flags & (Unit.TURN_DONE | Unit.TURN_ATTACKED) == 0


## Returns true if this unit can act.
func can_act() -> bool:
	if (turn_flags & Unit.TURN_DONE == 0):
		return false
	return (turn_flags & Unit.TURN_ATTACKED == 0) or (turn_flags & Unit.TURN_MOVED == 0)


## Returns true if this unit has taken any actions.
func has_taken_action() -> bool:
	return turn_flags & (Unit.TURN_ATTACKED | Unit.TURN_MOVED) != 0


## Returns true if alive.
func is_alive() -> bool:
	return not ((state == State.INVALID) or (state == State.DEAD))


## Returns true if dead.
func is_dead() -> bool:
	return (state != State.INVALID) and (state == State.DEAD)


## Returns true if unit is on standby.
func is_standby() -> bool:
	return map_position == Map.OUT_OF_BOUNDS

##
#### Returns the path to reach target cell.
##func pathfind_cell(context: BattleContext, target: Vector2) -> PackedVector2Array:
	### don't go through all that trouble if target == cell
	##if target == cell():
		##return [target]
##
	##var pathable_cells := get_pathable_cells(context, false)
##
	### append the target in pathable list so we can path to it
	##if target not in pathable_cells:
		##pathable_cells.append(target)
##
	### pathfind
	##var pathfinder := PathFinder.new(context.map.world, pathable_cells)
	##var path := pathfinder.calculate_point_path(cell(), target)
	##
	### starting from the end, trim off path until we get a spot we can land on
	##for i in range(path.size() - 1, -1, -1):
		##if (not context.is_occupied(path[i])) and (Util.cell_distance(cell(), path[i]) <= stats.mov):
			##return path.slice(0, i + 1)
			##
	##return path
	##
##
#### Returns an array of cells this unit can path through.
##func get_pathable_cells(context: BattleContext, use_mov_stat := false) -> PackedVector2Array:
	##var cond := func(x):
		##return context.is_pathable(self, x)
	##return Util.flood_fill(cell(), stats.mov if use_mov_stat else 20, context.world_bounds(), cond)
