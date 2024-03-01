@tool
class_name TerritoryButton
extends Control


signal attack_pressed(button: TerritoryButton)
signal rest_pressed(button: TerritoryButton)
signal train_pressed(button: TerritoryButton)


## List of adjacent territories.
@export var adjacent: Array[TerritoryButton]

## List of maps to load.
@export var maps: Array[PackedScene]:
	set(value):
		maps = value
		update_configuration_warnings()

## Unit names. Count can be given by doing [code]name:count[/code].
@export var _unit_list: PackedStringArray

## Whether to connect this territory to the boss when it's spawned.
@export var connect_to_boss: bool

@export_group("Internal")

## The empire node.
@export var empire_node: EmpireNode

## Makes it so the button stays highlighteded.
var locked: bool

## Sets the button highlighteded state.
var highlighted: bool:
	set(value):
		highlighted = value
		if not is_node_ready():
			await ready
		scale = Vector2.ONE * 1.08 if highlighted else Vector2.ONE
		
var _territory: Territory
var _empire: Empire
var _adjacent_to_player: bool


## Group node containin the button connections.
@onready var connections = $Connections


func _ready() -> void:
	update_territory_name(name)
	update_configuration_warnings()

	renamed.connect(func(): update_territory_name(name))

	if not Engine.is_editor_hint():
		OverworldEvents.territory_owner_changed.connect(update_owner_empire)
		OverworldEvents.empire_adjacency_updated.connect(update_player_adjacent)
		OverworldEvents.empire_unit_list_updated.connect(update_avatars_present)
		OverworldEvents.empire_force_rating_updated.connect(update_force_strength)


## Returns the unit entries.
func get_unit_entries() -> Dictionary:
	assert(not Engine.is_editor_hint(), "can't use in editor")
	var arr := {}
	for u in _unit_list:
		var split := u.rsplit(':', true, 1)
		var unit_name := split[0].strip_edges()
		var unit_count := split[1].strip_edges().to_int() if split.size() > 1 else 1
		arr[unit_name] = unit_count
	return arr


## Initializes this button with territory.
func initialize(data: Dictionary) -> void:
	_territory = data.territory
	update_territory_name(_territory.name)
	update_owner_empire(_territory, null, data.empire)
	_adjacent_to_player = data.adjacent_to_player
	update_avatars_present(data.empire, data.empire_units)
	update_force_strength(data.empire, data.empire.force_rating)
	close_panel()

		
## Updates the territory name.
func update_territory_name(territory_name: String) -> void:
	Util.bb_big_caps(%NameLabel, territory_name, {font_size = 18})
	if name == territory_name:
		return
	name = territory_name


## Updates the empire.
func update_owner_empire(territory: Territory, _old_owner: Empire, new_owner: Empire) -> void:
	if territory != _territory:
		return
	_empire = new_owner
	%Portrait.texture = _empire.leader.portrait
	%HomeIcon.visible = _empire.home_territory == _territory


## Updates the adjacency.
@warning_ignore("shadowed_variable")
func update_player_adjacent(empire: Empire, adjacent: Array[Territory]) -> void:
	if empire.is_player_owned():
		_adjacent_to_player = _territory in adjacent


## Updates the avatars present.
func update_avatars_present(empire: Empire, units: Array[Unit]) -> void:
	if empire != _empire:
		return
		
	var hero_names := PackedStringArray()
	for unit in units:
		if unit.is_hero():
			hero_names.append(unit.display_name())

	if empire.is_player_owned():
		%AvatarsPresentLabel.text = 'Avatars Present: ' + ', '.join(hero_names)
	else:
		%EnemyLeadersLabel.text = 'Enemy Leaders: ' + ', '.join(hero_names)


## Updates the force strength.
func update_force_strength(empire: Empire, rating: float) -> void:
	if empire != _empire:
		return
	if _empire.is_player_owned():
		%PlayerForceStrengthLabel.text = '(stub)'
	else:
		if is_nan(rating):
			%EnemyForceStrengthLabel.text = 'Force Strength: N/A'
		else:
			var force_strength: String = 'Force Strength: %s' % _force_string(rating)
			if OS.is_debug_build():
				force_strength += ' (%s)' % snappedf(rating, 0.01)
			%EnemyForceStrengthLabel.text = force_strength


func _force_string(ratio: float) -> String:
	if ratio > 2:
		return 'Dangerous'
	if ratio >= 1.5:
		return 'Formidable'
	if ratio >= 1.2:
		return 'Strong'
	if ratio >= 0.8:
		return 'Moderate'
	if ratio >= 0.5:
		return 'Fair'
	return 'Weak'
	

## Opens the interactive panel.
func open_panel(show_attack_button: bool) -> void:
	%PlayerPanel.visible = _empire.is_player_owned()
	%EnemyPanel.visible = not _empire.is_player_owned()
	%AttackButton.visible = show_attack_button
	z_index = 1


## Opens the interactive panel.
func close_panel() -> void:
	%PlayerPanel.hide()
	%EnemyPanel.hide()
	z_index = 0
	
	
## Creates connections to buttons.
func create_connections(buttons: Array[TerritoryButton]) -> void:
	remove_connections()
	for btn in buttons:
		var conn := preload("res://scenes/overworld/connection.tscn").instantiate() as TerritoryConnection
		conn.point_a = global_position
		conn.point_b = btn.global_position
		connections.add_child(conn)
		
	
## Removes all connections.
func remove_connections() -> void:
	while connections.get_child_count() > 0:
		# not ideal but meh
		var child := connections.get_child(0)
		connections.remove_child(child)
		child.queue_free()
	

func _get_configuration_warnings() -> PackedStringArray:
	if maps.is_empty():
		return ['no maps assigned']
	return []
	

func _on_detector_mouse_entered() -> void:
	$Glow.visible = true
	$Connections.visible = true
	highlighted = true


func _on_detector_mouse_exited() -> void:
	$Glow.visible = false
	$Connections.visible = false
	if not locked:
		highlighted = false


func _on_detector_gui_input(_event) -> void:
	# TODO
	pass # Replace with function body.


func _on_detector_focus_entered() -> void:
	locked = true
	highlighted = true
	open_panel(_adjacent_to_player)


func _on_detector_focus_exited() -> void:
	locked = false
	# has to be done this way because pressing the button takes the
	# focus from the detector and if we close the panel during that
	# the button won't actually be pressed
	if not (%AttackButton.is_hovered() or %RestButton.is_hovered()):
		highlighted = false
		close_panel()


func _on_attack_button_pressed() -> void:
	close_panel()
	attack_pressed.emit(self)


func _on_rest_button_pressed() -> void:
	close_panel()
	rest_pressed.emit(self)