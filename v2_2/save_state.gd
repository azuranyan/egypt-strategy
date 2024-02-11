class_name SaveState
extends Resource


@export_group('Header')

## Save version.
@export var version: String

## Save slot.
@export var slot: int

## Preview image.
@export var preview: Texture

## Dictionary timestamp.
@export var timestamp: Dictionary

@export_group('Game Data')

## A descriptor for where we stopped in-game.
@export var paused_event: String

## Paused data storage.
@export var paused_data: Dictionary

## The current active game context.
@export_enum('none', 'overworld', 'battle', 'event') var active_context: String = 'none'

## The overworld data.
@export var overworld_data: Dictionary

## The battle data.
@export var battle_data: Dictionary

## For unit id generation.
@export var next_unit_id: int

## The record of spawned units.
@export var units: Dictionary

## Scene stack.
@export var scene_stack: Array[SceneStackFrame]

## Generic data.
@export var data: Dictionary


static func load_from_file(path: String) -> SaveState:
	return ResourceLoader.load(path)
	

func save_to_file(path: String) -> Error:
	return ResourceSaver.save(self, path)
	
	
