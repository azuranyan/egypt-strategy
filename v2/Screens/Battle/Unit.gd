extends Path2D

## Object that renders a UnitInstance. This is not meant to be used directly
## and instead use add_unit_type, add_unit_instance or add_ghost.
class_name Unit


# Internal important signals
signal world_changed
signal unit_type_changed
signal empire_changed

# Visible properties
signal world_pos_changed
signal unit_name_changed
signal facing_changed

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
		world = value
		world_changed.emit()

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
var world_pos := Vector2.ZERO:
	set(value):
		world_pos = value
		world_pos_changed.emit()

## Where this unit is facing.
var facing: float = PI:
	set(value):
		facing = value
		facing_changed.emit()

## If this unit is walking.
var is_walking := false:
	set(value):
		is_walking = value
		
		# setting is_walking to false while unit is still walking may cause bugs
		set_process(is_walking)


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


@onready var model := $PathFollow2D/UnitModel as UnitModel
@onready var shadow := $PathFollow2D/Shadow as Sprite2D
@onready var animation := $AnimationPlayer as AnimationPlayer
@onready var path_follow := $PathFollow2D as PathFollow2D
@onready var debug := $Debug
@onready var hud := $PathFollow2D/HUD

@onready var _hud_hp_bar = $PathFollow2D/HUD/hp_bar
@onready var _hud_hp_label = $PathFollow2D/HUD/hp_label
@onready var _hud_name =  $PathFollow2D/HUD/name
@onready var _hud_rect =  $PathFollow2D/HUD/rect
@onready var _hud_status_effects =  $PathFollow2D/HUD/StatusEffects


##
static func create(node: Node, kwargs: Dictionary) -> Unit:
	var unit := preload("res://Screens/Battle/Unit.tscn").instantiate() as Unit
	node.add_child(unit)
	unit.load_vars(kwargs)
	return unit


# Called when the node enters the scene tree for the first time.
func _ready():
	# we can only connect after _ready
	world_changed.connect(_on_world_changed)
	unit_type_changed.connect(_on_unit_type_changed)
	
	world_pos_changed.connect(_on_world_pos_changed)
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
	if not is_walking:
		return # because fuckface still processes even when set_process(false)
	
	_old_pos = path_follow.position
	
	path_follow.progress += walk_speed * delta
	
	var v := world.screen_to_world(path_follow.position) - world.screen_to_world(_old_pos)
	facing = atan2(v.y, v.x)
	
	if path_follow.progress_ratio >= 1:
		walking_finished.emit()


## Convenience function to load values.
func load_vars(kwargs: Dictionary):
	_set_if_has("world", kwargs)
	_set_if_has("unit_type", kwargs)
	_set_if_has("empire", kwargs)
	
	_set_if_has("world_pos", kwargs)
	_set_if_has("name", kwargs)
	_set_if_has("facing", kwargs)
	
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
	var v := target - world_pos
	facing = atan2(v.y, v.x)


## Walks along a path.
func walk_along(path: PackedVector2Array):
	if path.is_empty():
		return
	
	# create the path
	for point in path:
		curve.add_point(world.uniform_to_screen(point) - position)
	
	# start walk cycle
	is_walking = true
	walking_started.emit()
	
	# await until walking is done
	await self.walking_finished
	
	# cleanup code
	is_walking = false
	world_pos = path[-1]
	path_follow.progress = 0
	curve.clear_points()


## Sets the general direction of this object.
func set_heading(value: Heading):
	facing = value * PI/2
	
	
## Returns the general direction of this object.
func get_heading() -> Heading:
	return model.get_heading()


## Snaps self to grid.
func snap_to_grid():
	world_pos = Vector2(roundi(world_pos.x), roundi(world_pos.y))
	

func _on_world_changed():
	position = world.uniform_to_screen(world_pos)
	
	var m = Transform2D()
	
	# scale to downsize to unit vector
	var shadow_scale := 1.0
	m = m.scaled(Vector2(shadow_scale, shadow_scale)/shadow.texture.get_size())

	# scale to tile size
	m = m.scaled(Vector2(world.tile_size, world.tile_size))

	shadow.transform = world._world_to_screen_transform * m
	
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
	
	
func _on_world_pos_changed():
#	if not world.in_bounds(world_pos):
#		world_pos = world.clamp_pos(world_pos)
#	else:
	position = world.uniform_to_screen(world_pos)
	

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


## Simple class for holding status effect instance information.
class AppliedStatusEffect:
	var status_effect: StatusEffect
	var duration: int
	var stacks: int
	
