@tool
extends Node

## Instance of a unit type that's also a component.
class_name UnitInstance


signal stat_changed(stat: String)
signal status_effect_added(effect: AppliedStatusEffect)
signal status_effect_changed(effect: AppliedStatusEffect)
signal status_effect_removed(effect: AppliedStatusEffect)
signal empire_changed


enum Heading { East, North, West, South }

enum {
	RESET_HP = 1 << 0,
	RESET_STATS = 1 << 1,
	RESET_BOND = 1 << 2,
	RESET_STATUS_EFFECTS = 1 << 3,
	RESET_ALL = RESET_HP | RESET_STATS | RESET_STATUS_EFFECTS | RESET_BOND,
}

	
## The unit archetype.
@export var unit_type: UnitType:
	set(value):
		unit_type = value
		if unit_type:
			update_unit_type()
		update_configuration_warnings()


var maxhp: int:
	set(value):
		maxhp = value
		stat_changed.emit("maxhp")
		
var hp: int:
	set(value):
		hp = value
		stat_changed.emit("hp")
		
var mov: int:
	set(value):
		mov = value
		stat_changed.emit("mov")
		
var dmg: int:
	set(value):
		dmg = value
		stat_changed.emit("dmg")
		
var rng: int:
	set(value):
		rng = value
		stat_changed.emit("rng")
		
var bond: int:
	set(value):
		bond = value
		stat_changed.emit("bond")

var status_effects: Array[AppliedStatusEffect] = []

var empire: Empire:
	set(value):
		empire = value
		empire_changed.emit()


func _get_configuration_warnings() -> PackedStringArray:
	var re := PackedStringArray()
	if unit_type == null:
		re.append("unit_type cannot be null")
	return re


## Internal function to change the unit type.
func update_unit_type():
	reset()
	if name == "UnitInstance" or name == "":
		name = unit_type.name


## Resets the unit.
func reset(flags := RESET_ALL):
	if flags & RESET_STATS != 0:
		maxhp = unit_type.stat_hp
		mov = unit_type.stat_mov
		dmg = unit_type.stat_dmg
		rng = unit_type.basic_attack.range
	
	if flags & RESET_HP != 0:
		hp = maxhp
		
	if flags & RESET_BOND != 0:
		bond = 0
	
	if flags & RESET_STATUS_EFFECTS != 0:
		for effect in status_effects:
			status_effect_removed.emit(effect)
		status_effects.clear()
	

## Adds a status effect.
func add_status_effect(status_effect: StatusEffect, duration: int):
	var effect := AppliedStatusEffect.new()
	effect.status_effect = status_effect
	effect.duration = duration
	
	status_effects.append(effect)
	status_effect_added.emit(effect)
	
	
## Ticks down the duration of a status effect.
func tick_status_effect(effect: AppliedStatusEffect):
	effect.duration -= 1
	status_effect_changed.emit(effect)
	if effect.duration <= 0:
		remove_status_effect(effect)


## Removes a status effect.
func remove_status_effect(effect: AppliedStatusEffect):
	status_effects.erase(effect)
	status_effect_removed.emit(effect)


## Returns true if player owned.
func is_player_owned() -> bool:
	return empire and empire.is_player_owned()
	
	
## Returns the leader if present.
func get_leader() -> Chara:
	return empire.leader if empire else null


## Simple class for holding status effect instance information.
class AppliedStatusEffect:
	var status_effect: StatusEffect
	var duration: int
	var stacks: int
	
