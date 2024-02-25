class_name RemoveStatusEffect
extends AttackEffect
## Represents an effect that removes a status effect from the target unit.


## The status effect to remove.
@export_enum('STN', 'VUL', 'BLK', 'PSN') var effect: String = 'STN'
