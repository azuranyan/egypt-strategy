class_name Empire
extends Resource


var leader: CharacterInfo


func is_player_owned() -> bool:
	return leader.get_meta("player", false)

