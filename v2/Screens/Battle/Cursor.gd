@tool
extends Sprite2D

@export var pos_x: int:
	set(value):
		pos_x = value
		#self.position = $"..".uniform_to_screen(Vector2(pos_x, pos_y))
	get:
		return pos_x
		
@export var pos_y: int:
	set(value):
		pos_y = value
		#self.position = $"..".uniform_to_screen(Vector2(pos_x, pos_y))
	get:
		return pos_y

func _enter_tree():
	set_process_input(true)
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	var m = Transform2D()
	
	# scale to downsize to unit vector
	m = m.scaled(Vector2(1/texture.get_size().x, 1/texture.get_size().y))
	
	# scale to tile size
	m = m.scaled(Vector2($"..".world.tile_size, $"..".world.tile_size))
	
	transform = $"..".world.world_to_screen_transform * m


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# set the transform to get to the same space
	#self.transform = $"..".world_to_screen_transform
	
	#self.transform = Transform2D()
	#var offset := Vector2()#($"..".tile_size/8, $"..".tile_size/8)
	#offset.x = $"..".tile_size/2# * $"..".y_ratio / 2
	#offset.y = $"..".tile_size/2
	#self.position = $"..".world_to_screen_transform*offset
	#self.transform = $"..".world_to_screen_transform.translated(offset)
	pass

	
func _unhandled_input(event):
	if event is InputEventMouse:
		var uniform: Vector2 = $"..".world.screen_to_uniform(event.position, true)
		
		$Label.text = "screen: %s\nworld: %s\nuniform: %s" % [position, $"..".world.screen_to_world(position), uniform]

		position = $"..".world.uniform_to_screen(uniform)
		#$"../Tree1".position = position
		

class MapNode:
	var world: World = null
	
	func set_map(map: Map):
		if map != null:
			self.world = map.world
		else:
			self.world = null
		
	
	
