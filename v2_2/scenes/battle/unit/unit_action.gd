class_name UnitAction
## Class representing unit action.
	
# move data
var is_move: bool
var cell: Vector2

# attack data
var is_attack: bool
var attack: Attack
var target: Vector2
var rotation: float


## Unit does nothing.
static func do_nothing(_unit: Unit) -> UnitAction:
	return UnitAction.new(false, Vector2.ZERO, false, null, Vector2.ZERO, 0)
	
	
## Unit moves to a cell.
static func move(_unit: Unit, _cell: Vector2) -> UnitAction:
	return UnitAction.new(true, _cell, false, null, Vector2.ZERO, 0)
	

## Unit uses an attack.

## Unit

	
## Unit uses basic attack.
static func basic_attack(unit: Unit, _target: Vector2, _rotation: float) -> UnitAction:
	return UnitAction.new(false, Vector2.ZERO, true, unit.basic_attack(), _target, _rotation)
	
	
## Unit uses special attack.
static func special_attack(unit: Unit, _target: Vector2, _rotation: float) -> UnitAction:
	return UnitAction.new(false, Vector2.ZERO, true, unit.special_attack(), _target, _rotation)


## Unit moves to a cell then uses basic attack.
static func move_and_basic_attack(unit: Unit, _cell: Vector2, _target: Vector2, _rotation: float) -> UnitAction:
	return UnitAction.new(true, _cell, true, unit.basic_attack(), _target, _rotation)
	
	
## Unit moves to a cell then uses special attack.
static func move_and_special_attack(unit: Unit, _cell: Vector2, _target: Vector2, _rotation: float) -> UnitAction:
	return UnitAction.new(true, _cell, true, unit.special_attack(), _target, _rotation)


@warning_ignore("shadowed_variable")
func _init(is_move: bool, cell: Vector2, is_attack: bool, attack: Attack, target: Vector2, rotation: float):
	self.is_move = is_move
	self.cell = cell
	self.is_attack = is_attack
	self.attack = attack
	self.target = target
	self.rotation = rotation


func is_same_action(other: UnitAction) -> bool:
	return (is_move == other.is_move
		and cell == other.cell
		and is_attack == other.is_attack
		and attack == other.attack
		and target == other.target
		and rotation == other.rotation)

