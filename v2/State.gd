# https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/
extends Node2D
class_name State

var state_machine: StateMachine = null


func handle_gui_input(_event: InputEvent) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass
	
func physics_update(_delta: float) -> void:
	pass
	
func enter(_kwargs := {}) -> void:
	pass
	
func exit() -> void:
	pass
