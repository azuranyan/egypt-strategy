extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	print("ready: combined player menu")
	OverworldEvents.connect("inspect", show_inspect)
	OverworldEvents.connect("rest", show_rest)
	OverworldEvents.connect("train", show_train)


func show_inspect():
	$ColorRect.show()
	$Esc.show()
	$Inspect.show()
	$Rest.hide()
	$Train.hide()
	print("inspect!")
	# TODO show inspect screen
	# does not end turn
	
	
func show_rest():
#	$ColorRect.show()
#	$Esc.show()
#	$Inspect.hide()
#	$Rest.show()
#	$Train.hide()
	# TODO fix ugly code
	get_parent().empire_rest(Globals.empires["Lysandra"])
	_end_turn()


func show_train():
#	$ColorRect.show()
#	$Esc.show()
#	$Inspect.hide()
#	$Rest.hide()
#	$Train.show()
	print("train!")
	_end_turn()

func _end_turn():
	OverworldEvents.emit_signal("cycle_turn_end", Globals.empires["Lysandra"])
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_esc_pressed():
	$ColorRect.hide()
	$Esc.hide()
	$Inspect.hide()
	$Rest.hide()
	$Train.hide()
