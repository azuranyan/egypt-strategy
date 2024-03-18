class_name ButtonSoundEmitter
extends Node
## A simple node that adds sounds to a list of buttons.


## The buttons to add sounds to.
@export var buttons: Array[BaseButton]


func _ready() -> void:
	for button in buttons:
		if button == null:
			continue
		
		AudioManager.add_button_sounds(button)