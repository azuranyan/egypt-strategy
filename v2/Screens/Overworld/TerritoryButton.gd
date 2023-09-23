@tool
extends Node2D 

class_name TerritoryButton

signal territory_changed


var stored_z_index: int

var territory: Territory:
	set(value):
		territory = value
		territory_changed.emit()
		

@onready var highlight := $ColorRect
@onready var label := $Label


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if territory == null:
		warnings.append("Missing Territory child")
	
	return warnings


func _ready():
	# this has to be here and cannot be connected through inspector. we only
	territory_changed.connect(_on_territory_changed)
	territory = territory
	
	# you can't do this here because we're initialized first before overworld
	# there should be a messagebus object or node that gets initialized before
	# everything else that gets loaded first
	# TODO we really shouldn't be messing with sibling nodes like this, so
	# maybe we can put the messagebus somewhere else
	OverworldEvents.connect("territory_owner_changed", _on_owner_change)
	
	OverworldEvents.connect("cycle_turn_start", _on_cycle_turn_start)
	
	OverworldEvents.connect("cycle_turn_end", _on_cycle_turn_end)


func show_extended_enemy_panel(show_attack: bool):
	# no need to do hide the other panel, it's only there for formality
	$ExtendedEnemyPanel.show()
	$ExtendedPlayerPanel.hide() 
	if show_attack:
		$ExtendedEnemyPanel/Background1.hide()
		$ExtendedEnemyPanel/Background2.show()
		$ExtendedEnemyPanel/AttackButton.show()
	else:
		$ExtendedEnemyPanel/Background1.show()
		$ExtendedEnemyPanel/Background2.hide()
		$ExtendedEnemyPanel/AttackButton.hide()
		
	if territory.is_home_territory():
		$ExtendedEnemyPanel/Home.show()
	else:
		$ExtendedEnemyPanel/Home.hide()


func show_extended_player_panel():
	# no need to do hide the other panel, it's only there for formality
	$ExtendedEnemyPanel.hide()
	$ExtendedPlayerPanel.show()
	
	
func hide_extended_panel():
	$ExtendedPlayerPanel.hide()
	$ExtendedEnemyPanel.hide()


func _on_owner_change(_old_owner: Empire, _new_owner: Empire, _territory: Territory):
	# all the buttons are subscribed to the event so we first check if it's ours
	if territory == _territory:
		_update_territory_owner()
		
		
func _on_cycle_turn_start(empire: Empire):
	if empire == territory.empire:
		highlight.show()
	else:
		highlight.hide()
	
	
func _on_cycle_turn_end(_empire: Empire):
	# hides all panels
	hide_extended_panel()
	
	
func _on_texture_button_toggled(button_pressed):
	if button_pressed:
		# raise z so it is over all other buttons
		self.z_index += 1
		if territory.is_player_owned():
			show_extended_player_panel()
		else:
			var adjacent: bool = Globals.empires["Lysandra"].is_territory_adjacent(self.territory)
			show_extended_enemy_panel(adjacent)
	else:
		self.z_index -= 1
		hide_extended_panel()
		
		
func _on_attack_button_pressed():
	$TextureButton.button_pressed = false
	
	# this button should appear only for player and therefore is
	# always the player empire triggering this
	OverworldEvents.emit_signal("empire_attack", Globals.empires["Lysandra"], territory)
	OverworldEvents.emit_signal("cycle_turn_end", Globals.empires["Lysandra"])


func _on_inspect_button_pressed():
	OverworldEvents.emit_signal("inspect")


func _on_rest_button_pressed():
	OverworldEvents.emit_signal("rest")


func _on_train_button_pressed():
	OverworldEvents.emit_signal("train")
	

func _on_child_entered_tree(node: Node):
	# we only connect if territory is null
	if node is Territory and territory == null:
		node.renamed.connect(_update_territory_name)
		territory = node


func _on_child_exiting_tree(node: Node):
	# we only disconnect if it is the territory
	if territory == node:
		node.renamed.disconnect(_update_territory_name)
		territory = null
		

func _on_territory_changed():
	_update_territory_name()
	_update_territory_owner()


func _update_territory_name():
	if territory:
		label.text = territory.name
	else:
		label.text = ""


func _get_button_texture(chara: Chara) -> Texture2D:
	if chara:
		return load("res://Screens/Overworld/ButtonImage/%s.png" % chara.name)
	else:
		return preload("res://Screens/Overworld/ButtonImage/Base.png")
		
		
func _update_territory_owner():
	if territory:
		var texture := _get_button_texture(territory.get_leader())
		
		$TextureButton.texture_normal = texture
		
		var mask := BitMap.new()
		mask.create_from_image_alpha(texture.get_image())
		$TextureButton.texture_click_mask = mask
		
		if territory.is_player_owned():
			pass
		else:
			$ExtendedEnemyPanel/LeaderLabel.text = "Enemy Leader: %s" % territory.get_leader()
			$ExtendedEnemyPanel/ForceLabel.text = "Force Strength: %s" % territory.get_force_strength()
	else:
		$TextureButton.texture_normal = null
		$TextureButton.texture_click_mask = null
		$ExtendedEnemyPanel/LeaderLabel.text = "Enemy Leader: None"
		$ExtendedEnemyPanel/ForceLabel.text = "Force Strength: None"
		
