@tool
class_name SpawnPoint
extends MapObject


enum Type {
	ENEMY,
	PLAYER,
}


@export var type: Type:
	set(value):
		type = value
		if type == Type.ENEMY:
			modulate = Color(1, 0, 0, 0.2)
		elif type == Type.PLAYER:
			modulate = Color(0, 0, 1, 0.2)
			
