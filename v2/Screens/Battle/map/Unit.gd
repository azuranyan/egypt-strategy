@tool
extends Path2D

## Object that renders a UnitInstance. This is not meant to be used directly
## and instead use add_unit_type, add_unit_instance or add_ghost.
class_name Unit


# Internal important signals
signal world_changed
signal unit_type_changed
signal empire_changed

# Visible properties
signal map_pos_changed
signal unit_name_changed
signal facing_changed
signal selectable_changed

# Control signals
signal button_down(button: int)
signal button_up(button: int)
signal walking_started
signal walking_finished

# Data signals
signal stat_changed(stat: String)
signal status_effect_added(effect: AppliedStatusEffect)
signal status_effect_changed(effect: AppliedStatusEffect)
signal status_effect_removed(effect: AppliedStatusEffect)


## The general direction.
enum Heading { East, South, West, North }

enum {
	RESET_HP = 1 << 0,
	RESET_STATS = 1 << 1,
	RESET_BOND = 1 << 2,
	RESET_STATUS_EFFECTS = 1 << 3,
	RESET_ANIMATION = 1 << 4,
	RESET_ALL = RESET_HP | RESET_STATS | RESET_STATUS_EFFECTS | RESET_BOND | RESET_ANIMATION,
}


## How fast the unit walks.
@export var walk_speed := 600.0


## Internal properties.

## The world object.
var world: World:
	set(value):
		_world = value
		world_changed.emit()
	get:
		return _world

## This objects unit type.
var unit_type: UnitType:
	set(value):
		unit_type = value
		unit_type_changed.emit()
		
## The empire this object belongs to.
var empire: Empire:
	set(value):
		empire = value
		empire_changed.emit()


## Visible properties.

## Custom name for this unit.
var unit_name: String:
	set(value):
		unit_name = value
		unit_name_changed.emit()

## The position of this unit in the world.
var map_pos := Vector2.ZERO:
	set(value):
		_map_pos = value
		map_pos_changed.emit()
	get:
		return _map_pos

## Where this unit is facing.
var facing: float = PI:
	set(value):
		facing = value
		facing_changed.emit()

## If this unit is walking.
var walking := false:
	set(value):
		walking = value
		
		# setting walking to false while unit is still walking may cause bugs
		set_process(walking)
		
## Whether to allow selection interaction with this unit.
var selectable := true:
	set(value):
		selectable = value
		selectable_changed.emit()
		

## Allows the unit to phase through units.
var phase_units: bool = false

## Allows the unit to phase through objects.
var phase_doodads: bool = false

## Allows the unit to phase and stand on everything.
var flying: bool = false


# Data properties

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


# Private properties

var _old_pos: Vector2
var _map_pos: Vector2
var _world: World

@onready var mapobject := $MapObject as MapObjectComponent

@onready var model := $PathFollow2D/UnitModel as UnitModel
@onready var shadow := $PathFollow2D/Shadow as Sprite2D
@onready var animation := $AnimationPlayer as AnimationPlayer
@onready var path_follow := $PathFollow2D as PathFollow2D
@onready var debug := $Debug
@onready var hud := $PathFollow2D/HUD
@onready var input_control := $PathFollow2D/Control as Control

@onready var _hud_hp_bar = $PathFollow2D/HUD/hp_bar
@onready var _hud_hp_label = $PathFollow2D/HUD/hp_label
@onready var _hud_name =  $PathFollow2D/HUD/name
@onready var _hud_rect =  $PathFollow2D/HUD/rect
@onready var _hud_status_effects =  $PathFollow2D/HUD/StatusEffects


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
	
	map_pos_changed.connect(_on_map_pos_changed)
	unit_name_changed.connect(_on_unit_name_changed)
	
	facing_changed.connect(_on_facing_changed)
	walking_started.connect(_on_walking_started)
	walking_finished.connect(_on_walking_finished)
	
	stat_changed.connect(_on_stat_changed)
	
	# keeping a reference to curve resource makes it extremely buggy
	# because curve is a resource that get saved with the scene. this
	# is why we're creating a new curve every _ready.
	curve = Curve2D.new()


func _process(delta: float):
	if not walking:
		return # because fuckface still processes even when set_process(false)
	
	_old_pos = path_follow.position
	
	path_follow.progress += walk_speed * delta
	
	var v := world.screen_to_world(path_follow.position) - world.screen_to_world(_old_pos)
	facing = atan2(v.y, v.x)
	
	if path_follow.progress_ratio >= 1:
		walking_finished.emit()


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


## Walks along a path.
func walk_along(path: PackedVector2Array):
	if path.is_empty():
		return
	
	# create the path
	for point in path:
		curve.add_point(world.uniform_to_screen(point) - position)
	
	# start walk cycle
	walking = true
	walking_started.emit()
	
	# await until walking is done
	await self.walking_finished
	
	# cleanup code
	walking = false
	map_pos = path[-1]
	path_follow.progress = 0
	curve.clear_points()
	

## Stops walking
func stop_walking():
	if walking:
		walking_finished.emit()


## Sets the general direction of this object.
func set_heading(value: Heading):
	facing = value * PI/2
	
	
## Returns the general direction of this object.
func get_heading() -> Heading:
	return model.get_heading()


## Snaps self to grid.
func snap_to_grid():
	map_pos = Vector2(roundi(map_pos.x), roundi(map_pos.y))
	

## Returns true if unit can path through node.
func can_path(node: Node) -> bool:
	match node.mapobject.pathing_group:
		Map.Pathing.NONE:
			return true
		Map.Pathing.UNIT:
			if node.empire == empire:
				return true
			else:
				return phase_units
		Map.Pathing.DOODAD:
			return phase_doodads
		Map.Pathing.TERRAIN:
			return flying
		Map.Pathing.IMPASSABLE, _:
			return false


## Returns true if unit can stand on node.
func can_stand(node: Node) -> bool:
	match node.mapobject.pathing_group:
		Map.Pathing.NONE:
			return true
		Map.Pathing.DOODAD, Map.Pathing.TERRAIN:
			return flying
		Map.Pathing.UNIT, Map.Pathing.IMPASSABLE, _:
			return false


## Used for the awkward syncing of component properties.
func _update_map_pos(__pos: Vector2):
	_map_pos = __pos
	position = _world.uniform_to_screen(_map_pos)
	
	
## Used for the awkward syncing of component properties.
func _update_world(__world: World):
	_world = __world
	
	position = _world.uniform_to_screen(_map_pos)
	
	var m = Transform2D()
	
	# scale to downsize to unit vector
	var shadow_scale := 1.0
	m = m.scaled(Vector2(shadow_scale, shadow_scale)/shadow.texture.get_size())

	# scale to tile size
	m = m.scaled(Vector2(_world.tile_size, _world.tile_size))

	shadow.transform = _world._world_to_screen_transform * m
	
	# offset shadow
	shadow.position = Vector2.ZERO


################################################################################
# Signals
################################################################################


func _on_world_changed():
	mapobject.world = world


func _on_unit_type_changed():
	# stuff that don't get reset are reset here
	model.sprite_frames = unit_type.sprite_frames
	
	unit_name = unit_type.name
	
	_hud_rect.color = unit_type.map_color
	
	reset()
	

func _on_unit_name_changed():
	_hud_name.text = unit_name
	
	
func _on_map_pos_changed():
	mapobject.map_pos = map_pos
	
	
func _on_selectable_changed():
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


func _on_walking_started():
	model.animation = "walk"


func _on_walking_finished():
	model.animation = "idle"


func _on_map_object_map_pos_changed():
	_update_map_pos(mapobject.map_pos)
	

func _on_map_object_world_changed():
	_update_world(mapobject.world)


################################################################################
# Classes
################################################################################


## Simple class for holding status effect instance information.
class AppliedStatusEffect:
	var status_effect: StatusEffect
	var duration: int
	var stacks: int
	



