extends Node

const battle_ui_scene = preload("res://src/ui/BattleUI.tscn")

signal actor_deployed

enum TurnType {
	ALLY,
	ENEMY,
}

var actors: Array
var allies: Array
var enemies: Array

var ally_team_size: int
var enemy_team_size: int

var current_turn: int = 0
var current_ally_turn: int = 1
var current_enemy_turn: int = 1
var turn_type: int = TurnType.ALLY

var current_actor: Actor
var current_actor_moved: bool

var battle_started: bool = false 
var animating: bool = false # Set while moving the camera and actors
var selecting_target: bool = false # Set while selecting a tile or enemy

onready var grid: Grid = get_node("Grid") as Grid
# warning-ignore:integer_division
# warning-ignore:integer_division
onready var central_tile: Tile = grid.tile_at(Globals.GRID_DIM / 2 - 1, Globals.GRID_DIM / 2 - 1)
onready var hud = $Label
onready var camera: Camera2D = get_node("Camera2D") as Camera2D
onready var battle_indicator = get_node("BattleIndicator")
onready var battle_ui: BattleUI = battle_ui_scene.instance()



func _input(event: InputEvent) -> void:
	if not battle_started or animating or selecting_target or turn_type == TurnType.ENEMY or not current_actor:
		return
	
	if current_actor.already_moved:
		return
	
	if event is InputEventKey:
		match event.scancode:
			KEY_SPACE:
				if not battle_ui.spacebar.visible:
					return
				
				var next_actor: Actor = get_next_actor()
				
				if not next_actor:
					return
				
				current_actor = next_actor
				battle_ui.hide()
				update_turn_hud()
				yield(update_camera(), "completed")
				battle_ui.show()
				current_actor.start_turn()


func _on_actor_turn_ended(actor: Actor) -> void:
	if is_battle_over():
		end_battle()
		return
	
	if actor.is_in_group("ally"):
		current_ally_turn += 1
		
		if current_ally_turn > ally_team_size:
			start_enemy_turn()
		else:
			current_actor = get_next_actor()
	else:
		current_enemy_turn += 1
		
		if current_enemy_turn > enemy_team_size:
			start_ally_turn()
		else:
			current_actor = get_next_actor()
	
	next_turn()


func _on_actor_dead(actor: Actor) -> void:
	remove_actor(actor)


# Used by allies
func _on_actor_clicked(actor: Actor) -> void:
	if animating:
		return
	
	if current_actor.can_attack_actor(actor):
		for a in actors:
			a.unlight()
		
		battle_ui.hide()
		current_actor.attack(actor)
		get_tree().set_group("actor", "selectable", false)


# Used by enemies
func _on_actor_attacked(grid_pos_x: int, grid_pos_y: int) -> void:
	while animating:
		yield(get_tree(), "idle_frame")
	
	var actor: Actor
	
	for a in actors:
		if a.current_tile.grid_position == Vector2(grid_pos_x, grid_pos_y):
			actor = a
	
	current_actor.attack(actor)


func _on_actor_move_done() -> void:
	yield(update_camera(), "completed")
	
	if current_actor.is_in_group("enemy"):
		return
	
	selecting_target = false
	battle_ui.show_options()
	battle_ui.show()
	battle_ui.move_button.disabled = true
	battle_ui.undo_button.disabled = false


func remove_actor(actor: Actor) -> void:
	actors.erase(actor)
	
	if actor.is_in_group("ally"):
		allies.erase(actor)
		ally_team_size -= 1
	else:
		enemies.erase(actor)
		enemy_team_size -= 1
	
	# Later will be set to a 'dead' state or smth instead of freeing memory (reviving?)
	actor.queue_free()


func _on_tile_selected(tile: Tile) -> void:
	if not battle_started:
		if tile.type == Tile.TileFlags.PASSABLE and not tile.occupied:
			emit_signal("actor_deployed", tile.grid_position)
		else:
			tile.deselect()
		
		return
	
	if animating:
		return
	
	if current_actor.can_move_to_tile(tile):
		battle_ui.hide()
		get_tree().set_group("tile", "selectable", false)
		get_tree().call_group("tile", "unlight")
		current_actor.move_to_tile(tile)
		battle_indicator.hide()
	else:
		tile.deselect()


func _on_move_button_pressed() -> void:
	if not turn_type == TurnType.ALLY:
		return
	
	selecting_target = true
	battle_ui.hide_options()
	battle_ui.spacebar.hide()
	get_tree().set_group("tile", "selectable", true)
	highlight_neighbors()


func _on_attack_button_pressed() -> void:
	if not turn_type == TurnType.ALLY:
		return
	
	selecting_target = true
	battle_ui.hide_options()
	battle_ui.undo_button.disabled = true
	battle_ui.spacebar.hide()
	get_tree().set_group("actor", "selectable", true)
	
	for actor in actors:
		if current_actor.can_attack_actor(actor):
			actor.highlight()


func _on_wait_button_pressed() -> void:
	if not turn_type == TurnType.ALLY:
		return
	
	battle_ui.hide()
	battle_ui.spacebar.hide()
	current_actor.rest()


func _on_undo_button_pressed() -> void:
	if not turn_type == TurnType.ALLY:
		return
	
	current_actor.undo_move()
	battle_ui.hide()
	yield(update_camera(), "completed")
	battle_ui.undo_button.disabled = true
	battle_ui.move_button.disabled = false
	battle_ui.show()
	
	if current_ally_turn < ally_team_size:
		battle_ui.spacebar.show()


func _on_cancel_button_pressed() -> void:
	selecting_target = false
	get_tree().set_group("tile", "selectable", false)
	get_tree().set_group("actor", "selectable", false)
	unlight_neighbors()
	battle_ui.show_options()
	
	for a in actors:
		a.unlight()
	
	if current_actor.already_moved:
		battle_ui.undo_button.disabled = false
	else:
		if current_ally_turn < ally_team_size:
			battle_ui.spacebar.show()


func get_next_actor() -> Actor:
	var next_actor: Actor
	var current_team: Array
	
	if turn_type == TurnType.ALLY:
		current_team = allies
	else:
		current_team = enemies
	
	for actor in current_team:
		if actor == current_actor:
			continue
		
		if not actor.already_moved:
			next_actor = actor
			return next_actor
	
	return current_actor


func next_turn() -> void:
	if not battle_started:
		return
	
	if is_battle_over():
		end_battle()
		return
	
	current_turn += 1
	update_turn_hud()
	yield(update_camera(), "completed")
	selecting_target = false
	
	if turn_type == TurnType.ALLY:
		battle_ui.move_button.disabled = false
		battle_ui.undo_button.disabled = true
		battle_ui.show_options()
		battle_ui.show()
		
		if current_ally_turn < ally_team_size:
			battle_ui.spacebar.show()
	
	current_actor.start_turn()


func start_ally_turn() -> void:
	current_ally_turn = 1
	current_actor = allies[0] as Actor
	turn_type = TurnType.ALLY
	
	for ally in allies:
		ally.prepare()


func start_enemy_turn() -> void:
	current_enemy_turn = 1
	current_actor = enemies[0] as Actor
	turn_type = TurnType.ENEMY
	
	for enemy in enemies:
		enemy.prepare()

func update_turn_hud() -> void:
	hud.text = "Ally turn: " + str(current_ally_turn) 
	hud.text += "\nEnemy turn: " + str(current_enemy_turn)
	hud.text += "\nCurrent turn: " + str(current_turn)
	hud.text += "\nCurrent actor: " + str(current_actor.name)


func update_camera() -> void:
	animating = true
	
	if current_actor:
		battle_indicator.show()
		battle_indicator.stop_tween()
		battle_indicator.global_position = current_actor.global_position
		battle_indicator.tween.resume_all()
		battle_indicator.start_tween()
		camera.hover_above(lerp(central_tile.global_position + Vector2.UP * 100, current_actor.global_position, 0.2))
	else:
		camera.hover_above(central_tile.global_position + Vector2.UP * 100)
	
	yield(camera.tween, "tween_all_completed")
	animating = false


func is_battle_over() -> bool:
	return is_won() or is_lost()


func is_won() -> bool:
	return enemy_team_size == 0


func is_lost() -> bool:
	return ally_team_size == 0


func start_battle(joining_actors: Array) -> void:
	actors = joining_actors
	var actor: Actor
	
	yield(update_camera(), "completed")
	
	for tile in get_tree().get_nodes_in_group("tile"):
		tile.connect("selected", self, "_on_tile_selected", [tile])
		tile.selectable = true
	
	for a in actors:
		actor = a
		var actor_position: Vector2
		
		if actor.is_in_group("ally"):
			actor_position = yield(self, "actor_deployed")
			grid.tile_at_pos(actor_position).selectable = false
			ally_team_size += 1
			allies.push_back(actor)
		else:
			actor_position = actor.start_position
			enemy_team_size += 1
			enemies.push_back(actor)
		
		grid.add_child(actor)
		actor.place_at_pos(actor_position)
		
		actor.connect("turn_ended", self, "_on_actor_turn_ended", [actor])
		actor.connect("clicked", self, "_on_actor_clicked", [actor])
		actor.connect("attacked", self, "_on_actor_attacked")
		actor.connect("move_done", self, "_on_actor_move_done")
		actor.connect("dead", self, "_on_actor_dead", [actor])
	
	get_tree().set_group("tile", "selectable", false)
	get_tree().call_group("tile", "unlight")
	
	current_actor = allies[0] as Actor
	turn_type = TurnType.ALLY
	battle_indicator.show()
	battle_started = true
	
	get_tree().call_group("game", "add_ui", hud)
	get_tree().call_group("game", "add_ui", battle_ui)
	yield(battle_ui, "ready")
	
	battle_ui.move_button.connect("pressed", self, "_on_move_button_pressed")
	battle_ui.attack_button.connect("pressed", self, "_on_attack_button_pressed")
	battle_ui.wait_button.connect("pressed", self, "_on_wait_button_pressed")
	battle_ui.undo_button.connect("pressed", self, "_on_undo_button_pressed")
	battle_ui.cancel_button.connect("pressed", self, "_on_cancel_button_pressed")
	
	next_turn()


func end_battle() -> void:
	current_actor = null
	battle_ui.hide()
	battle_indicator.hide()
	hud.rect_global_position = OS.window_size * 0.5
	hud.text = "Won" if is_won() else "Lost"
	battle_started = false


func highlight_neighbors() -> void:
	for tile in current_actor.get_reachable_tiles():
		tile.highlight()


func unlight_neighbors() -> void:
	for tile in current_actor.get_reachable_tiles():
		tile.unlight()
