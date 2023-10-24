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


#var overworld_scene := preload("res://Screens/Overworld/Overworld.tscn").instantiate()
#var battle_scene := preload("res://Screens/Battle/Battle.tscn").instantiate()


var overworld: Overworld = preload("res://Screens/Overworld/Overworld.tscn").instantiate()
var battle: Battle = preload("res://Screens/Battle/Battle.tscn").instantiate()

var screen_stack: Array[Node] = []


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


func _ready():
	push_screen.call_deferred(overworld, '')
	

## Replaces the top screen with another.
func transition_screen(new: Node, transition: String = ''):
	if screen_stack.size() == 0:
		push_screen(new, transition)
	else:
		var old := screen_stack[-1]
		screen_stack[-1] = new
		_transition(old, new, transition)


## Pushes a new screen on top.
func push_screen(new: Node, transition: String = ''):
	# this check is not necessary but back() spits an error if null is empty
	# which is undesirable instead of just being fucking quiet about it 
	var old: Node = null if screen_stack.is_empty() else screen_stack.back()
	screen_stack.push_back(new)
	_transition(old, new, transition)


## Pops the top screen and restores the previous screen.
func pop_screen(transition: String = ''):
	var old: Node = screen_stack.pop_back()
	var new: Node = screen_stack.back()
	_transition(old, new, transition)
	

func _transition(old: Node, new: Node, transition: String):
	if old:
		get_tree().root.remove_child(old)
	get_tree().root.add_child(new)
	
	
