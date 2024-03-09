@tool
class_name DefeatTargetObjective
extends Objective


enum TargetType {
	PRE_PLACED_UNIT,
	PLAYER_HERO,
	ENEMY_HERO,
	CHARA_ID,
	CHARA_NAME,
}


## The type of target.
@export var target_type: TargetType:
	set(value):
		target_type = value
		match target_type:
			TargetType.PLAYER_HERO, TargetType.ENEMY_HERO, TargetType.PRE_PLACED_UNIT:
				target_data = null
			TargetType.CHARA_ID:
				target_data = &''
			TargetType.CHARA_NAME:
				target_data = ''
		notify_property_list_changed()


var target_data: Variant


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	match target_type:
		TargetType.PLAYER_HERO:
			props.append({
				name = "target_data",
				type = TYPE_NIL,
				usage = PROPERTY_USAGE_NO_EDITOR,
			})
		TargetType.ENEMY_HERO:
			props.append({
				name = "target_data",
				type = TYPE_NIL,
				usage = PROPERTY_USAGE_NO_EDITOR,
			})
		TargetType.PRE_PLACED_UNIT:
			props.append({
				name = "target_data",
				type = TYPE_OBJECT,
				hint = PROPERTY_HINT_NODE_TYPE,
				hint_string = 'UnitMapObject',
				usage = PROPERTY_USAGE_DEFAULT,
			})
		TargetType.CHARA_ID:
			props.append({
				name = "target_data",
				type = TYPE_STRING_NAME,
				usage = PROPERTY_USAGE_DEFAULT,
			})
		TargetType.CHARA_NAME:
			props.append({
				name = "target_data",
				type = TYPE_STRING,
				usage = PROPERTY_USAGE_DEFAULT,
			})
	return props


func _activated() -> void:
	var target := target_unit()
	if not target:
		push_warning("Trigger cannot find target unit" % target_type)
		deactivate()
		return
	UnitEvents.died.connect(_on_unit_defeated)


func _deactivated() -> void:
	UnitEvents.died.disconnect(_on_unit_defeated)


## Returns the target unit.
func target_unit() -> Unit:
	match target_type:
		TargetType.PLAYER_HERO:
			return Game.get_hero_unit(Battle.instance().player())
		TargetType.ENEMY_HERO:
			return Game.get_hero_unit(Battle.instance().ai())
		TargetType.PRE_PLACED_UNIT:
			push_error("pre placed unit not supported yet")
			return null
		TargetType.CHARA_ID:
			return Game.find_unit_by_chara_id(target_data)
		TargetType.CHARA_NAME:
			return Game.find_unit_by_name(target_data)
	return null


## Returns the description.
func description() -> String:
	var unit := target_unit()
	var target_name := unit.display_name() if unit else "<null>"
	return "Defeat " + target_name + countdown_suffix()


func _on_unit_defeated(unit: Unit) -> void:
	if unit == target_unit():
		objective_completed(BattleResult.empire_victory(Battle.instance().player()))
