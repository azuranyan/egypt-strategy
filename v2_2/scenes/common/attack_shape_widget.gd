@tool
class_name AttackShapeWidget
extends Control


const MAX_RENDERABLE_COLUMNS := 20
const MIN_RENDERABLE_COLUMNS := 3

@export_group("Grid")

@export_range(MIN_RENDERABLE_COLUMNS, MAX_RENDERABLE_COLUMNS) var columns := 1:
	set(value):
		columns = clampi(value, MIN_RENDERABLE_COLUMNS, MAX_RENDERABLE_COLUMNS)
		if not is_node_ready():
			await ready
		update_grid(columns)
		update_shape(columns, shape)

@export var separation := 4:
	set(value):
		separation = value
		if not is_node_ready():
			await ready
		grid.add_theme_constant_override('h_separation', separation)
		grid.add_theme_constant_override('v_separation', separation)

@export_group("Shape")

@export var shape: Array[Vector2i]:
	set(value):
		shape = value
		if not is_node_ready():
			await ready
		update_shape(columns, shape)

@export var active_shape_color: Color = Color.RED:
	set(value):
		active_shape_color = value
		if not is_node_ready():
			await ready
		update_shape(columns, shape)

@export var inactive_shape_color: Color = Color.WHITE:
	set(value):
		inactive_shape_color = value
		if not is_node_ready():
			await ready
		update_shape(columns, shape)


@onready var grid := %GridContainer
@onready var grid_rect := %GridRect1


func update_grid(sz: int):
	for child in grid.get_children():
		if child != grid_rect:
			child.free()

	grid.columns = sz
	for i in range(1, sz * sz):
		var rect := grid_rect.duplicate()
		rect.name = 'GridRect' + str(i + 1)
		grid.add_child(rect)
	grid.queue_redraw()


@warning_ignore("integer_division")
func update_shape(sz: int, cells: Array[Vector2i]):
	for i in grid.get_child_count():
		grid.get_child(i).modulate = inactive_shape_color
	
	for cell in cells:
		var x := cell.x + sz/2
		var y := cell.y + sz/2
		if x < 0 or x >= sz or y < 0 or y >= sz:
			continue
		grid.get_child(x + y * sz).modulate = active_shape_color
	grid.queue_redraw()


## Renders the attack shape.
func render_attack_shape(attack: Attack):
	if attack:
		var max_x := 0
		var max_y := 0

		for cell in attack.target_shape:
			max_x = maxi(max_x, absi(cell.x))
			max_y = maxi(max_y, absi(cell.y))

		columns = maxi(max_x, max_y) * 2 + 1
		shape = attack.target_shape
	else:
		columns = 0
		shape = []
