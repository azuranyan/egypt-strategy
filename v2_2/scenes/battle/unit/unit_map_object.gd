@tool
class_name UnitMapObject
extends MapObject


@export_group("Editor")
@export var unit_type: UnitType

@export var heading: Map.Heading:
	set(value):
		heading = value
		if not is_node_ready():
			await ready
		unit_model.heading = heading

var unit: Unit

@onready var unit_model = $UnitModel
@onready var hp_bar_single = %HPBarSingle
@onready var hp_bar = %HPBar


func _ready():
	var test := func():
		var unit = load("res://scenes/battle/unit/unit_impl.tscn").instantiate()
		unit._id = 0
		unit._chara = load("res://units/alara/chara.tres")
		unit._unit_type = load("res://units/alara/unit_type.tres")
		unit._stats.hp = 3
		unit._stats.maxhp = 6
		get_tree().root.add_child(unit)
		# hack for testing
		unit.map_object.queue_free()
		unit.map_object = self
		# another hack for testing
		unit.set_state(Unit.State.IDLE) 
		initialize(unit)
	test.call_deferred()


func _input(event):
	if event.is_action_pressed('ui_accept'):
		unit.take_damage(2, null)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		unit.walk_towards(Vector2.ZERO)


func initialize(_unit: Unit):
	print('initialized')
	unit = _unit
	$HUD/Label.text = unit.display_name()
	
	update_hp_bar(unit.get_stat('hp'), unit.get_stat('maxhp'))
	update_state(0, unit.state())
	unit.stat_changed.connect(on_unit_stat_changed)
	unit.state_changed.connect(update_state)
	unit.damaged.connect(on_damage_taken)
	
	
func update_hp_bar(hp: int, maxhp: int):
	hp_bar.value = hp/float(maxhp) * hp_bar.max_value
	
	
func update_state(old: Unit.State, new: Unit.State):
	const STATE_NAMES := ['invalid', 'idle', 'walking', 'attacking', 'hurt', 'dying', 'dead']
	
	print(self, ' unit change state: %s -> %s' % [STATE_NAMES[old], STATE_NAMES[new]])
	unit_model.state = new
	
	
func on_unit_stat_changed(stat: StringName, value: int):
	if stat == &'hp':
		update_hp_bar(value, unit.get_stat(&'maxhp'))
		
		
func on_damage_taken(amount: int, source: Variant):
	var color := Color.WHITE
	if source == &'PSN':
		color = Color(0.949, 0.29, 0.949)
	elif source == &'VUL':
		color = Color(0.949, 0.949, 0.29)
	else:
		#camera.get_node("AnimationPlayer").play('shake') # battle will do the shake
		color = Color(0.949, 0.29, 0.392)
	play_floating_number(abs(amount), color)
	
	
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
	$Transformable.world = _world

