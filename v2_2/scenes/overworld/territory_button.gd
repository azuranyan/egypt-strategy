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
		

var _context: OverworldContext
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
	set_territory_name(territory_node.name)


func _exit_tree():
	request_ready()
	# TODO if connections show funky duplicating behaviour, just remove them here
	_remove_null_territory()
	territory_node = null


func _remove_null_territory():
	for child in get_children():
		if child.has_meta('NullTerritory'):
			child.queue_free()
	

## Returns the territory this node refers to.
func get_territory(ctx: OverworldContext) -> Territory:
	if _context:
		return _territory
	return territory_node.get_territory(ctx)
	
	
## Initializes this button with territory.
func initialize(ctx: OverworldContext, t: Territory):
	_context = ctx
	_territory = t
	close_panel(t)
	create_connections()
	set_territory_name(t.name)
	%Portrait.texture = ctx.get_territory_owner(t).leader.portrait
	%HomeIcon.visible = _is_home_territory(t)
	
	var heroes: Array[String] = []
	for u in _context.get_territory_owner(t).units:
		if not (_context.is_hero_unit(u) and u.display_name not in heroes):
			continue
		if _context.get_territory_owner(t).is_player_owned():
			heroes.append(u.display_name)
			%AvatarsPresentLabel.text = 'Avatars Present: %s' % ','.join(heroes)
		else:
			heroes.append(u.display_name)
			%EnemyLeadersLabel.text = 'Enemy Leaders: %s' % ','.join(heroes)
				
	var force_strength := 'Force Strength: %s' % _get_force_strength(ctx.get_territory_owner(t))
	%EnemyForceStrengthLabel.text = force_strength
	%PlayerForceStrengthLabel.text = force_strength


func set_territory_name(territory_name: String):
	_funky_text(%NameLabel, territory_name, 26)


# TODO put this function somewhere else
func _funky_text(label: RichTextLabel, text: String, caps_size := 26):
	label.clear()
	label.text = ''
	label.append_text('[center]')
	var caps: Array[String] = []
	var insert_caps := func():
		if not caps.is_empty():
			label.push_font_size(caps_size)
			for c in caps:
				label.append_text(c)
			label.pop()
			caps.clear()
			
	for c in text:
		var upper := c.to_upper()
		if c == upper:
			caps.append(upper)
		else:
			insert_caps.call()
			label.append_text(upper)
	insert_caps.call()
	#label.append_text('[/center]')
	

func _is_home_territory(t: Territory) -> bool:
	for e in _context.empires:
		if e.home_territory == t:
			return not e.is_defeated()
	return false
	
	
func _get_force_strength(e: Empire) -> String: # TODO update force strength
	if e.hp_multiplier >= 1:
		return 'Full'
	if e.hp_multiplier >= 0.7:
		return 'Hurt'
	if e.hp_multiplier >= 0.3:
		return 'Low'
	return 'Critical'
	
	
func open_panel(t: Territory):
	var player := _context.get_territory_owner(t).is_player_owned()
	%PlayerPanel.visible = player
	%EnemyPanel.visible = not player
	%AttackButton.visible = _context.player_empire.is_adjacent_territory(t)
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

