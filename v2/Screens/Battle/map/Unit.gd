@tool
extends MapObject

## Object that renders a UnitInstance. This is not meant to be used directly
## and instead use add_unit_type, add_unit_instance or add_ghost.
class_name Unit


# Internal important signals
signal unit_type_changed
signal empire_changed

# Visible properties
signal unit_name_changed
signal facing_changed
signal selectable_changed

# Control signals
signal button_down(button: int)
signal button_up(button: int)
#signal walking_started
#signal walking_finished

# Data signals
signal stat_changed(stat: String)
signal status_effect_added(effect: AppliedStatusEffect)
signal status_effect_changed(effect: AppliedStatusEffect)
signal status_effect_removed(effect: AppliedStatusEffect)


## The general direction.
enum Heading { East, South, West, North }

const Directions := [
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(-1, 0),
	Vector2(0, -1),
]

enum {
	RESET_HP = 1 << 0,
	RESET_STATS = 1 << 1,
	RESET_BOND = 1 << 2,
	RESET_STATUS_EFFECTS = 1 << 3,
	RESET_ANIMATION = 1 << 4,
	RESET_ALL = RESET_HP | RESET_STATS | RESET_STATUS_EFFECTS | RESET_BOND | RESET_ANIMATION,
}

## Internal properties.

## This objects unit type.
@export var unit_type: UnitType:
	set(value):
		unit_type = value
		unit_type_changed.emit()
		
## The empire this object belongs to.
var empire: Empire:
	set(value):
		empire = value
		empire_changed.emit()


## Visible properties.

@export_subgroup("Display")

## How fast the unit walks.
@export var walk_speed := 600.0

## Custom name for this unit.
@export var unit_name: String:
	set(value):
		unit_name = value
		unit_name_changed.emit()

## Where this unit is facing.
@export var facing: float:
	set(value):
		facing = fmod(value, 2*PI)
		facing_changed.emit()

### If this unit is walking.
#var walking := false:
#	set(value):
#		walking = value
#
#		# setting walking to false while unit is still walking may cause bugs
#		set_process(walking)
		
## Whether to allow selection interaction with this unit.
@export var selectable := true:
	set(value):
		selectable = value
		selectable_changed.emit()
		
		
@export_subgroup("Pathing")

## Allows the unit to phase through units.
@export var phase_units: bool = false

## Allows the unit to phase through objects.
@export var phase_doodads: bool = false

## Allows the unit to phase and stand on everything.
@export var flying: bool = false


# Data properties

@export_subgroup("Stats")

@export var maxhp: int:
	set(value):
		maxhp = value
		stat_changed.emit("maxhp")
		
@export var hp: int:
	set(value):
		hp = value
		stat_changed.emit("hp")
		
@export var mov: int:
	set(value):
		mov = value
		stat_changed.emit("mov")
		
@export var dmg: int:
	set(value):
		dmg = value
		stat_changed.emit("dmg")
		
@export var rng: int:
	set(value):
		rng = value
		stat_changed.emit("rng")
		
@export var bond: int:
	set(value):
		bond = value
		stat_changed.emit("bond")

var status_effects: Array[AppliedStatusEffect] = []


# Private properties

var _old_pos: Vector2

@onready var model := $UnitModel as UnitModel
@onready var shadow := $Shadow as Sprite2D
@onready var animation := $AnimationPlayer as AnimationPlayer
@onready var debug := $Debug
@onready var hud := $HUD
@onready var input_control := $Control as Control

@onready var _hud_hp_bar = $HUD/hp_bar
@onready var _hud_hp_label = $HUD/hp_label
@onready var _hud_name =  $HUD/name
@onready var _hud_rect =  $HUD/rect
@onready var _hud_status_effects =  $HUD/StatusEffects


##
static func create(node: Node, kwargs: Dictionary) -> Unit:
	var unit := preload("res://Screens/Battle/map/Unit.tscn").instantiate() as Unit
	node.add_child(unit)
	unit.load_vars(kwargs)
	return unit


func _ready():
	# we can only connect after _ready
	world_changed.connect(_on_world_changed)
	unit_type_changed.connect(_on_unit_type_changed)
	
	unit_name_changed.connect(_on_unit_name_changed)
	
	facing_changed.connect(_on_facing_changed)
	#selectable_changed.connect(_on_selectable_changed)
#	walking_started.connect(_on_walking_started)
#	walking_finished.connect(_on_walking_finished)
	
	stat_changed.connect(_on_stat_changed)
	
	# keeping a reference to curve resource makes it extremely buggy
	# because curve is a resource that get saved with the scene. this
	# is why we're creating a new curve every _ready.
#	curve = Curve2D.new()
	


#func _process(delta: float):
#	if not walking:
#		return # because fuckface still processes even when set_process(false)
#
#	_old_pos = path_follow.position
#
#	path_follow.progress += walk_speed * delta
#
#	var v := world.screen_to_world(path_follow.position) - world.screen_to_world(_old_pos)
#	facing = atan2(v.y, v.x)
#
#	if path_follow.progress_ratio >= 1:
#		walking_finished.emit()


################################################################################
# Object
################################################################################


## Convenience function to load values.
func load_vars(kwargs: Dictionary):
	_set_if_has("world", kwargs)
	_set_if_has("unit_type", kwargs)
	_set_if_has("empire", kwargs)
	
	_set_if_has("map_pos", kwargs)
	_set_if_has("name", kwargs)
	_set_if_has("facing", kwargs)
	_set_if_has("selectable", kwargs)
	
	if kwargs.has("heading"):
		set_heading(kwargs.get("heading"))
	
	_set_if_has("modulate", kwargs)
		
	hud.visible = kwargs.get("hud", hud.visible)
	shadow.visible = kwargs.get("shadow", shadow.visible)
	debug.visible = kwargs.get("debug", debug.visible)
	
	
func _set_if_has(prop: String, kwargs: Dictionary):
	if kwargs.has(prop):
		assert(kwargs.get(prop) != null)
		set(prop, kwargs.get(prop))


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
		
	if flags & RESET_ANIMATION:
		model.refresh_animation()
		
		
## Adds a status effect.
func add_status_effect(status_effect: StatusEffect, duration: int) -> AppliedStatusEffect:
	var effect := AppliedStatusEffect.new()
	effect.status_effect = status_effect
	effect.duration = duration
	
	status_effects.append(effect)
	status_effect_added.emit(effect)
	return effect
	

## Removes a status effect.
func remove_status_effect(effect: AppliedStatusEffect):
	status_effects.erase(effect)
	status_effect_removed.emit(effect)


## Ticks down the duration of status effects.
func tick_status_effects():
	var copy := status_effects.duplicate()
	for eff in copy:
		tick_status_effect(eff)


## Ticks down the duration of a status effect.
func tick_status_effect(effect: AppliedStatusEffect):
	effect.duration -= 1
	status_effect_changed.emit(effect)
	if effect.duration <= 0:
		remove_status_effect(effect)


## Returns true if player owned.
func is_player_owned() -> bool:
	return empire and empire.is_player_owned()
	
	
## Returns the leader if present.
func get_leader() -> Chara:
	return empire.leader if empire else null
	
		
## Faces towards target.
func face_towards(target: Vector2):
	var v := target - map_pos
	facing = atan2(v.y, v.x)


### Walks along a path.
#func walk_along(path: PackedVector2Array):
#	if path.is_empty():
#		return
#
#	# create the path
#	for point in path:
#		curve.add_point(world.uniform_to_screen(point) - position)
#
#	# start walk cycle
#	walking = true
#	walking_started.emit()
#
#	# await until walking is done
#	await self.walking_finished
#
#	# cleanup code
#	walking = false
#	map_pos = path[-1]
#	path_follow.progress = 0
#	curve.clear_points()
	

## Stops walking
#func stop_walking():
#	if walking:
#		walking_finished.emit()


## Sets the general direction of this object.
func set_heading(value: Heading):
	facing = value * PI/2
	
	
## Returns the general direction of this object.
func get_heading() -> Heading:
	return model.get_heading()


## Snaps self to grid.
func snap_to_grid():
	map_pos = Vector2(roundi(map_pos.x), roundi(map_pos.y))
	

################################################################################
# Convenience functions
################################################################################


## Returns true if unit can path through obj.
func can_path(obj: MapObject) -> bool:
	if obj:
		match obj.pathing:
			Map.Pathing.UNIT:
				if is_enemy(obj):
					return phase_units
			Map.Pathing.DOODAD:
				return phase_doodads
			Map.Pathing.TERRAIN:
				return flying
			Map.Pathing.IMPASSABLE:
				return false
	return true


## Returns true if unit can be placed on top of obj.
func can_place(obj: MapObject) -> bool:
	if obj:
		match obj.pathing:
			Map.Pathing.DOODAD, Map.Pathing.TERRAIN:
				return flying
			Map.Pathing.UNIT, Map.Pathing.IMPASSABLE:
				return false
	return true


## Returns true if the other unit is an ally.
func is_ally(other: Unit) -> bool:
	return other.empire == empire
	

## Returns true if the other unit is an enemy.
func is_enemy(other: Unit) -> bool:
	return other.empire != empire
	

################################################################################
# Signals
################################################################################


func _on_world_changed():
	var m = Transform2D()
	
	if world:
		# scale to downsize to unit vector
		var shadow_scale := 1.0
		m = m.scaled(Vector2(shadow_scale, shadow_scale)/shadow.texture.get_size())

		# scale to tile size
		m = m.scaled(Vector2(world.tile_size, world.tile_size))
		
		m = world._world_to_screen_transform * m

	shadow.transform = m
	
	# offset shadow
	shadow.position = Vector2.ZERO


func _on_unit_type_changed():
	# stuff that don't get reset are reset here
	model.sprite_frames = unit_type.sprite_frames
	
	unit_name = unit_type.name
	
	_hud_rect.color = unit_type.map_color
	
	reset()
	

func _on_unit_name_changed():
	_hud_name.text = unit_name
	
	
func _on_selectable_changed():
	if not is_node_ready():
		await self.ready
	# there's no set_process_gui_input
	# input_control.set_process_gui_input()
	if selectable:
		input_control.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		input_control.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_stat_changed(stat):
	match stat:
		"hp", "maxhp":
			_hud_hp_bar.scale = Vector2(hp/float(maxhp), 1)
			_hud_hp_label.text = "%s/%s" % [hp, maxhp]


func _on_status_effect_added(effect):
	var icon = preload("res://Screens/Battle/StatusEffectIcon.tscn").instantiate()
	_hud_status_effects.add_child(icon)
	icon.texture = effect.status_effect.icon
	effect.set_meta("hud_icon", icon)


func _on_status_effect_changed(effect):
	if effect.duration <= 1:
		effect.get_meta("hud_icon").get_node("AnimationPlayer").play("blink")


func _on_status_effect_removed(effect: Object):
	var icon = effect.get_meta("hud_icon")
	effect.remove_meta("hud_icon")
	_hud_status_effects.remove_child(icon)
	icon.free()


func _on_control_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			button_down.emit(event.button_index)
		else:
			button_up.emit(event.button_index)


func _on_facing_changed():
	model.facing = facing


################################################################################
# Classes
################################################################################


## Simple class for holding status effect instance information.
class AppliedStatusEffect:
	var status_effect: StatusEffect
	var duration: int
	var stacks: int
	



