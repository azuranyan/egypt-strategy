@tool
class_name UnitMapObject
extends MapObject
## The visual part of the unit that is present in the map.


## Emitted when model is done animating. This will not be emitted for looping animations!
signal animation_finished(state: Unit.State)

## Emitted when the model is interacted to.
signal interacted(cursor_pos: Vector2, button_index: int, pressed: bool)

## Emitted when the heading is changed.
signal heading_changed(old_heading: Map.Heading, new_heading: Map.Heading)


const BasicUnitModel := preload("res://scenes/battle/unit/basic_unit_model.tscn")


@export_group("Editor")

## The type of the unit to be created.
@export var unit_type: UnitType:
	set(value):
		unit_type = value
		if not is_node_ready():
			await ready
		set_unit_model(_get_unit_type_unit_model(unit_type))

## The empire this unit will be given to.[br]
## Also understands special strings like [code]$ai[/code] and [code]$player[/code].
@export var empire_id: StringName
		
## The state to show.[br]
## The game is free to ignore this and reset to idle on load.
@export var state: Unit.State
	
@export_group("Map")

## The unit heading.
@export var heading: Map.Heading:
	set(value):
		var old := heading
		heading = value
		if unit_model:
			unit_model.heading = heading
		heading_changed.emit(old, heading)
		
		
## A reference to the created unit.
var unit: Unit

## A reference to the unit type unit_model.
var unit_model: UnitModel

# TODO these could be diff components too
@onready var hp_bar_single = %HPBarSingle
@onready var hp_bar = %HPBar


func _ready():
	super._ready()
	initialize(null)


## Initializes this unit object with a new unit.
func initialize(new_unit: Unit):
	if unit:
		_disconnect_from_unit(unit)
		
	if new_unit:
		_connect_to_unit(new_unit)
		
		# initialize ui elements that doesn't change. the unit will reset
		# after us so we don't have to manually update our stuff
		$HUD/Label.text = new_unit.display_name()
		unit_type = new_unit.unit_type()
		empire_id = new_unit.get_empire().leader_id if new_unit.get_empire() else &''
		state = new_unit.state()
	else:
		unit_type = null
		empire_id = &''
		state = Unit.State.IDLE
	unit = new_unit
	
	
func _connect_to_unit(_unit: Unit):
	_unit.stat_changed.connect(_on_unit_stat_changed)
	_unit.state_changed.connect(_update_state)
	_unit.damaged.connect(_on_damage_taken)
	
	
func _disconnect_from_unit(_unit: Unit):
	_unit.stat_changed.disconnect(_on_unit_stat_changed)
	_unit.state_changed.disconnect(_update_state)
	_unit.damaged.disconnect(_on_damage_taken)
	
	
func _get_unit_type_unit_model(ut: UnitType) -> UnitModel:
	if ut and ut.unit_model:
		return ut.unit_model.instantiate()
	return BasicUnitModel.instantiate()
	
	
## Sets the unit model. Must not be null.
func set_unit_model(new_model: UnitModel):
	if unit_model: 
		# make sure no stray signals are fired after queue_free
		unit_model.animation_finished.disconnect(_emit_model_animation_finished)
		unit_model.interacted.disconnect(_emit_model_interacted)
		remove_child(unit_model)
		unit_model.queue_free()
	unit_model = new_model
	unit_model.animation_finished.connect(_emit_model_animation_finished)
	unit_model.interacted.connect(_emit_model_interacted)
	unit_model.heading = heading
	add_child(unit_model)
	
	
func _emit_model_animation_finished(st: Unit.State):
	animation_finished.emit(st)
	
	
func _emit_model_interacted(cursor_pos: Vector2, button_index: int, pressed: bool):
	interacted.emit(cursor_pos, button_index, pressed)
	
	
## Makes this unit face towards target.
func face_towards(target: Vector2):
	heading = Map.to_heading(map_position.angle_to_point(target))
	
	
## Plays a floating number over this unit.
func play_floating_number(value: int, color: Color):
	var node := preload("res://scenes/battle/unit/floating_number.tscn").instantiate()
	var anim: AnimationPlayer = node.get_node('AnimationPlayer')
	var label: Label = node.get_node('Label')
	
	add_child(node)
	node.position.x = randf_range(node.position.x - 24, node.position.x + 24)
	node.position.y = randf_range(node.position.y - 12, node.position.y + 12)
	
	label.text = str(value)
	node.modulate = color
	
	anim.play('start')
	await anim.animation_finished
	anim.queue_free()
	

func _world_changed(_world: World):
	super._world_changed(_world)
	%Shadow.world = _world


func _update_hp_bar(hp: int, maxhp: int):
	hp_bar.value = hp/float(maxhp) * hp_bar.max_value
	
	
func _update_state(_old: Unit.State, new: Unit.State):
	unit_model.state = new
	$HUD.visible = unit.is_alive()
	

func _on_unit_stat_changed(stat: StringName, value: int):
	if stat == &'hp':
		_update_hp_bar(value, unit.get_stat(&'maxhp'))
		
		
func _on_damage_taken(amount: int, source: Variant):
	var color := Color.WHITE
	if source == &'PSN':
		color = Color(0.949, 0.29, 0.949)
	elif source == &'VUL':
		color = Color(0.949, 0.949, 0.29)
	else:
		#camera.get_node("AnimationPlayer").play('shake') # battle will do the shake
		color = Color(0.949, 0.29, 0.392)
	play_floating_number(abs(amount), color)
