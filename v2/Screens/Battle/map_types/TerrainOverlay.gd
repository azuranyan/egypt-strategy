@tool
extends TileMap


enum {
	TERRAIN_WHITE,
	TERRAIN_BLUE,
	TERRAIN_GREEN,
	TERRAIN_RED,
}


@export var world: World


## Draws terrain overlay.
func draw(cells: PackedVector2Array, idx := TERRAIN_GREEN, clear := true):
	if clear:
		clear()
	for cell in cells:
		# idk why it's source 1 but if the tileset shows an error in the editor
		# or displays nothing in-game, then check source
		set_cell(0, cell, 1, Vector2i(idx, 0), 0)
	
	
func _on_world_world_changed():
	var unit_scale := Vector2.ONE / Vector2(tile_set.tile_size) * world.tile_size
	var m := Transform2D(0, unit_scale, 0, Vector2.ZERO)
	transform = world.world_transform * m
