extends GameScene


signal _hold_finished


const DEFAULT_TEXT_SPEED := 30.0
const DEFAULT_TEXT_FADE_DURATION := 0.5


@export_range(10, 100) var text_speed: float = DEFAULT_TEXT_SPEED
@export_range(0.01, 2) var text_fade_duration: float = DEFAULT_TEXT_FADE_DURATION

@export_group('Connections')
@export var background: TextureRect
@export var vignette: TextureRect
@export var text_label: RichTextLabel
@export var panel: Control
@export var hold_timer: Timer
@export var skip_button: Button


var slide_script := \
"""
background="res://events/dungeon_entrance.jpg"

fade_in=0.7

In the mystical world of Khemia, dozens of gods and goddesses vy for power.
Lands have been destroyed and made anew countless times.

As a means to end this destruction, the Creator God designs a contest.
He creates a magical artefact, the Eye of the Conqueror, and sends it down to the mortal realm.

The Gods, now forbidden from the realm, must imbue chosen Avatars with their spirits to fight on their behalf.
The conqueror of all lands will claim the Eye, and all defeated Avatars must yield their land and loyalty to the victors. *No murder

In a feat of deception, the Dark Serpent, Apophis, seizes the Eye of the Conqueror.
Along with her resentful mother, Kauket, she taints the Eye with sinister power.
Using this power, she launches her assault on the lands.

Such a heretical, unholy god must never be allowed to rule Khemia.
The Sun God Ra descends to the battlefield, aiming to unite the Avatars in a crusade against the Serpent.
You awaken to his call and begin your quest.

Can you bring a nation of warring gods to heel?
Or will you vanish into the shifting sands?
"""

var slides: PackedStringArray = slide_script.split("\n")

var should_stop: bool = false


func _ready() -> void:
	text_label.clear()
	panel.gui_input.connect(_on_panel_gui_input)
	hold_timer.timeout.connect(emit_signal.bind('_hold_finished'))
	skip_button.pressed.connect(skip_slides)

	play_slides.call_deferred()


func play_slides() -> void:
	for slide in slides:
		if should_stop:
			break
		var text := slide.strip_edges()
		var key := text.substr(0, slide.find("=")).strip_edges()
		var value := text.substr(slide.find("=") + 1).strip_edges()

		if text.is_empty():
			continue

		match key:
			'background':
				background.texture = load(value.trim_prefix('\"').trim_suffix('\"'))
			'vignette':
				vignette.visible = value == 'true'
			'speed':
				text_speed = value.to_float() if value.is_valid_float() else DEFAULT_TEXT_SPEED
			'wait':
				var wait_time := value.to_float() if value.is_valid_float() else 0.0
				if wait_time > 0.0:
					await get_tree().create_timer(wait_time).timeout
			'fade_in':
				await fade_in(panel, value.to_float() if value.is_valid_float() else DEFAULT_TEXT_FADE_DURATION).finished
			'fade_out':
				await fade_out(panel, value.to_float() if value.is_valid_float() else DEFAULT_TEXT_FADE_DURATION).finished
			_:
				if text:
					await play_text(text)
	fade_out(panel, DEFAULT_TEXT_FADE_DURATION)
	should_stop = false

	SceneManager.load_new_scene('res://scenes/new_game/independent_story_event_scene.tscn', 'fade_to_black', {next_scene=SceneManager.scenes.overworld})


func skip_hold() -> void:
	if hold_timer.time_left > 0.0:
		_hold_finished.emit()
		hold_timer.stop()


func skip_slides() -> void:
	skip_hold()
	should_stop = true
	if get_viewport().gui_get_focus_owner() == skip_button:
		skip_button.release_focus()
				

func play_text(text: String) -> void:
	text_label.text = '[center]' + text + '[/center]'
	await fade_in(text_label, text_fade_duration).finished
	hold_timer.wait_time = text.length()/text_speed
	hold_timer.start()
	await _hold_finished
	await fade_out(text_label, text_fade_duration).finished


func fade_in(what: Variant, duration: float, property := 'modulate') -> Tween:
	what.set(property, Color.TRANSPARENT)
	var tween := create_tween()
	tween.tween_property(what, property, Color.WHITE, duration)
	return tween


func fade_out(what: Variant, duration: float, property := 'modulate') -> Tween:
	what.set(property, Color.WHITE)
	var tween := create_tween()
	tween.tween_property(what, property, Color.TRANSPARENT, duration)
	return tween


func _on_panel_gui_input(event: InputEvent) -> void:
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		skip_hold()
		panel.accept_event()