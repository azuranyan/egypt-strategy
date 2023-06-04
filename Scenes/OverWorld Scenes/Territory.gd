extends TextureButton

class_name Territory

# Exposed properties
export var territory_name: String = ""
export var adjacient_territories: Array = []
export var units: Array = []
export var training_battle_scenes: Array = []
export var invasion_scene: PackedScene

# Internal properties
onready var owner_name_label: Label = get_node("CanvasLayer/ColorRect/OwnerAndStrengthLabel")
var strength = "Full"
var owner_name = ""

func update_display_strength(new_strength):
	strength = new_strength
	owner_name_label.text = owner_name_label.text % [owner_name,strength]
	
func update_owner(new_owner):
	owner_name = new_owner
	owner_name_label.text = owner_name_label.text % [owner_name,strength]

# Change owner function
func change_owner(new_owner: String) -> void:
	update_owner(new_owner)
	
	# Change texture for all button states
	var texture_path = "res://assets/CharacterPotraits2/" + new_owner + ".png"
	var texture = load(texture_path)
	set_button_texture(texture)

	# Generate click mask from the image
	var click_mask = ImageTexture.new()
	click_mask.create_from_image_alpha(texture.get_data())
	set_click_mask(click_mask)

# Set button texture for all states
func set_button_texture(texture: Texture) -> void:
	texture_normal = texture
	texture_hover = texture
	texture_pressed = texture
	texture_disabled = texture

# Initialization
func _ready() -> void:
	pass
	# Find owner name label by name
	# Connect the button's pressed signal to handle invasion
	#connect("pressed", self, "_on_territory_pressed")


func _on_Territory_mouse_entered() -> void:
	_on_Territory_focus_entered()
	

func _on_Territory_focus_entered() -> void:
	$AnimationPlayer.play("Appear")

