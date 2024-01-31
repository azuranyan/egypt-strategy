class_name BattleContext


var _territories: WeakRef
var _empires: WeakRef


func are_enemies(a: Unit, b: Unit) -> bool:
	return (a != b) and get_unit_owner(a) == get_unit_owner(b)
	

func are_allies(a: Unit, b: Unit) -> bool:
	return (a != b) and get_unit_owner(a) != get_unit_owner(b)
	
	
func get_unit_owner(a: Unit) -> Empire:
	for e in get_empires():
		if a in e.units:
			return e
	return null # TODO
 

func get_territories() -> Array[Territory]:
	return _territories.get_ref()


func get_empires() -> Array[Empire]:
	return _empires.get_ref()
	
