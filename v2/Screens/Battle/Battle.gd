@tool
extends Control
class_name Battle


## Emitted when the map is loaded to the game.
signal map_loaded(map)

## Emitted when battle is started.
signal battle_started(attacker, defender, territory)

## Emitted when battle ended.
signal battle_ended(result)


class Action:
	var frame: int
	var fun: Callable
	var args: Array
	
var action_stack: Array[Action] = []
var frames: int = 0

#var current_map: Node2D

@onready var map: Map
@onready var viewport: Viewport = $SubViewportContainer/Viewport
var cursor: Cursor

func _ready():
	set_debug_tile_visible(false)
	
	print("battle ready")
	Globals.battle = self

func _unhandled_input(event: InputEvent):
	# because we're using a camera that transforms the viewport
	# we need to make this event local to the map input!!!
	event = map.make_input_local(event)
	var uniform: Vector2
#
#	var p := viewport.get_mouse_position()
#	if event is InputEventMouse:# and cursor.enable_mouse_control:
#		uniform = map.world.screen_to_uniform(event.position, true)
#
#
#		cursor.position = map.world.uniform_to_screen(uniform)
#		cursor.get_node("Node2D/Label").text = "screen: %s\nworld: %s\nuniform: %s" % [event.position, map.world.screen_to_world(event.position), map.world.screen_to_uniform(event.position, true)]
#
#		$UI/Label.text = "Tile: %s\nx = %s\ny = %s" % [map.get_tile(uniform).get_name(), uniform.x, uniform.y]
#
	if event is InputEventKey and event.pressed:
		uniform = map.world.screen_to_uniform(cursor.position, true)
		match event.keycode:
			KEY_W: 
				uniform.y += 1
			KEY_A: 
				uniform.x -= 1
			KEY_S: 
				uniform.y -= 1
			KEY_D: 
				uniform.x += 1
				
		cursor.position = map.world.uniform_to_screen(uniform)
		$UI/Label.text = "Tile: %s\nx = %s\ny = %s" % [map.get_tile(uniform).get_name(), uniform.x, uniform.y]
			
	#if cursor.position != cursor._last_position:
	#	cursor.position_changed.emit(uniform)
	#	cursor._last_position = cursor.position
				
				
func _process(delta):
	frames += 1
	
	
func push_action(fun: Callable, args: Array):
	var action := Action.new()
	action.frame = frames
	action.fun = fun
	action.args = args
	action_stack.push_back(action)

func pop_action():
	action_stack.pop_back()
	
func undo():
	pop_action()
	action_stack[-1].fun.callv(action_stack[-1].args)
	
func load_map(res: String):
	load_map_scene(load(res) as PackedScene)
	
	
func load_map_scene(scene: PackedScene):
	# we need to be in the tree for everything to work, so do that first
	Globals.get_tree().root.add_child(self)
	
	map = scene.instantiate() as Map
	
	# do not set owner, as we don't want it to be saved along with the scene
	viewport.add_child(map)
	#map.owner = self
	
	# only at this point we can add cursor because it relies on the map.
	# we need to be ready for the onready map var so we can only add cursor
	# as a child after we are ready.
	cursor = load("res://Screens/Battle/Cursor.tscn").instantiate()
	#cursor.position_changed.connect(_on_cursor_position_changed)
	cursor.name = "Cursor"
	#viewport.add_child(cursor)
	add_map_object(cursor)
	
	map_loaded.emit(map)
	
	
## The result of the battle.
enum Result {
	## Attacker cannot fulfill battle requirements.
	AttackerRequirementsError=-1,
	
	## Attacker cancels before starting the fight.
	Cancelled=0,
	
	## Attacker wins.
	AttackerVictory,
	
	## Attacker loses.
	DefenderVictory,
	
	## Attacker loses via withdraw.
	AttackerWithdraw,
	
	## Attacker wins via defender withdraw.
	DefenderWithdraw,
}


## The state of the battle.
class Context:
	var attacker: Empire
	var defender: Empire
	var territory: Territory
	var result: Result
	
	var turns: int
	var current_turn: Empire
	
var context: Context

@onready var state_machine: StateMachine = $States

	
	
	
func start_battle(attacker: Empire, defender: Empire, territory: Territory, do_quick:=true):
	if !_fulfills_battle_requirements(attacker, territory):
		battle_ended.emit(Result.AttackerRequirementsError)
		return
	
	if do_quick and !(attacker.is_player_owned() or defender.is_player_owned()):
		_start_quick_battle(attacker, defender, territory)
	else:
		_start_real_battle.call_deferred(attacker, defender, territory)
		

func _fulfills_battle_requirements(empire: Empire, territory: Territory) -> bool:
	return true
	
	
func _start_quick_battle(attacker: Empire, defender: Empire, territory: Territory):
	battle_started.emit(attacker, defender, territory)
		
	# we start the battle on the next frame to allow this frame end first
	var continuation := func():
		await get_tree().create_timer(1.0).timeout
		battle_ended.emit(Result.AttackerVictory)
		
	continuation.call_deferred()
	
	
func _start_real_battle(attacker: Empire, defender: Empire, territory: Territory):
	get_tree().current_scene = self
	
	state_machine.transition_to("Init", {battle=self, attacker=attacker, defender=defender, territory=territory})

	
func get_viewport_size() -> Vector2i:
	return viewport.size
	
	
func set_debug_tile_visible(debug_tile_visible: bool):
	# inspector starts with 1 but this is 0-based
	viewport.set_canvas_cull_mask_bit(9, debug_tile_visible)


func add_map_object(object: MapObject):
	map.add_child(object)
	object._map_enter(map)
	

func _on_cursor_position_changed(pos: Vector2):
	$UI/Label.text = "Tile: %s\nx = %s\ny = %s" % [map.get_tile(pos).get_name(), pos.x, pos.y]
	
	
