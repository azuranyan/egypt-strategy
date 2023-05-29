extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var os = OS.get_singleton()
	
	# Get the number of displays connected
	var num_displays = os.get_video_driver_count()
	
	# Print information about each display
	for i in range(num_displays):
		var display_info = os.get_video_driver_info(i)
		print("Display ", i, ": ", display_info.name)
	
	# Set the current display to the second display
	os.set_current_video_driver(1)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
