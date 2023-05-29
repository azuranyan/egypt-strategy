extends TextureRect

func _draw():
	# Draw black outline around TextureRect
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0, 0, 0, 1), false, 2)


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
