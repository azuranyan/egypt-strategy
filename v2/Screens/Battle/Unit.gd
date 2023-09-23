extends Path2D

## Object that renders a UnitInstance. This is not meant to be used directly
## and instead use add_unit_type, add_unit_instance or add_ghost.
class_name Unit

signal world_changed

signal unit_changed
signal world_pos_changed
signal facing_changed
signal button_down(button: int)
signal button_up(button: int)

signal walking_started
signal walking_finished


enum Heading { East, South, West, North }


## How fast the unit walks.
@export var walk_speed := 600.0

## The world object.
@export var world: World:
	set(value):
		world = value
		world_changed.emit()

## The position of this unit in the world.
@export var world_pos := Vector2.ZERO:
	set(value):
		world_pos = value
		world_pos_changed.emit()

## Where this unit is facing.
@export var facing: float = PI:
	set(value):
		facing = value
		facing_changed.emit()


## The unit instance component.
var unit_instance: UnitInstance:
	set(value):
		if unit_instance:
			_disconnect_unit(unit_instance)
		unit_instance = value
		if unit_instance:
			_connect_unit(unit_instance)
		unit_changed.emit()

## If this unit is walking.
var is_walking := false:
	set(value):
		is_walking = value
		
		# setting is_walking to false while unit is still walking may cause bugs
		set_process(is_walking)


var _old_pos: Vector2
var _kwargs: Dictionary

@onready var model := $PathFollow2D/UnitModel as UnitModel
@onready var shadow := $PathFollow2D/Shadow
@onready var animation := $AnimationPlayer as AnimationPlayer
@onready var path_follow := $PathFollow2D as PathFollow2D
@onready var debug := $Debug
@onready var hud := $PathFollow2D/HUD
@onready var _hud_hp_bar = hud.get_node("hp_bar")
@onready var _hud_hp_label = hud.get_node("hp_label")
@onready var _hud_name = hud.get_node("name")
@onready var _hud_rect = hud.get_node("rect")
@onready var _hud_status_effects = hud.get_node("StatusEffects")


## Creates a unit with a given type.
static func add_unit_type(node: Node, unit_type: UnitType, kwargs := {}) -> Unit:
	var unit_instance := UnitInstance.new()
	unit_instance.unit_type = unit_type
	unit_instance.empire = kwargs.get("empire", null)
	
	return add_unit_instance(node, unit_instance, kwargs)


## Creates a unit with an already existing unit instance.
static func add_unit_instance(node: Node, unit_instance: UnitInstance, kwargs := {}) -> Unit:
	var unit := load("res://Screens/Battle/Unit.tscn").instantiate() as Unit
	
	# add unit instance to unit
	if unit_instance.get_parent():
		unit_instance.get_parent().remove_child(unit_instance)
	unit.add_child(unit_instance)
	
	# initialize variables that need to be present on ready
	unit.world = kwargs.get("world", null)
	unit.world_pos = kwargs.get("world_pos", Vector2.ZERO)
	unit.facing = kwargs.get("facing", 0)
	
	if kwargs.has("heading"):
		unit.set_heading(kwargs.get("heading"))
	
	if kwargs.has("color"):
		unit.modulate = kwargs.get("color", Color.WHITE)
	
	# add unit to map (calls ready)
	node.add_child(unit)
	
	# initialize stuff that relies on stuff available after ready
	unit.hud.visible = kwargs.get("hud", true)
	unit.shadow.visible = kwargs.get("shadow", true)
	unit.debug.visible = kwargs.get("debug", false)
	
	if kwargs.has("name"):
		unit.unit_instance.name = kwargs.get("name")
	
	return unit
	

## Creates a ghost of a unit, unit instance or unit type.
static func add_ghost(node: Node, variant: Variant) -> Unit:
	var kwargs := {
		hud = false,
		shadow = false,
		debug = false,
		color = Color(1, 1, 1, 0.5),
	}
	
	if variant is Unit:
		kwargs.world = variant.world
		kwargs.world_pos = variant.world_pos
		kwargs.facing = variant.facing
		return add_unit_instance(node, variant, kwargs)
		
	elif variant is UnitInstance:
		return add_unit_instance(node, variant, kwargs)
		
	elif variant is UnitType:
		return add_unit_type(node, variant, kwargs)
	
	else:
		return null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	if unit_instance == null:
		warnings.append("This node needs a UnitInstance component")
	else:
		for child in get_children():
			if child is UnitInstance and child != unit_instance:
				warnings.append("Multiple unit nodes detected")
			
	return warnings


# Called when the node enters the scene tree for the first time.
func _ready():
	# we can only connect after _ready
	world_changed.connect(_on_world_changed)
	world_pos_changed.connect(_on_world_pos_changed)
	
	unit_changed.connect(_on_unit_changed)
	facing_changed.connect(_on_facing_changed)
	walking_started.connect(_on_walking_started)
	walking_finished.connect(_on_walking_finished)
	
	world = world
	world_pos = world_pos
	unit_instance = unit_instance
	facing = facing
	
	# keeping a reference to curve resource makes it extremely buggy
	# because points is a resource that get saved with the scene. this
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


func _connect_unit(_unit_instance: UnitInstance):
	_unit_instance.renamed.connect(_on_unit_renamed)
	_unit_instance.stat_changed.connect(_on_unit_stat_changed)
	_unit_instance.status_effect_added.connect(_on_unit_status_effect_added)
	_unit_instance.status_effect_changed.connect(_on_unit_status_effect_changed)
	_unit_instance.status_effect_removed.connect(_on_unit_status_effect_removed)
	_unit_instance.empire_changed.connect(_on_unit_empire_changed)


func _disconnect_unit(_unit_instance: UnitInstance):
	_unit_instance.renamed.disconnect(_on_unit_renamed)
	_unit_instance.stat_changed.disconnect(_on_unit_stat_changed)
	_unit_instance.status_effect_added.disconnect(_on_unit_status_effect_added)
	_unit_instance.status_effect_changed.disconnect(_on_unit_status_effect_changed)
	_unit_instance.status_effect_removed.disconnect(_on_unit_status_effect_removed)
	_unit_instance.empire_changed.disconnect(_on_unit_empire_changed)


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


func _on_world_pos_changed():
	position = world.uniform_to_screen(world_pos)
	

func _on_unit_changed():
	facing = PI
	if unit_instance:
		model.sprite_frames = unit_instance.unit_type.sprite_frames
		
		_on_unit_stat_changed("hp")
		_hud_name.text = unit_instance.name
		_hud_rect.color = unit_instance.unit_type.map_color
	else:
		_hud_hp_label.text = ""
		_hud_name.text = ""
		_hud_rect.color = Color.BLACK


func _on_unit_renamed():
	_hud_name.text = unit_instance.name


func _on_unit_stat_changed(stat):
	match stat:
		"hp", "maxhp":
			_hud_hp_bar.scale = Vector2(unit_instance.hp/float(unit_instance.maxhp), 1)
			_hud_hp_label.text = "%s/%s" % [unit_instance.hp, unit_instance.maxhp]


func _on_unit_status_effect_added(effect):
	var icon = preload("res://Screens/Battle/StatusEffectIcon.tscn").instantiate()
	_hud_status_effects.add_child(icon)
	icon.texture = effect.status_effect.icon
	effect.set_meta("hud_icon", icon)


func _on_unit_status_effect_changed(effect):
	if effect.duration <= 1:
		effect.get_meta("hud_icon").get_node("AnimationPlayer").play("blink")


func _on_unit_status_effect_removed(effect: Object):
	var icon = effect.get_meta("hud_icon")
	effect.remove_meta("hud_icon")
	_hud_status_effects.remove_child(icon)
	icon.free()


func _on_unit_empire_changed():
	pass


func _on_child_entered_tree(node: Node):
	# we only connect if our unit is null
	if node is UnitInstance and unit_instance == null:
		unit_instance = node
	update_configuration_warnings()


func _on_child_exiting_tree(node: Node):
	# we only disconnect if node is our unit
	if node == unit_instance:
		unit_instance = null
	update_configuration_warnings()
		

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

