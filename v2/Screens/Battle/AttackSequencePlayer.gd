extends Node
class_name AttackSequencePlayer

signal done


var battle: Battle

var _map := {}
var _use_attack_id := 0


func _ready():
	battle = get_parent()
			
	
## This function was made like this to prevent signals tangling and awaiting
## and that one weird godot bug where animatedsprite2d created one after the
## other keeps the last one from playing and stuck at frame 0.
func use_attack(unit: Unit, attack: Attack, target: Vector2i, targets: Array[Unit]):
	print("%s%s used %s%s %s" % [unit.name, battle.map.cell(unit.map_pos), attack.name, target, targets])
	
	# play animations
	for t in targets:
		t.model.play_animation(attack.target_animation)
	unit.model.play_animation(attack.user_animation)
	
	# spawn effects
	var uuid := 'AttackSequencePlayer_use_attack_%s' % _use_attack_id
	_use_attack_id += 1
	for eff in attack.effects:
		for t in targets:
			if not _is_effect_target(unit, t, eff):
				continue
			
			# create new effect
			var gfx := AnimatedSprite2D.new()
			add_child(gfx)
			
			# setup effect
			gfx.sprite_frames = preload("res://Screens/Battle/data/default_effects.tres")
			gfx.position = battle.map.world.uniform_to_screen(t.map_pos) + Vector2(0, -50)
			gfx.scale = Vector2(0.5, 0.5)
			gfx.play(eff.get_animation())
			gfx.pause()
			gfx.animation_finished.connect(gfx.queue_free)
			gfx.name = 'GFX_%s_%s' % [uuid, t.unit_name]
			gfx.add_to_group(uuid + '_GFX')
			
	# play gfx all at once
	get_tree().call_group(uuid + '_GFX', 'play')
	
	# loop again for the actual application of the effect
	_map[uuid] = []
	for eff in attack.effects:
		for t in targets:
			if not _is_effect_target(unit, t, eff):
				continue
			
			# create new curry
			var c := CurryEffect.new()
			add_child(c)
			
			# setup curry
			c.player = self
			c.uuid = uuid
			c.effect = eff
			c.unit = unit
			c.attack = attack
			c.cell = target
			c.target = t
			_map[uuid].append(c)
			c.name = 'EFFECT_%s_%s' % [uuid, t.unit_name]
			c.add_to_group(uuid + '_EFFECT')
	
	# apply effect all at once
	get_tree().call_group(uuid + '_EFFECT', 'apply')
	
	
func effect_done(c: CurryEffect):
	# stop animations
	c.target.model.play_animation("idle")
	c.unit.model.play_animation("idle")
	
	c.queue_free()
	_map[c.uuid].erase(c)
	if _map[c.uuid].is_empty():
		_map.erase(c.uuid)
		emit_signal.call_deferred('done')
		

func _is_effect_target(unit: Unit, target: Unit, effect: AttackEffect) -> bool:
	match effect.target:
		0: # Enemy
			return unit.is_enemy(target)
		1: # Ally
			return unit.is_ally(target)
		2: # Self
			return unit == target
	return false
	
	
class CurryEffect extends Node:
	var player: AttackSequencePlayer
	var uuid: String
	var effect: AttackEffect
	var unit: Unit
	var attack: Attack
	var cell: Vector2i
	var target: Unit
	
	func apply():
		await effect.apply(Globals.battle, unit, attack, cell, target)
		player.effect_done(self)