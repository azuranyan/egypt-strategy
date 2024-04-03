class_name BattlePauseMenu
extends PauseMenu


@export_group("Connections/Buttons")
@export var forfeit_button_path: NodePath


@onready var forfeit_button := get_node(forfeit_button_path)