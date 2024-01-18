@tool
class_name Unit
extends MapObject


signal mouse_button_pressed(unit: Unit, button: int, position: Vector2, pressed: bool)

signal stat_changed(stat, value)

signal status_effect_added(effect)
signal status_effect_removed(effect)

signal walking_started
signal walking_finished

signal attack_started(attack: Attack, target: Variant, target_rotation: Variant)
signal attack_finished()

signal _multicast_finished


const HEADING_ANGLES := [0, PI/2, PI, PI*3/4]

## Default walk (phase friendly units).
const PHASE_NONE := 0

## Ignores enemies.
const PHASE_ENEMIES := 1 << 0

## Ignores doodads.
const PHASE_DOODADS := 1 << 1

## Ignores terrain.
const PHASE_TERRAIN := 1 << 2

## Ignores all pathing and placement restrictions.
const PHASE_NO_CLIP := 1 << 3


## Dictates how his unit chooses its actions.
enum Behavior {
	## Always advances towards nearest target and attacks.
	NormalMelee,
	
	## Always attacks nearest target, flees adjacent attackers.
	NormalRanged,
	
	## Always advances and tries to attack target with lowest HP.
	ExploitativeMelee,
	
	## Always tries to attack targets that would not be able to retaliate.
	ExploitativeRanged,
	
	## Holds 1 spot and attacks any who approach.
	DefensiveMelee,
	
	## Holds 1 spot and attacks any who approach, flees adjacent attackers.
	DefensiveRanged,
	
	## Heals allies and self, runs away from attackers.
	SupportHealer,
	
	## Aims to inflict as many enemies with negative status as possible, will choose different target if already afflicted.
	StatusApplier,
}

## Headings
enum Heading {East, South, West, North}

const DIRECTIONS := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

enum {
	ATTACK_OK = 0,
	ATTACK_NOT_UNLOCKED,
	ATTACK_TARGET_INSIDE_MIN_RANGE,
	ATTACK_TARGET_OUT_OF_RANGE,
	ATTACK_NO_TARGETS,
	ATTACK_INVALID_TARGET,
}

enum {
	TURN_NEW = 0,
	TURN_MOVED = 1 << 0,
	TURN_ATTACKED = 1 << 1,
	TURN_DONE = 1 << 2,
}


@export_subgroup("Character")

# godot is a fucking pest and couldn't use UnitType but works if qualified as Resource
# and doesn't work with preload either. FUCKING DIPSHIT
@export var unit_type: Resource = load("res://Screens/Battle/data/unit_type/Dummy.tres"):
	set(value):
		if unit_type == value:
			return
		unit_type = value
		if is_node_ready():
			_update_unit_type()
	
## The scale of the model.
@export var model_scale := Vector2.ONE:
	set(value):
		if model_scale == value:
			return
		model_scale = value
		if is_node_ready():
			model.scale = model_scale

## The behavior of this unit.
@export var behavior: UnitType.Behavior


@export_subgroup("Movement")

## The angle the unit is facing in radians.
@export var facing: float:
	set(value):
		if facing == value:
			return
		facing = value
		if is_node_ready():
			model.facing = facing
			
## The speed this unit walks.
@export var walk_speed: float = 200

## Objects this unit can phase through.
@export_flags("Enemies:1", "Doodads:2", "Terrain:4", "No Clip:8") var phase = PHASE_NONE

@export_subgroup("Others")

@export var selectable: bool = true

@export var special_unlocked: bool

var alive: bool = true

var maxhp: int:
	set(value):
		if maxhp == value:
			return
		maxhp = value
		if is_node_ready():
			stat_changed.emit('maxhp', value)
			_update_stats()
		
var hp: int:
	set(value):
		if hp == value:
			return
		hp = value
		if is_node_ready():
			stat_changed.emit('hp', value)
			_update_stats()
		
var move: int:
	set(value):
		if move == value:
			return
		move = value
		if is_node_ready():
			stat_changed.emit('move', value)
			_update_stats()
		
var damage: int:
	set(value):
		if damage == value:
			return
		damage = value
		if is_node_ready():
			stat_changed.emit('damage', value)
			_update_stats()
		
var range: int:
	set(value):
		if range == value:
			return
		range = value
		if is_node_ready():
			stat_changed.emit('range', value)
			_update_stats()
		
var bond: int:
	set(value):
		if bond == value:
			return
		bond = value
		if is_node_ready():
			_update_bond()
			
var stat_growth_1: Dictionary = {'maxhp': 0, 'move': 0, 'damage': 0, 'range': 0}

var stat_growth_2: Dictionary = {'maxhp': 0, 'move': 0, 'damage': 0, 'range': 0}
			
var basic_attack: Attack

var special_attack: Attack

## The owner empire.
var empire: Empire

## Mapping of status effect -> duration.
var status_effects := {}

var turn_flags: int

var _standby_pos: Vector2

var _driver: UnitDriver

@onready var model: UnitModel = $UnitModel
		
		
var _base_stats: Dictionary
			
			
func _ready():
	super._ready()
	_update_unit_type()
	
	model.facing = facing
	model.scale = model_scale
	
	$UnitModel/Shadow.visible = false
	
	_update_stats()
		
		
func _update_unit_type():
	if not unit_type:
		return
	display_name = unit_type.name
	display_icon = unit_type.chara.portrait
	model.sprite_frames = unit_type.sprite_frames
	
	maxhp = unit_type.stat_maxhp
	hp = maxhp
	move = unit_type.stat_mov
	damage = unit_type.stat_dmg
	range = unit_type.stat_rng
	stat_growth_1.maxhp = unit_type.stat_growth_1.maxhp
	stat_growth_1.move = unit_type.stat_growth_1.mov
	stat_growth_1.damage = unit_type.stat_growth_1.dmg
	stat_growth_1.range = unit_type.stat_growth_1.rng
	stat_growth_2.maxhp = unit_type.stat_growth_2.maxhp
	stat_growth_2.move = unit_type.stat_growth_2.mov
	stat_growth_2.damage = unit_type.stat_growth_2.dmg
	stat_growth_2.range = unit_type.stat_growth_2.rng
	basic_attack = unit_type.basic_attack
	special_attack = unit_type.special_attack
	_base_stats = {
		"maxhp" = maxhp,
		"hp" = hp,
		"move" = move,
		"damage" = damage,
		"range" = range,
	}

	
func _update_stats():
	$HUD/Label.text = display_name
	if maxhp <= 0:
		$HUD/ColorRect2.scale = Vector2.ONE
	else:
		$HUD/ColorRect2.scale.x = hp/maxhp
	
	
func _update_bond():
	stat_changed.emit('bond', bond)
	for stat in stat_growth_1:
		var v: int = _base_stats[stat]
		if bond >= 1:
			v += stat_growth_1[stat]
		if bond >= 2:
			v += stat_growth_2[stat]
		set(stat, v)
		
	
func _update_position():
	super._update_position()
	if cell() == Map.OUT_OF_BOUNDS:
		add_to_group("standby_units")
	else:
		remove_from_group("standby_units")
		
		
## Sets the unit standby status.
func set_standby(standby: bool):
	if standby:
		_standby_pos = map_pos
		map_pos = Map.OUT_OF_BOUNDS
		add_to_group("standby_units")
	else:
		map_pos = _standby_pos
		remove_from_group("standby_units")
	

## Returns true if the unit is on standby.
func is_standby() -> bool:
	return is_in_group("standby_units")
	
	
func map_ready():
	# the world is iso-like rotated at 45 degrees so this should be correct.
	# if wonky things happen, then we'll just do the complete calculation
	#model.position.y = world.tile_size * sqrt(2) * world.y_ratio / 2
	$UnitModel/Shadow.scale = world.world_transform.get_scale() * Vector2(1, world.y_ratio) * 0.5
	$UnitModel/Shadow.visible = true


## Returns the direction this unit is facing.
func get_heading() -> Unit.Heading:
	return model.heading
	
	
## Returns true if special is unlocked.
func is_special_unlocked() -> bool:
	return special_unlocked or bond >= 2
	
	
## Sets the direction this unit is facing.
func set_heading(heading: Unit.Heading):
	facing = HEADING_ANGLES[heading]
	
	
## Sets the current animation for this unit.
func play_animation(anim: String, loop: bool):
	model.play_animation(anim, loop)
	
	
## Stops the current animation.
func stop_animation():
	model.play_animation('idle', true)
	
	
func add_status_effect(effect: String, duration: int):
	status_effects[effect] = duration
	# TODO
	

func remove_status_effect(effect: String):
	status_effects.erase(effect)
	# TODO
	
	
func is_player_owned() -> bool:
	return empire != null and empire.is_player_owned()
	
	
## Returns true if the other unit is an ally.
func is_ally(other: Unit) -> bool:
	return other.empire == empire
	

## Returns true if the other unit is an enemy.
func is_enemy(other: Unit) -> bool:
	return other.empire != empire
	
	
## Returns true if this unit can move.
func can_move() -> bool:
	return turn_flags & (TURN_DONE | TURN_ATTACKED | TURN_MOVED) == 0
	
	
## Returns true if this unit can attack.
func can_attack() -> bool:
	return turn_flags & (TURN_DONE | TURN_ATTACKED) == 0


## Returns true if this unit can act.
func can_act() -> bool:
	return (turn_flags & TURN_DONE == 0) and ((turn_flags & TURN_ATTACKED == 0) or (turn_flags & TURN_ATTACKED == 0))


## Returns true if this unit has taken any actions.
func has_taken_action() -> bool:
	return turn_flags & (TURN_ATTACKED | TURN_MOVED) != 0
	
	
## Resets the turn flags.
func reset_turn_flags():
	turn_flags = TURN_NEW


## Uses attack.
func use_attack(attack: Attack, target: Array[Vector2], target_rotation: Array[float]):
	if not attack or (attack != basic_attack and attack != special_attack):
		return
	attack_started.emit(attack, target, target_rotation)
	await _use_attack_multicast(attack, target, target_rotation)
	attack_finished.emit()
	
	
func _use_attack_multicast(attack: Attack, target: Array[Vector2], target_rotation: Array[float]):
	var timer := get_tree().create_timer(1)
	play_animation(attack.user_animation, false)
	var capture := {active_multicast_counter = target.size()}
	var all_target_units: Array[Unit] = []
	for i in target.size():
		var multicaster := func():
			var target_units := get_attack_target_units(attack, target[i], target_rotation[i])
			all_target_units.append_array(target_units)
			await attack.execute(self, target[i], target_units)
			capture.active_multicast_counter -= 1
			if capture.active_multicast_counter <= 0:
				_multicast_finished.emit()
		multicaster.call_deferred()
	await _multicast_finished
		
	# just in case we're playing an extra long animation or we finished early
	if timer.time_left > 0:
		await timer.timeout
		
	stop_animation()
	for target_unit in all_target_units:
		target_unit.stop_animation()
	
	
## Returns an array of cells in the attack range.
func get_attack_range(attack: Attack) -> int:
	return attack.range if attack.range >= 0 else range
	
	
## Returns an array of cells in the attack range.
func get_attack_range_cells(attack: Attack) -> PackedVector2Array:
	var _cell: Vector2 = cell()
	var arr := Util.flood_fill(_cell, get_attack_range(attack), map.get_playable_bounds())
	
	if attack.min_range <= 0:
		return arr
		
	var re: PackedVector2Array = []
	for p in arr: # PackedVector2Array has no fucking .filter() method
		if Util.cell_distance(p, _cell) > attack.min_range:
			re.append(p)
	return re
	
	
## Returns a list of units in range of the attack.
func get_attack_target_units(attack: Attack, target: Vector2, target_rotation: float) -> Array[Unit]:
	var re: Array[Unit] = []
	for target_cell in get_attack_target_cells(attack, target, target_rotation):
		var u := map.get_unit(target_cell)
		if u:
			re.append(u)
	return re
	
	
## Returns an array of cells in the target aoe.
func get_attack_target_cells(attack: Attack, target: Vector2, target_rotation: float) -> PackedVector2Array:
	if attack.melee:
		target_rotation = get_heading() * PI/2
	return attack.get_target_cells(target, target_rotation)


## Checks if the attack 
func check_use_attack(attack: Attack, target_cell: Vector2, target_rotation: float) -> int:
	# check for bond level
	if attack == special_attack and not is_special_unlocked():
		return ATTACK_NOT_UNLOCKED
	
	# check for minimum range
	if attack.min_range > 0:
		if target_cell in Util.flood_fill(cell(), attack.min_range, map.get_world_bounds()):
			return ATTACK_TARGET_INSIDE_MIN_RANGE
		
	# check for range
	if target_cell not in Util.flood_fill(cell(), get_attack_range(attack), map.get_world_bounds()):
		return ATTACK_TARGET_OUT_OF_RANGE
		
	# check for any targets
	var target_cells := get_attack_target_cells(attack, target_cell, target_rotation)
	var targets := map.get_units().filter(func(x): return x.cell() in target_cells)
	if targets.is_empty():
		return ATTACK_NO_TARGETS
		
	# check for valid targets
	var has_valid_target := false
	for t in targets:
		var target_flags := attack.get_target_flags()
		if  (target_flags & 1 != 0 and is_enemy(t)) or \
			(target_flags & 2 != 0 and not is_enemy(t)) or \
			(target_flags & 4 != 0 and self == t):
			has_valid_target = true
			break
	if not has_valid_target: 			# causes the attack to release as long
		return ATTACK_INVALID_TARGET	# even if there are invalid targets
	
	return ATTACK_OK


## Unit faces towards a point.
func face_towards(target: Vector2):
	facing = map_pos.angle_to_point(target)
	
	
## Unit pathfinds and walk towards target.
func walk_towards(target: Vector2):
	await walk_along(pathfind_cell(target))
	
	
## Walks unit along specified path.
func walk_along(path: PackedVector2Array):
	if is_walking():
		stop_walking()
		
	walking_started.emit()
	
	if not (path.size() == 0 or (path.size() == 1 and path[0] == cell())):
		_driver = preload("res://Screens/Battle/map_types/unit/UnitDriver.tscn").instantiate() as UnitDriver
		_driver.target = self
		map.drivers.add_child(_driver)
		await _driver.start_driver(path)
	
	walking_finished.emit()
			

## Stops unit walking.
func stop_walking():
	if is_walking():
		_driver.stop_driver()
		map.drivers.remove_child(_driver)
		_driver.queue_free()
		_driver = null
	
	
## Returns true if unit is walking.
func is_walking() -> bool:
	return _driver != null
	
	
## Pathfinds to a target cell.
func pathfind_cell(end: Vector2) -> PackedVector2Array:
	var start := cell()
	var pathable := get_pathable_cells()
	if end not in pathable:
		pathable.append(end)
	var pathfinder := PathFinder.new(map.world, pathable)
	var long_path := pathfinder.calculate_point_path(start, end)
	
	for i in range(long_path.size() - 1, -1, -1):
		if is_placeable(long_path[i]) and Util.cell_distance(start, long_path[i]) <= move:
			return long_path.slice(0, i + 1)
	return long_path
	
	
## Returns an array of cells this unit can path through.
func get_pathable_cells(limit_move := false) -> PackedVector2Array:
	return Util.flood_fill(cell(), move if limit_move else 20, map.get_world_bounds(), is_pathable)
	
	
## Returns true if this unit can path through cell.
func is_pathable(cell: Vector2) -> bool:
	if phase & PHASE_NO_CLIP == 0:
		for obj in map.get_objects_at(cell):
			if not _is_pathable_object(obj):
				return false
	return true
	

func _is_pathable_object(obj: MapObject) -> bool:
	match obj.pathing:
		Map.Pathing.UNIT:
			if is_enemy(obj):
				return phase & PHASE_ENEMIES != 0
		Map.Pathing.DOODAD:
			return phase & PHASE_DOODADS != 0
		Map.Pathing.TERRAIN:
			return phase & PHASE_TERRAIN != 0
		Map.Pathing.IMPASSABLE:
			return false
	return true
	
	
## Returns true if this unit can be placed on cell.
func is_placeable(cell: Vector2) -> bool:
	if phase & PHASE_NO_CLIP == 0:
		for obj in map.get_objects_at(cell):
			if not _is_placeable_object(obj):
				return false
	return true


func _is_placeable_object(obj: MapObject) -> bool:
	match obj.pathing:
		Map.Pathing.DOODAD:
			return phase & PHASE_DOODADS != 0
		Map.Pathing.TERRAIN:
			return phase & PHASE_TERRAIN != 0
		Map.Pathing.UNIT, Map.Pathing.IMPASSABLE:
			return false
	return true
