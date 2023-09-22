@tool
extends Path2D

## Object that renders a UnitInstance.
class_name Unit


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
@export var world: World = preload("res://Screens/Battle/data/World_StartingZone.tres")

## The position of this unit in the world.
@export var world_pos := Vector2.ZERO:
	set(value):
		world_pos = value
		position = world.uniform_to_screen(world_pos)
		world_pos_changed.emit()

## Where this unit is facing.
@export var facing: float = PI:
	set(value):
		facing = value
		facing_changed.emit()
		
		
## The unit instance component.
var unit: UnitInstance:
	set(value):
		if unit:
			_disconnect_unit(unit)
		unit = value
		if unit:
			_connect_unit(unit)
		unit_changed.emit()
		
## If this unit is walking.
var is_walking := false:
	set(value):
		is_walking = value
		
		# setting is_walking to false while unit is still walking may cause bugs
		set_process(is_walking)


var _old_pos: Vector2


@onready var model := $PathFollow2D/UnitModel as UnitModel
@onready var animation := $AnimationPlayer as AnimationPlayer
@onready var path_follow := $PathFollow2D as PathFollow2D
@onready var hud := $PathFollow2D/HUD
@onready var _hud_hp_bar = hud.get_node("hp_bar")
@onready var _hud_hp_label = hud.get_node("hp_label")
@onready var _hud_name = hud.get_node("name")
@onready var _hud_rect = hud.get_node("rect")
@onready var _hud_status_effects = hud.get_node("StatusEffects")


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	if unit == null:
		warnings.append("This node needs a UnitInstance component")
	else:
		for child in get_children():
			if child is UnitInstance and child != unit:
				warnings.append("Multiple unit nodes detected")
			
	return warnings


# Called when the node enters the scene tree for the first time.
func _ready():
	unit_changed.connect(_on_unit_changed)
	
	unit = unit
	
	# keeping a reference to curve resource makes it extremely buggy
	# because the points get saved. this is why we're creating a new
	# curve every reload.
	curve = Curve2D.new()
	
	if not Engine.is_editor_hint():
		var points: PackedVector2Array = [
			Vector2(3, 3),
			Vector2(4, 5),
			Vector2(3, 4),
			Vector2(7, 2),
			Vector2(0, 0),
		]
		
		walk_along.call_deferred(make_square_path(points))


func _process(delta: float):
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
	

## TODO code to be put somewhere else, unit just trusts that the path provided
## are of right angles and not passing through objects
func make_square_path(path: PackedVector2Array) -> PackedVector2Array:
	var re := PackedVector2Array()
	var prev := Vector2.ZERO
	
	re.append(prev)
	for p in path:
		if p.x != prev.x and p.y != prev.y:
			if p.x < p.y:
				re.append(Vector2(p.x, prev.y))
			else:
				re.append(Vector2(prev.x, p.y))
		re.append(p)
		prev = p
	return re
			

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
	
	
func _connect_unit(_unit: UnitInstance):
	_unit.renamed.connect(_on_unit_renamed)
	_unit.stat_changed.connect(_on_unit_stat_changed)
	_unit.status_effect_added.connect(_on_unit_status_effect_added)
	_unit.status_effect_changed.connect(_on_unit_status_effect_changed)
	_unit.status_effect_removed.connect(_on_unit_status_effect_removed)
	_unit.empire_changed.connect(_on_unit_empire_changed)
	
	
func _disconnect_unit(_unit: UnitInstance):
	_unit.renamed.disconnect(_on_unit_renamed)
	_unit.stat_changed.disconnect(_on_unit_stat_changed)
	_unit.status_effect_added.disconnect(_on_unit_status_effect_added)
	_unit.status_effect_changed.disconnect(_on_unit_status_effect_changed)
	_unit.status_effect_removed.disconnect(_on_unit_status_effect_removed)
	_unit.empire_changed.disconnect(_on_unit_empire_changed)
	
	
func _on_unit_changed():
	facing = PI
	if unit:
		model.sprite_frames = unit.unit_type.sprite_frames
		
		_on_unit_stat_changed("hp")
		_hud_name.text = unit.name
		_hud_rect.color = unit.unit_type.map_color
	else:
		_hud_hp_label.text = ""
		_hud_name.text = ""
		_hud_rect.color = Color.BLACK


func _on_unit_renamed():
	_hud_name.text = unit.name
	
	
func _on_unit_stat_changed(stat):
	match stat:
		"hp", "maxhp":
			_hud_hp_bar.scale = Vector2(unit.hp/float(unit.maxhp), 1)
			_hud_hp_label.text = "%s/%s" % [unit.hp, unit.maxhp]
	

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
	if node is UnitInstance and unit == null:
		unit = node
	update_configuration_warnings()


func _on_child_exiting_tree(node: Node):
	# we only disconnect if node is our unit
	if node == unit:
		unit = null
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
