class_name AddFXEffect
extends AttackEffect
	

@export var sprite_frames: SpriteFrames = preload("res://Screens/Battle/data/default_effects.tres")

@export var animation: String = 'basic_damage'


func apply(_battle: Battle, _user: Unit, attack: Attack, _target_cell: Vector2i, target_unit: Unit) -> void:
	var gfx := preload("res://Screens/Battle/GFX.tscn").instantiate()
	gfx.sprite_frames = sprite_frames
	gfx.animation = animation
	target_unit.add_child(gfx, false, Node.INTERNAL_MODE_BACK)
	
	attack.effect_complete(self)
	
