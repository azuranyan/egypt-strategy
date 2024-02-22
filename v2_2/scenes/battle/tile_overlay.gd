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


# @export var world: World:
# 	set(value):
# 		if is_instance_valid(world):
# 			world.world_changed.disconnect(_on_world_changed)
# 		world = value
# 		if is_instance_valid(world):
# 			world.world_changed.connect(_on_world_changed)
# 		_on_world_changed()
# 		update_configuration_warnings()


# func _ready():
# 	_on_world_changed()
	

func set_cells(cells: PackedVector2Array, tile_color: TileColor = TileColor.SOLID_WHITE, layer: int = 0):
	for cell in cells:
		set_cell(layer, cell, 0, Vector2i(tile_color, 0))


func erase_cells(cells: PackedVector2Array, layer: int = 0):
	for cell in cells:
		erase_cell(layer, cell)


func get_used_cells_by_color(tile_color: TileColor, layer: int = 0) -> Array[Vector2i]:
	return get_used_cells_by_id(layer, 0, Vector2i(tile_color, 0))


# func _on_world_changed():
# 	if is_instance_valid(world):
# 		var unit_scale := Vector2.ONE / Vector2(tile_set.tile_size) * world.tile_size
# 		var m := Transform2D(0, unit_scale, 0, Vector2.ZERO)
# 		transform = world.world_transform * m
# 	else:
# 		transform = Transform2D()


# func _get_configuration_warnings() -> PackedStringArray:
# 	if not is_instance_valid(world):
# 		return ['world is null']
# 	return []
