@tool
extends Control

@export var text: String:
	set(value):
		text = value
		_update_text_next_frame()
			
@export var center_x: bool = true:
	set(value):
		center_x = value
		_update_text_next_frame()

@export var center_y: bool = true:
	set(value):
		center_y = value
		_update_text_next_frame()

@export_subgroup("Font")

@export var font: Font:
	set(value):
		font = value
		_update_text_next_frame()

@export var font_size: int:
	set(value):
		font_size = value
		_update_text_next_frame()
		
@export var font_color: Color:
	set(value):
		font_color = value
		_update_text_next_frame()
		
@export var outline_size: int:
	set(value):
		outline_size = value
		_update_text_next_frame()
		
@export var outline_color: Color:
	set(value):
		outline_color = value
		_update_text_next_frame()
		
@export var caps_size: int:
	set(value):
		caps_size = value
		_update_text_next_frame()
			
		
# This is called once in the frame where the label is marked as needs
# updating. This is done this way so all the changes are applied in one
# go, once per frame, because bbcode parsing is quite expensive.
func _process(_delta):
	_update_text(text)
	set_process(false)
	

func _update_text_next_frame():
	set_process(true)


func _update_text(new_text: String):
	$VBoxContainer/RichTextLabel.clear()
	$VBoxContainer/RichTextLabel.text = ""
	
	# horizontal centering does not have push_center so we
	# have to manually insert the bbcode 
	if center_x:
		$VBoxContainer/RichTextLabel.append_text("[center]")
		
	# font
	$VBoxContainer/RichTextLabel.push_font(font, font_size)
	$VBoxContainer/RichTextLabel.push_color(font_color)
	$VBoxContainer/RichTextLabel.push_outline_color(outline_color)
	$VBoxContainer/RichTextLabel.push_outline_size(outline_size)
	
	# capitalization
	var caps: Array[String] = []
	var insert_caps = func():
		if not caps.is_empty():
			$VBoxContainer/RichTextLabel.push_font_size(caps_size)
			for c in caps:
				$VBoxContainer/RichTextLabel.append_text(c)
			$VBoxContainer/RichTextLabel.pop()
			caps.clear()
	for c in new_text:
		var upper = c.to_upper()
		if c == upper:
			caps.append(upper)
		else:
			insert_caps.call()
			$VBoxContainer/RichTextLabel.append_text(upper)
	insert_caps.call() # handle trailing caps
	$VBoxContainer/RichTextLabel.pop()
	
	# centering vertically is not supported so we put it
	# in a container supperts centering vertically. this
	# also has to be done last after everything is parsed
	if center_y:
		$VBoxContainer.alignment = VBoxContainer.ALIGNMENT_CENTER
	else:
		$VBoxContainer.alignment = VBoxContainer.ALIGNMENT_BEGIN
	
