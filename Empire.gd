extends Node

export(float, 0, 1) var aggression_rating = 0.0
var territories = []
var units = []
var leader = 5
export var is_AI_controlled = true
export var use_mock_str_rateing = true
export(float, 0, 1) var mock_strength_rating: float = 0.5
var strength_rating = 0.5
var hp_multiplier: float = 1.0

var home_territory

func _ready():
	pass

func calculate_strength_rating():
	if use_mock_str_rateing == false:
		var random_factor = randf() * 0.2
		strength_rating = territories.size() * leader.power * random_factor
	else:
		strength_rating = randf() * 0.2 + mock_strength_rating

func win_territory(territory):
	for each_unit in territory.home_turf_units:
		units.append(each_unit)
	territories.append(territory)
	territory.set_owner(leader)
	territory.owner_empire = self
	
func lose_territory(territory):
	for each_unit in territory.home_turf_units:
		units.remove(each_unit)
	territories.remove(territory)

func get_adjacent_territories():
	var adjacent_territories = []
	for territory in territories:
		for adjacent in territory.adjacent_territories:
			if not adjacent in territories and not adjacent in adjacent_territories:
				adjacent_territories.append(adjacent)
	return adjacent_territories

func set_hp_multiplier(value: float):
	hp_multiplier = value

func reset_hp_multiplier():
	hp_multiplier = 1.0

func rest_action():
	reset_hp_multiplier()

func has_been_beaten() -> bool:
	return territories.empty()
