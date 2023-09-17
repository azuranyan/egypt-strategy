@tool
extends ColorRect

class_name CharacterButton

signal portrait_changed
signal display_name_changed
signal highlight_changed

signal selected
signal released
signal drag_started(pos: Vector2)
signal dragged(pos: Vector2)

@export var portrait: Texture2D:
	set(value):
		portrait = value
		portrait_changed.emit()
		
@export var display_name: String:
	set(value):
		display_name = value
		display_name_changed.emit()
		
@export var highlight: bool:
	set(value):
		highlight = value
		highlight_changed.emit()
		
		
		
@onready var sprite := $ColorRect/Sprite2D as Sprite2D
@onready var control := $Control as Control
@onready var label := $Label as Label
		
		

func _ready():
	portrait_changed.connect(_update_portrait)
	display_name_changed.connect(_update_name)
	highlight_changed.connect(_update_highlight)
	
	portrait = portrait
	display_name = display_name
	highlight = highlight
	

func _update_portrait():
	sprite.texture = portrait
	
	if portrait:
		var sz := portrait.get_size()
		var minsize := size
		
		var scale_y := minsize.y/sz.y * 2.75
		
		sprite.position.x = -minsize.y/6
		sprite.position.y = -(scale_y*sz.y)/3
		
		sprite.scale = Vector2(scale_y, scale_y)
		
	
func _update_name():
	label.text = display_name


func _update_highlight():
	control.visible = highlight


enum State {
	IDLE,
	PRESSED,
	SELECTED,
	DRAGGED,
}

var state := State.IDLE


func _to_global_mouse_pos(pos: Vector2) -> Vector2:
	# TODO we're using global coordinates cos i can't fix the event.position issue with global rect
	return get_global_mouse_position()
	
func _gui_input(event):
	var pos := _to_global_mouse_pos(event.position)
	match state:
		State.IDLE:
			if event is InputEventMouseButton and event.button_index == 1 and event.is_pressed():
				scale = Vector2(1.05, 1.05)
				highlight = true
				state = State.PRESSED
				
				
		State.PRESSED:
			if event is InputEventMouseButton and event.button_index == 1:
				# releasing lmb turns it to selected
				if !event.is_pressed():
					state = State.SELECTED
					selected.emit()
			
			elif event is InputEventMouseMotion and !get_global_rect().has_point(pos):
				state = State.DRAGGED
				drag_started.emit(pos)
				
				
		State.DRAGGED:
			if event is InputEventMouseMotion:
				dragged.emit(pos)
			
			# releasing or pressing any button cancels the interaction and only
			# LMB will emit the proper signal
			elif event is InputEventMouseButton:
				scale = Vector2(1, 1)
				highlight = false
				state = State.IDLE
				if event.button_index == 1 and !event.pressed:
					released.emit()

						
		State.SELECTED:
			if event is InputEventMouseButton and event.button_index == 1:
				if !event.is_pressed() and get_global_rect().has_point(pos):
					selected.emit()
					
			elif event is InputEventMouseMotion and !get_global_rect().has_point(pos):
				state = State.DRAGGED
				drag_started.emit(pos)
					
	accept_event()
				
				
func _input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 2:
		scale = Vector2(1, 1)
		highlight = false
		state = State.IDLE


func set_selected(_selected: bool, emit := true):
	if _selected:
		scale = Vector2(1.05, 1.05)
		highlight = true
		state = State.SELECTED
		if emit:
			selected.emit()
	else:
		scale = Vector2(1, 1)
		highlight = false
		state = State.IDLE
		if emit:
			released.emit()
		

func _on_mouse_entered():
	highlight = true
	pass


func _on_mouse_exited():
	highlight = state != State.IDLE
	pass
