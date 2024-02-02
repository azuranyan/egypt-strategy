class_name CharacterInfoPanel
extends Control



func initialize(chara: CharacterInfo):
	clear_info()
	if not chara:
		return
	if chara.gender == 'F':
		$GenderIcon.texture = preload("res://tools/female-icon.png")
	else:
		$GenderIcon.texture = preload("res://tools/Male-icon.png")
	$AspectRatioContainer/TextureRect.texture = chara.portrait
	$MapColorRect.color = chara.map_color
	$NameLabel.text = chara.name
	$AvatarLabel.text = chara.avatar
	$TitleLabel.text = chara.title


func clear_info():
	$GenderIcon.texture = preload("res://tools/female-icon.png")
	$AspectRatioContainer/TextureRect.texture = preload("res://units/placeholder/placeholder.webp")
	$MapColorRect.color = Color.BLACK
	$NameLabel.text = 'Name'
	$AvatarLabel.text = 'Avatar'
	$TitleLabel.text = 'Title'
	
