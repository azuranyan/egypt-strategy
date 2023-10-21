extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.register_data('attack', func(res: Attack): return res.resource_path.get_file())
	Globals.register_data('chara', func(res: Chara): return res.name)
	Globals.register_data('doodad_type', func(res: DoodadType): return res.resource_name)
	Globals.register_data('status_effect', func(res: StatusEffect): return res.short_name)
	Globals.register_data('unit_type', func(res: UnitType): return res.name)
	Globals.register_data('world', func(res: World): return res.resource_path.get_file())
	
	
