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

var _state: UnitState:
	set(value):
		_state = value
		if not is_node_ready():
			await ready
		# TOD


func _to_string() -> String:
	return display_name
	
	
func _update_position():
	super._update_position()
	if _state:
		_state.map_position = map_position
	
	
func get_state() -> UnitState:
	return _state
	
	
func load_from_map():
	var empire := Game.get_empire_by_leader(owner_name)
	_state = UnitState.new(unit_type, {
		display_name = self.display_name,
		display_icon = self.display_icon,
		heading = self.heading,
		owner_id = empire.id if empire else -1,
	})
	

#region UnitState functions
## Returns true if special is unlocked.
func is_special_unlocked() -> bool:
	return _state.is_special_unlocked()
	
	
## Returns true if this unit is player owned.
func is_player_owned() -> bool:
	return _state.is_player_owned()
	

## Returns true if the other unit is an ally.
func is_ally(other: Unit) -> bool:
	return _state.is_ally(other.state)
	

## Returns true if the other unit is an enemy.
func is_enemy(other: Unit) -> bool:
	return _state.is_enemy(other.state)

	
## Returns true if this unit can move.
func can_move() -> bool:
	return _state.can_move()

	
## Returns true if this unit can attack.
func can_attack() -> bool:
	return _state.can_attack()


## Returns true if this unit can act.
func can_act() -> bool:
	return _state.can_act()


## Returns true if this unit has taken any actions.
func has_taken_action() -> bool:
	return _state.has_taken_action()


## Returns true if alive.
func is_alive() -> bool:
	return _state.is_alive()


## Returns true if dead.
func is_dead() -> bool:
	return _state.is_dead()


## Returns true if unit is on standby.
func is_standby() -> bool:
	return _state.is_standby()


## Returns the path to reach target cell.
func pathfind_cell(context: BattleContext, target: Vector2) -> PackedVector2Array:
	return _state.pathfind_cell(context, target)
	
	
## Returns an array of cells this unit can path through.
func get_pathable_cells(context: BattleContext, use_mov_stat := false) -> PackedVector2Array:
	return _state.get_pathable_cells(context, use_mov_stat)


## Returns true if cell is pathable.
func is_pathable(context: BattleContext, which_cell: Vector2) -> bool:
	return _state.is_pathable(context, which_cell)


## Returns true if cell is placeable.
func is_placeable(context: BattleContext, which_cell: Vector2) -> bool:
	return _state.is_placeable(context, which_cell)
#endregion UnitState functions
