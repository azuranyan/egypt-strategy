@tool
class_name UnitModel
extends Node2D

signal animation_started(anim_name: StringName)
signal animation_finished(anim_name: StringName)


@export var state := Unit.State.INVALID

@export var heading: Map.Heading


func transition_to(new_state: Unit.State):
	pass
