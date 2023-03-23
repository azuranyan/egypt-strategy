extends Sprite

var amp: float = 5.0

onready var tween := get_node("Tween") as Tween



func _on_Tween_tween_all_completed() -> void:
	amp *= -1.0
	start_tween()


func start_tween() -> void:
	tween.interpolate_property(
		self, 
		"global_position:y", 
		null, 
		global_position.y - amp,
		.7,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
		)
	
	tween.start()


func stop_tween() -> void:
	amp = 5.0
	tween.stop_all()
