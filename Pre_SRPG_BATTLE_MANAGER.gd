extends Node

enum BattleOutcome { DEFENDER_VICTORY, ATTACKER_WITHDRAWAL, ATTACKER_VICTORY, DEFENDER_WITHDRAWAL }
export(bool) var MOCKING: bool = true

signal battle_outcome(outcome)

func start_battle(attacker, defender, location):
	if attacker == get_tree().get_root().get_node("PlayerEmpire") or defender == get_tree().get_root().get_node("PlayerEmpire"):
		if MOCKING:
			_mock_battle()
		else:
			_srpg_battle(attacker, defender, location)
	else:
		_quick_battle(attacker, defender)

func _quick_battle(attacker: Node, defender: Node):
	var attacker_strength = attacker.strength_rating * attacker.hp_multiplier + randf()
	var defender_strength = defender.strength_rating * defender.hp_multiplier + randf()
	var outcome

	if defender_strength >= attacker_strength:
		if defender_strength + 0.2 >= attacker_strength:
			outcome = BattleOutcome.ATTACKER_WITHDRAWAL
		else:
			outcome = BattleOutcome.DEFENDER_VICTORY
	else:
		outcome = BattleOutcome.ATTACKER_VICTORY

	emit_signal("battle_outcome", outcome)

func _mock_battle():
	# Create buttons and connect their signals
	var buttons = []
	for outcome in BattleOutcome.values():
		var button = Button.new()
		button.text = BattleOutcome[outcome]
		button.connect("pressed", self, "_on_button_pressed", [outcome])
		add_child(button)
		buttons.append(button)

	# Wait for button press
	yield(self, "button_pressed")

	# Remove buttons
	for button in buttons:
		button.queue_free()

func _on_button_pressed(outcome):
	emit_signal("battle_outcome", outcome)

func _srpg_battle(attacker: Node, defender: Node, location: Node):
	# Load the combat scene and pass the attacker, defender, and location
	var combat_scene = load("res://path/to/CombatScene.tscn")
	var combat_instance = combat_scene.instance()
	combat_instance.attacker = attacker
	combat_instance.defender = defender
	combat_instance.location = location
	get_tree().get_root().add_child(combat_instance)

	# Transition to the combat scene
	get_tree().change_scene_to(combat_instance)

	# Wait for the combat to end and receive the outcome
	yield(combat_instance, "combat_ended")
	
signal button_pressed(outcome)
