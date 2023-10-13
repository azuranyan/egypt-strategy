extends Resource
class_name Attack

enum {
	Ground = 1 << 0,
	Enemy = 1 << 1,
	Ally = 1 << 2,
	Self = 1 << 3,
}

# The damage attack inflicts == chara.dmg.
# fixed_damage, multiplier_damage, heal_amount are all metadata
# icon, animation_tag, etc

## The name of this attack.
@export var name: String

## A short description for this attack.
@export var description: String

## The range hint for this attack.
@warning_ignore("shadowed_global_identifier")
@export var range: int

## Attack type.
@export_enum("attack", "heal", "other") var type_tag: String = "attack"

## Status effect this attack may inflict.
@export_enum("None", "PSN", "STN", "VUL") var status_effect: String = "None"

## Cast animation string.
@export var cast_animation: String = "attack"

## Target animation string.
@export var target_animation: String = "hurt"

## If true, attack can only change direction and not freely repositioned.
@export var target_melee: bool = false:
	set(value):
		target_melee = (target_unit == Self) or value
	get:
		return target_melee

## Selecting valid targets.
@export_flags("Enemy", "Ally", "Self") var target_unit: int = 1:
	set(value):
		target_unit = value
		target_melee = target_melee
	get:
		return target_unit
	
## the shape of the targeting area.
@export var target_shape: Array[Vector2i] = [Vector2i(0, 0)]

