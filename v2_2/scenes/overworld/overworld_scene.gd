class_name OverworldScene
extends GameScene


var territory_buttons: Array[TerritoryButton]


@onready var battle_result_banner = $BattleResultBanner


func _ready() -> void:
	territory_buttons.clear()
	for button in $Territories.get_children():
		if not button is TerritoryButton:
			continue
		territory_buttons.append(button)
		button.attack_pressed.connect(_on_territory_button_attack_pressed)
		button.rest_pressed.connect(_on_territory_button_rest_pressed)
		button.train_pressed.connect(_on_territory_button_train_pressed)
		# TODO highlight all owned buttons when clicked

	OverworldEvents.cycle_started.connect(update_turn_counter)
	OverworldEvents.turn_ended.connect(update_new_available_scenes)
	OverworldEvents.territory_adjacency_changed.connect(update_button_connections)

	OverworldEvents.turn_started.connect(func(empire: Empire):
		allow_inputs(empire.is_player_owned())
	)

	OverworldEvents.turn_ended.connect(func(_empire: Empire):
		allow_inputs(false)
	)


## Returns the territory nodes.
func get_territory_nodes() -> Array[TerritoryButton]:
	return territory_buttons


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


func scene_enter(_kwargs = {}) -> void:
	initialize_buttons()
	update_turn_counter(Overworld.instance().cycle())
	update_new_available_scenes()
	allow_inputs(Overworld.instance().on_turn().is_player_owned())


## Initializes the buttons.
func initialize_buttons() -> void:
	assert(Overworld.instance().is_initialized())
	for button in territory_buttons:
		# get the territory
		var territory := Overworld.instance().get_territory_by_name(button.name)
		var empire := Overworld.instance().get_territory_owner(territory)
		# initialize
		button.initialize({
			territory = territory,
			empire = empire,
			empire_units = Game.get_empire_units(empire, Game.ALL_UNITS_MASK),
			player_empire = Overworld.instance().player_empire(),
			adjacent_to_player = Overworld.instance().player_empire().is_adjacent_territory(territory),
		})

		# hide the boss button if necessary.
		if territory == Overworld.instance().boss_empire().home_territory:
			button.visible = Overworld.instance().is_boss_active()


func update_turn_counter(cycle: int) -> void:
	%TurnCountLabel.text = str(cycle + 1)
	
	
func update_new_available_scenes(_empire: Empire = null) -> void:
	%NewSceneIcon.visible = Game.has_new_scenes()


func update_button_connections(territory: Territory, adjacent: Array[Territory]) -> void:
	var adjacent_buttons: Array[TerritoryButton] = []
	for adj in adjacent:
		adjacent_buttons.append(find_territory_button(adj))
	find_territory_button(territory).create_connections(adjacent_buttons)


func allow_inputs(allow: bool) -> void:
	$InputBlocker.mouse_filter = Control.MOUSE_FILTER_IGNORE if allow else Control.MOUSE_FILTER_STOP
	set_block_signals(not allow)

		
func show_marching_animation(attacker: Empire, _defender: Empire, target: Territory) -> void:
	# find nearest position
	var start_pos := find_territory_button(target).global_position
	var sorted_positions := territory_buttons \
		.filter(func(btn): return Overworld.instance().get_territory_owner(btn._territory) == attacker and attacker.is_adjacent_territory(target)) \
		.map(func(btn): return btn.global_position)
	sorted_positions.sort_custom(Util.is_closer.bind(start_pos))
	
	# start and wait for march
	var anim := preload("res://scenes/overworld/marching_animation.tscn").instantiate()
	anim.global_position = sorted_positions[0]
	add_child(anim)
	anim.march(start_pos)
	await anim.done
	

func show_battle_result_banner(result: BattleResult, allow_strategy_room: bool) -> bool:
	var banner := battle_result_banner.duplicate()
	add_child(banner)
	return await banner.show_parsed_result(result, allow_strategy_room)


func _on_territory_button_attack_pressed(button: TerritoryButton):
	var attacker := Overworld.instance().on_turn()
	var defender := Overworld.instance().get_territory_owner(button._territory)
	OverworldEvents.player_action_chosen.emit({
		type = 'attack',
		attacker = attacker,
		defender = defender,
		territory = button._territory,
		map_id = 0,
		source = self,
	})
	

func _on_territory_button_rest_pressed(button: TerritoryButton) -> void:
	OverworldEvents.player_action_chosen.emit({type='rest', territory=button._territory, source = self})
	
	
func _on_territory_button_train_pressed(button: TerritoryButton) -> void:
	OverworldEvents.player_action_chosen.emit({type='train', territory=button._territory, source = self})
	
	
func _on_strategy_room_button_pressed() -> void:
	OverworldEvents.player_action_chosen.emit({type='strategy', source = self})


func _unhandled_input(event) -> void:
	if not is_active():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		return scene_call('pause', {save_data = Game.save_state()})
	
