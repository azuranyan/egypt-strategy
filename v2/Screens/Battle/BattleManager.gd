extends Control


signal _continue


## The result of the battle.
enum Result {
	## Attacker cancels before starting the fight.
	Cancelled=-2,
	
	## Attacker cannot fulfill battle requirements.
	AttackerRequirementsError=-1,
	
	## Invalid.
	None=0,
	
	## Attacker wins.
	AttackerVictory,
	
	## Attacker loses.
	DefenderVictory,
	
	## Attacker loses via withdraw.
	AttackerWithdraw,
	
	## Attacker wins via defender withdraw.
	DefenderWithdraw,
}


@onready var map: NewMap = $SubViewportContainer/SubViewport/Map


var player: Empire
var ai: Empire
var attacker: Empire
var defender: Empire
var territory: Territory
var turns: int
var on_turn: Empire
var should_end: bool
var victory_conditions: Array[VictoryCondition]

var _warnings = []
var _lock := 0

func _ready():
	pass


func _exit_tree():
	request_ready()
	

func _process(delta):
	var mouse_pos := map.world.as_uniform(get_global_mouse_position())
	draw_unit_path(map.test_unit, mouse_pos)
	draw_unit_pathable_cells(map.test_unit)
	draw_unit_attack_range(map.test_unit, map.test_unit.basic_attack)
	draw_unit_attack_targets(map.test_unit, map.test_unit.basic_attack, mouse_pos, 0)
	
	
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:
				set_unit_standby(map.test_unit, map.test_unit.map_pos != NewMap.OUT_OF_BOUNDS)
			KEY_A:
				damage_unit(map.test_unit, 'test', 1)
			KEY_D:
				heal_unit(map.test_unit, 'test', 1)
			KEY_SPACE:
				spawn_unit("res://Screens/Battle/map_types/unit/Unit.tscn", "", map.to_cell(map.world.as_uniform(get_global_mouse_position())))     
	
	
#region Core API
func start_battle(attacker: Empire, defender: Empire, territory: Territory, do_quick = null) -> bool:
	if !_fulfills_attack_requirements(attacker, territory):
		return false
	
	_start_battle.call_deferred(attacker, defender, territory, do_quick)
	return true
		

func _start_battle(attacker: Empire, defender: Empire, territory: Territory, do_quick):
	# initialize context
	if attacker.is_player_owned():
		self.player = attacker
		self.ai = defender
	else:
		self.player = defender
		self.ai = attacker
	self.attacker = attacker
	self.defender = defender
	self.territory = territory
	self.turns = 0
	self.on_turn = attacker
	self.should_end = false
	self.victory_conditions = [VictoryCondition.new()]
	self._warnings = []
	
	var result: Result = Result.None
	
	# start battle
	BattleSignalBus.battle_started.emit(attacker, defender, territory)
	await Globals.play_queued_scenes()
	
	# do battle
	var should_do_quick := not (attacker.is_player_owned() or defender.is_player_owned())
	if do_quick:
		should_do_quick = bool(do_quick)
		
	if should_do_quick:
		result = await _quick_battle(attacker, defender, territory)
	else:
		result = await _real_battle(attacker, defender, territory)
		
	# end battle
	BattleSignalBus.battle_ended.emit(result)
	await Globals.play_queued_scenes()
	
	
## Returns true if the attacker can initiate the attack to territory.
func _fulfills_attack_requirements(empire: Empire, territory: Territory) -> bool:
	# TODO put battle requirements here
	_warnings = []
	return true


## Returns true if the attacker fulfills prep requirements over territory.
func _fulfills_prep_requirements(empire: Empire, territory: Territory) -> bool:
	# TODO put battle requirements here
	_warnings = []
	return true
	
	
func show_message(type, message, blocking):
	# TODO place somewhere else
	pass
	

func acquire_lock():
	_lock += 1
	

func release_lock():
	if _lock > 0:
		_lock -= 1
#endregion Core API


#region Unit Functions
# TODO walk_unit, unit_use_attack, set_unit, etc
## Spawns a unit.
func spawn_unit(path: String, custom_name := "", pos := NewMap.OUT_OF_BOUNDS, heading := Unit.Heading.East) -> NewUnit:
	#assert(empire == context.attacker or empire == context.defender, "owner is neither empire!")	
	var unit := load(path).instantiate() as NewUnit
	unit.display_name = custom_name if custom_name != "" else unit.chara.name
	if pos == NewMap.OUT_OF_BOUNDS:
		set_unit_standby(unit, true)
	else:
		unit.map_pos = pos
	unit.set_heading(heading)
	map.get_node("Entities").add_child(unit)
	# TODO
	#unit.hp = maxi(1, unit.empire.hp_multiplier * unit.maxhp)
	return unit
		
	
## Kills a unit.
func kill_unit(unit: NewUnit):
	unit.add_to_group('units_dead')
	unit.alive = false
	

## Revives a unit.
func revive_unit(unit: NewUnit, hp: int):
	unit.hp = mini(hp, unit.maxhp)
	unit.add_to_group('units_alive')
	unit.alive = true


## Standby unit.
func set_unit_standby(unit: NewUnit, standby: bool):
	if standby:
		unit.set_meta("Battle_unit_standby_old_pos", unit.map_pos)
		unit.map_pos = NewMap.OUT_OF_BOUNDS
		unit.add_to_group('units_standby')
	else:
		var pos: Vector2 = unit.get_meta("Battle_unit_standby_old_pos", Vector2.ZERO)
		unit.map_pos = pos
		unit.remove_from_group('units_standby')

	
## Inflict damage upon a unit.
func damage_unit(unit: NewUnit, source: Variant, amount: int):
	var vul := false
	var blk := false
	# if unit has vul, increase damage taken by 1
	if 'VUL' in unit.status_effects:
		amount += 1
		vul = true
		
	# if unit has block, remove black and set damage to 0
	if 'BLK' in unit.status_effects:
		amount = 0
		unit.remove_status_effect('BLK')
		blk = true
		
	# do the damage
	unit.hp = clampi(unit.hp - amount, 0, unit.maxhp)
	if unit.hp <= 0:
		kill_unit(unit)
	
	# special effects
	if amount > 0:
		$SubViewportContainer/Camera2D/AnimationPlayer.play("shake")
	
	var color := Color(0.949, 0.29, 0.392)
	if source == 'PSN':
		color = Color(0.949, 0.29, 0.949)
	if vul:
		color = Color(0.949, 0.949, 0.29)
	if blk:
		color = Color(0, 0.691, 0.833)
	draw_floating_number(unit, amount, color)
	

## Heals unit.
func heal_unit(unit: NewUnit, _source: Variant, amount: int):
	# unit might have been killed prior to this within the same frame,
	# before dead units are processed
	if unit.alive:
		unit.hp = clampi(unit.hp + amount, 0, unit.maxhp)
		draw_floating_number(unit, amount, Color(0.29, 0.949, 0.392))
#endregion Unit Functions


#region Draw
func draw_unit_path(unit: NewUnit, target_cell: Vector2):
	map.unit_path.initialize(unit.get_pathable_cells())
	map.unit_path.draw(unit.cell(), target_cell)


func draw_unit_pathable_cells(unit: NewUnit):
	map.pathing_overlay.draw(unit.get_pathable_cells(), 2) # green


func draw_unit_attack_range(unit: NewUnit, attack: Attack):
	map.attack_overlay.draw(unit.get_attack_range(attack), 3) # red
	
	
func draw_unit_attack_targets(unit: NewUnit, attack: Attack, target: Variant, target_rotation: Variant, is_multi_target := false):
	if is_multi_target:
		map.attack_overlay.clear()
		for i in target.size():
			var cells := unit.get_attack_target(attack, target[i], target_rotation[i])
			map.target_overlay.draw(cells, 1, false) # blue
	else:
		var cells := unit.get_attack_target(attack, target, target_rotation)
		map.target_overlay.draw(cells, 1, true) # blue
		
		
func draw_floating_number(unit: NewUnit, number: int, color: Color):
	# create the node
	var node := preload("res://Screens/Battle/FloatingNumber.tscn").instantiate()
	var anim := node.get_node('AnimationPlayer') as AnimationPlayer
	var label := node.get_node('Label') as Label
	unit.add_child(node)
	
	# add some offset randomness
	node.position.x = randf_range(node.position.x - 24, node.position.x + 24)
	node.position.y = randf_range(node.position.x - 12, node.position.x + 12)
	
	label.text = str(number)
	node.modulate = color
	
	anim.play('start')
	
	await anim.animation_finished
	node.queue_free()
	
#endregion Draw


#region Internals
func _redistribute_units():
	for u in map.get_units():
		var default_owner: String = u.get_meta("default_owner", null)
		if default_owner == "attacker.name":
			pass # TODO give to attacker
		elif default_owner == "defender.name":
			pass # TODO give to defender
		
		
func _process_dead_units():
	pass
	
	
func _quick_battle(attacker: Empire, defender: Empire, territory: Territory):
	pass
	
	
func _real_battle(attacker: Empire, defender: Empire, territory: Territory):
	pass
#endregion Internals
