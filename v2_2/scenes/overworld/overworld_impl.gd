class_name OverworldImpl
extends Overworld

@export_group("Game Data")
@export var _overworld_scene: PackedScene
@export var _territories: Array[Territory]
@export var _empires: Array[Empire]
@export var _player_empire: Empire
@export var _boss_empire: Empire

@export_group("State")
@export var _active_empires: Array[Empire]
@export var _defeated_empires: Array[Empire]
@export var _cycle_count: int
@export var _turn_index: int


func _ready():
	add_to_group('game_event_listeners')
	
	
func on_new_save(save: SaveState):
	var overworld_scene := preload("res://scenes/overworld/overworld_scene.tscn")
	var instance: OverworldScene = overworld_scene.instantiate()
	add_child(instance)

	var data := instance.create_initial_data()
	
	# do some simple verification
	if not data.player_empire:
		push_error('player_empire not found %s' % instance)
	if not data.boss_empire:
		push_error('boss_empire not found in %s' % instance)
	
	# add empires to active
	data.active_empires.append(data.player_empire)
	for e: Empire in data.empires:
		if e.is_random():
			data.active_empires.append(e)

	# give units to empires
	for e: Empire in data.empires:
		# skip non participating empires (aka empires with no home set)
		if not e.home_territory:
			continue
		
		e.hero_units = [Game.create_unit(save, e.leader_id)]
		e.units.append_array(e.hero_units)
		for t in e.territories:
			for chara_id in t.units:
				for i in t.units[chara_id]:
					e.units.append(Game.create_unit(save, e.leader_id))
	
	# add to save
	save.overworld_data = data


func on_save(save: SaveState):
	save.overworld_data = {
		overworld_scene = _overworld_scene,
		territories = _territories.duplicate(),
		empires = _empires.duplicate(),
		player_empire = _player_empire,
		boss_empire = _boss_empire,
		active_empires = _active_empires.duplicate(),
		defeated_empires = _defeated_empires.duplicate(),
		cycle_count = _cycle_count,
		turn_index = _turn_index,
	}


## Starts the overworld cycle.
func start_overworld_cycle():
	assert(false, 'not implemented')
	
	
## Stops the overworld cycle.
func stop_overworld_cycle():
	assert(false, 'not implemented')
	
	
## Pauses the overworld and waits until resume.
func queue_pause():
	assert(false, 'not implemented')
	
	
## Returns an array of all territories.
func territories() -> Array[Territory]:
	return _territories


## Returns an array of all the empires.
func empires() -> Array[Empire]:
	return _empires
	
	
## Returns the player empire.
func player_empire() -> Empire:
	return _player_empire
	
	
## Returns the boss empire.
func boss_empire() -> Empire:
	return _boss_empire
	
	
## Returns a list of all the active empires.
func active_empires() -> Array[Empire]:
	return _active_empires
	
	
## Returns a list of all the defeated empires.
func defeated_empires() -> Array[Empire]:
	return _defeated_empires
	
	
## Returns the number of overworld cycles.
func cycle() -> int:
	return _cycle_count

	
## Returns the empire currently on turn.
func on_turn() -> Empire:
	return _active_empires[_turn_index]
	

## Returns true if the boss is active.
func is_boss_active() -> bool:
	return _boss_empire in _active_empires
	
	
## Returns the empire with the given leader.
func get_empire_by_leader_id(leader_id: StringName) -> Empire:
	for e in _empires:
		if e.leader_id == leader_id:
			return e
	return null
	
	
## Returns the empire with the given leader name.
func get_empire_by_leader_name(name: StringName) -> Empire:
	for e in _empires:
		if e.leader.name == name:
			return e
	return null
	
	
## Returns the territory with the given name.
func get_territory_by_name(name: StringName) -> Territory:
	for t in _territories:
		if t.name == name:
			return t
	return null
	
	
## Returns the owner of the territory.
func get_territory_owner(territory: Territory) -> Empire:
	for e in _empires:
		if territory in e.territories:
			return e
	return null
	
	
## Returns true if territory is a home territory.
func is_home_territory(t: Territory) -> bool:
	for e in _empires:
		if t == e.home_territory:
			return true
	return false
	
	
## Connects two territories, [code]a[/code] and [code]b[/code].
func connect_territories(a: Territory, b: Territory):
	if not a.is_adjacent(b):
		a.adjacent.append(b.name)
	if not b.is_adjacent(a):
		b.adjacent.append(a.name)
		
		
## Transfers territory to [code]new_owner[/code].
func transfer_territory(new_owner: Empire, territory: Territory):
	assert(false, 'not implemented')
	

## Returns the owner of the unit.
func get_unit_owner(unit: Unit) -> Empire:
	assert(false, 'not implemented')
	return null


## Returns true if unit is a hero unit.
func is_hero_unit(unit: Unit) -> bool:
	assert(false, 'not implemented')
	return false
