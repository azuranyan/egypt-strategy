extends Control
## This node fucking exists because of mouse filter stop and unhandled input interaction


func _gui_input(event: InputEvent) -> void:
	get_parent().do_unhandled_input(event)