extends CanvasLayer


func _ready():
	# capture screenshot of old screen
	var img := get_viewport().get_texture().get_image()
	$TextureRect.texture = ImageTexture.create_from_image(img)


func _unhandled_input(_event):
	# intercept all inputs when active
	get_viewport().set_input_as_handled()
