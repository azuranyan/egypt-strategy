class_name ConditionalEffect
extends AttackEffect
## Represents an effect that conditionally executes an effect.


## Path to the node that will be called for the condition.
@export var node: NodePath

## The method that returns true or false.
@export var method: StringName

## The effect to execute if the condition is met.
@export var effect: AttackEffect