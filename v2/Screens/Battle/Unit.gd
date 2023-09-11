extends Node2D

## A complex MapObject representing a unit.
class_name Unit


enum {
	RESET_HP = 1 << 0,
	RESET_STATS = 1 << 1,
	RESET_BOND = 1 << 2,
	RESET_STATUS_EFFECTS = 1 << 3,
	RESET_ANIMATION = 1 << 4,
	RESET_ALL = RESET_HP | RESET_STATS | RESET_STATUS_EFFECTS | RESET_BOND | RESET_ANIMATION,
}


class AppliedStatusEffect:
	var status_effect: StatusEffect
	var duration: int
	
	
@export var unit_type: UnitType:
	set(value):
		unit_type = value
		reset(RESET_ALL)
	get:
		return unit_type

var maxhp: int
var hp: int:
	set(value):
		hp = value
		if hud_hp_bar != null:
			hud_hp_bar.scale = Vector2(hp/float(maxhp), 1)
		if hud_hp_label != null:
			hud_hp_label.text = "%s/%s" % [hp, maxhp]
var mov: int
var dmg: int
var rng: int

var bond: int

var status_effects: Array[AppliedStatusEffect] = []

@onready var hud_hp_bar = $HUD/HP
@onready var hud_hp_label = $HUD/Label
@onready var sprite = $Sprite

enum Heading { North, East, West, South }

var heading: Heading:
	set(value):
		heading = value
		if sprite != null:
			sprite.flip_h = heading == Heading.North or heading == Heading.East
			if heading == Heading.North or heading == Heading.West:
				sprite.animation = "BackIdle"
			else:
				sprite.animation = "FrontIdle"
	get:
		return heading

var map_pos: Vector2


func face_towards(target: Vector2):
	var v := target - map_pos
	var angle := atan2(v.y, v.x)
	angle = fmod(angle + PI*2 + PI/4, PI*2)
	
	match int(angle/PI*2):
		0:
			heading = Heading.East
		1:
			heading = Heading.North
		2:
			heading = Heading.West
		3:
			heading = Heading.South
		
func reset(flags: int=RESET_STATS | RESET_HP | RESET_STATUS_EFFECTS):
	if flags & RESET_HP != 0:
		maxhp = unit_type.stat_hp
		mov = unit_type.stat_mov
		dmg = unit_type.stat_dmg
		rng = unit_type.basic_attack.range
	
	if flags & RESET_STATS != 0:
		hp = maxhp
		
	if flags & RESET_BOND != 0:
		bond = 0
	
	if flags & RESET_STATUS_EFFECTS != 0:
		status_effects.clear()

	if flags & RESET_ANIMATION != 0:
		heading = heading

# Called when the node enters the scene tree for the first time.
func _ready():
	reset(RESET_ALL)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Q:
				hp -= 1
			KEY_E:
				hp += 1
			KEY_W:
				heading = Heading.North
			KEY_A:
				heading = Heading.West
			KEY_S:
				heading = Heading.South
			KEY_D:
				heading = Heading.East
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	map_pos = position
	var target = get_global_mouse_position()
	target.y = 1080 - target.y
	$HUD/Label2.text = "pos = %s\nheading = %s\nx = %s\ny = %s" % [position, Heading.keys()[heading], target.x, target.y]
	face_towards(target)
