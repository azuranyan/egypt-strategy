class_name LoadingScreen
extends CanvasLayer


signal safe_to_load


func _unhandled_input(_event):
	# intercept all inputs when active
	get_viewport().set_input_as_handled()


# TODO update

# TODO fade_out
