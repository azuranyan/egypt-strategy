class_name BalloonContainer
extends Control


signal container_emptied


@export var target_offset := Vector2(400, -300)
@export var v_spacing: float = 20.0

var open_balloons: Array[Balloon]

var resource: DialogueResource
var current_line: DialogueLine:
	set(value):
		if not value:
			responses_menu.hide()
			responses_menu.responses = current_line.responses

			_close_all()
			return

		current_line = value
		update_dialogue()
		
var current_balloon: Balloon

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	test.call_deferred()


@onready var narration_balloon := $"../ClassicDialogueBox"
@onready var characters := $"../Characters"
@onready var responses_menu := $"../ResponsesContainer/ResponsesMenu"


func test() -> void:
	DialogueEvents.next_requested.connect(next_requested)
	responses_menu.response_selected.connect(func(response: DialogueResponse): next(response.next_id))

	await get_tree().create_timer(1).timeout
	resource = preload("data/test.dialogue")
	
	current_balloon = preload("res://scenes/dialogue/balloon.tscn").instantiate()
	# this doesnt have to be added - this will only be used for duplication
	# add_child(first)
	next("start")


func reset_conversation() -> void:
	if open_balloons.is_empty():
		return

	_close_all.call_deferred()
	await container_emptied


func _close_all() -> void:
	for balloon in open_balloons.duplicate():
		balloon.closed.connect(balloon.queue_free)
		balloon.close()


func next_requested(balloon: Balloon) -> void:
	next(balloon._current_line.next_id)


func next(next_id: String) -> void:
	current_line = await DialogueManager.get_next_dialogue_line(resource, next_id)


func update_dialogue() -> void:
	if resource.titles.find_key(current_line.id):
		await reset_conversation()

	responses_menu.hide()
	responses_menu.responses = current_line.responses

	# if no character is set, play on the narration dialogue
	if current_line.character.is_empty():
		narration_balloon.play_dialogue_line(current_line)
		return

	# find target character
	var target := characters.find_child(current_line.character)
	if target:
		var head := target.find_child("Head")
		if head:
			target = head
	
	# if no target character is found, use the narration box
	if not target or not target.visible:
		narration_balloon.play_dialogue_line(current_line)
		return
		
	# create new balloon
	current_balloon = current_balloon.duplicate()
	current_balloon.target = target

	if will_overflow(current_balloon):
		await reset_conversation()

	add_child(current_balloon)
	current_balloon.play_dialogue_line(current_line)

	if current_balloon.is_waiting_for_response():
		current_balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()


func _enter_tree() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)


func _exit_tree() -> void:
	child_entered_tree.disconnect(_on_child_entered_tree)
	child_exiting_tree.disconnect(_on_child_exiting_tree)
	request_ready()


## Returns true if adding this balloon will overflow the container.
func will_overflow(balloon: Balloon) -> bool:
	return not get_global_rect().has_point(find_free_position(balloon))


## Returns the position should this balloon be added.
func find_free_position(balloon: Balloon) -> Vector2:
	var tpos := balloon.target.global_position
	
	if tpos.x <= Game.get_viewport_size().x/2:
		# if the target is on the left side of the screen, put it to the right
		tpos.x += target_offset.x
	else:
		# otherwise put it to the left
		tpos.x -= target_offset.x

	# center balloon to the target position
	tpos.x -= balloon.size.x/2

	# position vertically
	if open_balloons.is_empty():
		tpos.y += target_offset.y
	else:
		tpos.y = open_balloons[-1].global_position.y + open_balloons[-1].size.y + v_spacing

	# clamp tpos to the container region
	tpos.x = clamp(tpos.x, global_position.x, global_position.x + size.x)
	if tpos.y < global_position.y:
		tpos.y = global_position.y

	return tpos


func _on_child_entered_tree(node: Node) -> void:
	if not node is Balloon:
		return

	node.opened.connect(_on_balloon_opened.bind(node))
	node.closed.connect(_on_balloon_closed.bind(node))
	if node.is_open():
		_on_balloon_opened(node)


func _on_child_exiting_tree(node: Node) -> void:
	if not node is Balloon:
		return

	node.opened.disconnect(_on_balloon_opened.bind(node))
	node.closed.disconnect(_on_balloon_closed.bind(node))
	if node.is_open():
		_on_balloon_closed(node)

	
func _on_balloon_opened(balloon: Balloon) -> void:
	if not balloon.target:
		return

	balloon.global_position = find_free_position(balloon) 
	open_balloons.append(balloon)


func _on_balloon_closed(balloon: Balloon) -> void:
	open_balloons.erase(balloon)
	if open_balloons.is_empty():
		container_emptied.emit()