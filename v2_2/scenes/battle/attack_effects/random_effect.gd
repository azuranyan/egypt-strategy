@tool
class_name RandomEffect
extends AttackEffect
## Represents an effect that executes a list of effects in sequence.


# TODO change this so it's much nicer to edit as a table.
## The list of effects and their weights.
@export var effects: Array[RandomEffectEntry]