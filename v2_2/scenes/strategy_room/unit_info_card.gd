extends VBoxContainer


signal basic_attack_button_toggled(toggle: bool)
signal special_attack_button_toggled(toggle: bool)


@onready var basic_attack_button: Button = %BasicAttackButton
@onready var special_attack_button: Button = %SpecialAttackButton


func _ready() -> void:
	basic_attack_button.toggled.connect(_on_basic_attack_button_toggled)
	special_attack_button.toggled.connect(_on_special_attack_button_toggled)


func render_unit(unit: Unit, show_growth: bool) -> void:
	# basic unit info
	%NameLabel.text = unit.display_name()
	%AvatarLabel.text = unit.chara().avatar
	%TitleLabel.text = unit.chara().title

	# bond level
	for i in %StarContainer.get_child_count():
		if i <= unit.get_bond():
			%StarContainer.get_child(i).texture = load('res://scenes/overworld/data/star-filled.svg')
		else:
			%StarContainer.get_child(i).texture = load('res://scenes/overworld/data/star.svg')
			
	# stats
	for stat_line in %StatLines.get_children():
		if show_growth:
			stat_line.render_stat_growth(unit)
		else:
			stat_line.render_stat(unit)
	
	# attacks
	basic_attack_button.disabled = unit.basic_attack() == null
	if unit.basic_attack():
		basic_attack_button.text = unit.basic_attack().name
		%BasicAttackContainer.modulate = Color.WHITE 
	else:
		%BasicAttackContainer.modulate = Color.TRANSPARENT 

	special_attack_button.disabled = unit.special_attack() == null
	if unit.special_attack():
		special_attack_button.text = unit.special_attack().name
		if unit.is_special_unlocked():
			%SpecialUnlockLabel.modulate = Color(0.569, 1.847, 0.686)
		else:
			%SpecialUnlockLabel.modulate = Color.TRANSPARENT 
		%SpecialAttackContainer.modulate = Color.WHITE 
	else:
		%SpecialAttackContainer.modulate = Color.TRANSPARENT 


func _on_basic_attack_button_toggled(toggled_on: bool) -> void:
	basic_attack_button_toggled.emit(toggled_on)


func _on_special_attack_button_toggled(toggled_on: bool) -> void:
	special_attack_button_toggled.emit(toggled_on)
