class_name Util
## Collection of utility functions that doesnt belong anywhere else.

enum Interrupt {
	## Uses the elapsed time of the ongoing tween. This is useful for animating
	## state back and forth and interrupting halfway.
	REVERSE,

	## Advances the ongoing tween to the final state.
	ADVANCE,

	## Just kills the current ongoing tween.
	IGNORE,
}



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
	

## Type safe equality check.
static func is_equal(a, b) -> bool:
	return typeof(a) == typeof(b) and a == b
	

## Returns true a is closer than b from c.[br]
## Can be used with [code]is_closer.bind(start)[/code] for comparing two points.
static func is_closer(a: Vector2, b: Vector2, c: Vector2) -> bool:
	return a.distance_squared_to(c) < b.distance_squared_to(c)
	
	
## Makes big caps for [RichTextLabel].
static func bb_big_caps(rt: RichTextLabel, text: String, props := {}):
	# "setting text to an empty string also clears the stack" is a fucking lie
	rt.clear()
	rt.text = ''
	
	# does not support centering and no push_center either so we do it like this
	if props.get('center', true):
		rt.append_text('[center]')
	
	# font
	var font_size: int
	if 'font_size' in props:
		font_size = props.font_size
	else:
		var override: int = rt.get('theme_override_font_sizes/normal_font_size')
		if override:
			font_size = override
		else:
			font_size = rt.get_theme_default_font_size()
	if 'font' in props:
		rt.push_font(props.font, props.get('font_size', 0))
	
	# misc props
	if 'font_color' in props: rt.push_color(props.font_color)
	if 'outline_color' in props: rt.push_outline_color(props.outline_color)
	if 'outline_size' in props:  rt.push_outline_size(props.outline_size)
	
	var big_font_size := int(1.5 * font_size)
	if 'ratio' in props:
		big_font_size = props.ratio * font_size
	if 'big_font_size' in props:
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


## Kills a tween and returns the total elapsed time.
func interrupt_tween(tween: Tween, interrupt_mode: ) -> float:
	var duration = tween.get_total_elapsed_time()
	tween.kill()
	return duration

	
## Simple flood fill algorithm.
static func flood_fill(cell: Vector2, rect: Rect2, max_dist: float, condition: Callable = Util.always_true) -> PackedVector2Array:
	if max_dist> 0:
		return CSUtil.FloodFill(cell, rect, max_dist, condition)
	return []


## A simple function that always returns true.
static func always_true(_dummy) -> bool:
	return true


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
