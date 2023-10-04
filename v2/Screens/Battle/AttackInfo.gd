extends Control


signal attack_changed




var attack: Attack:
	set(value):
		attack = value
		attack_changed.emit()


func _on_attack_changed():
	pass # Replace with function body.
