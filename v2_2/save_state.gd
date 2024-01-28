class_name SaveState
extends Resource


@export var overworld: PackedScene


static func load_from_file(path: String) -> SaveState:
	return ResourceLoader.load(path, 'SaveState')
	

func save_to_file(path: String) -> Error:
	return ResourceSaver.save(self, path)
	
	
