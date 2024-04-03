class_name UnitDriver
extends Path2D


## Emitted when walking is finished.
signal walking_finished

## Internal signal emitted when walking is finished.
signal _walking_finished


## The target unit to move around.
var target: Unit
var world: World

var _walking: bool
var _old_pos: Vector2


@onready var path_follow := $PathFollow2D
@onready var remote_transform := $PathFollow2D/RemoteTransform2D


# Called when the node enters the scene tree for the first time.
func _ready():
	curve = Curve2D.new()
	set_process(false)
	
	
func _exit_tree():
	request_ready()
	
	
func _process(delta):
	assert(_walking and target)
	
	path_follow.progress += target.state.walk_speed * delta
	
	# this is a deceptive amount of computation..
	var new_pos = target.world.as_uniform(path_follow.position - position)
	target.face_towards(new_pos)
	target.map_position = new_pos
	_old_pos = new_pos
	
	if path_follow.progress_ratio >= 1:
		_walking_finished.emit()


## Starts the driver.
func start_driver(path: PackedVector2Array):
	if not target:
		return
		
	# stop driver else we will leak signals and do weird stuff
	stop_driver()
	
	position = target.position
	remote_transform.remote_path = target.get_path()
	
	# skip all the work if walking speed is invalid 
	if (target.walk_speed > 0) and (Util.path_length(path) > 0):
		_old_pos = target.map_position
		#curve.add_point(Vector2.ZERO)
			
		for p in path:
			curve.add_point(world.as_global(p) - position)
			
		# start
		_walking = true
		remote_transform.force_update_cache()
		remote_transform.update_position = true
		set_process(true)
		
		# walking
		await _walking_finished
		
		# finish
		set_process(false)
		remote_transform.update_position = false
		target.map_position = path[-1]
		target.stop_animation()
		path_follow.progress = 0
		curve.clear_points()
	
	remote_transform.remote_path = ""
	_walking = false
	walking_finished.emit()
	queue_free()
	
	
## Stops the driver.
func stop_driver():
	if _walking:
		_walking_finished.emit()


