class_name TerritoryButton
extends Node2D


var territory: Territory


func _ready():
	_remove_null_territory()
	for child in get_children():
		if child is Territory:
			territory = child
	if not territory:
		territory = preload("res://scenes/overworld/null_territory.tscn").instantiate() as Territory
		territory.set_meta('NullTerritory', true)
		add_child(territory)
		push_error('"%s" (%s) using NullTerritory (not assigned)' % [name, self])


func _exit_tree():
	request_ready()
	_remove_null_territory()
	territory = null


func _remove_null_territory():
	for child in get_children():
		if child.has_meta('NullTerritory'):
			child.queue_free()
	
