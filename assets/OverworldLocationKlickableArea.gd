extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var parent_node = get_parent()



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var popup_label = null
var popup_bg = null
var timer = null

func _on_OverworldLocationKlickableArea_input_event(viewport, event, shape_idx):
	
	if(event is InputEventMouseButton):
		if(popup_label == null):
			var message = "Klicked"
		# Create background rectangle
			popup_bg = ColorRect.new()
			popup_bg.color = Color(0, 0, 0, 0.7)
			popup_bg.rect_size = Vector2(get_viewport_rect().size.x, 80)
			popup_bg.rect_position = Vector2(0, get_viewport_rect().size.y / 2 - popup_bg.rect_size.y / 2)
			add_child(popup_bg)

			# Create label
			popup_label = Label.new()
			popup_label.text = message
			popup_label.align = Label.ALIGN_CENTER
			popup_label.rect_size = Vector2(get_viewport_rect().size.x, 50)
			popup_label.rect_position = Vector2(0, get_viewport_rect().size.y / 2 - popup_label.rect_size.y / 2)
			add_child(popup_label)

			# Set timer to remove popup after 5 seconds
			timer = Timer.new()
			add_child(timer)
			timer.wait_time = 1
			timer.one_shot = true
			timer.start()
			timer.connect("timeout", self, "on_timer_timeout")
		else:
			popup_bg.show()
			popup_label.show()
			timer.start()
			
			parent_node.I_have_been_klicked()
	

func on_timer_timeout():
	popup_label.hide()
	popup_bg.hide()

