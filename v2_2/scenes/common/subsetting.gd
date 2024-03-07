@tool
extends VBoxContainer


@export var title: String = 'Subsetting':
	set(value):
		title = value
		if not is_node_ready():
			await ready
		%TitleLabel.text = value