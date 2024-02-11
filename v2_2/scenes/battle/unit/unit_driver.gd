class_name UnitDriver
extends Path2D


## Emitted when walking is finished.
signal walking_finished

## Internal signal emitted when walking is finished.
signal _done


## The target unit to move around.
@export var target: UnitMapObject


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
	
	path_follow.progress += target.walk_speed * delta
	
	# this is a deceptive amount of computation..
	var new_pos = target.world.as_uniform(path_follow.position - position)
	target.heading = Map.to_heading(_old_pos.angle_to_point(new_pos))
	_old_pos = new_pos
	
	if path_follow.progress_ratio >= 1:
		_done.emit()


## Starts the driver.
func start_driver(path: PackedVector2Array):
	if not is_instance_valid(target):
		return
		
	# stop driver else we will leak signals and do weird stuff
	stop_driver()
	
	position = target.position
	remote_transform.remote_path = target.get_path()
	
	# skip all the work if walking speed is invalid 
	if target.walk_speed > 0:
		_old_pos = target.map_pos
		#curve.add_point(Vector2.ZERO)
			
		for p in path:
			curve.add_point(target.world.as_global(p) - position)
			
		# start
		target.play_animation('walk', true)
		_walking = true
		remote_transform.force_update_cache()
		remote_transform.update_position = true
		set_process(true)
		
		# walking
		await _done
		
		# finish
		set_process(false)
		remote_transform.update_position = false
		target.map_pos = path[-1]
		target.stop_animation()
		path_follow.progress = 0
		curve.clear_points()
	
	remote_transform.remote_path = ""
	_walking = false
	walking_finished.emit()
	
	
## Stops the driver.
func stop_driver():
	if _walking:
		_done.emit()


## Returns true if walking.
func is_walking() -> bool:
	return _walking
