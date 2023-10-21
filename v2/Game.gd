extends Node


const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
#var territories: Array[Territory] = []

#var gods: Array[God] = []
var units: Array[Unit] = []
var hp_multiplier: float = 1.0


var territories := {
	# This will be auto populated in Overworld._ready
}

var empires := {
	# This will be auto populated in Overworld._ready
}

var maps := {
	# This will be auto populated in Entrypoint._ready
}

var prefs := {
	'defeat_if_home_territory_captured': true,
	'camera_follow_unit_move': true,
	'mouse_edge_scrolling': true, # TODO
	'auto_end_turn': true,
}

var attack := {
	# This will be auto populated in Entrypoint._ready
}

var chara := {
	# This will be auto populated in Entrypoint._ready
}

var doodad_type := {
	# This will be auto populated in Entrypoint._ready
}

var status_effect := {
	# This will be auto populated in Entrypoint._ready
}

var unit_type := {
	# This will be auto populated in Entrypoint._ready
}

var world := {
	# This will be auto populated in Entrypoint._ready
}

var scene_queue: Array[String] = []


@onready var overworld := $Overworld as Overworld
@onready var battle := $Battle as Battle

	


## Registers data from /battle.
static func register_data(subdir: String, get_id: Callable):
	var path := "res://Screens/Battle/data/" + subdir + '/'
	var dir := DirAccess.open(path)
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if !dir.current_is_dir() and filename.ends_with(".tres"):
			var res = load(path + filename)
			Globals.get(subdir)[get_id.call(res)] = res
		filename = dir.get_next()
		
		
static func attack_range(unit: Unit, attack: Attack) -> int:
	if attack.range < 0:
		return unit.stat_rng
	else:
		return attack.range

