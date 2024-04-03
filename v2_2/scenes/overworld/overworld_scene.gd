class_name OverworldScene
extends GameScene


const BattleResultBanner := preload('res://scenes/overworld/battle_result_banner.gd')


@export var battle_result_banner_scene: PackedScene

@export var bgm: AudioStream

var music_player: AudioStreamPlayer

var territory_buttons: Array[TerritoryButton]


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

	OverworldEvents.marching_animation_requested.connect(show_marching_animation)
	OverworldEvents.battle_result_banner_requested.connect(show_battle_result_banner)


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
	if not Overworld.instance().is_running():
		# HACK until this sequence is figured out
		Overworld.instance()._overworld_main()

	initialize_buttons()
	update_turn_counter(Overworld.instance().cycle())
	update_new_available_scenes()
	allow_inputs(Overworld.instance().on_turn().is_player_owned())

	music_player = AudioManager.play_music(bgm)


func scene_exit() -> void:
	AudioManager.fade_out(music_player)


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
	
	
func update_new_available_scenes(empire: Empire = Overworld.instance().player_empire()) -> void:
	%NewEventsAvailableIcon.visible = has_any_new_events(empire)


func has_any_new_events(empire: Empire) -> bool:
	for u in Game.get_empire_units(empire, Game.ALL_UNITS_MASK):
		if Dialogue.instance().has_new_character_event(u.chara()):
			print('new event for ', u.chara(), '?')
			return true
	return false


func update_button_connections(territory: Territory, adjacent: Array[Territory]) -> void:
	var adjacent_buttons: Array[TerritoryButton] = []
	for adj in adjacent:
		adjacent_buttons.append(find_territory_button(adj))
	find_territory_button(territory).create_connections(adjacent_buttons)


func allow_inputs(allow: bool) -> void:
	$InputBlocker.mouse_filter = Control.MOUSE_FILTER_IGNORE if allow else Control.MOUSE_FILTER_STOP
	set_block_signals(not allow)

		
func show_marching_animation(from: Territory, to: Territory, empire: Empire) -> void:
	var start_pos: Vector2
	var end_pos: Vector2 = find_territory_button(to).global_position

	if from:
		start_pos = find_territory_button(from).global_position
	else:
		# find nearest position
		var sorted_positions := territory_buttons \
			.filter(func(btn): return Overworld.instance().get_territory_owner(btn._territory) == empire and empire.is_adjacent_territory(to)) \
			.map(func(btn): return btn.global_position)
		sorted_positions.sort_custom(Util.is_closer.bind(start_pos))
		start_pos = sorted_positions[0]
	
	# start and wait for march
	var anim := preload("res://scenes/overworld/marching_animation.tscn").instantiate()
	anim.global_position = start_pos
	add_child(anim)

	Overworld.instance().wait_for_marching_animation = true
	anim.march(empire, end_pos)
	await anim.done
	Overworld.instance().notify_marching_animation_finished()
	

func show_battle_result_banner(result: BattleResult, allow_strategy_room: bool) -> void:
	var banner: BattleResultBanner = battle_result_banner_scene.instantiate()
	$Overlay.add_child(banner)

	Overworld.instance().wait_for_battle_result_banner = true
	var strategy_room := await banner.show_parsed_result(result, allow_strategy_room)
	Overworld.instance().notify_battle_result_banner_finished(strategy_room)


func _emit_player_attack_action(territory: Territory, training: bool) -> void:
	var attacker := Overworld.instance().on_turn()
	var defender := Overworld.instance().get_territory_owner(territory)
	OverworldEvents.player_action_chosen.emit({
		type = 'train' if training else 'attack',
		attacker = attacker,
		defender = defender,
		territory = territory,
		map_id = 0,
		source = self,
	})
	

func _on_territory_button_attack_pressed(button: TerritoryButton) -> void:
	_emit_player_attack_action(button._territory, false)
	

func _on_territory_button_rest_pressed(button: TerritoryButton) -> void:
	OverworldEvents.player_action_chosen.emit({type='rest', territory=button._territory, source = self})
	
	
func _on_territory_button_train_pressed(button: TerritoryButton) -> void:
	_emit_player_attack_action(button._territory, true)
	
	
func _on_strategy_room_button_pressed() -> void:
	OverworldEvents.player_action_chosen.emit({type='strategy', source = self})
