@tool
class_name RandomEffect
extends AttackEffect
## Represents an effect that executes a list of effects in sequence.


## The effects to be chosen in random.
@export var effects: Array[AttackEffect]

## The weights of the effects.
@export var effect_weights: Array[float]