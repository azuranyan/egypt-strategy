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
	pass # Replace with function body.


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
		#self.transform = $"..".world_to_screen_transform
		position = event.position
		var uniform: Vector2 = $"..".screen_to_uniform(position, true)
		$Label.text = "screen: %s\nworld: %s\nuniform: %s" % [position, $"..".screen_to_world(position), uniform]
		
		
	
	
