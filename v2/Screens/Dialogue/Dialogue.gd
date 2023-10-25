extends Node


func _ready():
	Globals.scene_queue.append('start')
	Globals.scene_started.connect(play_scene)
	
	
func play_scene(scene: String):
	self.visible = true
	# stub
	match scene:
		'start':
			await cps_text('This is a test')
			await cps_text('Just wait')
			await cps_text('Only 2s per message')
	self.visible = false
	Globals.notify_end_scene()
	
			
func cps_text(text: String):
	$ColorRect/RichTextLabel.text = text
	await get_tree().create_timer(2).timeout
