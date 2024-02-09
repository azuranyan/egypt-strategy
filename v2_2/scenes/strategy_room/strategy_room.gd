extends GameScene

@onready var strategy_room_label = %StrategyRoomLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	Util.bb_big_caps(strategy_room_label, 'Strategy Room', {
		font_size = 56,
		font_color = Color('#efe6de'),
		outline_size = 36,
	})


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		scene_return()
