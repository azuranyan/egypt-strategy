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
			

func _ready():
	super._ready()
	if Engine.is_editor_hint():
		return

	hide()
	if type == Type.PLAYER:
		BattleEvents.prep_phase_started.connect(show.unbind(1))
		
		# we dont get to hide again if player quits before starting battle,
		# but it's fine cos we'll get unloaded together with the map anyway
		BattleEvents.prep_phase_ended.connect(hide.unbind(1))
