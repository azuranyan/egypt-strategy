@tool
class_name UnitState
extends Resource
## The saveable unit state resource and controller.


@export_group("Character")

## The blueprint unit type of this unit.
@export var unit_type: UnitType

## Custom display name.
@export var display_name: String

## Custom display icon.
@export var display_icon: Texture

## The scale of the unit model.
@export var model_scale: Vector2

## Unit behavior.
@export var behavior: Unit.Behavior

@export_group("Stats")

## UnitState stats. Not meant to be changed directly.
@export var stats := {
	maxhp = 0,
	hp = 0,
	mov = 0,
	dmg = 0,
	rng = 0,
}

## Bond level.
@export var bond: int

## Overrides bond level and unlocks special.
@export var special_unlocked: bool

## List of buffs and debuffs.
@export var status_effects: Dictionary

@export_group("Movement")

## The direction this unit is facing.
@export var heading: Map.Heading

## The map position.
@export var map_position: Vector2

## This unit's walk speed.
@export var walk_speed: float

## Objects this unit can phase through.
@export var phase: int
			
@export_group("Others")

## The empire this unit belongs to.
@export var empire_id: int

## Action flags made on the turn.
@export var turn_flags: int

## Whether unit is selectable or not.
@export var selectable: bool

## The unit state.
@export var state := 'idle'


## Initializer
func _init(_unit_type: UnitType = null, prop := {}):
	if not _unit_type:
		_unit_type = UnitType.PLACEHOLDER

	unit_type = _unit_type
	display_name = prop.get('display_name', unit_type.character_info.name)
	display_icon = prop.get('display_icon', unit_type.character_info.portrait)
	model_scale = prop.get('model_scale', Vector2.ONE)
	behavior = prop.get('behavior', unit_type.behavior)

	stats.maxhp = unit_type.stats.maxhp
	stats.hp = unit_type.stats.maxhp
	stats.mov = unit_type.stats.mov
	stats.dmg = unit_type.stats.dmg
	stats.rng = unit_type.stats.rng
	bond = prop.get('bond', 0)
	special_unlocked = prop.get('special_unlocked', false)
	status_effects = {}

	heading = prop.get('heading', Map.Heading.EAST)
	map_position = prop.get('map_position', Vector2.ZERO if Engine.is_editor_hint() else Map.OUT_OF_BOUNDS)
	walk_speed = prop.get('walk_speed', 200)
	phase = prop.get('phase', Unit.PHASE_NONE)
	
	if empire_id in prop:
		empire_id = prop.get('empire_id')
	turn_flags = prop.get('turn_flags', Unit.TURN_NEW)
	selectable = prop.get('selectable', true)
	state = 'idle'
	

## Returns the base stats.
func base_stats() -> Dictionary:
	return unit_type.stats


## Returns the cell position.
func cell() -> Vector2:
	return Vector2(roundf(map_position.x), roundf(map_position.y))


## Returns true if special is unlocked.
func is_special_unlocked() -> bool:
	return special_unlocked or bond >= 2
	
	
## Returns true if this unit is player owned.
func is_player_owned() -> bool:
	return get_empire().is_player_owned()
	
	
## Returns the empire this unit belongs to.
func get_empire() -> Empire:
	assert(empire_id >= -1 and empire_id < Game.empires.size())
	return Game.empires[empire_id] if empire_id != -1 else null


## Returns true if the other unit is an ally.
func is_ally(other: UnitState) -> bool:
	return (other != self) and (other.empire_id == empire_id)
	

## Returns true if the other unit is an enemy.
func is_enemy(other: UnitState) -> bool:
	return (other != self) and (other.empire_id != empire_id)

	
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
	return stats.hp > 0


## Returns true if dead.
func is_dead() -> bool:
	return stats.hp <= 0


## Returns true if unit is on standby.
func is_standby() -> bool:
	return map_position == Map.OUT_OF_BOUNDS

#
### Returns the path to reach target cell.
#func pathfind_cell(context: BattleContext, target: Vector2) -> PackedVector2Array:
	## don't go through all that trouble if target == cell
	#if target == cell():
		#return [target]
#
	#var pathable_cells := get_pathable_cells(context, false)
#
	## append the target in pathable list so we can path to it
	#if target not in pathable_cells:
		#pathable_cells.append(target)
#
	## pathfind
	#var pathfinder := PathFinder.new(context.map.world, pathable_cells)
	#var path := pathfinder.calculate_point_path(cell(), target)
	#
	## starting from the end, trim off path until we get a spot we can land on
	#for i in range(path.size() - 1, -1, -1):
		#if (not context.is_occupied(path[i])) and (Util.cell_distance(cell(), path[i]) <= stats.mov):
			#return path.slice(0, i + 1)
			#
	#return path
	#
#
### Returns an array of cells this unit can path through.
#func get_pathable_cells(context: BattleContext, use_mov_stat := false) -> PackedVector2Array:
	#var cond := func(x):
		#return context.is_pathable(self, x)
	#return Util.flood_fill(cell(), stats.mov if use_mov_stat else 20, context.world_bounds(), cond)
