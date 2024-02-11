class_name OverworldScene
extends GameScene

signal _player_choose_action(action: Dictionary)


var territory_buttons: Array[TerritoryButton]
var overworld: Overworld

@onready var battle_result_banner = $BattleResultBanner


func _ready():
	territory_buttons.clear()
	for i in get_child_count():
		var button := get_child(i) as TerritoryButton
		if not button:
			continue
		territory_buttons.append(button)
		button.attack_pressed.connect(_on_territory_button_attack_pressed)
		button.rest_pressed.connect(_on_territory_button_rest_pressed)
		button.train_pressed.connect(_on_territory_button_train_pressed)
	overworld = Game.overworld
	overworld.territory_owner_changed.connect(func(_a, _b, _c): update_territory_buttons())
	overworld.cycle_started.connect(update_turn_counter)
	overworld.turn_ended.connect(update_new_available_scenes)
	

## Returns the empire nodes.
func get_empire_nodes() -> Array[EmpireNode]:
	var arr: Array[EmpireNode] = []
	for child in $Empires.get_children():
		if child is EmpireNode:
			arr.append(child)
	return arr


## Returns the random empire nodes.
func get_random_empire_nodes() -> Array[EmpireNode]:
	var arr:Array[EmpireNode] = []
	for child in $RandomEmpireSelection.get_children():
		if child is EmpireNode:
			arr.append(child)
	return arr
	

## Returns the territory node for the empire.
func find_territory_button(territory: Territory) -> TerritoryButton:
	for t in territory_buttons:
		if t._territory == territory:
			return t
	return null

	
## Returns a new context.
func create_initial_data() -> Dictionary:
	assert(is_node_ready(), 'node needs to be ready to save')
	var data := {
		territories = [] as Array[Territory],
		empires = [] as Array[Empire],
		player_empire = null,
		boss_empire = null,
		# these data will be removed later
		grabs = [] as Array[Territory]
	}

	_save_territories(data)
	_save_empires(data)
	data.erase('grabs')
	return data


## Saves the territories to ctx.
func _save_territories(data: Dictionary):
	for button in territory_buttons:
		var node: TerritoryNode = button.territory_node
		var t := Territory.new()
		t.name = node.name
		for adj in node.adjacent:
			t.adjacent.append(adj.name)
		t.maps = node.maps.duplicate()
		t.units = node.get_unit_entries()
		data.territories.append(t)
		data.grabs.append(t)


## Saves the empire to ctx.
func _save_empires(data: Dictionary):
	# add the preset empires
	for node in get_empire_nodes():
		if not node.home_territory_node:
			push_error('"%s" included in Empires, but has no home territory set' % node.name)
			continue
		var e := _create_empire_from_node(node)
		var home_territory: Territory = data.territories.filter(func(t): return t.name == node.home_territory_node.name)[0]
		_set_empire_territory(e, home_territory, true)
		_add_empire_to_data(data, e)
		data.grabs.erase(home_territory)
	
	# add random empires
	_distribute_empires(data)
	
	
## Creates the empire from node. Note that this doesn't set the territories or units.
func _create_empire_from_node(node: EmpireNode) -> Empire:
	var e := Empire.new()
	e.type = node.type
	e.leader_id = node.leader_id
	e.leader = node.leader
	e.hero_units = []
	e.base_aggression = node.base_aggression
	# units and territory will be set later
	e.aggression = node.base_aggression
	return e
	
	
## Adds territory to empire.
func _set_empire_territory(empire: Empire, territory: Territory, home: bool):
	if home:
		empire.home_territory = territory
	if territory not in empire.territories:
		empire.territories.insert(0 if home else empire.territories.size(), territory)
	
	
## Removes territory from empire.
func _unset_empire_territory(empire: Empire, territory: Territory):
	empire.territories.erase(territory)


## Adds the empire to context.
func _add_empire_to_data(data: Dictionary, empire: Empire):
	if empire not in data.empires:
		data.empires.append(empire)
	if empire.is_player_owned():
		data.player_empire = empire
	if empire.is_boss():
		data.boss_empire = empire

	
## Distributes the empires to territories.
func _distribute_empires(data: Dictionary):
	if data.grabs.is_empty():
		return
		
	# create the selection of random empires
	var selection: Array[Empire] = []
	for node in get_random_empire_nodes():
		var empire := _create_empire_from_node(node)
		selection.append(empire)
		if selection.size() > data.grabs.size():
			break
	selection.shuffle()
	
	# every empire gets their home territory
	for empire in selection:
		var idx := randi_range(0, data.grabs.size() - 1)
		var random_territory: Territory = data.grabs.pop_at(idx)
		_set_empire_territory(empire, random_territory, true)
		_add_empire_to_data(data, empire)
		data.grabs.erase(random_territory)
		
	# the rest will be distributed randomly
	for t: Territory in data.grabs:
		# get potential owners
		var potential_owner: Array[Empire] = []
		for e: Empire in selection:
			if e.is_adjacent_territory(t):
				potential_owner.append(e)
		
		# give territory to owner
		if potential_owner.is_empty():
			push_error('isolated territory %s' % t.name)
			_set_empire_territory(selection.pick_random(), t, false)
		else:
			_set_empire_territory(potential_owner.pick_random(), t, false)


#############################################################################

func scene_enter(_kwargs = {}):
	update_territory_buttons()
	update_turn_counter(overworld.cycle())
	update_new_available_scenes()
	# TODO just a hack to keep it working when resumed
	# and overworld is waiting for player action
	if overworld.on_turn():
		$InputBlocker.mouse_filter = 2
	
	
func update_turn_counter(cycle: int):
	%TurnCountLabel.text = str(cycle + 1)
	
	
func update_new_available_scenes(_empire: Empire = null):
	%NewSceneIcon.visible = Game.has_new_scenes()


func update_territory_buttons():
	for btn in territory_buttons:
		btn.initialize(overworld.get_territory_by_name(btn.territory_node.name))
		if btn._territory == overworld.boss_empire().home_territory:
			btn.visible = overworld.is_boss_active()
	

func wait_for_player_action() -> Dictionary:
	$InputBlocker.mouse_filter = 2
	var action: Dictionary = await _player_choose_action
	$InputBlocker.mouse_filter = 0
	return action


func initiate_battle(attacker: Empire, defender: Empire, territory: Territory, map_id: int):
	print("%s attacks %s (%s)!" % [attacker.leader_id, territory.name, defender.leader_id])
	await show_marching_animation(attacker, defender, territory)
	if (attacker.is_player_owned() or defender.is_player_owned()):
		Game.battle.start_battle(attacker, defender, territory, map_id)
		#scene_call('battle', {attacker=attacker, defender=defender, territory=territory, map_id=map_id})
	else:
		# TODO show quick battle sim
		var result := BattleResult.new(BattleResult.ATTACKER_VICTORY, attacker, defender, territory, map_id)
		Game.battle.started.emit(attacker, defender, territory, map_id)
		await get_tree().create_timer(0.1).timeout
		Game.battle.ended.emit(result)
		
		
func show_marching_animation(attacker: Empire, _defender: Empire, target: Territory):
	# find nearest position
	var start_pos := find_territory_button(target).global_position
	var sorted_positions := territory_buttons \
		.filter(func(btn): return overworld.get_territory_owner(btn._territory) == attacker and attacker.is_adjacent_territory(target)) \
		.map(func(btn): return btn.global_position)
	sorted_positions.sort_custom(Util.is_closer.bind(start_pos))
	
	# start and wait for march
	var anim := preload("res://scenes/overworld/marching_animation.tscn").instantiate()
	anim.global_position = sorted_positions[0]
	add_child(anim)
	anim.march(start_pos)
	await anim.done
	

func show_battle_result_banner(result: BattleResult):
	var banner := battle_result_banner.duplicate()
	add_child(banner)
	await banner.show_parsed_result(result)


func _on_territory_button_attack_pressed(button: TerritoryButton):
	if not overworld.on_turn().is_player_owned():
		push_warning('attack button pressed when not on turn!')
		return
	var attacker := overworld.on_turn()
	var defender := overworld.get_territory_owner(button._territory)
	_player_choose_action.emit({
		type = 'attack',
		attacker = attacker,
		defender = defender,
		territory = button._territory,
		map_id = 0,
	})
	

func _on_territory_button_rest_pressed(_button: TerritoryButton):
	if not overworld.on_turn().is_player_owned():
		push_warning('rest button pressed when not on turn!')
		return
	_player_choose_action.emit({type='rest'})
	
	
func _on_territory_button_train_pressed(_button: TerritoryButton):
	if not overworld.on_turn().is_player_owned():
		push_warning('train button pressed when not on turn!')
		return
	_player_choose_action.emit({type='train'})
	
	
func _on_strategy_room_button_pressed():
	scene_call('strategy_room')


func _unhandled_input(event) -> void:
	if not is_active():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		return scene_call('pause', {save_data = Game.save_state()})
	
