extends Node


func _ready():
	#Globals.scene_queue.append('start')
	Globals.scene_started.connect(play_scene)
	OverworldEvents.boss_defeated.connect(func(): Globals.scene_queue.append('gameover win'))
	OverworldEvents.player_defeated.connect(func(): Globals.scene_queue.append('gameover loss'))
	
	
func play_scene(scene: String):
	self.visible = true
	# stub
	match scene:
		'start':
			await cps_text('This is a test')
			await cps_text('Just wait')
			await cps_text('Only 2s per message')
		'gameover win':
			await cps_text('Cengerts!!! The Winner is...')
			if not $AudioStreamPlayer.is_playing():
				$AudioStreamPlayer.stream = preload("res://you.mp3")
				$AudioStreamPlayer.play()
		'gameover loss':
			await cps_text('YOU ARE')
			await cps_text('deFEETed')
	self.visible = false
	Globals.notify_end_scene()
	
			
func cps_text(text: String):
	$ColorRect/RichTextLabel.text = text
	await get_tree().create_timer(2).timeout
