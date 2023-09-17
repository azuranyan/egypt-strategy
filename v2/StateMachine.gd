extends Control
class_name StateMachine

signal transition(from, to)

@export var initial_state: NodePath

@onready var state: State = get_node(initial_state)

func _ready():
	await get_parent().ready
	
	for child in get_children():
		if child is State:
			child.state_machine = self
	
	assert(state != null, "did you forget to set initial_state?")
	state.enter()
	

func _gui_input(event: InputEvent) -> void:
	state.handle_gui_input(event)
	
	
func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)
	

func _process(delta: float) -> void:
	state.update(delta)
	

func _physics_process(delta: float) -> void:
	state.physics_update(delta)
	

func transition_to(new_state: String, kwargs:={}) -> void:
	if not has_node(new_state):
		return
	
	var old_state := state.name
	state.exit()
	state = get_node(new_state)
	state.enter(kwargs)
	
	transition.emit(old_state, new_state)
