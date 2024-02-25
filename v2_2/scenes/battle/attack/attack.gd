class_name Attack
extends Resource


enum {
	## Allows the user to target itself.
	TARGET_SELF = 1 << 0,
	
	## Allows the user to target an ally.
	TARGET_ALLY = 1 << 1,
	
	## Allows the user to target an enemy.
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

## Automatically include user in the target units.
## This will cause the user to be hit once with the self_effects.
## If set to true and the user is also included in the target units, will cause it to hit twice.
@export var include_user: bool

## Attack target flags.
@export_flags("Self:1", "Ally:2", "Enemy:4") var target_flags: int = TARGET_ENEMY

## Whether rotation is allowed.
@export var allow_rotation: bool

## Range of the attack.
@export var max_range: int = -1

## Minimum range of the attack.
@export var min_range: int

	
## Returns true if attack is multicast.
func is_multicast() -> bool:
	return multicast > 0
	
	
## Returns the attack range for a given unit.
func attack_range(unit_range: int) -> int:
	return max_range if max_range != -1 else unit_range


## Returns the cells in range.
func get_cells_in_range(cell: Vector2, unit_range: int) -> PackedVector2Array:
	var _range := attack_range(unit_range)
	if melee:
		return [
			Vector2(cell.x, cell.y + _range),
			Vector2(cell.x, cell.y - _range),
			Vector2(cell.x + _range, cell.y),
			Vector2(cell.x - _range, cell.y),
		]
	else:
		return Util.flood_fill(cell, _range, Util.bounds(Vector2(12, 12)))


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
	
	
## Returns the name of this attack.
func _to_string() -> String:
	return name
