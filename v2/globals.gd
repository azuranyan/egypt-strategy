extends Node


const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
#var territories: Array[Territory] = []

#var gods: Array[God] = []
var units: Array[Unit] = []
var hp_multiplier: float = 1.0

var battle: Battle = preload("res://Screens/Battle/Battle.tscn").instantiate()

const charas := {
	"Lysandra" = preload("res://Screens/Battle/data/Chara_Lysandra.tres"),
	"Maia" = preload("res://Screens/Battle/data/Chara_Maia.tres"),
	"Zahra" = preload("res://Screens/Battle/data/Chara_Zahra.tres"),
	"Ishtar" = preload("res://Screens/Battle/data/Chara_Ishtar.tres"),
	"Alara" = preload("res://Screens/Battle/data/Chara_Alara.tres"),
	"Eirene" = preload("res://Screens/Battle/data/Chara_Eirene.tres"),
	"Sutekh" = preload("res://Screens/Battle/data/Chara_Sutekh.tres"),
	"Nyaraka" = preload("res://Screens/Battle/data/Chara_Nyaraka.tres"),
	"Tali" = preload("res://Screens/Battle/data/Chara_Tali.tres"),
	"Sitri" = preload("res://Screens/Battle/data/Chara_Sitri.tres"),
	"Hesra" = preload("res://Screens/Battle/data/Chara_Hesra.tres"),
	"Nebet" = preload("res://Screens/Battle/data/Chara_Nebet.tres"),
}

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
	'auto_end_turn': false, # TODO
}

var chara := {}
var doodad_type := {}
var status_effect := {}
var unit_type := {}
var world := {}

var scene_queue: Array[String] = []

func _ready():
#	var dir := DirAccess.open("res://Screens/Battle/data/")
#	dir.list_dir_begin()
#	var filename := dir.get_next()
#	while filename != "":
#		if !dir.current_is_dir() and filename.begins_with("Chara_"):
#			var chara: Chara = load(filename)
#
#		filename = dir.get_next()

	#get_tree().root.add_child.call_deferred(battle)
	#print("battle added")
	pass


## Flood fill algorithm.
func flood_fill(cell: Vector2, max_distance: int, bounds: Rect2i, condition: Callable = func(_br): return true) -> PackedVector2Array:
	var re := PackedVector2Array()
	var stack := [cell]
	
	while not stack.is_empty():
		var current = stack.pop_back()
		
		# diagonal distance check (not circle or square)
		var diff: Vector2 = (current - cell).abs()
		var dist := int(diff.x + diff.y)
		
		# various checks
		var out_of_bounds: bool = not bounds.has_point(current)
		var dupe: bool = current in re
		var out_of_range: bool = dist > max_distance
		
		if out_of_bounds or dupe or out_of_range:
			continue
		
		if condition.call(current):
			re.append(current)
		
		for direction in DIRECTIONS:
			var coords: Vector2 = current + direction
			
			if not bounds.has_point(current) or coords in re:
				continue
			
			stack.append(coords)
	return re
	

## Appends object to array if it doesn't exist.
static func append_unique(arr, what):
	if what not in arr:
		arr.append(what)


## Returns a square path from a given path.
static func make_square_path(path: PackedVector2Array) -> PackedVector2Array:
	var re := PackedVector2Array()
	var prev := Vector2.ZERO
	
	re.append(prev)
	for p in path:
		if p.x != prev.x and p.y != prev.y:
			if p.x < p.y:
				re.append(Vector2(p.x, prev.y))
			else:
				re.append(Vector2(prev.x, p.y))
		re.append(p)
		prev = p
	return re


## Returns a random path of a given length.
static func make_random_path(
		length: int,
		start: Vector2,
		min: Vector2,
		max: Vector2,
		square := true
		) -> PackedVector2Array:
	var re := PackedVector2Array()
	var prev := start
	
	re.append(prev)
	for i in length:
		var p := Vector2(randi_range(min.x, max.x), randi_range(min.y, max.y))
		if square:
			if p.x != prev.x and p.y != prev.y:
				if p.x < p.y:
					p = Vector2(p.x, prev.y)
				else:
					p = Vector2(prev.x, p.y)
		re.append(p)
		prev = p
	
	return re
