@tool
extends Node2D

## Object that renders a UnitInstance.
class_name RenderableUnit


signal unit_changed
signal facing_changed


enum Heading { North, East, West, South }


## The unit variable.
var unit: UnitInstance:
	set(value):
		if unit:
			_disconnect_unit(unit)
		unit = value
		if unit:
			_connect_unit(unit)
		unit_changed.emit()

## The position of this unit in the world.
var world_pos: Vector2

## Where this unit is facing.
var facing: float:
	set(value):
		facing = value
		facing_changed.emit()
		

@onready var sprite := $Sprite as AnimatedSprite2D
@onready var animation := $AnimationPlayer as AnimationPlayer
@onready var hud := $HUD
@onready var _hud_hp_bar = $HUD/hp_bar
@onready var _hud_hp_label = $HUD/hp_label
@onready var _hud_name = $HUD/name
@onready var _hud_rect = $HUD/rect


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

	
## Faces towards target.
func face_towards(target: Vector2):
	var v := target - world_pos
	facing = atan2(v.y, v.x)
	
	
## Returns the general direction this unit is facing.
func get_heading() -> Heading:
	var angle := fmod(facing + PI*2 + PI/4, PI*2)
	return int(angle/PI*2)
	
	
func _connect_unit(_unit: UnitInstance):
	_unit.stat_changed.connect(_on_unit_stat_changed)
	_unit.status_effect_added.connect(_on_unit_status_effect_added)
	_unit.status_effect_changed.connect(_on_unit_status_effect_changed)
	_unit.status_effect_removed.connect(_on_unit_status_effect_removed)
	_unit.empire_changed.connect(_on_unit_empire_changed)
	
	
func _disconnect_unit(_unit: UnitInstance):
	_unit.stat_changed.disconnect(_on_unit_stat_changed)
	_unit.status_effect_added.disconnect(_on_unit_status_effect_added)
	_unit.status_effect_changed.disconnect(_on_unit_status_effect_changed)
	_unit.status_effect_removed.disconnect(_on_unit_status_effect_removed)
	_unit.empire_changed.disconnect(_on_unit_empire_changed)
	
	
func _on_unit_changed():
	facing = 0
	if unit:
		# sprite = _unit.unit_type.sprite
		# animation setup
		
		_on_unit_stat_changed("hp")
		_hud_name.text = unit.name
		_hud_rect.color = unit.unit_type.map_color
	else:
		_hud_hp_label.text = ""
		_hud_name.text = ""
		_hud_rect.color = Color.BLACK
		

func _on_facing_changed():
	var h := get_heading()
	
	sprite.flip_h = h == UnitInstance.Heading.North or h == UnitInstance.Heading.East
	
	if h == UnitInstance.Heading.North or h == UnitInstance.Heading.West:
		sprite.animation = "BackIdle"
	else:
		sprite.animation = "FrontIdle"
	
	
func _on_unit_stat_changed(stat):
	match stat:
		"hp", "maxhp":
			_hud_hp_bar.scale = Vector2(unit.hp/float(unit.maxhp), 1)
			_hud_hp_label.text = "%s/%s" % [unit.hp, unit.maxhp]
	

func _on_unit_status_effect_added(effect):
	pass
	
	
func _on_unit_status_effect_changed(effect):
	pass
	
	
func _on_unit_status_effect_removed(effect):
	pass


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
	pass # Replace with function body.
