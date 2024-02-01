class_name SaveState
extends Resource


@export var overworld_context: OverworldContext
@export var locked: bool


static func load_from_file(path: String) -> SaveState:
	return ResourceLoader.load(path)#, 'SaveState')
	

func save_to_file(path: String) -> Error:
	return ResourceSaver.save(self, path)
	
	
