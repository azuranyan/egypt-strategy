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


enum Tag {
	ATTACK, ## Default tag for damaging attacks with no extra properties.
	DOT, ## Damaging attack but is dot instead of one big damage.
	DEBUFF, ## Tag for attacks that inflict debuffs.
	OFFENSIVE_BUFF, ## Skill is an offensive buff.
	DEFENSIVE_BUFF, ## Skill is a defensive buff.
	HEAL, ## Tag for recovery skills.
	CC, ## Tag for crowd control abilities.
	RELOCATE_ENEMY, ## Tag for skills that relocates the enemy.
	RELOCATE_SELF, ## Tag for skills that relocates the user.
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

@export_group("Tags")

## List of tags for metadata.
@export var tags: Array[Tag] = [Tag.ATTACK]


## Returns true if attack is multicast.
func is_multicast() -> bool:
	return multicast > 0
	
	
## Returns the attack range for a given unit.
func attack_range(unit_range: int) -> int:
	return max_range if max_range != -1 else unit_range


## Returns the cells in range.
func get_cells_in_range(cell: Vector2, unit_range: int) -> PackedVector2Array:
	var r := attack_range(unit_range)
	if melee:
		# if the attack is melee, we simply return the cells in each cardinal direction at max range
		return [
			Vector2(cell.x, cell.y + r),
			Vector2(cell.x, cell.y - r),
			Vector2(cell.x + r, cell.y),
			Vector2(cell.x - r, cell.y),
		]
	else:
		# if the attack is ranged, we return all the cells within the attack range
		var re := PackedVector2Array()
		for x in range(-r, r + 1):
			for y in range(-r, r + 1):
				var d := absi(x) + absi(y)
				if d > min_range and d <= r:
					re.append(Vector2(x, y))
		return re


## Returns an array of cells in the target aoe.
func get_target_cells(target: Vector2, target_rotation: float) -> PackedVector2Array:
	var re := PackedVector2Array()

	# snap rotation into 90 degrees
	match Map.to_heading(target_rotation):
		Map.Heading.EAST:
			for offs: Vector2 in target_shape:
				re.append(target + offs)
		Map.Heading.SOUTH:
			for offs: Vector2 in target_shape:
				re.append(target + Vector2(offs.y, -offs.x))
		Map.Heading.WEST:
			for offs: Vector2 in target_shape:
				re.append(target + Vector2(-offs.x, -offs.y))
		Map.Heading.NORTH:
			for offs: Vector2 in target_shape:
				re.append(target + Vector2(-offs.y, offs.x))

	assert(not re.is_empty())
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
