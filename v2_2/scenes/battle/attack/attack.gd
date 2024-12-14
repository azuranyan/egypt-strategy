@tool
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

## Unformatted flavor text description. Use [method get_formatted_description] for formatted description.
@export_multiline var description: String

## Description args for formatting.
@export var description_args: Dictionary

@export_group('Casting')

## UnitState animation played for the user.
@export var user_animation: String = 'attack'

## Allows the attack to be queued more than once.
@export var multicast: int

## Maximum range of the attack.
@export var max_range: int = -1

## Minimum range of the attack.
@export var min_range: int

@export_group('Effects')

## Automatically include user in the target units causing [member self_effects] to
## trigger immediately. If set to true and the user is also included in the target
## units, will cause it to trigger again.
@export var include_user: bool

## List of attack effects.
@export var self_effects: Array[AttackEffect] = []

## List of attack effects.
@export var ally_effects: Array[AttackEffect] = []

## List of attack effects.
@export var enemy_effects: Array[AttackEffect] = []

@export_group('Targeting')

## Shape of the targeted area.
@export var target_shape: Array[Vector2i] = [Vector2i(0, 0)]

## Melee targeting mode. Melee attacks cannot be rotated and can only target
## [member max_range] in the direction the unit is facing.
@export var melee: bool

## Attack target flags.
@export_flags("Self:1", "Ally:2", "Enemy:4") var target_flags: int = TARGET_ENEMY

## Whether rotation is allowed.
@export var allow_rotation: bool


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
		var cells := Util.flood_fill(cell, Battle.instance().world_bounds(), _range)
		if min_range > 0:
			var re := PackedVector2Array()
			for c in cells:
				if Util.cell_distance(cell, c) > min_range:
					re.append(c)
			return re
		else:
			return cells


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


## Returns formatted description.
func get_formatted_description(env := {}) -> String:
	var combined_args := description_args.duplicate()
	combined_args.merge(env, false)
	var colored_description := description.replace('{', '[color=#111111]{').replace('}', '}[/color]')
	return colored_description.format(combined_args)
