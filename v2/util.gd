class_name Util


## Simple suboptimal flood fill algorithm.
static func flood_fill(cell: Vector2, max_distance: int, bounds: Rect2i, condition: Callable = func(_br): return true) -> PackedVector2Array:
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
		
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var coords: Vector2 = current + direction
			
			if not bounds.has_point(coords) or coords in re:
				continue
			
			if condition.call(current):
				stack.append(coords) # not ideal
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
