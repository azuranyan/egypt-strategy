extends Node
## Manages the save files and game state.


const SAVE_DIRECTORY := 'user://saves/'


var _saves_cache: Dictionary


func _ready():
	# we only check for the saves dir once. if this is deleted 
	# while running then it's no longer our responsibility 
	var userdir := DirAccess.open('user://')
	if not userdir.dir_exists(SAVE_DIRECTORY):
		userdir.make_dir(SAVE_DIRECTORY)
	
	
## Returns true if save slot is in use.
func slot_in_use(slot: int) -> bool:
	return _save_exists(_slot_filename(slot))
	
	
## Scans for changes.
func scan_for_changes():
	var savedir := DirAccess.open(SAVE_DIRECTORY)
	savedir.list_dir_begin()
	# naive update
	var filename := savedir.get_next()
	while filename != '':
		var slot := _filename_slot(filename)
		if slot != -1:
			_saves_cache[slot] = SAVE_DIRECTORY.path_join(filename)
		filename = savedir.get_next()
	savedir.list_dir_end()
	
	
## Returns the number of save files.
func get_save_count() -> int:
	return _saves_cache.size()
	
	
## Returns the newest save slot.
func get_newest_save_slot() -> int:
	return Persistent.newest_save_slot
	
	
## Saves data to slot.
func save_to_slot(save: SaveState, slot: int):
	save.slot = slot
	if ResourceSaver.save(save, _slot_filename(slot), ResourceSaver.FLAG_COMPRESS) != OK:
		return
		
	Persistent.newest_save_slot = slot
	
	
## Saves data.
func load_from_slot(slot: int) -> SaveState:
	return ResourceLoader.load(_slot_filename(slot))
	
	
## Deletes data.
func clear_slot(slot: int):
	var path := SAVE_DIRECTORY.path_join(_slot_filename(slot))
	OS.move_to_trash(ProjectSettings.globalize_path(path))
	
	
## Saves game data to file.
func save_data(save: SaveState, path: String) -> Error:
	return ResourceSaver.save(save, path)

	
## Loads game data from file.
func load_data(path: String) -> SaveState:
	return ResourceLoader.load(path) as SaveState


## Returns the save filename for a given save.
func _state_filename(save: SaveState) -> String:
	return _slot_filename(save.slot)
	
	
## Returns the save filename for a given slot.
func _slot_filename(slot: int) -> String:
	return SAVE_DIRECTORY + str(slot) + '.res'


## Returns the encoded slot in the filename.
func _filename_slot(filename: String) -> int:
	if filename.get_extension() != 'res':
		return -1
	var slot := filename.get_file().get_basename()
	if not slot.is_valid_int():
		return -1
	return int(slot)
	
	
## Returns true if save with filename exists.
func _save_exists(filename: String) -> bool:
	# this is not an atomic operation and 
	var savedir := DirAccess.open(SAVE_DIRECTORY)
	if not savedir.file_exists(filename):
		return false
	if _filename_slot(filename) == -1:
		return false
	return true
	