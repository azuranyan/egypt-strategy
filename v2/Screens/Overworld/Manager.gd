#extends Node
class_name Manager

enum Battle {
	Training,
	Conquest,
	Defense,
}

# counts the number of turn cycles that have passed
var turn_cycles: int = 0

# empire turn order
var turn_order: Array[Empire]

# ugly implementation details
var current_turn: int = 0

# we need to have a global autoload but will also be initialized late
func _init():
	print('manager created')
	
	refresh_turn_order()


func refresh_turn_order():
	turn_order = []
	
	# TODO implementation detail
	# [0] = dummy; [1] = player; [2] = boss; ...
	turn_order.append(Globals.empires[1])
	
	for i in range(3, Globals.empires.size()):
		turn_order.append(Globals.empires[i])
	
	
func remove_from_turn_order(empire: Empire):
	var idx := get_empire_turn_order(empire)
	print("removing %s from turn order" % empire.leader.name)
	
	assert(idx != -1, "logic error; defeated territory not in turn order")
	assert(idx != current_turn, "logic error; trying to remove empire on current turn")
	
	turn_order.remove_at(idx)
	
	# current_turn will be invalid removed item index < current turn, so fix it
	if idx < current_turn:
		current_turn -= 1
	
	
func get_empire_turn_order(empire: Empire) -> int:
	return turn_order.find(empire)
	

func do_cycle():
	var new_cycle = true
	while true:
		if new_cycle:
			OverworldEvents.emit_signal("cycle_start")
		
		# do the scene queue
		while !Globals.scene_queue.is_empty():
			var scene: String = Globals.scene_queue.pop_front()
			
			# emit signal to start scene
			OverworldEvents.emit_signal("cycle_scene_start", scene)
			
			# wait for the signal to end scene
			await OverworldEvents.cycle_scene_end
		
		# refresh turn order, just in case something changed?
		# refresh_turn_order()
		print("TURN ORDER ", turn_cycles)
		for e in turn_order:
			if e == turn_order[current_turn]:
				print("  * ", e.leader.name)
			else:
				print("    ", e.leader.name)
			
		# do the turn
		var empire := turn_order[current_turn]
		OverworldEvents.emit_signal("cycle_turn_start", empire)
			
		# wait for the signal to end turn
		await OverworldEvents.cycle_turn_end
		
		# do next turn
		current_turn += 1
		print("TURN ORDER END")
			
		# turn over cycle if needed
		if current_turn >= turn_order.size():
			OverworldEvents.emit_signal("cycle_end")
			current_turn = 0
			turn_cycles += 1
			new_cycle = true
		else:
			new_cycle = false
		
		
		
