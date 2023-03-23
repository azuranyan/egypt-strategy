extends Camera2D

onready var tween: Tween = get_node("CameraTween") as Tween



func hover_above(target_position: Vector2) -> void:
	tween.interpolate_property(
		self,
		"global_position",
		null,
		target_position,
		.85,
		Tween.TRANS_CIRC,
		Tween.EASE_OUT
	)
	
	tween.start()

