class_name Heuristics
extends Resource


@export var use_buff_self: float

@export var use_buff_ally: float

@export var use_heal_self: float

@export var use_heal_ally: float

@export var use_deify: float

@export var can_kill_enemy: float

@export var can_debuff_enemy: float

@export var 

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