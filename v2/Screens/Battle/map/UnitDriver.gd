extends Path2D

class_name UnitDriver


signal walking_started
signal walking_finished


@export var walk_speed: float = 300
@export var unit: Unit


@onready var path_follow := $PathFollow2D as PathFollow2D


var _old_pos: Vector2


var walking := false:
	set(value):
		walking = value
		set_process(walking)
		

# Called when the node enters the scene tree for the first time.
func _ready():
	curve = Curve2D.new()


func _process(delta: float):
	if not walking:
		return # because fuckface still processes even when set_process(false)
	
	_old_pos = path_follow.position
	
	path_follow.progress += walk_speed * delta
	
	# update map_pos
	unit.map_pos = unit.world.screen_to_uniform(position + path_follow.position)
	
	# overwrite position because map_pos computation sometimes makes it choppy
	unit.position = position + path_follow.position
	
	var v := unit.world.screen_to_world(path_follow.position) - unit.world.screen_to_world(_old_pos)
	unit.facing = atan2(v.y, v.x)
	
	if path_follow.progress_ratio >= 1:
		walking_finished.emit()


## Walks along a path.
func walk_along(path: PackedVector2Array):
	# place where he is
	position = unit.position
	
	if path.is_empty():
		return
	
	# create the path
	for point in path:
		curve.add_point(unit.world.uniform_to_screen(point) - position)
	
	# start walk cycle
	walking = true
	unit.model.play_animation("walk")
	walking_started.emit()
	
	# await until walking is done
	await self.walking_finished
	
	# cleanup code
	unit.model.play_animation("idle")
	unit.model.stop_animation()
	walking = false
	unit.map_pos = path[-1]
	path_follow.progress = 0
	curve.clear_points()


## Stops walking
func stop_walking():
	if walking:
		walking_finished.emit()
