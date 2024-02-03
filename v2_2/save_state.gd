class_name SaveState
extends Resource


## Save slot.
@export var slot: int

## Preview image.
@export var preview: Texture

## Dictionary timestamp.
@export var timestamp: Dictionary

## A descriptor for where we stopped in-game.
@export var paused_event: String

## Paused data storage.
@export var paused_data: Dictionary

## The current active game context.
@export_enum('none', 'overworld', 'battle', 'event') var active_context: String = 'none'

## The overworld data.
@export var overworld_context: OverworldContext

## The battle data.
@export var battle_context: BattleContext

## The record of spawned units.
@export var units: Array[Unit]

## Scene stack.
@export var scene_stack: Array[SceneStackFrame]

## Generic data.
@export var data: Dictionary


static func load_from_file(path: String) -> SaveState:
	return ResourceLoader.load(path)
	

func save_to_file(path: String) -> Error:
	return ResourceSaver.save(self, path)
	
	
