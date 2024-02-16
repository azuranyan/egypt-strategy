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
		Game.battle.player_prep_phase.connect(show)
		# we dont get to hide again if player quits before starting battle,
		# but it's fine cos we'll get unloaded together with the map anyway
		Game.battle.battle_started.connect(func(_a, _d, _t, _m): hide())
		