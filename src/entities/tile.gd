class_name Tile
extends Node2D

signal selected

enum TileFlags {
	PASSABLE,
	UNPASSABLE,
	CONDITIONAL,
}

enum TileTeam {
	FREE,
	ALLY,
	ENEMY,
}

export(TileFlags) var type: int 

var grid_position: Vector2
var neighbors: Array
var selectable: bool setget set_selectable
var occupied: bool = false
var team: int = TileTeam.FREE setget set_team 



func _on_Area2D_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (selectable
	and event is InputEventMouseButton 
	and event.is_pressed()
	and event.button_index == BUTTON_LEFT):
		if not occupied:
			select()


func set_selectable(value: bool) -> void:
	selectable = value
	$Polygon2D.visible = value


func set_team(value: int) -> void:
	assert(value in TileTeam.values())
	
	team = value


func select() -> void:
	modulate = Color.magenta
	emit_signal("selected")


func deselect() -> void:
	modulate = Color.white


func highlight() -> void:
	modulate = Color.blue


func unlight() -> void:
	modulate = Color.white

