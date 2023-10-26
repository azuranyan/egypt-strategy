extends Node


func _ready():
	Globals.register_data('attack', func(res: Attack): return res.resource_path.get_file())
	Globals.register_data('chara', func(res: Chara): return res.name)
	Globals.register_data('doodad_type', func(res: DoodadType): return res.resource_name)
	Globals.register_data('status_effect', func(res: StatusEffect): return res.short_name)
	Globals.register_data('unit_type', func(res: UnitType): return res.name)
	Globals.register_data('world', func(res: World): return res.resource_path.get_file())
	
	run_game.call_deferred()
	

func run_game():
	# create the rudimentary dialogue screen
	var diag := preload("res://Screens/Dialogue/Dialogue.tscn").instantiate()
	diag.visible = false
	get_tree().root.add_child(diag)
	
	# start overworld cycle
	Globals.push_screen(Globals.overworld, '')
	Globals.transition_finished.connect(Globals.overworld.do_cycle, CONNECT_ONE_SHOT)
