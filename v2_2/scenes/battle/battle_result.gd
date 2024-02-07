class_name BattleResult

enum {
	CANCELLED = -1,
	NONE = 0,
	ATTACKER_VICTORY,
	DEFENDER_VICTORY,
	ATTACKER_WITHDRAW,
	DEFENDER_WITHDRAW,
}

# TODO this should just take a weakref to context?
var value: int
var attacker: Empire
var defender: Empire
var territory: Territory
var map_id: int


func _init(_value: int, _attacker: Empire, _defender: Empire, _territory: Territory, _map_id: int):
	value = _value
	attacker = _attacker
	defender = _defender
	territory = _territory
	map_id = _map_id
	
	
func attacker_won() -> bool:
	return value == ATTACKER_VICTORY or value == DEFENDER_WITHDRAW
	
	
func defender_won() -> bool:
	return value == DEFENDER_VICTORY or value == ATTACKER_WITHDRAW
	
	
func winner() -> Empire:
	return attacker if attacker_won() else defender
	
	
func loser() -> Empire:
	return attacker if defender_won() else defender
	
	
func player_won() -> bool:
	if attacker.is_player_owned():
		return attacker_won()
	else:
		return defender_won()
	
	
func enemy_won() -> bool:
	return not player_won()


func is_player_participating() -> bool:
	return attacker.is_player_owned() or defender.is_player_owned()
