class_name Actor
extends Node2D

signal clicked
signal turn_ended
signal move_done
signal attacked(grid_pos_x, grid_pos_y)
signal dead

enum AnimStates {
	IDLE, 
	ATTACK,
	WALK,
}


export(int) var _mov: int
export(float) var _hp: float 
export(int) var _rng: int
export(float) var _dmg: float
export(int) var _bnd: int

onready var mov: int =  _mov
onready var hp: float = _hp setget set_hp
onready var rng: int = _rng
onready var dmg: float = _dmg
onready var bnd: int = _bnd

export(Vector2) var start_position: Vector2
export(bool) var ai_controlled: bool

var grid: Grid
var current_tile: Tile
var previous_tile: Tile
var passing_through: bool
var selectable: bool
var already_moved: bool
var face_dir: String
var poison_turn_count: int 
var already_poisoned: bool 

var poison: bool
var stun: bool
var dead: bool

onready var tween: Tween = get_node("Tween") as Tween
onready var sprite: AnimatedSprite = get_node("Sprite") as AnimatedSprite
onready var vfx: AnimatedSprite = get_node("VFX") as AnimatedSprite
onready var base_modulate: Color = sprite.self_modulate as Color

#TEMP
onready var name_label: Label = get_node("HUD/NameLabel")
onready var hp_label: Label = get_node("HUD/HPLabel")
onready var hp_bar: ProgressBar = get_node("HUD/HPBar")



func _ready() -> void:
	name_label.show_on_top = true
	name_label.text = name
	
	hp_label.show_on_top = true
	hp_label.text = str(hp)


func _on_Area2D_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (selectable 
	and event is InputEventMouseButton 
	and event.is_pressed()
	and event.button_index == BUTTON_LEFT):
		emit_signal("clicked")


func highlight() -> void:
	sprite.self_modulate = Color.blue


func unlight() -> void:
	sprite.self_modulate = base_modulate


func set_hp(value: float) -> void:
	if value <= 0.0:
		die()
		hp = 0.0
	elif value > _hp:
		hp = _hp
	else:
		hp = value
	
	hp_label.text = str(hp)
	hp_bar.value = hp * 100 / _hp


func die() -> void:
	leave_current_tile()
	dead = true
	emit_signal("dead")


func place_at(pos_x: int, pos_y: int) -> void:
	occupy_tile(grid.tile_at(pos_x, pos_y))


func place_at_pos(pos: Vector2) -> void:
	place_at(pos.x, pos.y)


func place_at_tile(tile: Tile) -> void:
	place_at_pos(tile.grid_position)


func get_moves_to(goal_x: int, goal_y: int) -> Array:
	var prev_x: int = current_tile.grid_position.x
	var prev_y: int = current_tile.grid_position.y
	var x_moves: PoolIntArray
	var y_moves: PoolIntArray
	
	x_moves = range(min(goal_x, prev_x), max(goal_x, prev_x))
	x_moves.append(max(goal_x, prev_x))
	
	if goal_x < prev_x:
		x_moves.invert()
	
	y_moves = range(min(goal_y, prev_y), max(goal_y, prev_y))
	y_moves.append(max(goal_y, prev_y))
	
	if goal_y < prev_y:
		y_moves.invert()
	
	return [x_moves, y_moves]


func get_moves_to_pos(grid_pos: Vector2) -> Array:
	return get_moves_to(grid_pos.x, grid_pos.y)


func get_moves_to_tile(tile: Tile) -> Array:
	return get_moves_to_pos(tile.grid_position)


func can_move_by(moves: Array) -> bool:
	var goal_tile: Tile = grid.tile_at(moves[0][moves[0].size() - 1], moves[1][moves[1].size() - 1])
	
	var x_moves: PoolIntArray = moves[0]
	var y_moves: PoolIntArray = moves[1]
	x_moves.remove(0)
	y_moves.remove(0)
	
	if not (x_moves.size() or y_moves.size()):
		return false
	
	if grid.get_distance_between_tiles(current_tile, goal_tile) > mov or goal_tile.occupied:
		return false
	
	var tile: Tile
	
	for i in x_moves:
		tile = grid.tile_at(i, current_tile.grid_position.y)
		
		if not can_pass_tile(tile):
			return false
	
	for j in y_moves:
		tile = grid.tile_at(goal_tile.grid_position.x, j)
		
		if not can_pass_tile(tile):
			return false
	
	return true 


func can_move_to(goal_x: int, goal_y: int) -> bool:
	return can_move_by(get_moves_to(goal_x, goal_y))


func can_move_to_pos(grid_pos: Vector2) -> bool:
	return can_move_to(grid_pos.x, grid_pos.y)


func can_move_to_tile(tile: Tile) -> bool:
	return can_move_to_pos(tile.grid_position)


func can_pass_tile(tile: Tile) -> bool:
	return tile.type == Tile.TileFlags.PASSABLE and (not tile.occupied or tile.team == current_tile.team)


func can_pass_tile_at(grid_pos_x: int, grid_pos_y: int) -> bool:
	return can_pass_tile(grid.tile_at(grid_pos_x, grid_pos_y))


func can_pass_tile_at_pos(grid_pos: Vector2) -> bool:
	return can_pass_tile(grid.tile_at_pos(grid_pos))


func move_by(moves: Array) -> void:
	var x_moves: PoolIntArray = moves[0]
	var y_moves: PoolIntArray = moves[1]
	x_moves.remove(0)
	y_moves.remove(0)
	
	previous_tile = current_tile
	
	for i in x_moves:
		var tile: Tile = grid.tile_at(i, current_tile.grid_position.y)
		animate(AnimStates.WALK, tile.grid_position)
		yield(occupy_tile(tile, true), "completed")
	
	for j in y_moves:
		var tile: Tile = grid.tile_at(current_tile.grid_position.x, j)
		animate(AnimStates.WALK, tile.grid_position)
		yield(occupy_tile(tile, true), "completed")
	
	current_tile.deselect()
	animate(AnimStates.IDLE, current_tile.grid_position)
	
	already_moved = true
	emit_signal("move_done")


func move_to(goal_x: int, goal_y: int) -> void:
	move_by(get_moves_to(goal_x, goal_y))


func move_to_pos(grid_pos: Vector2) -> void:
	move_to(grid_pos.x, grid_pos.y)


func move_to_tile(tile: Tile) -> void:
	move_to_pos(tile.grid_position)


func undo_move() -> void:
	occupy_tile(previous_tile)
	already_moved = false


func get_reachable_tiles() -> Array:
	var tiles: Array = []
	var pos: Vector2 = current_tile.grid_position
	
	for i in range(- mov, mov + 1):
		for j in range(-mov, mov + 1):
			var tile_pos: Vector2 = Vector2(pos.x + i, pos.y + j)
			
			if not grid.has_tile_at_pos(tile_pos):
				continue
			
			var tile: Tile = grid.tile_at(pos.x + i, pos.y + j)
			
			if tile == current_tile or not can_move_to_tile(tile):
				continue
			
			tiles.push_back(tile)
	
	return tiles


func start_turn() -> void:
	prepare()
	
	if poison and not already_poisoned:
		vfx.play("poison")
		yield(vfx, "animation_finished")
		vfx.play("default")
		poison_turn_count += 1
		already_poisoned = true
		
		if poison_turn_count == 2:
			poison_turn_count = 0
			poison = false
		
		self.hp -= 1.0
	
	if dead:
		end_turn()
		return
	
	if stun:
		vfx.play("stun")
		yield(vfx, "animation_finished")
		vfx.play("default")
		stun = false
		end_turn()
		return
	
	yield(get_tree(), "idle_frame")
	
	if ai_controlled:
		auto()


func end_turn() -> void:
	already_poisoned = false
	emit_signal("turn_ended")


func prepare() -> void:
	already_moved = false
	previous_tile = null


func rest() -> void:
	if not already_moved:
		self.hp += 1.0
	
	end_turn()


func occupy_tile(tile: Tile, smooth: bool = false) -> void:
	leave_current_tile()
	
	current_tile = tile
	
	if current_tile.occupied:
		passing_through = true
	else:
		current_tile.occupied = true
	
	if is_in_group("ally"):
		current_tile.team = Tile.TileTeam.ALLY
	else:
		current_tile.team = Tile.TileTeam.ENEMY
	
	z_index = current_tile.z_index
	
	if smooth:
		tween.interpolate_property(self, "global_position", null, current_tile.global_position, .5)
		tween.start()
		yield(tween, "tween_all_completed")
		tween.remove_all()
	else:
		global_position = current_tile.global_position


func leave_current_tile() -> void:
	if current_tile:
		if passing_through:
			passing_through = false
			return
		
		current_tile.occupied = false
		current_tile.team = Tile.TileTeam.FREE


func can_attack_at(grid_pos_x: int, grid_pos_y: int) -> bool:
	var tile: Tile = grid.tile_at(grid_pos_x, grid_pos_y)
	
	return tile != current_tile\
	and tile.occupied\
	and tile.team != current_tile.team\
	and grid.get_distance(current_tile.grid_position.x, current_tile.grid_position.y, grid_pos_x, grid_pos_y) <= rng


func can_attack_actor(actor: Actor) -> bool:
	return can_attack_at(actor.current_tile.grid_position.x, actor.current_tile.grid_position.y)


func attack(actor: Actor) -> void:
	already_moved = true
	
	animate(AnimStates.ATTACK, actor.current_tile.grid_position)
	yield(actor.receive_damage(dmg), "completed")
	animate(AnimStates.IDLE, actor.current_tile.grid_position)
	
	if not (actor.dead or actor.poison):
		randomize()
		
		if randi() % 100 < 30:
			actor.poison = true
			actor.vfx.play("poison")
			yield(actor.vfx, "animation_finished")
			actor.vfx.play("default")
	
	end_turn()


func receive_damage(damage: float) -> void:
	var prev_mod = sprite.self_modulate
	sprite.self_modulate = Color.magenta
	vfx.play("damage")
	yield(vfx, "animation_finished")
	sprite.self_modulate = prev_mod
	vfx.play("default")
	print(name + " was attacked. Damage: " + str(damage))
	
	self.hp -= damage


func animate(anim_state: int, goal: Vector2) -> void:
	assert(anim_state in AnimStates.values())
	
	if goal.y < current_tile.grid_position.y:
		if goal.x > current_tile.grid_position.x:
			face_dir = "Back"
			sprite.flip_h = true
		else:
			face_dir = "Back" 
			sprite.flip_h = false
	
	elif goal.y > current_tile.grid_position.y:
		if goal.x >= current_tile.grid_position.x:
			face_dir = "Front" 
			sprite.flip_h = true
		elif goal.x < current_tile.grid_position.x:
			face_dir = "Front"
			sprite.flip_h = false
	
	else:
		if goal.x > current_tile.grid_position.x:
			face_dir = "Back" 
			sprite.flip_h = true
		elif goal.x < current_tile.grid_position.x:
			face_dir = "Front"
			sprite.flip_h = false
	
	match anim_state:
		AnimStates.IDLE:
			sprite.play(face_dir + "Idle")
		AnimStates.ATTACK:
			sprite.play(face_dir + "Attack")
		AnimStates.WALK:
			sprite.play(face_dir + "Walk")


func auto() -> void:
	randomize()
	
	if auto_attack():
		return
	
	if auto_move():
		yield(self, "move_done")
		yield(WaitUtil.wait_for_seconds(1), "completed") # Will cause a mess later
	
	if not auto_attack():
		rest()


func auto_attack() -> bool:
	for i in range(-rng, rng + 1):
		for j in range(-rng, rng + 1):
			var attack_x: int = current_tile.grid_position.x + i 
			var attack_y: int = current_tile.grid_position.y + j
			
			attack_x = clamp(attack_x, 0, Globals.GRID_DIM - 1)
			attack_y = clamp(attack_y, 0, Globals.GRID_DIM - 1)
			
			var tile: Tile = grid.tile_at(attack_x, attack_y)
			
			if can_attack_at(attack_x, attack_y):
				emit_signal("attacked", attack_x, attack_y)
				return true
	
	return false


func auto_move() -> bool:
	var max_attempts = 30
	var attempts = 0
	
	while attempts < max_attempts:
		var move_x = int(
			rand_range(
				current_tile.grid_position.x - mov, 
				current_tile.grid_position.x + mov
			)
		)
		
		var move_y = int(
			rand_range(
				current_tile.grid_position.y - mov, 
				current_tile.grid_position.y + mov
			)
		)
		
		move_x = clamp(move_x, 0, Globals.GRID_DIM - 1)
		move_y = clamp(move_y, 0, Globals.GRID_DIM - 1)
		
		var goal_tile: Tile = grid.tile_at(move_x, move_y)
		
		if can_move_to_tile(goal_tile):
			goal_tile.select()
			return true
		
		attempts += 1
	
	return false
