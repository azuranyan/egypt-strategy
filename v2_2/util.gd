class_name Util
## Collection of utility functions that doesnt belong anywhere else.


## Simple do nothing function.
static func do_nothing():
	pass


## Returns the mean center of an array of points.
static func centroid(arr) -> Vector2:
	var total := Vector2.ZERO
	for e in arr:
		total += e
	return total/arr.size()

	
## Connects signals. Will not produce an error if object is null or signal is already connected.
static func just_connect(obj: Object, sig: StringName, fun: Callable):
	if is_instance_valid(obj) and not obj.is_connected(sig, fun):
		obj.connect(sig, fun)


## Disconnects signals. Will not produce an error if object is null or signal is not connected.
static func just_disconnect(obj: Object, sig: StringName, fun: Callable):
	if is_instance_valid(obj) and obj.is_connected(sig, fun):
		obj.disconnect(sig, fun)
	

## Returns true if the scene is root.
static func is_scene_root(node: Node) -> bool:
	if Engine.is_editor_hint():
		return node == node.get_tree().edited_scene_root
	else:
		return node.get_parent() == node.get_tree().root


## Returns true if the game is ran in f6 mode. Doesn't work if F6 is used on the main scene though.
static func is_f6(_node: Node) -> bool:
	# TODO fix
	# if node and node.is_inside_tree() and node.get_tree().current_scene:
	# 	return node.get_tree().current_scene.scene_file_path != ProjectSettings.get_setting("application/run/main_scene")
	return false
	
	
## Returns true a is closer than b from c.[br]
## Can be used with [code]is_closer.bind(start)[/code] for comparing two points.
static func is_closer(a: Vector2, b: Vector2, c: Vector2) -> bool:
	return a.distance_squared_to(c) < b.distance_squared_to(c)
	
	
## Makes big caps for [RichTextLabel].
static func bb_big_caps(rt: RichTextLabel, text: String, props := {}):
	# "setting text to an empty string also clears the stack" is a fucking lie
	rt.clear()
	rt.text = ''
	
	# does not support centering and no push_center either
	if props.get('center', true):
		rt.append_text('[center]')
	
	# font
	var font: Font = props.get('font', rt.get_theme_default_font())
	var font_size: int = props.get('font_size', rt.get_theme_default_font_size())
	rt.push_font(font, font_size)
	
	# misc props
	if props.has('font_color'): rt.push_color(props.font_color)
	if props.has('outline_color'): rt.push_outline_color(props.outline_color)
	if props.has('outline_size'):  rt.push_outline_size(props.outline_size)
	
	var big_font_size := int(1.5 * font_size)
	if props.has('ratio'):
		big_font_size = props.ratio * font_size
	if props.has('big_font_size'):
		big_font_size = props.big_font_size
	
	# capitalize
	var caps: Array[String] = []
	var insert_caps := func():
		if caps.is_empty():
			return
		rt.push_font_size(big_font_size)
		rt.add_text(''.join(caps))
		rt.pop()
		caps.clear()
	
	var first_letter_only: bool = props.get('first_letter_only', true)
	var all_caps: bool = props.get('all_caps', true)
	var prev := ''
	for c in text:
		if not c.is_valid_identifier() or c.to_upper() == c and (prev == '' or prev == ' ' or (not first_letter_only and prev in caps)):
			caps.append(c)
		else:
			insert_caps.call()
			rt.add_text(c.to_upper() if all_caps else c)
		prev = c
	insert_caps.call()
	
	if props.has('outline_color'): rt.pop()
	if props.has('outline_color'): rt.pop()
	if props.has('outline_size'):  rt.pop()
	
	
## Simple flood fill algorithm.
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
