class_name MapNode
extends Node2D


enum Type {
	UNIT,
	DOODAD,
	TERRAIN,
	OTHER,
}

var map_position: Vector2
var map_rotation: float
var map_scale: Vector2

var map_object: MapObject
