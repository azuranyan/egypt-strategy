@tool
class_name UnitMapObject
extends MapObject
## The visual part of the unit that is present in the map.


## Emitted when model is done animating. This will not be emitted for looping animations!
signal animation_finished(state: Unit.State)

## Emitted when the heading is changed.
signal heading_changed(old_heading: Map.Heading, new_heading: Map.Heading)


enum Highlight {
	NONE,
	NORMAL,
	RED,
}

const BasicUnitModel := preload("res://scenes/battle/unit/basic_unit_model.tscn")


@export_group("Editor")

## The type of the unit to be created.
@export var unit_type: UnitType:
	set(value):
		unit_type = value
		if not is_node_ready():
			await ready
		load_unit_model(unit_type.unit_model if unit_type and unit_type.unit_model else BasicUnitModel)

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


@export var highlight := Highlight.NONE:
	set(value):
		const HIGHLIGHT_ANIMATIONS := ['RESET', 'highlight', 'highlight_red']
		highlight = value
		if not is_node_ready():
			await ready
		$AnimationPlayer.play(HIGHLIGHT_ANIMATIONS[highlight])
		
		
## A reference to the created unit. It's here for convenience, [b]do not change.[/b]
var unit: Unit

## A reference to the unit type unit_model. It's here for convenience, [b]do not change.[/b]
var unit_model: UnitModel

# TODO these could be diff components too
@onready var hp_bar = %HPBar


func _ready():
	super._ready()

	# cleanup dangling unitmodels from scene (tool changes and stuff)
	_remove_model_recursive(self)

	if not Engine.is_editor_hint():
		UnitEvents.state_changed.connect(_on_unit_state_changed)
		UnitEvents.stat_changed.connect(_on_unit_stat_changed)
		UnitEvents.damaged.connect(_on_unit_damaged)
		UnitEvents.turn_flags_changed.connect(_on_unit_turn_flags_changed)
	initialize(null)
	assert(unit_model != null)


func _remove_model_recursive(node: Node):
	for child in node.get_children():
		if child is UnitModel:
			node.remove_child(child)
		else:
			_remove_model_recursive(child)


## Initializes this unit object with a new unit.
func initialize(new_unit: Unit):
	if new_unit:
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

	
## Loads the unit model.
func load_unit_model(model_scene: PackedScene):
	_remove_unit_model()

	unit_model = model_scene.instantiate()
	if not unit_model:
		push_error('error loading model')
		return

	_connect_unit_model_signals(unit_model)
	unit_model.heading = heading

	$UnitModelContainer.add_child(unit_model)


## The grab offset.
func grab_offset() -> Vector2:
	if unit_model and unit_model.grab_point:
		return unit_model.grab_point.position
	return Vector2.ZERO


func _remove_unit_model():
	_disconnect_unit_model_signals(unit_model)
	if unit_model:
		$UnitModelContainer.remove_child(unit_model)
		unit_model.queue_free()
		unit_model = null


func _connect_unit_model_signals(mdl: UnitModel):
	if Engine.is_editor_hint():
		return
	Util.just_connect(mdl, 'animation_finished', _emit_model_animation_finished)
	Util.just_connect(mdl, 'input_event', _emit_model_input_event)
	Util.just_connect(mdl, 'mouse_entered', _emit_model_mouse_entered)
	Util.just_connect(mdl, 'mouse_exited', _emit_model_mouse_exited)
	Util.just_connect(mdl, 'clicked', _emit_model_clicked)


func _disconnect_unit_model_signals(mdl: UnitModel):
	if Engine.is_editor_hint():
		return
	Util.just_disconnect(mdl, 'animation_finished', _emit_model_animation_finished)
	Util.just_disconnect(mdl, 'input_event', _emit_model_input_event)
	Util.just_disconnect(mdl, 'mouse_entered', _emit_model_mouse_entered)
	Util.just_disconnect(mdl, 'mouse_exited', _emit_model_mouse_exited)
	Util.just_disconnect(mdl, 'clicked', _emit_model_clicked)
	
	
func _emit_model_animation_finished(st: Unit.State):
	animation_finished.emit(st)
	

func _emit_model_input_event(event: InputEvent):
	if is_instance_valid(unit) and unit.is_selectable():
		UnitEvents.input_event.emit(unit, event)


func _emit_model_mouse_entered():
	if is_instance_valid(unit) and unit.is_selectable():
		UnitEvents.mouse_entered.emit(unit)


func _emit_model_mouse_exited():
	if is_instance_valid(unit) and unit.is_selectable():
		UnitEvents.mouse_exited.emit(unit)
		
	
func _emit_model_clicked(mouse_pos: Vector2, button_index: int, pressed: bool):
	if is_instance_valid(unit) and unit.is_selectable():
		UnitEvents.clicked.emit(unit, mouse_pos, button_index, pressed)

	
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


func update_hp_bar(hp: int, maxhp: int):
	hp_bar.value = hp/float(maxhp) * hp_bar.max_value


func _world_changed(_world: World):
	super._world_changed(_world)
	%Shadow.world = _world


func _on_unit_state_changed(_unit: Unit, _old_state: Unit.State, new_state: Unit.State):
	if _unit != unit:
		return
	unit_model.state = new_state
	$HUD.visible = unit.is_alive()
	

func _on_unit_stat_changed(_unit: Unit, stat: StringName):
	if _unit != unit:
		return
	if stat == &'hp':
		update_hp_bar(unit.get_stat(&'hp'), unit.get_stat(&'maxhp'))


func _on_unit_damaged(_unit: Unit, amount: int, source: Variant):
	if _unit != unit:
		return
	var color := Color.WHITE
	if source == &'PSN':
		color = Color(0.949, 0.29, 0.949)
	elif source == &'VUL':
		color = Color(0.949, 0.949, 0.29)
	else:
		#camera.get_node("AnimationPlayer").play('shake') # battle will do the shake
		color = Color(0.949, 0.29, 0.392)
	play_floating_number(abs(amount), color)


func _on_unit_turn_flags_changed(_unit: Unit):
	if _unit != unit:
		return
	%EndTurnIcon.visible = _unit.is_turn_done()

	
	
