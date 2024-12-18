class_name Util

## Use this because godot is fucking stupid.
static func get_canvas_size(_node: Node) -> Vector2:
	# IT SHOULD JUST BE THIS, BUT
	#return node.get_viewport().size
	
	# THERE'S NO WAY TO GET IT PROPERLY BECAUSE
	# THIS IS DIFFERENT IN THE EDITOR (WHICH RETURNS ***THE PANEL SIZE***
	# LIKE THE FUCKING ASS BACKWARDS SMART APE OF A FUCNTION IT IS) AND THERE'S
	# NO PROPER DOCUMENTED FUNCTION THAT RETURNS THE SIZE OF THAT BLUE AREA
	# LIKE JESUS FUCKING CHRIST AFTER YOU SAID TO USE THE CANVAS COORDINATE
	# SYSTEM BECAUSE SCREEN SCALING AND VIEWPORT AND CAMERA SHIT IS A HEADACHE
	# AND IM TRYING TO DO THAT BUT YOU'RE NOT GIVING ME EASY ACCESS TO THE
	# """""""VIEWPORT"""""" SIZE??? HOLY FUCKING SHIT THIS IS STUPID
	
	# extremely stupid hardcoded viewport size which will cause you lots
	# of scaling headaches later on, but we have no other choice because
	# of the beautiful engine design and existing solutions
	return Vector2(1920, 1080)


## Simple do nothing function.
static func do_nothing():
	pass


## Simple suboptimal flood fill algorithm.
static func flood_fill(cell: Vector2, max_distance: float, rect: Rect2, condition: Callable = func(_br): return true) -> PackedVector2Array:
	var dest = PackedVector2Array()
	
	# for degen case where int <= 0 we skip
	if max_distance > 0:
		var stack := [cell]
		
		while not stack.is_empty():
			var p: Vector2 = stack.pop_back()
			
			dest.append(p)
			
			for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				var q: Vector2 = p + direction
				
				if q in stack:
					continue
					
				if q not in dest and rect.has_point(q) and cell_distance(q, cell) <= max_distance and condition.call(q):
					stack.append(q)
					
	return dest

## Returns the cell distance between two cells.
static func cell_distance(a: Vector2, b: Vector2) -> int:
	var diff := (a - b).abs()
	return int(diff.x + diff.y)


## Returns the total length of a given path.
static func path_length(path: PackedVector2Array) -> float:
	if path.is_empty():
		return 0

	var total := 0.0
	var prev := path[0]
	for i in range(1, path.size()):
		total += prev.distance_to(path[i])
		prev = path[i]
	return total
	
	
## Appends object to array if it doesn't exist.
static func append_unique(arr, what):
	if what not in arr:
		arr.append(what)
		
		
## Simple size to rect.
static func bounds(size: Vector2) -> Rect2:
	return Rect2(0, 0, size.x, size.y)
	
	
## Simple size to rect.
static func boundsi(size: Vector2i) -> Rect2i:
	return Rect2i(0, 0, size.x, size.y)

	
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
		_min: Vector2,
		_max: Vector2,
		square := true
		) -> PackedVector2Array:
	var re := PackedVector2Array()
	var prev := start
	
	re.append(prev)
	for i in length:
		var p := Vector2(int(randf_range(_min.x, _max.x)), int(randf_range(_min.y, _max.y)))
		if square:
			if p.x != prev.x and p.y != prev.y:
				if p.x < p.y:
					p = Vector2(p.x, prev.y)
				else:
					p = Vector2(prev.x, p.y)
		re.append(p)
		prev = p
	
	return re
