@tool
class_name Unit
extends MapObject


signal unit_type_changed
signal property_changed(prop: StringName)
signal stat_changed(stat: StringName)

signal status_effect_added(effect: String)
signal status_effect_removed(effect: String)
signal status_effect_changed(effect: String)

signal attack_started(attack_state: AttackState)
signal attack_finished

signal walking_started(cell: Vector2)
signal walking_finished

signal state_changed(old_state: String, new_state: String)


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
	SUPPORT_MELEE,
	
	## Aims to inflict as many enemies with negative status as possible, will choose different target if already afflicted.
	STATUS_APPLIER,
}


@export var state := UnitState.new():
	set(value):
		state = value
		if not is_node_ready():
			await ready
		map_position = state.map_position
		$Sprite.scale = state.model_scale
		$Sprite/AnimatedSprite2D.sprite_frames = state.unit_type.sprite_frames
		%NameLabel.text = state.display_name
		_on_stat_changed('hp')
		

var driver: UnitDriver


func _update_position():
	super._update_position()
	if state:
		state.map_position = map_position
	

#region UnitState functions
### Returns the cell position.
#func cell() -> Vector2:
	#return state.cell()

	
## Returns true if special is unlocked.
func is_special_unlocked() -> bool:
	return state.is_special_unlocked()
	
	
## Returns true if this unit is player owned.
func is_player_owned() -> bool:
	return state.is_player_owned()
	

## Returns true if the other unit is an ally.
func is_ally(other: Unit) -> bool:
	return state.is_ally(other.state)
	

## Returns true if the other unit is an enemy.
func is_enemy(other: Unit) -> bool:
	return state.is_enemy(other.state)

	
## Returns true if this unit can move.
func can_move() -> bool:
	return state.can_move()

	
## Returns true if this unit can attack.
func can_attack() -> bool:
	return state.can_attack()


## Returns true if this unit can act.
func can_act() -> bool:
	return state.can_act()


## Returns true if this unit has taken any actions.
func has_taken_action() -> bool:
	return state.has_taken_action()


## Returns true if alive.
func is_alive() -> bool:
	return state.is_alive()


## Returns true if dead.
func is_dead() -> bool:
	return state.is_dead()


## Returns true if unit is on standby.
func is_standby() -> bool:
	return state.is_standby()


## Returns the path to reach target cell.
func pathfind_cell(context: BattleContext, target: Vector2) -> PackedVector2Array:
	return state.pathfind_cell(context, target)
	
	
## Returns an array of cells this unit can path through.
func get_pathable_cells(context: BattleContext, use_mov_stat := false) -> PackedVector2Array:
	return state.get_pathable_cells(context, use_mov_stat)


## Returns true if cell is pathable.
func is_pathable(context: BattleContext, which_cell: Vector2) -> bool:
	return state.is_pathable(context, which_cell)


## Returns true if cell is placeable.
func is_placeable(context: BattleContext, which_cell: Vector2) -> bool:
	return state.is_placeable(context, which_cell)
#endregion UnitState functions


## Sets the stat to a new value.
func set_stat(stat: StringName, value: int):
	if stat == 'hp':
		state.stats.hp = clampi(value, 0, state.unit_type.stats.maxhp)
	else:
		state.stats[stat] = maxi(value, 0)
	print(state.stats[stat])	
	stat_changed.emit(stat)


## Adds a status effect.
func add_status_effect(effect: String, duration: int):
	state.status_effects[effect] = duration
	status_effect_added.emit(effect)


## Removes a status effect.
func remove_status_effect(effect: String):
	state.status_effects.erase(effect)
	status_effect_removed.emit(effect)
	

## Changes duration of a status effect.
func change_status_effect(effect: String, duration: int):
	if duration <= 0:
		remove_status_effect(effect)
	else:
		state.status_effects[effect] = duration
		status_effect_changed.emit(effect)


## Sets heading by angle.
func set_facing(angle: float):
	state.heading = Map.to_heading(angle)


## Sets this unit to face towards a target point.
func face_towards(target: Vector2):
	set_facing(map_position.angle_to_point(target))
	

## Returns true if walking.
func is_walking() -> bool:
	return is_instance_valid(driver)


## Returns true if attacking.
func is_attacking() -> bool:
	return false # TODO


## Returns true if attacking.
func is_dying() -> bool:
	return false # TODO


## Pathfinds to target and walks to it.
func walk_towards(context: BattleContext, target: Vector2):
	await walk_along(context, pathfind_cell(context, target))
	

## Walk along a specified path.
func walk_along(context: BattleContext, path: PackedVector2Array):
	stop_walking()

	if path.is_empty():
		path.append(cell())

	walking_started.emit(path[-1])
	driver = context.battle.create_unit_driver(self, path)
	state.state = 'walking'
	await driver.walking_finished
	walking_finished.emit()
	state.state = 'idle'
	

## Stops walking.
func stop_walking():
	if is_walking():
		driver.stop_driver()


func _on_property_changed(prop:StringName):
	if prop == 'display_name':
		%NameLabel.text = state.display_name


func _on_stat_changed(stat:StringName):
	if stat == 'hp' or stat == 'maxhp':
		%HPBar.scale.x = clampf(float(state.stats.hp)/state.stats.maxhp, 0, 1)


	
