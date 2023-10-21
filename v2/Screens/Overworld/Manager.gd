#extends Node
class_name Manager

enum Battle {
	Training,
	Conquest,
	Defense,
}

# counts the number of turn cycles that have passed
var turn_cycles: int = 0

# initial turn order
var initial_turn_order: Array[Empire]

# the turn queue
var turn_queue: Array[Empire]

# the empire currently taking their turn
var on_turn: Empire

# flag to indicate end
var should_end := false


# we need to have a global autoload but will also be initialized late
func _init():
	print('manager created')
	

## Removes the empire from the turn order.
func remove_from_turn_order(empire: Empire):
	empire.set_meta('Overworld.manager.eliminated', true)
	
	
## Starts the overworld main loop.
func do_cycle():
	while not should_end:
		OverworldEvents.cycle_start.emit()
		
		# create turn order if not yet
		if initial_turn_order.is_empty():
			# player takes turn first
			initial_turn_order.append(Globals.empires['Lysandra'])
			
			# add the rest of them
			for ename in Globals.empires:
				if ename != 'Lysandra' and ename != 'Sitri':
					initial_turn_order.append(Globals.empires[ename])
					
		# start the turns
		turn_queue = initial_turn_order.duplicate()
		while not turn_queue.is_empty():
			# should_end is checked before the start of a new turn
			if should_end:
				break
				
			on_turn = turn_queue.pop_front()
			
			# skip eliminated empires - we do it this way because 
			# empires can be defeated while the queue is on going
			if on_turn.get_meta('Overworld.manager.eliminated', false):
				continue
				
			# allow scene to play before the start of a turn
			await _play_scene_insert()
			
			OverworldEvents.emit_signal("cycle_turn_start", on_turn)
			await OverworldEvents.cycle_turn_end
			
			# allow scene to play after the end of a turn
			await _play_scene_insert()
			
		OverworldEvents.cycle_end.emit()
		turn_cycles += 1
	

func _play_scene_insert():
	# do the scene queue
	while !Globals.scene_queue.is_empty():
		var scn: String = Globals.scene_queue.pop_front()
		
		# emit signal to start scene
		OverworldEvents.cycle_scene_start.emit(scn)
		
		# wait for the signal to end scene
		await OverworldEvents.cycle_scene_end
