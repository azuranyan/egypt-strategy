class_name Heuristics
extends Resource


@export var use_buff_self: float

@export var use_buff_ally: float

@export var use_heal_self: float

@export var use_heal_ally: float

@export var use_deify: float

@export var can_kill_enemy: float

@export var can_debuff_enemy: float


# heuristics -> behavior -> personality -> realtime adjustments -> player preferences
var behavior := {
	# target preferences
	target_nearest = 1.0,
	target_weakest = 1.0,
	target_strongest = 1.0,
	target_healers = 1.0,
	target_furthest = 1.0,

	# movement preferences
	move_away_from_enemy = 1.0,
	move_away_from_ally = 1.0,
	move_away_distance = 1.0,
	move_towards_enemy = 1.0,
	move_towards_ally = 1.0,
	move_towards_distance = 1.0,
	smart_positioning = 1.0,
	roam = 1.0,
	hold_position = 1.0,

	# attack preferences
	use_crowd_control = 1.0,
	use_debuff = 1.0,
	use_buff = 1.0,
	avoid_friendly_fire = 1.0,

	# misc behavior
	flee = 1.0,
	kill_enemy = 1.0,
}


# TODO transfer to c# and linq the hell out of it


## A unit filter that returns any unit.
static func any_unit(_unit: Unit) -> bool:
	return true


## Returns the unit closest to the specified unit.
static func get_nearest_unit(unit: Unit, filter: Callable = any_unit) -> Unit:
	var cell := unit.get_position()
	var nearest_target: Unit
	var nearest_dist: float
	for tid: int in Game.unit_registry:
		var t: Unit = Game.unit_registry[tid]
		if not filter.call(t):
			continue
		var tdist := Util.cell_distance(cell, t.get_position())
		if nearest_dist == null or tdist < nearest_dist:
			nearest_target = t
			nearest_dist = tdist
	return nearest_target


## Returns the weakest enemy to the specified unit.
static func get_weakest_unit(unit: Unit, filter: Callable = any_unit) -> Unit:
	var weakest_unit: Unit
	var weakest_hp: int
	for tid: int in Game.unit_registry:
		var t: Unit = Game.unit_registry[tid]
		if not filter.call(t):
			continue
		if weakest_unit == null or weakest_hp > t.get_stat('hp'):
			weakest_unit = t
			weakest_hp = t.get_stat('hp')
	return weakest_unit


static func get_any_unit_within_distance(unit: Unit, distance: int, filter: Callable = any_unit) -> Unit:
	# TODO
	return null

# Pre-defined fixed behavior

## Advances towards nearest target and attacks.
static func normal_melee(unit: Unit) -> Array[Dictionary]:
	var re: Array[Dictionary] = []
	var t := get_nearest_unit(unit, unit.is_enemy)
	if t:
		# move towards the target if we have to
		if unit.can_move():
			if target_within_range(t, unit.basic_attack()):
				pass
			else:
				re.append({
					unit = unit,
					priority = 0,
					hint = '',
					cell = t.get_position(),
				})

		# attack if we can
		if unit.can_attack():
			if unit.basic_attack().is_multicast():
				pass # TODO handle multicast
			else:
				re.append({
					unit = unit,
					priority = 0,
					hint = '',
					attack = unit.basic_attack(),
					target = t.get_position(),
					rotation = 0.0,
				})

	return re
		


static func normal_ranged() -> void:
	pass


static func exploitative_melee


static func can_buff_self(unit: Unit, heur: Dictionary) -> Array[Dictionary]:
	var move := {
		unit = unit,
		priority = 0,
		target = unit,
		hint = '',
		is_move = false,
		is_attack = false,
	}
	return []


static func can_buff_ally(unit: Unit, heur: Dictionary) -> Array[Dictionary]:
	return []