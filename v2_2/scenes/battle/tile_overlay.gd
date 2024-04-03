@tool
class_name TileOverlay
extends TileMap


enum TileColor {
	SOLID_WHITE,
	RED,
	GREEN,
	BLUE,
	CYAN,
	YELLOW,
	PINK,
	BLACK,
}


func set_cells(cells: PackedVector2Array, tile_color: TileColor = TileColor.SOLID_WHITE, layer: int = 0):
	for cell in cells:
		set_cell(layer, cell, 0, Vector2i(tile_color, 0))


func erase_cells(cells: PackedVector2Array, layer: int = 0):
	for cell in cells:
		erase_cell(layer, cell)


func get_used_cells_by_color(tile_color: TileColor, layer: int = 0) -> Array[Vector2i]:
	return get_used_cells_by_id(layer, 0, Vector2i(tile_color, 0))

