extends CanvasLayer


@export var battle: Battle


func _input(event):
	if not battle.map:
		return
		
	if event is InputEventMouseMotion:
		$Debug/HBoxContainer2/Label2.text = "%s" % event.global_position
		
		var pos: Vector2 = get_viewport().canvas_transform.affine_inverse() * event.position
		
		$Debug/HBoxContainer3/Label2.text = "%s" % pos
		$Debug/HBoxContainer/Label2.text = "%s" % battle.map.to_cell(battle.map.world.as_uniform(pos))
		
			
			
