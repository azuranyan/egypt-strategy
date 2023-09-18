@tool
extends Control

signal sprite_source_changed

@export var sprite_source: Sprite2D:
	set(value):
		sprite_source = value
		sprite_source_changed.emit()


@onready var button := $TextureButton as TextureButton


func _ready():
	sprite_source_changed.connect(_on_sprite_changed)
	
	sprite_source = sprite_source


func _on_sprite_changed():
	if sprite_source:
		var mask := BitMap.new()
		mask.create_from_image_alpha(sprite_source.texture.get_image())
		
		button.texture_click_mask = mask
		button.size = sprite_source.texture.get_size()
		button.position = sprite_source.position
		button.rotation = sprite_source.rotation
		button.scale = sprite_source.scale


func _on_button_pressed():
	print("pressed")
