class_name Unit

# Dictates unit behavior
enum Behavior {
	PlayerControlled,
	NormalMeele,
	NormalRanged,
	ExploitativeMeele,
	ExploitativeRanged,
	DefensiveMeele,
	DefensiveRanged,
	SupportHealer,
	StatusApplier,
}

class Attack:
	var name: String
	
class BattleStats:
	var mov: int
	var hp: int
	var basic_attack: Attack
	var extra_skills: Array[Attack]
	
class UnitType:
	var name: String
	var stats_bond: Array[BattleStats]
	# var renderable stuff
	
class StatusEffectType:
	var name: String
	var long_name: String
	var simple_description: String
	var description: String
	var icon: String
	
class StatusEffect:
	var status_effect_type: StatusEffectType
	var duration: int
	
	
var unit_type: UnitType
#var leader # can either be null for default or bool override
var behavior: Behavior
var bond: int
var stats: BattleStats
var status_effects: Array[StatusEffect]


# Returns true if unit represents a god
func is_god() -> bool:
	for god in God.all:
		if god.name == unit_type.name:
			return true
	return false

# TODO no longer used
# This is used for determining leader units.
# Each territory is owned by an empire, and every empire has a leader god.
# All gods have unit representations.
#func is_leader() -> bool:
#	if leader == null:
#		return is_god()
#	else:
#		return leader == true
	
func is_player_controlled() -> bool:
	return behavior == Behavior.PlayerControlled
	
func is_ai_controlled() -> bool:
	return behavior != Behavior.PlayerControlled
