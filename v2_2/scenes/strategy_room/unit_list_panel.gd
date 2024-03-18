extends Panel


func _ready() -> void:
	AudioManager.add_item_list_sounds(%UnitList)


func get_selected_unit() -> Unit:
	return null