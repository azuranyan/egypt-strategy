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

## Group node containing the button connections.
@onready var connections: Node2D = $Connections

@onready var name_label: RichTextLabel = %NameLabel
@onready var home_icon: TextureRect = %HomeIcon
@onready var portrait_button: TextureButton = %PortraitButton
@onready var glow: TextureRect = %Glow

@onready var extended_panel: Control = %ExtendedPanel
@onready var heroes_label: Label = %HeroesLabel
@onready var force_strength_label: Label = %ForceStrengthLabel
@onready var attack_button: Button = %AttackButton
@onready var train_button: Button = %TrainButton
@onready var rest_button: Button = %RestButton

@onready var _original_index: int = get_index()


func _ready() -> void:
	extended_panel.visible = extended_panel.visible and not Engine.is_editor_hint()
	update_territory_name(name)
	update_configuration_warnings()

	if Engine.is_editor_hint():
		return

	renamed.connect(func(): update_territory_name(name))

	OverworldEvents.territory_owner_changed.connect(update_owner_empire)
	OverworldEvents.empire_adjacency_updated.connect(update_player_adjacent)
	OverworldEvents.empire_unit_list_updated.connect(update_avatars_present)
	OverworldEvents.empire_force_rating_updated.connect(update_force_strength)

	portrait_button.mouse_entered.connect(func():
		glow.visible = true
		connections.visible = true
		highlighted = true
	)

	portrait_button.mouse_exited.connect(func():
		glow.visible = false
		connections.visible = false
		if not locked:
			highlighted = false
	)

	portrait_button.toggled.connect(func(toggled: bool):
		locked = toggled
		highlighted = toggled
		if toggled:
			open_panel(_adjacent_to_player)
		else:
			close_panel()
	)

	# portrait_button.focus_entered.connect(func():
	# 	locked = true
	# 	highlighted = true
	# 	open_panel(_adjacent_to_player)
	# )

	# portrait_button.focus_exited.connect(func():
	# 	locked = false
	# 	# has to be done this way because pressing the button takes the
	# 	# focus from the detector and if we close the panel during that
	# 	# the button won't actually be pressed. i've yet to come up with
	# 	# a solution for this, prob better to have toggle and button groups
	# 	if not (attack_button.is_hovered() or train_button.is_hovered() or rest_button.is_hovered()):
	# 		highlighted = false
	# 		close_panel()
	# )

	attack_button.pressed.connect(_on_attack_button_pressed)
	train_button.pressed.connect(_on_train_button_pressed)
	rest_button.pressed.connect(_on_rest_button_pressed)


func _exit_tree() -> void:
	# request_ready() when using tool script so the initial part of the setup gets ran
	if Engine.is_editor_hint():
		request_ready()


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
	Util.bb_big_caps(name_label, territory_name, {font_size = 22, font = preload("res://scenes/data/fonts/Rakkas-Regular.ttf")})
	if name == territory_name:
		return
	name = territory_name


## Updates the empire.
func update_owner_empire(territory: Territory, _old_owner: Empire, new_owner: Empire) -> void:
	if territory != _territory:
		return
	_empire = new_owner

	# update portrait texture
	portrait_button.texture_normal = _empire.leader.portrait
	portrait_button.texture_pressed = _empire.leader.portrait
	portrait_button.texture_hover = _empire.leader.portrait

	# update texture mask
	var mask := BitMap.new()
	mask.create_from_image_alpha(_empire.leader.portrait.get_image())
	portrait_button.texture_click_mask = mask
	
	home_icon.visible = _empire.home_territory == _territory
	%HomeIconGhost.visible = home_icon.visible


## Updates the adjacency.
@warning_ignore("shadowed_variable")
func update_player_adjacent(empire: Empire, adjacent: Array[Territory]) -> void:
	if empire.is_player_owned():
		_adjacent_to_player = _territory in adjacent


## Updates the avatars present.
func update_avatars_present(empire: Empire, units: Array[Unit]) -> void:
	if empire != _empire:
		return
	
	# find all hero names
	var hero_names := PackedStringArray()
	for unit in units:
		if unit.is_hero():
			hero_names.append(unit.display_name())

	# update label
	if empire.is_player_owned():
		heroes_label.text = 'Avatars Present: ' + ', '.join(hero_names)
	else:
		heroes_label.text = 'Enemy Leaders: ' + ', '.join(hero_names)


## Updates the force strength.
func update_force_strength(empire: Empire, rating: float) -> void:
	if empire != _empire:
		return

	force_strength_label.visible = _empire.is_player_owned()

	if _empire.is_player_owned():
		force_strength_label.text = '(stub)'
	else:
		if is_nan(rating):
			force_strength_label.text = 'Force Strength: N/A'
		else:
			var force_strength: String = 'Force Strength: %s' % _force_string(rating)
			if OS.is_debug_build():
				force_strength += ' (%s)' % snappedf(rating, 0.01)
			force_strength_label.text = force_strength
		force_strength_label.show()


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
	extended_panel.show()
	attack_button.visible = show_attack_button
	train_button.visible = show_attack_button
	rest_button.visible = not show_attack_button and _empire.is_player_owned()
	get_parent().move_child(self, -1)
	z_index = 2


## Opens the interactive panel.
func close_panel() -> void:
	extended_panel.hide()
	get_parent().move_child(self, _original_index)
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
	

func _on_attack_button_pressed() -> void:
	close_panel()
	attack_pressed.emit(self)


func _on_rest_button_pressed() -> void:
	close_panel()
	rest_pressed.emit(self)


func _on_train_button_pressed() -> void:
	close_panel()
	train_pressed.emit(self)
