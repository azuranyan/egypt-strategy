class_name Overworld
extends CanvasLayer


@export_subgroup("Internal")
@export var _initial_setup_done: bool
@export var _all_territories: Array[Territory]
@export var _all_empires: Array[Empire]
@export var _player_empire: Empire
@export var _boss_empire: Empire
@export var _active_empires: Array[Empire]
@export var _defeated_empires: Array[Empire]


func _ready():
	if not _initial_setup_done:
		_initial_setup()
	
	
func _initial_setup():
	print('[Overworld] Doing initial setup.')
	_init_territories()
	_init_empires()
	_init_distribute_empires()
	_all_territories.make_read_only()
	_all_empires.make_read_only()
	_initial_setup_done = true
	print('[Overworld] Initial setup done.')
	
	
func _init_territories():
	print('[Overworld] Setup: loading territories.')
	for i in get_child_count():
		var button := get_child(i) as TerritoryButton
		if button == null:
			continue
		if not button.territory:
			push_warning('TerritoryButton node has no Territory')
			continue
		button.territory.id = _all_territories.size()
		_all_territories.append(button.territory)

func _init_empires(): 
	print('[Overworld] Setup: loading empires.')
	for child in $Empires.get_children():
		var empire := child as Empire
		if empire == null:
			push_warning('non-empire node found in empires list, ignoring')
			continue
		if empire.is_player_owned():
			_player_empire = empire
		if empire.is_boss():
			_boss_empire = empire
		empire.id = _all_empires.size()
		_all_empires.append(empire)
	assert(_player_empire != null, 'player empire not found')
	assert(_boss_empire != null, 'boss empire not found')
	assert(_player_empire != _boss_empire, 'player empire is boss empire')
	
	
func _init_distribute_empires():
	print('[Overworld] Setup: distributing empires.')
	var selection: Array[Empire] = []
	for child in $RandomEmpireSelection.get_children():
		var empire := child as Empire
		if empire == null:
			push_warning('non-empire node found in random empires list, ignoring')
			continue
		selection.append(empire)
	selection.shuffle()
	
	var grabs: Array[Territory] = []
	for t in _all_territories:
		if t.empire == null:
			grabs.append(t)
	
	# do sanity check
	if grabs.is_empty():
		return
		
	if selection.is_empty():
		push_error('no empires to distribute!')
		return
	
	# remove excess empires
	while selection.size() > grabs.size():
		selection.erase(selection.pick_random())
	
	# every empire gets at least one
	for empire in selection:
		empire.id = _all_empires.size()
		_all_empires.append(empire)
		var territory: Territory = grabs.pick_random()
		grabs.erase(territory)
		empire.territories.append(territory)
		empire.home_territory = territory
		territory.empire = empire
		
	# the rest will be distributed randomly
	for territory in grabs:
		var empire: Empire = selection.pick_random()
		empire.territories.append(territory)
		territory.empire = empire
		
	
func get_all_empires() -> Array[Empire]:
	return get_empires(true)
	
	
func get_empires(include_defeated := false) -> Array[Empire]:
	return _all_empires if include_defeated else _active_empires
	
	
func get_defeated_empires() -> Array[Empire]:
	return _defeated_empires
	
	
func get_empire_by_id(id: int) -> Empire:
	if id == -1:
		return null
	assert(id >= 0 and id < get_all_empires().size())
	return get_empires(true)[id]
	

func get_empire_by_leader(leader_name: String) -> Empire:
	for e in get_all_empires():
		if e.leader_name() == leader_name:
			return e
	return null
	

func player_empire() -> Empire:
	return _player_empire
	
	
func boss_empire() -> Empire:
	return _boss_empire
	
	
func get_territories() -> Array[Territory]:
	return _all_territories
	
	
func get_territory_by_id(id: int) -> Territory:
	if id == -1:
		return null
	assert(id >= 0 and id < get_territories().size())
	return get_territories()[id]
	
	
func get_territory_by_name(territory_name: String) -> Territory:
	for t in get_territories():
		if t.territory_name == territory_name:
			return t
	return null
