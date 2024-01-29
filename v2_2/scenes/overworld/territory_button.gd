class_name TerritoryButton
extends Control


@export var overworld: Overworld

var territory: Territory
var locked: bool

var highlight: bool:
	set(value):
		highlight = value
		if not is_node_ready():
			await ready
		scale = Vector2.ONE * 1.08 if highlight else Vector2.ONE
		

func _ready():
	_remove_null_territory()
	for child in get_children():
		if child is Territory:
			territory = child
	if not territory:
		territory = preload("res://scenes/overworld/null_territory.tscn").instantiate() as Territory
		territory.set_meta('NullTerritory', true)
		add_child(territory)
		push_error('"%s" (%s) using NullTerritory (not assigned)' % [name, self])
	funky_text($NameLabel, territory.name)
	_create_connections()
	_update_home_icon()
	overworld.territory_transfer_ownership.connect(_on_territory_transfer_ownership)


func _exit_tree():
	request_ready()
	# TODO if connections show funky duplicating behaviour, just remove them here
	_remove_null_territory()
	territory = null


func funky_text(label: RichTextLabel, text: String, caps_size := 24):
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


func _remove_null_territory():
	for child in get_children():
		if child.has_meta('NullTerritory'):
			child.queue_free()
	

func open_panel():
	if territory.is_player_owned():
		$PlayerPanel.visible = true
	else:
		$EnemyPanel.visible = true
		$EnemyPanel/AttackButton.visible = Game.player_empire().is_adjacent_territory(territory)


func close_panel():
	if territory.is_player_owned():
		$PlayerPanel.visible = false
	else:
		$EnemyPanel.visible = false
	
	
func _create_connections():
	for adj in territory.adjacent:
		var conn := preload("res://scenes/overworld/connection.tscn").instantiate() as TerritoryConnection
		conn.point_a = global_position
		conn.point_b = adj.get_parent().global_position
		$Connections.add_child(conn)
	
	
func _update_home_icon():
	$TextureRect.visible = territory.is_home_territory()
		
	
func _on_territory_transfer_ownership(_old_owner: Empire, new_owner: Empire, _territory: Territory):
	if _territory != territory:
		return
	_update_home_icon()
	

func _on_detector_mouse_entered():
	$Glow.visible = true
	$Connections.visible = true
	highlight = true


func _on_detector_mouse_exited():
	$Glow.visible = false
	$Connections.visible = false
	if not locked:
		highlight = false


func _on_detector_gui_input(event):
	pass # Replace with function body.


func _on_detector_focus_entered():
	highlight = true
	locked = true
	open_panel()


func _on_detector_focus_exited():
	highlight = false
	locked = false
	if not ($EnemyPanel/AttackButton.is_hovered() or $PlayerPanel/RestButton.is_hovered()):
		close_panel()


func _on_attack_button_pressed():
	print('attack')
	overworld.choose_action(Overworld.AttackAction.new(Game.player_empire(), territory.empire, territory))
	close_panel()


func _on_rest_button_pressed():
	print('rest')
	overworld.choose_action(Overworld.RestAction.new(Game.player_empire()))
	close_panel()

