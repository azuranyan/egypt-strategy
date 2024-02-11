@tool
class_name UnitMapObject
extends MapObject


@export_group("Editor")
@export var unit_type: UnitType
@export var display_name: String
@export var display_icon: Texture
@export var heading: Map.Heading
@export var owner_name: String

var selected: bool
var unit: Unit

func initialize(_unit: Unit):
	unit = _unit
