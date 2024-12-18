@tool
# Draws the unit's movement path using an autotile.
class_name UnitPath
extends TileMap

@export var world: World

# This variable holds a reference to a PathFinder object. We'll create a new one every time the 
# player select a unit.
var _pathfinder: PathFinder

# This property caches a path found by the _pathfinder above.
# We cache the path so we can reuse it from the game board. If the player decides to confirm unit
# movement with the cursor, we can pass the path to the unit's walk_along() function.
var current_path := PackedVector2Array()


# Creates a new PathFinder that uses the AStar algorithm we use to find a path between two cells 
# among the `walkable_cells`.
# We'll call this function every time the player selects a unit.
func initialize(walkable_cells: Array) -> void:
	_pathfinder = PathFinder.new(world, walkable_cells)
	

# Finds and draws the path between `cell_start` and `cell_end`.
func draw(cell_start: Vector2, cell_end: Vector2, do_clear := true) -> void:
	# We first clear any tiles on the tilemap, then let the Astar2D (PathFinder) find the
	# path for us.
	if do_clear:
		clear()
	current_path = _pathfinder.calculate_point_path(cell_start, cell_end)
	# And we draw a tile for every cell in the path.
	for cell in current_path:
		set_cell(0, cell)
	# The function below updates the auto-tiling. Without it, you wouldn't get the nice path with curves
	# and the arrows on either end.
	set_cells_terrain_connect(0, current_path, 0, 0)


# Stops drawing, clearing the drawn path and the `_pathfinder`.
func stop() -> void:
	_pathfinder = null
	clear()


func _on_world_world_changed():
	var unit_scale := Vector2.ONE / Vector2(tile_set.tile_size) * world.tile_size
	var m := Transform2D(0, unit_scale, 0, Vector2.ZERO)
	transform = world.world_transform * m
