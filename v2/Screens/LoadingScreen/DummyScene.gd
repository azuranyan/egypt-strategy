extends CanvasLayer


func _ready():
	hide()
	# capture screenshot of old screen
	var img := get_viewport().get_texture().get_image()
	$TextureRect.texture = ImageTexture.create_from_image(img)
	show()
