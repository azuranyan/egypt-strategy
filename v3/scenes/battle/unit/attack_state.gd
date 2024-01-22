class_name AttackState

## Attack being used.
var attack: Attack

## The unit that casted the attack.
var user: Unit

## The target cell
var target_cells: Array[Vector2]

## The target shape rotation.
var target_rotations: Array[float]

## Units within the aoe of the attack.
var target_units := []

## Free use data.
var data := {}
