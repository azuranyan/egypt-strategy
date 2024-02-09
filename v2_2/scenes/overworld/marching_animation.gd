extends Node2D


signal done


@export_range(1, 9999) var speed: float = 200

@onready var path_follow: PathFollow2D = $PathFollow2D
@onready var sprite := %Sprite


func march(target: Vector2):
	self.curve = Curve2D.new()
	self.curve.add_point(Vector2.ZERO)
	self.curve.add_point(target - position)

	sprite.flip_h = (target.x - global_position.x) > 0
	if (target.y - global_position.y) > 0:
		sprite.play("front_walk_loop")
	else:
		sprite.play("back_walk_loop")


func _process(delta):
	path_follow.progress += delta * speed
	if path_follow.progress_ratio >= 1:
		done.emit()
		queue_free()
