class_name AttackCard
extends Control


@onready var attack_icon := %AttackIcon
@onready var attack_name_label := %AttackNameLabel
@onready var self_label := %SelfLabel
@onready var ally_label := %AllyLabel
@onready var enemy_label := %EnemyLabel
@onready var attack_description_label := %AttackDescriptionLabel
@onready var multicast_label := %MulticastLabel
@onready var attack_shape_widget: AttackShapeWidget = %AttackShapeWidget


func render_attack(unit: Unit, attack: Attack):
	# TODO attack icons
	# attack_icon.texture = attack.icon
	attack_name_label.text = attack.name
	self_label.modulate = Color.WHITE if Attack.TARGET_SELF & attack.target_flags else Color(1, 1, 1, 0.455)
	ally_label.modulate = Color.WHITE if Attack.TARGET_ALLY & attack.target_flags else Color(1, 1, 1, 0.455)
	enemy_label.modulate = Color.WHITE if Attack.TARGET_ENEMY & attack.target_flags else Color(1, 1, 1, 0.455)
	attack_description_label.text = attack.get_formatted_description({
		unit = unit,
	})
	attack_shape_widget.render_attack_shape(attack)
	multicast_label.text = '%dx' % (attack.multicast + 1)
	show()
