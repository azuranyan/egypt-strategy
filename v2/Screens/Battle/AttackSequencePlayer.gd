extends Node

signal cast_animation_finished


var battle: Battle
var animated_counter := 0


func _ready():
	battle = get_parent()


func decrement_animated_counter():
	animated_counter -= 1
	if animated_counter <= 0:
		var nodes := get_tree().get_nodes_in_group('cast_animation')
		for node in nodes:
			battle.remove_child(node)
			node.queue_free()
		cast_animation_finished.emit()
			
	
func activate_attack(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit]):
	print("%s%s used %s" % [unit.name, battle.map.cell(unit.map_pos), attack.name], ": ", target, " ", targets)

	# play animations
	for t in targets:
		t.model.play_animation(attack.target_animation)
	unit.model.play_animation(attack.user_animation)
	
	# apply attack effect
	for t in targets:
		for eff in attack.effects:
			# all targets are in the array so so we must check first
			if not _is_effect_target(unit, t, eff):
				continue
			
			var anim := AnimatedSprite2D.new()
			anim.sprite_frames = preload("res://Screens/Battle/data/default_effects.tres")
			
			battle.add_child(anim)
			anim.position = battle.map.world.uniform_to_screen(t.map_pos)
			anim.position.y -= 50
			anim.scale = Vector2(0.5, 0.5)
			anim.play(eff.get_animation())
			anim.pause()
			anim.add_to_group('cast_animation')
			anim.animation_finished.connect(decrement_animated_counter)
			animated_counter += 1
			
			eff.apply(battle, unit, attack, target, t)
	
	get_tree().call_group('cast_animation', 'play')
	await cast_animation_finished
	
	# stop animations
	for t in targets:
		t.model.play_animation("idle")
		t.model.stop_animation() # TODO wouldn't have to do this if there's a reset
	unit.model.play_animation("idle")
	unit.model.stop_animation()
	
	battle.notify_attack_sequence_finished()
		

func _is_effect_target(unit: Unit, target: Unit, effect: AttackEffect) -> bool:
	match effect.target:
		0: # Enemy
			return unit.is_enemy(target)
		1: # Ally
			return unit.is_ally(target)
		2: # Self
			return unit == target
	return false


func _on_battle_attack_sequence_started(unit, attack, target, targets):
	activate_attack(unit, attack, target, targets)


func _on_battle_attack_sequence_ended(unit, attack, target, targets):
	pass # Replace with function body.
