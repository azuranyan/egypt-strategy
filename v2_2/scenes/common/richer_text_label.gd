class_name RicherTextLabel
extends RichTextLabel


enum BigCaps {
	## No big caps.
	NONE,

	## Uppercase letters are made big.
	UPPERCASE,

	## Uppercase letters from [code]text.capitalize()[/code] are made big.
	CAPITALIZED,
}


## Makes uppercase letters bigger.
@export var big_caps: BigCaps = BigCaps.UPPERCASE

## Multiplier for the font size of [code]big_caps[/code] letters.
@export_range(1.0, 100.0) var big_caps_size: float = 1.5

## Forces everything to be all caps. The font size of uppercase letters formed this way follows [code]big_caps[/code].
@export var all_caps: bool

## Whether to center text.
@export var center_text: bool

## Pre-formatted text.
@export var format: String


## Whether to have a darkened outline.
##
## This will modify `theme_override_color/font_outline_color`.
@export_range(0.0, 1.0) var darkened_outline: float:
	set(value):
		darkened_outline = value
		if not is_node_ready():
			await ready
			
		if darkened_outline > 0.0:
			add_theme_color_override('font_outline_color', get_font_color().darkened(darkened_outline))
		else:
			remove_theme_color_override('font_outline_color')


var _raw_text: String
var _should_update: bool = true


func _process(_delta: float) -> void:
	#if _should_update:
	#	update_text(text)
	#	return

	# we can't do the _raw_text == text because when text gets updated we need to process it again
	if not _should_update and text == '':
		return

	_should_update = false
	# since there are no signals or callbacks for text changes,
	# we have to poll for changes in _process
	update_text(text)
	

## Updates the text stream.
##
## This will effectively clear [code]text[/code] and applies its own internal processing.
func update_text(new_text: String) -> void:
	_raw_text = new_text

	var formatted_text := format.format({text = _raw_text}) if format else _raw_text

	# "setting text to an empty string also clears the stack" isn't true
	clear()
	text = ''

	var darken_outline := darkened_outline > 0.0

	if center_text: append_text('[center]')
	if darken_outline: push_outline_color(get_font_color().darkened(darkened_outline))
	
	if big_caps == BigCaps.NONE:
		add_text(formatted_text)
	else:
		var processed_text := formatted_text if big_caps == BigCaps.UPPERCASE else formatted_text.capitalize()
		var big_font_size := int(big_caps_size * get_font_size())
		var caps: Array[String] = []
		var flush_caps := func():
			if caps.is_empty():
				return
			push_font_size(big_font_size)
			add_text(''.join(caps))
			pop()
			caps.clear()

		# capitalize
		for c in processed_text:
			var is_caps := c.is_valid_identifier() and c.to_upper() == c
			if is_caps:
				caps.append(c)
			else:
				flush_caps.call()
				add_text(c.to_upper() if all_caps else c)
		flush_caps.call()

	if darken_outline: pop()


func get_font_size() -> int:
	var override = get('theme_override_font_sizes/normal_font_size')
	if override:
		return override
	return get_theme_default_font_size()


func get_font_color() -> Color:
	var override = get('theme_override_colors/default_color')
	if override:
		return override
	return get_theme_color('default_color', 'RichTextLabel')