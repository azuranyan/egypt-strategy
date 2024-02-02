class_name SaveState
extends Resource


## A descriptor for where we stopped in-game.
@export var paused_event: String

## Paused data storage.
@export var paused_data: Dictionary

## Preferences.
@export var prefs: Preferences

## The overworld data.
@export var overworld_context: OverworldContext

## The battle data.
@export var battle_context: BattleContext

## The record of spawned units.
@export var units: Array[Unit]



static func load_from_file(path: String) -> SaveState:
	return ResourceLoader.load(path)
	

func save_to_file(path: String) -> Error:
	return ResourceSaver.save(self, path)
	
	
