extends TileMap

class_name TerrainOverlay


# Called every frame. 'delta' is the elapsed time since the previous frame.
func draw(tiles: PackedVector2Array):
	for cell in tiles:
		set_cell(0, cell)
