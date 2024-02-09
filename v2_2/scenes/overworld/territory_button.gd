@tool
class_name TerritoryButton
extends Control

signal attack_pressed(button)
signal rest_pressed(button)
signal train_pressed(button)


@onready var connections = $Connections


var territory_node: TerritoryNode
var locked: bool
var highlight: bool:
	set(value):
		highlight = value
		if not is_node_ready():
			await ready
		scale = Vector2.ONE * 1.08 if highlight else Vector2.ONE
		

var _territory: Territory


func _ready():
	_remove_null_territory()
	for child in get_children():
		if child is TerritoryNode:
			territory_node = child
	if not territory_node:
		territory_node = preload("res://scenes/overworld/null_territory.tscn").instantiate() as TerritoryNode
		territory_node.set_meta('NullTerritory', true)
		add_child(territory_node)
		# this avoids pushing the error when it's the og scene in the editor
		if not Util.is_scene_root(self):
			push_error('"%s" (%s) using NullTerritory (not assigned)' % [name, self])
	update_territory_name(territory_node.name)


func _exit_tree():
	request_ready()
	# TODO if connections show funky duplicating behaviour, just remove them here
	_remove_null_territory()
	territory_node = null


func _remove_null_territory():
	for child in get_children():
		if child.has_meta('NullTerritory'):
			child.queue_free()
	
	
## Initializes this button with territory.
func initialize(t: Territory):
	_territory = t
	close_panel(t)
	create_connections()
	
	update_territory_name(t.name)
	var empire := Game.overworld.get_territory_owner(t)
	%Portrait.texture = empire.leader.portrait
	%HomeIcon.visible = empire.home_territory == t
	
	var heroes: Array[String] = []
	for u in empire.hero_units:
		heroes.append(u.display_name)
		if empire.is_player_owned():
			%AvatarsPresentLabel.text = 'Avatars Present: %s' % ', '.join(heroes)
		else:
			%EnemyLeadersLabel.text = 'Enemy Leaders: %s' % ', '.join(heroes)
				
	if empire.is_player_owned():
		%PlayerForceStrengthLabel.text = '(stub)'
	else:
		var force_strength: String = 'Force Strength: %s' % _force_string(_force_rating(empire))
		if OS.is_debug_build():
			force_strength += ' (%s)' % snappedf(_force_rating(empire), 0.01)
		%EnemyForceStrengthLabel.text = force_strength
		

func update_territory_name(territory_name: String):
	Util.bb_big_caps(%NameLabel, territory_name, {font_size = 18})
	

func _get_force_strength_old(e: Empire) -> String: # TODO update force strength
	var total_combined_maxhp := 0
	var total_combined_hp := 0
	for u in e.units:
		total_combined_maxhp += u.stats.maxhp
		total_combined_hp += u.stats.hp
		
	var hp_ratio := float(total_combined_hp)/total_combined_maxhp
	if hp_ratio >= 1:
		return 'Full'
	if hp_ratio >= 0.7:
		return 'Hurt'
	if hp_ratio >= 0.3:
		return 'Low'
	return 'Critical'
	
	
func _force_rating(e: Empire) -> float:
	var player_empire := Game.overworld.player_empire()
	var enemy_stats := _get_empire_combined_unit_stat(e, &'maxhp') + _get_empire_combined_unit_stat(e, &'dmg')
	var player_stats := _get_empire_combined_unit_stat(player_empire, &'maxhp') + _get_empire_combined_unit_stat(player_empire, &'dmg')
	return float(enemy_stats)/player_stats
	
	
func _force_string(rating: float) -> String:
	if rating > 2:
		return 'Dangerous'
	if rating >= 1.5:
		return 'Formidable'
	if rating >= 1.2:
		return 'Strong'
	if rating >= 0.8:
		return 'Moderate'
	if rating >= 0.5:
		return 'Fair'
	return 'Weak'
	
	
func _get_empire_combined_unit_stat(e: Empire, stat: StringName) -> int:
	if e.units.size() == 0:
		return 0
	return e.units.map(func(u): return u.stats[stat]).reduce(func(a, b): return a + b)
	
	
func open_panel(t: Territory):
	var player := Game.overworld.get_territory_owner(t).is_player_owned()
	%PlayerPanel.visible = player
	%EnemyPanel.visible = not player
	%AttackButton.visible = Game.overworld.player_empire().is_adjacent_territory(t)
	z_index = 1
	

func close_panel(_t: Territory):
	%PlayerPanel.hide()
	%EnemyPanel.hide()
	z_index = 0
	
	
func create_connections():
	remove_connections()
	for adj in territory_node.adjacent:
		var conn := preload("res://scenes/overworld/connection.tscn").instantiate() as TerritoryConnection
		conn.point_a = global_position
		conn.point_b = adj.get_parent().global_position
		connections.add_child(conn)
		
	
func remove_connections():
	while connections.get_child_count() > 0:
		# not ideal but meh
		var child := connections.get_child(0)
		connections.remove_child(child)
		child.queue_free()
	

func _on_detector_mouse_entered():
	$Glow.visible = true
	$Connections.visible = true
	highlight = true


func _on_detector_mouse_exited():
	$Glow.visible = false
	$Connections.visible = false
	if not locked:
		highlight = false


func _on_detector_gui_input(_event):
	# TODO
	pass # Replace with function body.


func _on_detector_focus_entered():
	locked = true
	highlight = true
	open_panel(_territory)


func _on_detector_focus_exited():
	locked = false
	# has to be done this way because pressing the button takes the
	# focus from the detector and if we close the panel during that
	# the button won't actually be pressed
	if not (%AttackButton.is_hovered() or %RestButton.is_hovered()):
		highlight = false
		close_panel(_territory)


func _on_attack_button_pressed():
	close_panel(_territory)
	attack_pressed.emit(self)


func _on_rest_button_pressed():
	close_panel(_territory)
	rest_pressed.emit(self)

