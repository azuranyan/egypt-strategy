extends Node

signal UI_ACTIVE(active)
signal BOSS_ENABLED(value)

onready var empires = [$Player_Empire,$AI_Empire_1,$AI_Empire_2,$AI_Empire_3,$AI_Empire_4,$AI_Empire_5,$AI_Empire_6,$AI_Empire_7,$AI_Empire_8]
onready var boss_empire = $BOSS_Empire
var current_turn: int = 0
var agressor_empire 
var defender_empire

var UI_active = true
var Gods
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	Gods = Globals.Gods.values()
	Gods.erase(Globals.FINAL_BOSS_GOD)
	Gods.erase(Globals.Gods.Player)
	Gods.shuffle()
	Gods.append(Globals.Gods.Player)
	Gods.invert()
	Gods.append(Globals.FINAL_BOSS_GOD)
	
	var Location_Group1 = [$Zetennu]
	var Location_Group2 = [$"Neru-Khisi"]
	var Location_Group3 = [$Satayi]
	var Location_Group4 = [$"Khel-Et",]
	var Location_Group5 = [$ForsakenTemple]
	var Location_Group6 = [$"Medjed'sBeacon"]
	var Location_Group7 = [$FortZaka]
	var Location_Group8 = [$"Nekhet'sRest"]
	var Location_Group9 = [$RuinsOfAtesh]
	var Location_Group10 = [$CursedStronghold]
	var all_Location_Groups = [Location_Group1,Location_Group2,Location_Group3,Location_Group4,Location_Group5,Location_Group6,Location_Group7,Location_Group8,Location_Group9,Location_Group10]
	
	var Player_Empire = $Player_Empire
	var AI_Empire_1 = $AI_Empire_1
	var AI_Empire_2 = $AI_Empire_2
	var AI_Empire_3 = $AI_Empire_3
	var AI_Empire_4 = $AI_Empire_4
	var AI_Empire_5 = $AI_Empire_5
	var AI_Empire_6 = $AI_Empire_6
	var AI_Empire_7 = $AI_Empire_7
	var AI_Empire_8 = $AI_Empire_8
	var BOSS_Empire = $BOSS_Empire
	
	var Empires = [Player_Empire,AI_Empire_1,AI_Empire_2,AI_Empire_3,AI_Empire_4,AI_Empire_5,AI_Empire_6,AI_Empire_7,AI_Empire_8,BOSS_Empire]
	
	for i in range(Gods.size()):
		Empires[i].leader = Gods[i]
	
	for i in range(Empires.size()):
		Empires[i].home_territory = all_Location_Groups[i]
	
	start_turn()
	
func start_turn():
	var current_empire = empires[current_turn]
	emit_signal("UI_ACTIVE", false)
	UI_active = false

	if current_turn == 0:
		player_turn()
	else:
		ai_empire_turn(current_empire)

func determine_next_turn():
	while(true):
		current_turn = (current_turn + 1 % empires.size)
		if empires[current_turn].has_been_beaten() == false : 
			break
	determine_boss_active()
	start_turn()
	
func determine_boss_active():
	var remaining_empires = 0
	for empire in empires:
		if not empire.has_been_beaten():
			remaining_empires += 1 
	if remaining_empires <= 1:
		emit_signal("BOSS_ENABLED", true)

func player_turn():
	emit_signal("UI_ACTIVE", true)
	UI_active = true

func ai_empire_turn(empire: Node):
	emit_signal("UI_ACTIVE", false)
	UI_active = false
	if empire.hp_multiplier > 0.79:
		var aggression = empire.aggression_rating + randf()
		if aggression >= 1:
			var target_territory = empire.get_adjacent_territories()[randi() % empire.get_adjacent_territories().size()]
			
			agressor_empire = empire
			defender_empire = target_territory.owner_territory
			fight_over_territory(agressor_empire, defender_empire ,target_territory)
		else:
			empire.aggression_rating += 0.05
			empire.rest_action()
	else:
		empire.rest_action()

	determine_next_turn()

func fight_over_territory (attacker ,defender  ,territory )-> void:
	
	# Determine what is on the Line
	var antee = [territory]
	
	if(defender.home_territory == territory):
		antee = defender.territories
	# antee calculation DONE
	# Perform the battle
	var battle_outcome = battle(attacker.Units ,defender.Units, territory.invasion_scene)
	# returns 2 variables [attacker,defender] as strings with one of the states: "Win","Loss","Retreat"
	
	# Deal with Battle outcome
	var each = battle_outcome[0]
	if each == "Win":
		for every_territory in antee:
			win_territory(attacker,every_territory)
	if each == "Loss":
		pass
	if each == "Retreat":
		pass
			
	each = battle_outcome[1]
	if each == "Win":
		pass
	if each == "Loss":
		for every_territory in antee:
			lose_territory(defender,every_territory)
	if each == "Retreat":
		for every_territory in antee:
			lose_territory(defender,every_territory)
	
func battle(Attacker_Units : Array,Defender_Units : Array,Location) -> Array:
	return ["Win","Loss"]

func win_territory(winner ,territory ):
	winner.win_territory(territory)
	
func lose_territory(loser ,territory ):
	loser.lose_territory(territory)
	
func change_territory_owner(territory,new_owner,old_owner)-> void:
	win_territory(new_owner,territory)
	lose_territory(old_owner,territory)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func generic_territory_battle_from_player(territory):
	var defender = determine_owner(territory)
	fight_over_territory($Player_Empire,defender,territory)
	
	
func determine_owner(territory):
	
	for each in empires:
		if each.territories.contains(territory):
			return each
	return boss_empire

func _onZetennuAttack_button_up() -> void:
	generic_territory_battle_from_player($Zetennu)
	determine_next_turn()

func _onNeruKishiAttack_button_up() -> void:
	generic_territory_battle_from_player($"Neru-Khisi")
	determine_next_turn()

func _on_SatayoAttack_button_up() -> void:
	generic_territory_battle_from_player($Satayi)
	determine_next_turn()

func _on_KhelEtAttack_button_up() -> void:
	generic_territory_battle_from_player($"Khel-Et")
	determine_next_turn()

func _on_ForsakenTempleAttack_button_up() -> void:
	generic_territory_battle_from_player($ForsakenTemple)
	determine_next_turn()

func _on_MedjedsBeaconAttack_button_up() -> void:
	generic_territory_battle_from_player($"Medjed'sBeacon")
	determine_next_turn()

func _on_FortZakaAttack_button_up() -> void:
	generic_territory_battle_from_player($ForsakenTemple)
	determine_next_turn()

func _on_NekhetsRestAttack_button_up() -> void:
	generic_territory_battle_from_player($"Nekhet'sRest")
	determine_next_turn()

func _on_RuinsOfAteshAttack_button_up() -> void:
	generic_territory_battle_from_player($RuinsOfAtesh)
	determine_next_turn()

func _on_CursedStrongholdAttack_button_up() -> void:
	generic_territory_battle_from_player($CursedStronghold)
	determine_next_turn()
