class_name Battle
extends Control


signal battle_started
signal battle_ended

signal empire_preparation_started
signal empire_preparation_ended

signal turn_cycle_started
signal turn_cycle_ended

signal empire_turn_started
signal empire_turn_ended

signal action_started
signal action_ended


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


var empire_units := {}
var map: Map
var cursor: Cursor
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
var _lock := {}
var _waiting_for_lock := false

var _camera_target_remote: RemoteTransform2D = null


@onready var viewport := $SubViewportContainer/SubViewport as SubViewport
@onready var camera := $SubViewportContainer/Camera2D as Camera2D
@onready var prep_unit_list := $HUD/PrepUnitList as PrepUnitList
	
## Returns true if player won the battle.
static func player_battle_result_win(is_attacker: bool, result: Result) -> bool:
	if is_attacker:
		return result == Result.AttackerVictory or result == Result.DefenderWithdraw
	else:
		return result == Result.DefenderVictory or result == Result.AttackerWithdraw
		
		
## Returns the battle message from result.
static func player_battle_result_message(is_attacker: bool, result: Result) -> String:
	if is_attacker:
		match result:
			Result.AttackerVictory:
				return 'Territory Taken!'
			Result.DefenderVictory:
				return 'Conquest Failed.'
			Result.AttackerWithdraw:
				return 'Battle Forfeited.'
			Result.DefenderWithdraw:
				return 'Enemy Withdraw!'
	else:
		match result:
			Result.AttackerVictory:
				return 'Territory Lost.'
			Result.DefenderVictory:
				return 'Defense Success!'
			Result.AttackerWithdraw:
				return 'Enemy Withdraw!'
			Result.DefenderWithdraw:
				return 'Territory Surrendered.'
	return ''
	
	
func _ready():
	Globals.battle = self
	_test.call_deferred()
	

func _exit_tree():
	request_ready()
				
	
#region Core API
func start_battle(attacker: Empire, defender: Empire, territory: Territory, do_quick = null) -> bool:
	if !fulfills_attack_requirements(attacker, territory):
		return false
	
	_start_battle.call_deferred(attacker, defender, territory, do_quick)
	return true
		

func _start_battle(attacker: Empire, defender: Empire, territory: Territory, do_quick):
	print("Initiating battle between %s and %s over %s" % [attacker.leader.name, defender.leader.name, territory.name])
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
	
	self.empire_units[attacker] = [] # map and related stuff are loaded later
	self.empire_units[defender] = []
	
	var result: Result = Result.None
	
	# start battle
	battle_started.emit(attacker, defender, territory)
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
	battle_ended.emit(result)
	await Globals.play_queued_scenes()
	
	
## Returns true if the attacker can initiate the attack to territory.
func fulfills_attack_requirements(empire: Empire, territory: Territory) -> bool:
	# TODO put battle requirements here
	_warnings = []
	return true


## Returns true if the attacker fulfills prep requirements over territory.
func fulfills_prep_requirements(empire: Empire, territory: Territory) -> bool:
	# TODO put battle requirements here
	_warnings = []
	return true
	
	
## Quit battle.
func quit_battle(ask_for_confirmation := true, message := "Forfeit?"):
	if ask_for_confirmation:
		should_end = await show_pause_box(message, "Confirm", "Cancel")
	else:
		should_end = true
		

func show_pause_box(message: String, confirm = "Confirm", cancel = "Cancel") -> bool:
	return await $Overlay/PauseBox.show_pause_box(message, confirm, cancel)
	

func set_camera_follow(obj: Node2D):
	if _camera_target_remote:
		var target := _camera_target_remote.get_parent()
		if target == obj:
			return
		target.remove_child(_camera_target_remote)
		_camera_target_remote.queue_free()
		_camera_target_remote = null
	
	_camera_target_remote = RemoteTransform2D.new()
	obj.add_child(_camera_target_remote)
	_camera_target_remote.remote_path = camera.get_path()
	
	
func _unset_camera_follow(obj: Node2D):
	if obj and _camera_target_remote:
		obj.remove_child(_camera_target_remote)
		_camera_target_remote.queue_free()
		_camera_target_remote = null
		

func create_agent(empire: Empire) -> BattleAgent:
	var agent: BattleAgent
	if empire.is_player_owned():
		agent = BattleAgentPlayerv2.new()
	else:
		agent = BattleAgentAIv2.new()
		#agent = preload("res://Screens/Battle/BattleAgentAI.tscn").instantiate()
	agent.battle = self
	agent.empire = empire
	$Agents.add_child(agent)
	agent.initialize()
	return agent
	
	
func wait_for_death_animations():
	pass
	

func evaluate_victory_conditions() -> Result:
	var result: Result = Result.None
	for vc in victory_conditions:
		#result = vc.evaluate(self)
		if result != Result.None:
			break
	return result
	

## Stops the battle flow and waits until all locks are released.
func acquire_lock(tag: String):
	if tag not in _lock:
		_lock[tag] = true
	

## Releases an instance of lock.
func release_lock(tag: String):
	if tag in _lock:
		_lock.erase(tag)
		if _lock.is_empty() and _waiting_for_lock:
			_continue.emit()
		
		
func _wait_for_lock():
	if _waiting_for_lock:
		push_error("_wait_for_lock reentry detected")
	else:
		if not _lock.is_empty():
			_waiting_for_lock = true
			await _continue
			_waiting_for_lock = false
			
			
func screen_to_global(pos: Vector2) -> Vector2:
	return get_viewport().canvas_transform.affine_inverse() * pos


func play_error():
	if not $AudioStreamPlayer2D.is_playing():
		$AudioStreamPlayer2D.stream = preload("res://error-126627.wav")
		$AudioStreamPlayer2D.play()


var _selected_unit: Unit

func set_selected_unit(unit: Unit):
	_selected_unit = unit
	if unit:
		$HUD/CharacterPortrait/TextureRect.texture = unit.chara.portrait
		$HUD/CharacterPortrait/Label.text = unit.chara.name.to_upper()
		$HUD/CharacterPortrait.visible = true
		$HUD/RestButton.visible = unit.is_player_owned() and not unit.has_attacked
		$HUD/FightButton.visible = unit.is_player_owned() and not unit.has_attacked
		$HUD/DiefyButton.visible = unit.is_player_owned() and not unit.has_attacked
		$HUD/DiefyButton.disabled = not unit.is_special_unlocked()
	else:
		$HUD/CharacterPortrait.visible = false
		$HUD/RestButton.visible = false
		$HUD/FightButton.visible = false
		$HUD/DiefyButton.visible = false
		
#enum {
	#STATE_STANDBY,
	#STATE_HOVER_UNIT,
	#STATE_UNIT_SELECTED,
	#STATE_ATTACK_SELECTED,
	#STATE_ATTACK_SEQUENCE,
#}
#
#var _state := 0
#func hover_cell(cell: Vector2):
	#_selected_cell = cell
	#cursor.position = map.world.as_global(cell)
	#
	#if _selected_unit:
		#if not _selected_unit.has_taken_action:
			#map.unit_path.draw(_selected_unit.cell(), cell)
		#return
	#
	#var hovered := map.get_unit(cell)
	#if hovered:
		#$HUD/CharacterPortrait/TextureRect.texture = hovered.chara.portrait
		#$HUD/CharacterPortrait/Label.text = hovered.display_name
		#$HUD/CharacterPortrait.visible = true
	#else:
		#$HUD/CharacterPortrait.visible = false
		#
#
#func select_unit(unit: Unit):
	#if unit:
		#$HUD/CharacterPortrait/TextureRect.texture = unit.chara.portrait
		#$HUD/CharacterPortrait/Label.text = unit.display_name
		#$HUD/CharacterPortrait.visible = true
		#$HUD/RestButton.visible = unit.is_player_owned()
		#$HUD/FightButton.visible = unit.is_player_owned()
		#$HUD/DiefyButton.visible = unit.is_player_owned()
		#$HUD/DiefyButton.disabled = not unit.is_special_unlocked()
		#if not unit.has_taken_action:
			#var pathable := unit.get_pathable_cells(true)
			#map.pathing_overlay.draw(pathable)
			#map.unit_path.initialize(pathable)
		#_selected_unit = unit
	#else:
		#$HUD/RestButton.visible = false
		#$HUD/FightButton.visible = false
		#$HUD/DiefyButton.visible = false
		#map.pathing_overlay.clear()
		#map.unit_path.clear()
		#if _selected_unit and not _selected_unit.has_taken_action:
			#
			#await unit_action_walk(_selected_unit, _selected_cell)
		#_selected_unit = null
	#
	#
#func select_attack(attack: Attack):
	#_selected_attack = attack
	#if attack:
		#pass
	#else:
		#pass
		#
		#
#func hover_attack_target(cell: Vector2):
	#pass
	#
	#
#func select_attack_target(cell: Vector2):
	#_selected_multicast_queue.append(cell)
	#
	#
#func cancel():
	#match _state:
		#STATE_ATTACK_SEQUENCE:
			#pass
		#STATE_ATTACK_SELECTED:
			#while not _selected_multicast_queue.is_empty():
				#_selected_multicast_queue.pop_back()
				#var reselect: Vector2 = _selected_multicast_queue.pop_back()
				#select_attack_target(reselect)
				#
		#STATE_UNIT_SELECTED:
			#pass
		#STATE_HOVER_UNIT:
			#pass
		#STATE_STANDBY:
			#pass
#endregion Core API


#region Unit Functions
## Action
func unit_action_pass(unit: Unit):
	unit.has_moved = true
	unit.has_attacked = true
	unit.has_taken_action = false
	

## Action
func unit_action_walk(unit: Unit, target: Vector2):
	$HUD.visible = false
	var old_target := _camera_target_remote.get_parent()
	set_camera_follow(unit)
	await unit.walk_towards(target)
	$HUD.visible = true
	set_camera_follow(old_target)
	unit.has_moved = true
	#unit.has_attacked = false
	unit.has_taken_action = true
	

## Action
func unit_action_attack(unit: Unit, attack: Attack, target: Variant, target_rotation: Variant):
	$HUD.visible = false
	await _unit_use_attack(unit, attack, target, target_rotation)
	$HUD.visible = true
	#unit.has_moved = true
	unit.has_attacked = true
	unit.has_taken_action = true


func _unit_use_attack(unit: Unit, attack: Attack, target: Variant, target_rotation: Variant):
	var old_target := _camera_target_remote.get_parent()
	camera.drag_horizontal_enabled = false
	camera.drag_vertical_enabled = false
	camera.position_smoothing_enabled = false
	set_camera_follow(unit) # TODO follow target, not unit
	
	$Overlay/AttackNameBox/Label.text = attack.name
	$HUD.visible = false
	$Overlay/AttackNameBox.visible = true
	
	await unit.use_attack(attack, target, target_rotation)
	
	$Overlay/AttackNameBox.visible = false
	$HUD.visible = true
	camera.position_smoothing_enabled = true
	set_camera_follow(old_target)
	
	
## Returns units owned by game.
func get_owned_units(empire: Empire, standby := false) -> Array[Unit]:
	var re: Array[Unit] = []
	if standby:
		for unit in empire_units[empire]:
			re.append(unit)
	else:
		for unit in empire_units[empire]:
			if unit.is_in_group('units_standby'):
				continue
			re.append(unit)
	return re
	
	
## Returns nearby units.
func get_units_in_range(from: Vector2, distance: int, filter: Callable) -> Array[Unit]:
	var re: Array[Unit] = []
	for obj in map.get_objects():
		if obj is Unit and Util.cell_distance(obj.map_pos, from) <= distance and filter.call(obj):
			re.append(obj)
	return re
	
	
## Finds a unit by name.
func find_unit(unit_name: String) -> Unit:
	for u in map._get_objects():
		if u is Unit and u.display_name == unit_name:
			return u
	return null
	

## Returns the unit at given pos.
func get_unit_at(cell: Vector2) -> Unit:
	for u in map._get_objects():
		if u is Unit and u.cell() == cell:
			return u
	return null
	
	
## Spawns a unit.
func spawn_unit(path: String, empire: Empire, custom_name := "", pos := Map.OUT_OF_BOUNDS, heading := Unit.Heading.East) -> Unit:
	#assert(empire == context.attacker or empire == context.defender, "owner is neither empire!")	
	var unit := load(path).instantiate() as Unit
	unit.display_name = custom_name if custom_name != "" else unit.chara.name
	
	add_unit(unit, empire, pos, heading)
	return unit
	

## Adds the unit if it's not already yet.
func add_unit(unit: Unit, empire: Empire, pos := Map.OUT_OF_BOUNDS, heading := Unit.Heading.East):
	if not unit.has_meta("Battle_init_ready"):
		if unit.get_parent() == null:
			map.get_node("Entities").add_child(unit)
		
		unit.empire = empire
		if pos == Map.OUT_OF_BOUNDS:
			set_unit_standby(unit, true)
		else:
			unit.map_pos = pos
		unit.set_heading(heading)
		
		empire_units[unit.empire].append(unit)
		
		unit.set_meta("Battle_init_ready", true)
		

## Removes the unit from the map.
func remove_unit(unit: Unit):
	if unit.has_meta("Battle_init_ready"):
		unit.get_parent().remove_child(unit)
		empire_units[unit.empire].erase(unit)
		unit.remove_meta("Battle_init_ready")
		
## Kills a unit.
func kill_unit(unit: Unit):
	unit.add_to_group('units_dead')
	unit.alive = false
	

## Revives a unit.
func revive_unit(unit: Unit, hp: int):
	unit.hp = mini(hp, unit.maxhp)
	unit.add_to_group('units_alive')
	unit.alive = true


## Standby unit.
func set_unit_standby(unit: Unit, standby: bool):
	if standby:
		unit.set_meta("Battle_unit_standby_old_pos", unit.map_pos)
		unit.map_pos = Map.OUT_OF_BOUNDS
		unit.add_to_group('units_standby')
	else:
		var pos: Vector2 = unit.get_meta("Battle_unit_standby_old_pos", Vector2.ZERO)
		if unit.map_pos == Map.OUT_OF_BOUNDS:
			unit.map_pos = pos
		unit.remove_from_group('units_standby')

	
## Inflict damage upon a unit.
func damage_unit(unit: Unit, source: Variant, amount: int):
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
	if source is String and source == 'PSN':
		color = Color(0.949, 0.29, 0.949)
	if vul:
		color = Color(0.949, 0.949, 0.29)
	if blk:
		color = Color(0, 0.691, 0.833)
	draw_floating_number(unit, amount, color)
	

## Heals unit.
func heal_unit(unit: Unit, _source: Variant, amount: int):
	# unit might have been killed prior to this within the same frame,
	# before dead units are processed
	if unit.alive:
		unit.hp = clampi(unit.hp + amount, 0, unit.maxhp)
		draw_floating_number(unit, amount, Color(0.29, 0.949, 0.392))
#endregion Unit Functions


#region Draw
func draw_unit_path(unit: Unit, target_cell: Vector2):
	map.unit_path.initialize(unit.get_pathable_cells())
	map.unit_path.draw(unit.cell(), target_cell)


func draw_unit_pathable_cells(unit: Unit, use_alt_color := false):
	map.pathing_overlay.draw(unit.get_pathable_cells(true), 1 if use_alt_color else 2) # yes, 1 is the alt color


func draw_unit_attack_range(unit: Unit, attack: Attack):
	map.attack_overlay.draw(unit.get_attack_range_cells(attack), 3) # red
	
	
func draw_unit_attack_targets(unit: Unit, attack: Attack, target: Variant, target_rotation: Variant, is_multi_target := false):
	if is_multi_target:
		map.attack_overlay.clear()
		for i in target.size():
			var cells := unit.get_attack_target_cells(attack, target[i], target_rotation[i])
			map.target_overlay.draw(cells, 1, false) # blue
	else:
		var cells := unit.get_attack_target_cells(attack, target, target_rotation)
		map.target_overlay.draw(cells, 1, true) # blue
		
		
func draw_floating_number(unit: Unit, number: int, color: Color):
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
	

func show_turn_banner():
	set_process_input(false)
	if on_turn.is_player_owned():
		$AnimationPlayer.play("turn_banner.player")
		cursor.visible = true
	else:
		$AnimationPlayer.play("turn_banner.enemy")
		cursor.visible = false
	await $AnimationPlayer.animation_finished
	set_process_input(true)
	
#endregion Draw


#region Internals
		
		
func _process_dead_units():
	pass
	
	
func _quick_battle(attacker: Empire, defender: Empire, territory: Territory) -> Result:
	print("Entering quick battle.")
	# TODO randomize or simulate the victor
	return Result.AttackerVictory


func _real_battle(attacker: Empire, defender: Empire, territory: Territory) -> Result:
	print("Entering real battle.")
	Globals.push_screen(self)
	await Globals.screen_ready
	_load_map(territory.maps[0])
	
	var agent := {
		attacker: create_agent(attacker), 
		defender: create_agent(defender), 
	}
	
	await agent[ai].prepare_units()
		
	# wait for the screen transition before proceeding
	await Globals.transition_finished
	
	var result := Result.None
	if await _player_prep_phase(agent[player]):
		result = await _do_battle(agent)
		
		var message := player_battle_result_message(attacker.is_player_owned(), result)
		if message != '':
			var node := preload("res://Screens/Battle/BattleResultsScreen.tscn").instantiate()
			get_tree().root.add_child.call_deferred(node)
			node.text = message
			node.battle_won = player_battle_result_win(attacker.is_player_owned(), result)
			await node.animation_finished
			node.queue_free()
	else:
		result = Result.Cancelled
			
	# post-battle setup
	for e in agent.values():
		e.queue_free()
	Globals.pop_screen()
	await Globals.transition_finished
	_unload_map()
	
	return result


func _load_map(scene: PackedScene):
	print("Loading map '%s'" % scene.resource_path)
	map = scene.instantiate() as Map
	
	viewport.add_child(map)
	cursor = map.get_node("Cursor")
	_redistribute_units()
	
	
func _unload_map():
	print("Unloading map")
	viewport.remove_child(map)
	map.queue_free()
	map = null
	cursor = null
	
	
func _redistribute_units():
	for u in map.get_objects():
		if not u is Unit:
			continue
		
		if not u.has_meta("default_owner"):
			print("Pre-placed unit missing 'default_owner' metadata.")
			u.queue_free()
			continue
			
		match u.get_meta("default_owner"):
			attacker.leader.name:
				add_unit(u, attacker, u.map_pos)
			defender.leader.name:
				add_unit(u, defender, u.map_pos)
			_:
				u.queue_free()
		
	
func _player_prep_phase(player: BattleAgent) -> bool:
	print("Entering player prep phase.")
	# allow the player to prep
	#$UI/DonePrep.visible = true
	#$UI/CancelPrep.visible = attacker.is_player_owned()
	#_allow_quit = true
	await player.prepare_units()
	#_allow_quit = false
	#$UI/DonePrep.visible = false
	#$UI/CancelPrep.visible = false
	return not should_end
	
	
func _do_battle(agent: Dictionary) -> Result:
	print("Entering battle phase.")
	for u in map.get_units():
		u.hp = maxi(1, int(u.empire.hp_multiplier * u.maxhp))
		
	var result := Result.None
	while not should_end:
		print("Turn '%s'" % turns)
		turn_cycle_started.emit()
		await Globals.play_queued_scenes()
		
		for empire in [attacker, defender]:
			print("On turn ", empire)
			on_turn = empire
			
			# pre-turn
			for u in get_owned_units(empire):
				var stunned: bool = 'STN' in u.status_effects
				u.has_moved = stunned
				u.has_attacked = stunned
				u.has_taken_action = stunned
					
				# should be here so we can properly evaluate w/l
				# conditions before the turn actually starts
				if 'PSN' in u.status_effects:
					damage_unit(u, 'PSN', 1)
		
			# on-turn
			result = evaluate_victory_conditions()
			if result != Result.None:
				should_end = true
				break
				
			await show_turn_banner()
			set_camera_follow(cursor)
			
			empire_turn_started.emit()
			await Globals.play_queued_scenes()
			
			await agent[empire].do_turn()
			
			empire_turn_ended.emit()
			await Globals.play_queued_scenes()
			
			# post-turn
			for u in get_owned_units(empire):
				if not u.has_taken_action:
					heal_unit(u, self, 1) 
				
				# tick duration of status effects
				_tick_status_effects(u)
				
		turn_cycle_ended.emit()
		await Globals.play_queued_scenes()
		
		turns += 1
	
	return result
	
	
func _tick_status_effects(unit: Unit):
	var expired_effects := []
	for effect in unit.status_effects:
		unit.status_effects[effect] -= 1
		if unit.status_effects[effect] <= 0:
			expired_effects.append(expired_effects)
			
	for effect in expired_effects:
		unit.status_effects.erase(effect)
	
#endregion Internals


#endregion Testing
func _test():
	var a := Empire.new()
	a.set_meta("player", true)
	a.units = ['A', 'B']
	a.leader = preload("res://Screens/Battle/data/chara/Lysandra.tres")
	var b := Empire.new()
	b.leader = preload("res://Screens/Battle/data/chara/Alara.tres")
	var territory := Territory.new()
	territory.maps = [preload("res://Screens/Battle/map_types/Map.tscn")]
	start_battle(a, b, territory)



#endregion
