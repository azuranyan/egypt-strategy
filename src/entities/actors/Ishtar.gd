extends Actor



func can_attack_at(grid_pos_x: int, grid_pos_y: int) -> bool:
	var tile: Tile = grid.tile_at(grid_pos_x, grid_pos_y)
	
	return tile != current_tile\
	and tile.occupied\
	and grid.get_distance(current_tile.grid_position.x, current_tile.grid_position.y, grid_pos_x, grid_pos_y) <= rng


func attack(actor: Actor) -> void:
	already_moved = true
	
	animate(AnimStates.ATTACK, actor.current_tile.grid_position)
	
	if actor.is_in_group("enemy"):
		yield(actor.receive_damage(dmg), "completed")
		
		if not actor.stun:
			actor.stun = true
			actor.vfx.play("stun")
			yield(actor.vfx, "animation_finished")
			actor.vfx.play("default")
	else:
		yield(heal(actor, 2.0), "completed")
	
	animate(AnimStates.IDLE, actor.current_tile.grid_position)
	
	end_turn()


func heal(actor: Actor, amount: float) -> void:
	if actor == self:
		return
	
	already_moved = true
	
	animate(AnimStates.ATTACK, actor.current_tile.grid_position)
	
	var prev_mod = actor.sprite.self_modulate
	actor.sprite.self_modulate = Color.blue
	actor.vfx.play("heal")
	yield(actor.vfx, "animation_finished")
	actor.sprite.self_modulate = prev_mod
	actor.vfx.play("default")
	print(actor.name + " was healed. Recovered: " + str(amount))
	
	if actor.poison:
		actor.poison_turn_count = 0
		actor.poison = false
	
	actor.hp += amount
	
	animate(AnimStates.IDLE, actor.current_tile.grid_position)
