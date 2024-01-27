class_name Attack
extends Resource


enum {
	TARGET_SELF = 1 << 0,
	TARGET_ALLY = 1 << 1,
	TARGET_ENEMY = 1 << 2,
}


## Display name of the attack.
@export var name: String

## Flavor text description.
@export_multiline var description: String

@export_subgroup('Effect')

## UnitState animation played for the user.
@export var user_animation: String = 'attack'

## Allows the attack to be queued more than once.
@export var multicast: int

## List of attack effects.
@export var self_effects: Array[AttackEffect] = []

## List of attack effects.
@export var enemy_effects: Array[AttackEffect] = []

## List of attack effects.
@export var ally_effects: Array[AttackEffect] = []

@export_subgroup('Targeting')

## Shape of the targeting cursor.
@export var target_shape: Array[Vector2i] = [Vector2i(0, 0)]

## Melee targeting mode.
@export var melee: bool

@export_flags("Self:1", "Ally:2", "Enemy:4") var targeting: int = TARGET_ENEMY

## Whether rotation is allowed.
@export var allow_rotation: bool

## Range of the attack.
@export var max_range: int = -1

## Minimum range of the attack.
@export var min_range: int

	
## Returns true if attack is multicast.
func is_multicast() -> bool:
	return multicast > 0
	
	
## Returns the cells in range.
func get_cells_in_range(origin: Vector2, unit_range: int) -> PackedVector2Array:
	var range := max_range if max_range != -1 else unit_range
	return Util.flood_fill(origin, range, Util.bounds(Vector2(12, 12)))


## Returns an array of cells in the target aoe.
func get_target_cells(target: Vector2, target_rotation: float) -> PackedVector2Array:
	var re := PackedVector2Array()
	for offs in target_shape:
		var m := Transform2D()
		m = m.translated(offs)
		m = m.rotated(target_rotation)
		m = m.translated(target)
		var p := m * Vector2.ZERO 
		re.append(Vector2(roundi(p.x), roundi(p.y)))
	return re
	
