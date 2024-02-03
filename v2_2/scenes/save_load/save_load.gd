extends GameScene

const SAVE_PATH := 'user://saves/'


@export var max_pages: int = 20

var _save_data: SaveState
var _current_page: int
var _saves_cache: Dictionary

	
## Returns the save filename for a given save.
static func state_filename(save: SaveState) -> String:
	return slot_filename(save.slot)
	
	
## Returns the save filename for a given slot.
static func slot_filename(slot: int) -> String:
	return SAVE_PATH + str(slot) + '.res'


## Returns the encoded slot in the filename.
static func filename_slot(filename: String) -> int:
	if not filename.ends_with('.res'):
		return -1
	var slot := filename.rsplit('.')
	if slot.size() > 1 and slot[0].is_valid_int():
		return int(slot[0]) 
	return -1


func _ready():
	var sample_button := $Control/VBoxContainer/SampleButton
	for i in max_pages:
		var btn := sample_button.duplicate()
		btn.text = str((i + 1))
		btn.pressed.connect(_page_button_pressed.bind(i))
		$Control/VBoxContainer.add_child(btn)
	$Control/VBoxContainer.remove_child(sample_button)
	
	for i in range(1, 11):
		var slot := get_save_slot(i)
		slot.pressed.connect(_slot_pressed.bind(slot))
		slot.close_pressed.connect(_slot_closed_pressed.bind(slot))
		
	if Util.is_f6(self):
		Game.create_testing_context()
		scene_enter.call_deferred({save_data=Game.create_new_data()})


func scene_enter(kwargs := {}):
	update_saves_cache()
	load_slot_page(Game.persistent.newest_save_slot)
	
	_save_data = kwargs.get('save_data')
	
	if is_save_mode():
		$Control/SaveLoadLabel.text = 'Save'
		$Control/SaveInfoPanel.show()
		$Control/SaveInfoPanel/TextureRect.texture = _save_data.preview
	else:
		$Control/SaveLoadLabel.text = 'Load'
		$Control/SaveInfoPanel.hide()
		
	
func is_save_mode() -> bool:
	return _save_data != null
		
	
func update_saves_cache():
	_saves_cache.clear()
	var savedir := DirAccess.open(SAVE_PATH)
	savedir.list_dir_begin()
	
	var filename := savedir.get_next()
	while filename != '':
		var index := filename_slot(filename)
		if index == -1:
			printerr('savefile not recognized: %s' % filename)
		else:
			_saves_cache[index] = SAVE_PATH + filename
		filename = savedir.get_next()
		
	savedir.list_dir_end()
	
	
func scene_exit():
	# not necessary because we're getting freed anyway but it's better
	# to cleanup ourselves just in case the strategy changes
	_saves_cache.clear()
	
	
func get_save_slot(slot: int) -> SaveSlot:
	var index := (slot - 1) % 10
	# TODO figure out the maths on this, my brain aches
	var reindex := {0:0, 1:2, 2:4, 3:6, 4:8, 5:1, 6:3, 7:5, 8:7, 9:9}
	return $GridContainer.get_child(reindex[index])


func load_slot_page(slot: int):
	load_page((clampi(slot, 1, max_pages*10 + 1) - 1)/10)
	
	
func load_page(page: int):
	assert(page >= 0 and page < max_pages)
	for i in range(page*10 + 1, page*10 + 11):
		# update the slot
		var slot := get_save_slot(i)
		slot.slot = i
		slot.release_focus()
		
		# try loading save info
		if _saves_cache.has(i):
			var save := ResourceLoader.load(_saves_cache[i])
			if save:
				slot.initialize(save, Game.persistent.newest_save_slot == i)
				continue
			else:
				printerr('failed to load save %s' % _saves_cache[i])
		
		# load null
		slot.initialize(null, false)
	_current_page = page
	
	
func interact_load_from_slot(slot: int):
	var save := ResourceLoader.load(_saves_cache[slot])
	assert(save, 'save should have been verified to work at page load, bug?')
	Game._load_state(save)
	
	
func interact_save_to_slot(slot: int):
	# TODO if occupied, ask if overwrite
	
	_save_data.slot = slot
	var err := ResourceSaver.save(_save_data, state_filename(_save_data), ResourceSaver.SaverFlags.FLAG_COMPRESS)
	if err:
		printerr('unable to save data: %s (code %s)' % [state_filename(_save_data), err])
		return
		
	Game.persistent.newest_save_slot = slot
	
	update_saves_cache()
	load_slot_page(slot)
	
	
func interact_delete_slot(slot: int):
	# TODO confirm delete
	# TODO if newest save, update newest
	var savedir := DirAccess.open(SAVE_PATH)
	if FileAccess.file_exists(slot_filename(slot)):
		savedir.remove(slot_filename(slot))
		
	update_saves_cache()
	load_slot_page(slot)


func _slot_pressed(slot: SaveSlot):
	if is_save_mode():
		interact_save_to_slot(slot.slot)
	else:
		interact_load_from_slot(slot.slot)
	
	
func _slot_closed_pressed(slot: SaveSlot):
	interact_delete_slot(slot.slot)
	
	
func _page_button_pressed(page: int):
	load_page(page)


func _on_close_button_pressed():
	scene_return()
	
