@tool
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

signal unit_added(unit: Unit)
signal unit_removed(unit: Unit)
signal unit_taken_damage(unit: Unit, source: Variant, amount: int) # TODO
signal unit_died(unit: Unit) # TODO
signal unit_revived(unit: Unit) # TODO

signal _continue
signal _death_animations_done


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

var battle_result: Result

var _warnings = []
var _lock := {}
var _waiting_for_lock := false # TODO this feature wasn't used

var _battle_phase: bool

var _camera_target_remote: RemoteTransform2D = null


@onready var viewport := $SubViewportContainer/SubViewport as SubViewport
@onready var camera := $SubViewportContainer/Camera2D as Camera2D
@onready var hud := $HUD as BattleHUD


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
	Game.battle = self

	if not Engine.is_editor_hint():
		_test.call_deferred()
		
	_on_visibility_changed.call_deferred()
	
	
func _exit_tree():
	request_ready()
				
				
#region Core API
func start_battle(_attacker: Empire, _defender: Empire, _territory: Territory, _do_quick: Variant = null) -> bool:
	if !fulfills_attack_requirements(_attacker, _territory):
		return false
	
	visible = true
	_start_battle.call_deferred(_attacker, _defender, _territory, _do_quick)
	return true
		

func _start_battle(_attacker: Empire, _defender: Empire, _territory: Territory, _do_quick: Variant):
	print("Initiating battle between %s and %s over %s" % [_attacker.leader.name, _defender.leader.name, _territory.name])
	# initialize context
	if _attacker.is_player_owned():
		self.player = _attacker
		self.ai = _defender
	else:
		self.player = _defender
		self.ai = _attacker
	self.attacker = _attacker
	self.defender = _defender
	self.territory = _territory
	self.turns = 0
	self.on_turn = _attacker
	self.should_end = false
	self.victory_conditions = [VictoryCondition.new()]
	self.battle_result = Result.None
	
	self._warnings = []
	self.empire_units[attacker] = [] # map and related stuff are loaded later
	self.empire_units[defender] = []
	
	# start battle
	battle_started.emit(attacker, defender, territory)
	await Game.play_queued_scenes()
	
	# do battle
	var should_do_quick: bool = _do_quick if _do_quick != null else not (attacker.is_player_owned() or defender.is_player_owned())
		
	if should_do_quick:
		await _quick_battle()
	else:
		await _real_battle()
		
	# end battle
	battle_ended.emit(battle_result)
	await Game.play_queued_scenes()
	
	
## Returns true if the attacker can initiate the attack to territory.
func fulfills_attack_requirements(_empire: Empire, _territory: Territory) -> bool:
	# TODO put battle requirements here
	_warnings = []
	return true


## Returns true if the player fulfills prep requirements over territory.
func fulfills_prep_requirements(_empire: Empire, _territory: Territory) -> bool:
	var hero_deployed := false
	for unit in get_owned_units(_empire):
		if unit.unit_type.chara == _empire.leader:
			hero_deployed = true
	if not hero_deployed:
		_warnings = ["%s required" % _empire.leader.name]
		return false
	return true
	
	
## Quit battle.
func quit_battle(empire: Empire, message := "Retreat?"):
	var retreat := await show_pause_box(message)
	if not retreat:
		return
		
	if retreat and empire == defender:
		await show_pause_box("Cannot quit!", "Confirm", null)
		return

	if _battle_phase:
		end_battle(Result.AttackerWithdraw)
	else:
		end_battle(Result.Cancelled)
	
		
func end_battle(result: Result):
	battle_result = result
	should_end = true
	get_agent(on_turn).force_end()
	

func show_pause_box(message: String, confirm = "Confirm", cancel = "Cancel") -> bool:
	return await $Overlay/PauseBox.show_pause_box(message, confirm, cancel)
	
	
func show_message_box(message: String):
	$HUD/MessageBox/Label.text = message
	$HUD/MessageBox.visible = true
		
		
func hide_message_box():
	$HUD/MessageBox.visible = false
		

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
	$Agents.add_child(agent)
	agent.initialize(self, empire)
	empire.set_meta("Battle_agent", agent)
	return agent
	
	
func get_agent(empire: Empire) -> BattleAgent:
	return empire.get_meta("Battle_agent")
	
	
func delete_agent(agent: BattleAgent):
	$Agents.remove_child(agent)
	agent.empire.remove_meta("Battle_agent")
	agent.queue_free()
	
	
## Checks whether we should end the battle.
func check_for_turn_end(empire: Empire) -> bool:
	var result := evaluate_victory_conditions()
	if result != Result.None:
		end_battle(result)
		
	if should_end or _should_auto_end_turn(empire):
		get_agent(empire).end_turn()
		return true
	return false
			
			
func _should_auto_end_turn(empire: Empire) -> bool:
	if not Game.prefs.auto_end_turn:
		return false
	for u in get_owned_units(empire):
		if u.can_act():
			return false
	return true
		
	
func wait_for_death_animations():
	var dead_units := get_tree().get_nodes_in_group("units_dead")
	var capture := {count=dead_units.size()}
	if capture.count > 0:
		for u in dead_units:
			u.model.sprite.animation_finished.connect(func():
					u.stop_animation()
					u.set_standby(true)
					capture.count -= 1
					if capture.count <= 0:
						_death_animations_done.emit()
					, CONNECT_ONE_SHOT)
			u.play_animation("death", false)
		await _death_animations_done
	

func evaluate_victory_conditions() -> Result:
	var result: Result = Result.None
	for vc in victory_conditions:
		result = vc.evaluate(self)
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
		
	
func show_turn_banner():
	set_process_input(false)
	var hud_visible := hud.visible
	show_hud(false)
	if on_turn.is_player_owned():
		$AnimationPlayer.play("turn_banner.player")
		cursor.visible = true
	else:
		$AnimationPlayer.play("turn_banner.enemy")
		cursor.visible = false
	await $AnimationPlayer.animation_finished
	show_hud(hud_visible)
	set_process_input(true)
	
	
func show_attack_banner(attack: Attack):
	if attack:
		$Overlay/AttackNameBox/Label.text = attack.name
		$Overlay/AttackNameBox.visible = true
	else:
		$Overlay/AttackNameBox.visible = false


func show_hud(_show: bool):
	hud.show_ui(_show)
	cursor.visible = _show
	

#endregion Core API


#region Unit Functions
## Action
func unit_action_pass(unit: Unit):
	unit.turn_flags = Unit.TURN_DONE
	check_for_turn_end(unit.empire)
	

## Action
func unit_action_walk(unit: Unit, target: Vector2):
	#get_agent(unit.empire).set_process_input(false)
	hud.visible = false
	# TODO camera follow
	#var old_target := _camera_target_remote.get_parent()
	#set_camera_follow(unit)
	await unit.walk_towards(target)
	hud.visible = true
	unit.turn_flags |= Unit.TURN_MOVED
	#get_agent(unit.empire).set_process_input(true)
	check_for_turn_end(unit.empire)
	

## Action
func unit_action_attack(unit: Unit, attack: Attack, target: Array[Vector2], target_rotation: Array[float]):
	#get_agent(unit.empire).set_process_input(false)
	#var old_target := _camera_target_remote.get_parent()
	#camera.drag_horizontal_enabled = false
	#camera.drag_vertical_enabled = false
	#camera.position_smoothing_enabled = false
	#set_camera_follow(unit) # TODO follow target, not unit
	
	var hud_visible := hud.visible
	show_hud(false)
	show_attack_banner(attack)
	
	await unit.use_attack(attack, target, target_rotation)
	await wait_for_death_animations()
	
	show_attack_banner(null)
	show_hud(hud_visible)
	
	#camera.position_smoothing_enabled = true
	#set_camera_follow(old_target)
	unit.turn_flags |= Unit.TURN_ATTACKED
	#get_agent(unit.empire).set_process_input(true)
	check_for_turn_end(unit.empire)
	
		
## Returns units owned by game.
func get_owned_units(empire: Empire, include_standby := false) -> Array[Unit]:
	var re: Array[Unit] = []
	for unit in empire_units[empire]:
		if include_standby or not unit.is_standby():
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
func spawn_unit(id: String, empire: Empire, custom_name := "", pos := Map.OUT_OF_BOUNDS, heading := Unit.Heading.East) -> Unit:
	var unit: Unit
	if FileAccess.file_exists("res://Screens/Battle/data/unit/%s.tres" % id):
		unit = load("res://Screens/Battle/data/unit/%s.tres" % id).instantiate() as Unit
	else:
		var unit_type := load("res://Screens/Battle/data/unit_type/%s.tres" % id) as UnitType
		if not unit_type:
			unit_type = load("res://Screens/Battle/data/unit_type/Dummy.tres") as UnitType
		unit = preload("res://Screens/Battle/map_types/unit/Unit.tscn").instantiate() as Unit
		unit.unit_type = unit_type
	if custom_name != "":
		unit.display_name = custom_name
	add_unit(unit, empire, pos, heading)
	return unit
	

## Adds the unit if it's not already yet.
func add_unit(unit: Unit, empire: Empire, pos := Map.OUT_OF_BOUNDS, heading := Unit.Heading.East):
	if not unit.has_meta("Battle_init_ready"):
		if unit.get_parent() == null:
			map.get_node("Entities").add_child(unit)
		
		unit.empire = empire
		unit.map_pos = pos
		unit.set_heading(heading)
		
		empire_units[unit.empire].append(unit)
		
		unit.set_meta("Battle_init_ready", true)
		unit_added.emit(unit)
		

## Removes the unit from the map.
func remove_unit(unit: Unit):
	if unit.has_meta("Battle_init_ready"):
		unit.get_parent().remove_child(unit)
		empire_units[unit.empire].erase(unit)
		unit.remove_meta("Battle_init_ready")
		unit_removed.emit(unit)
		
## Kills a unit.
func kill_unit(unit: Unit):
	unit.add_to_group('units_dead')
	unit.alive = false
	unit.selectable = false
	

## Revives a unit.
func revive_unit(unit: Unit, hp: int):
	unit.hp = mini(hp, unit.maxhp)
	unit.add_to_group('units_alive')
	unit.alive = true
	unit.selectable = true

	
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
	
		
func draw_unit_attack_target(unit: Unit, attack: Attack, target: Array[Vector2], target_rotation: Array[float]):
	for i in target.size():
		var cells := unit.get_attack_target_cells(attack, target[i], target_rotation[i])
		map.target_overlay.draw(cells, 1, false) # blue
		
		
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
	
#endregion Draw


#region Internals
func _quick_battle():
	print("Entering quick battle.")
	# TODO randomize or simulate the victor
	battle_result = Result.AttackerVictory


func _real_battle():
	print("Entering real battle.")
	Game.push_screen(self)
	await Game.screen_ready
	
	create_agent(attacker)
	create_agent(defender)
	
	_load_map(territory.maps[0])
	
	_battle_phase = false
	hud.show_ui(true)
	
	# ai preparation is done before transition
	on_turn = ai
	await get_agent(ai).prepare_units()
	await Game.transition_finished
	
	on_turn = player
	await get_agent(player).prepare_units()
	if not should_end:
		_battle_phase = true
		hud.show_ui(true)
		await _do_battle()
		
		var message := Battle.player_battle_result_message(attacker.is_player_owned(), battle_result)
		if message != '':
			var node := preload("res://Screens/Battle/BattleResultsScreen.tscn").instantiate()
			get_tree().root.add_child.call_deferred(node)
			node.text = message
			node.battle_won = Battle.player_battle_result_win(attacker.is_player_owned(), battle_result)
			await node.animation_finished
			node.queue_free()
			
	# post-battle setup
	delete_agent(get_agent(attacker))
	delete_agent(get_agent(defender))
	Game.pop_screen()
	await Game.transition_finished
	_unload_map()


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
				u.set_meta("Battle_unit_pre_placed", true)
			defender.leader.name:
				add_unit(u, defender, u.map_pos)
				u.set_meta("Battle_unit_pre_placed", true)
			_:
				u.queue_free()
	
	
func _do_battle():
	print("Entering battle phase.")
	for u in map.get_units():
		u.hp = maxi(1, int(u.empire.hp_multiplier * u.maxhp))
		
	while not should_end:
		print("Turn '%s'" % turns)
		turn_cycle_started.emit()
		await Game.play_queued_scenes()
		
		for empire in [attacker, defender]:
			print("On turn ", empire)
			if should_end:
				break
			on_turn = empire
			
			# pre-turn
			for u in get_owned_units(empire):
				u.turn_flags = Unit.TURN_NEW if not 'STN' in u.status_effects else Unit.TURN_DONE
					
				# should be here so we can properly evaluate w/l
				# conditions before the turn actually starts
				if 'PSN' in u.status_effects:
					damage_unit(u, 'PSN', 1)
		
			# on-turn
			await show_turn_banner()
			set_camera_follow(cursor)
			
			empire_turn_started.emit()
			await Game.play_queued_scenes()
			
			if not check_for_turn_end(empire):
				await get_agent(empire).do_turn()
			
			empire_turn_ended.emit()
			await Game.play_queued_scenes()
			
			# post-turn
			for u in get_owned_units(empire):
				if not u.has_taken_action():
					heal_unit(u, self, 1) 
				
				# tick duration of status effects
				_tick_status_effects(u)
			check_for_turn_end(empire)
			await wait_for_death_animations()
				
		turn_cycle_ended.emit()
		await Game.play_queued_scenes()
		
		turns += 1
	
	
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
	a.units = ['Alara', 'Lysandra', 'Maia', 'Tali', 'Eirene']
	a.leader = preload("res://Screens/Battle/data/chara/Lysandra.tres")
	var b := Empire.new()
	b.units = ['cultist_axe', 'cultist_bow', 'cultist_mace', 'cultist_priestess', 'cultist_spear', 'cultist_sword', 'cultist_witch']
	b.leader = preload("res://Screens/Battle/data/chara/Alara.tres")
	var terr := Territory.new()
	terr.maps = [preload("res://Screens/Battle/map_types/Map.tscn")]
	start_battle(a, b, terr)



#endregion

func _on_visibility_changed():
	$Background.visible = visible
	$HUD.visible = visible
	$Overlay.visible = visible
