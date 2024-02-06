extends GameScene

const SAVE_PATH := 'user://saves/'


@export var max_pages: int = 20

var _save_data: SaveState
var _current_page: int


func _ready():
	var sample_button := $Control/VBoxContainer/SampleButton
	for i in max_pages:
		var btn := sample_button.duplicate()
		btn.text = str((i + 1))
		btn.pressed.connect(_page_button_pressed.bind(i))
		$Control/VBoxContainer.add_child(btn)
	sample_button.queue_free()
	
	for i in range(1, 11):
		var slot := get_save_slot(i)
		slot.pressed.connect(_slot_pressed.bind(slot))
		slot.close_pressed.connect(_slot_closed_pressed.bind(slot))
		
	if Util.is_f6(self):
		print('its f6')
		Game.create_testing_context()
		scene_enter.call_deferred({save_data=Game.create_new_data()})


func _input(event):
	if not is_active():
		return
	if event.is_action_pressed('ui_cancel') or event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		set_process_input(false)
		scene_return()


func scene_enter(kwargs := {}):
	SaveManager.scan_for_changes()
	load_slot_page(Persistent.newest_save_slot)
	
	_save_data = kwargs.get('save_data')
	if is_save_mode():
		$Control/SaveLoadLabel.text = 'Save'
		$Control/SaveInfoPanel.show()
		$Control/SaveInfoPanel/TextureRect.texture = _save_data.preview
	else:
		$Control/SaveLoadLabel.text = 'Load'
		$Control/SaveInfoPanel.hide()
	set_process_input(true)
		
	
func is_save_mode() -> bool:
	return _save_data != null
	
	
func get_save_slot(slot: int) -> SaveSlot:
	var index := (slot - 1) % 10
	# TODO figure out the maths on this, my brain aches
	var reindex := {0:0, 1:2, 2:4, 3:6, 4:8, 5:1, 6:3, 7:5, 8:7, 9:9}
	return $GridContainer.get_child(reindex[index])


@warning_ignore("integer_division")
func load_slot_page(slot: int):
	load_page((clampi(slot, 1, max_pages*10 + 1) - 1)/10)
	
	
func load_page(page: int):
	var button := $Control/VBoxContainer.get_child(page) as Button
	if not button.button_pressed:
		button.button_pressed = true
	
	assert(page >= 0 and page < max_pages)
	for i in range(page*10 + 1, page*10 + 11):
		var slot := get_save_slot(i)
		slot.slot = i
		slot.release_focus()
		
		if SaveManager.is_slot_in_use(i):
			var save := SaveManager.load_from_slot(i)
			if save:
				slot.initialize(save, Persistent.newest_save_slot == i)
				continue
		
		slot.initialize(null, false)
	_current_page = page
	
	
func interact_load_from_slot(slot: int):
	if not SaveManager.is_slot_in_use(slot):
		return
		
	var save := SaveManager.load_from_slot(slot)
	assert(save, 'save should have been verified to work at load_page, bug?')
	Game.load_state(save)
	
	
func interact_save_to_slot(slot: int):
	# TODO if occupied, ask if overwrite
	SaveManager.save_to_slot(_save_data, slot)
	load_slot_page(slot)
	
	
func interact_delete_slot(slot: int):
	# TODO confirm delete
	# TODO if newest save, update newest
	SaveManager.clear_slot(slot)
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
	

func _on_wipe_data_button_pressed():
	SaveManager.clear_saves()
	load_page(_current_page)
	
