class_name BattleContext
extends Resource
## The runtime battle context.


@export var state: Battle.State:
	set(value):
		state = value
		assert(state != Battle.State.ENDING)
@export var on_turn: Empire
@export var result: Battle.Result

@export var attacker: Empire
@export var defender: Empire
@export var territory: Territory
@export var map_id: int

@export var empire_units := {}

var battle: Battle
var map: Map


## Returns the ai-controlled empire.
func ai() -> Empire:
	return attacker if not attacker.is_player_owned() else defender
	
	
## Returns the player-controlled empire.
func player() -> Empire:
	return attacker if attacker.is_player_owned() else defender
	
	
## Returns the empire by leader name.
func get_empire(leader_name: String) -> Empire:
	if leader_name == attacker.leader_name():
		return attacker
	if leader_name == defender.leader_name():
		return defender
	return null
	
	
## Returns true if the battle has started.
func battle_started() -> bool:
	# started -> map loaded -> prep -> battle
	return state == Battle.State.BATTLE
	
	
## Returns true if battle should end.
func should_end() -> bool:
	return state == Battle.State.ENDING
	
	
## Returns the winner of the battle or null if no results yet.
func get_winner() -> Empire:
	match result:
		Battle.Result.ATTACKER_VICTORY:
			return attacker
		Battle.Result.DEFENDER_VICTORY:
			return defender
		Battle.Result.ATTACKER_WITHDRAW:
			return defender
		Battle.Result.DEFENDER_WITHDRAW:
			return attacker
	return null
			
			
## Returns the number of units the empire has on field.
func get_unit_count(empire: Empire) -> int:
	var count := 0
	for unit in get_empire_units(empire):
		count += 1
	return count


## Returns an iterator to the units owned by this empire.
func get_empire_units(empire: Empire, include_standby := false) -> UnitIterator:
	return UnitIterator.new(empire_units[empire], include_standby)


## Returns the unit at cell.
func get_unit_at(cell: Vector2) -> Unit:
	for obj in get_objects_at(cell):
		if (obj is Unit) and (obj.map_position == cell):
			return obj.unit
	return null


## Returns true if cell is occupied by a unit.
func is_occupied(cell: Vector2) -> bool:
	return get_unit_at(cell) != null


## Returns true if unit can path over cell.
func is_pathable(unit: Unit, cell: Vector2) -> bool:
	for obj in get_objects_at(cell):
		var pathable := obj.components.get(PathableComponent.GROUP_ID) as PathableComponent
		if (pathable != null) and not pathable.is_pathable(self, unit):
			return false
	return true


## Returns true if cell is placeable.
func is_placeable(unit: Unit, cell: Vector2) -> bool:
	return not is_occupied(cell) and is_pathable(unit, cell)


## Returns the objects at cell.
func get_objects_at(cell: Vector2) -> Array[MapObject]:
	return battle.level.get_objects_at(cell)
	

## Returns all the pathables.
func get_pathables() -> Array[Node]:
	return battle.get_tree().get_nodes_in_group('Pathables')


## Returns all the detectors.
func get_detectors() -> Array[Node]:
	return battle.get_tree().get_nodes_in_group('Detectors')


## Returns all the pathables at cell.
func get_pathables_at(cell: Vector2) -> Array[PathableComponent]:
	var arr: Array[PathableComponent] = []
	for pathable in get_pathables():
		if pathable.map_object.cell() == cell:
			arr.append(pathable)
	return arr


## Returns all the detectors at cell.
func get_detectors_at(cell: Vector2) -> Array[DetectorComponent]:
	var arr: Array[DetectorComponent] = []
	for detectable in get_detectors():
		if detectable.map_object.cell() == cell:
			arr.append(detectable)
	return arr


## Returns the world bounds.
func world_bounds() -> Rect2:
	return Util.bounds(map.world.map_size)

	
## Tests the evaluators and returns the first valid [enum Battle.Result].
func evaluate_result() -> Battle.Result:
	for eval in map.evaluators:
		var eval_result := eval.evaluate(self)
		if eval_result != Battle.Result.NONE:
			return eval_result
	return Battle.Result.NONE
	
	
## Iterates through units.
class UnitIterator:
	var arr: Array[Unit]
	var include_standby: bool
	var idx: int

	func _init(_arr: Array[Unit], _include_standby: bool):
		arr = _arr
		include_standby = _include_standby

	func should_continue() -> bool:
		return idx < arr.size()

	func _iter_init(_arg) -> bool:
		idx = 0
		return should_continue()

	func _iter_next(_arg) -> bool:
		while should_continue():
			if include_standby or not arr[idx].is_standby():
				continue
			idx += 1
		return should_continue()

	func _iter_get(_arg) -> Unit:
		return arr[idx]
