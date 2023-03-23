class_name BattleUI
extends Control


export(NodePath) onready var options = get_node(options) as Container
export(NodePath) onready var move_button = get_node(move_button) as Button
export(NodePath) onready var attack_button = get_node(attack_button) as Button
export(NodePath) onready var wait_button = get_node(wait_button) as Button
export(NodePath) onready var undo_button = get_node(undo_button) as Button
export(NodePath) onready var cancel_button = get_node(cancel_button) as Button
export(NodePath) onready var spacebar = get_node(spacebar) as Container



func hide_options() -> void:
	options.hide()
	cancel_button.show()


func show_options() -> void:
	options.show()
	cancel_button.hide()
