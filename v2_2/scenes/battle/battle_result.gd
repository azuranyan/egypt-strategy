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


static func empire_victory(empire: Empire) -> int:
	return ATTACKER_VICTORY if empire == Battle.instance().attacker() else DEFENDER_VICTORY


static func empire_defeat(empire: Empire) -> int:
	return DEFENDER_VICTORY if empire == Battle.instance().attacker() else ATTACKER_VICTORY


static func empire_withdraw(empire: Empire) -> int:
	return ATTACKER_WITHDRAW if empire == Battle.instance().attacker() else DEFENDER_WITHDRAW



func _init(_value: int, _attacker: Empire = null, _defender: Empire = null, _territory: Territory = null, _map_id: int = 0):
	# param list was kept like that for compatibility, clean it up later
	value = _value
	attacker = Game.battle.attacker()
	defender = Game.battle.defender()
	territory = Game.battle.territory()
	map_id = Game.battle.map_id()
	
	
func attacker_won() -> bool:
	return value == ATTACKER_VICTORY or value == DEFENDER_WITHDRAW
	
	
func defender_won() -> bool:
	return value == DEFENDER_VICTORY or value == ATTACKER_WITHDRAW
	
	
func winner() -> Empire:
	return attacker if attacker_won() else defender
	
	
func loser() -> Empire:
	return attacker if defender_won() else defender
	
	
func is_none() -> bool:
	return value == NONE
	
	
func player_won() -> bool:
	if attacker.is_player_owned():
		return attacker_won()
	else:
		return defender_won()
	
	
func enemy_won() -> bool:
	return not player_won()


func is_player_participating() -> bool:
	return attacker.is_player_owned() or defender.is_player_owned()
