class_name Grid
extends Node2D

onready var tiles: Array = get_node("Tiles").get_children() as Array



func _ready() -> void:
	var tile: Tile
	
	for i in range(Globals.GRID_DIM):
		for j in range(Globals.GRID_DIM):
			tile = tile_at(i, j)
			tile.grid_position.x = i
			tile.grid_position.y = j
			var sprite = tile.get_node_or_null("Sprite")
			var sprite_pos
			
			if sprite:
				sprite_pos = sprite.global_position
				
			tile.position = grid_to_world(i, j)
			
			if sprite:
				sprite.global_position = sprite_pos
			
			tile.z_index = Globals.GRID_DIM * (1 + j) - i - 1


func tile_at(grid_x: int, grid_y: int) -> Tile:
	assert(has_tile_at(grid_x, grid_y))
	return tiles[grid_x + Globals.GRID_DIM * grid_y]


func tile_at_pos(grid_pos: Vector2) -> Tile:
	return tile_at(grid_pos.x, grid_pos.y)


func has_tile_at(grid_x: int, grid_y: int) -> bool:
	var idx: int = grid_x + Globals.GRID_DIM * grid_y
	return idx >= 0 and idx < Globals.TILE_NUM


func has_tile_at_pos(grid_pos: Vector2) -> bool:
	return has_tile_at(grid_pos.x, grid_pos.y)


func has_tile(tile: Tile) -> bool:
	return has_tile_at_pos(tile.grid_position)


func grid_to_world(grid_x: int, grid_y: int) -> Vector2:
	var x = grid_x
	var y = grid_y
	return Vector2(
		(grid_x - grid_y) * Globals.TILE_H_HALF,
		(grid_x + grid_y) * Globals.TILE_W_HALF
		)


func grid_pos_to_world(grid_pos: Vector2) -> Vector2:
	return grid_to_world(grid_pos.x, grid_pos.y)


func grid_tile_pos_to_world(tile: Tile) -> Vector2:
	return grid_pos_to_world(tile.grid_position)


func get_distance(x0: int, y0: int, x1: int, y1: int) -> int:
	return int(abs(x1 - x0) + abs(y1 - y0)) 


func get_distance_between(start_pos: Vector2, end_pos: Vector2) -> int:
	return get_distance(start_pos.x, start_pos.y, end_pos.x, end_pos.y)


func get_distance_between_tiles(tile_0: Tile, tile_1: Tile) -> int:
	return get_distance_between(tile_0.grid_position, tile_1.grid_position)


func update_overlap() -> bool:
	yield(WaitUtil.wait_for_frames(15), "completed")
	return false
