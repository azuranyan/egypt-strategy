@tool
extends PanelContainer


@export var stat: StringName:
	set(value):
		stat = value
		if not is_node_ready():
			await ready
		stat_name_label.text = get_stat_string()

@export var custom_stat_text: String:
	set(value):
		custom_stat_text = value
		if not is_node_ready():
			await ready
		stat_name_label.text = get_stat_string()


@export_group("Stat Value")

@export var stat_value: int:
	set(value):
		stat_value = value
		if not is_node_ready():
			await ready
		stat_value_label.text = str(stat_value)

@export var stat_modifier_value: int:
	set(value):
		stat_modifier_value = value
		if not is_node_ready():
			await ready
		if stat_modifier_value != 0:
			stat_modifier_label.text = '%+d' % stat_modifier_value
			if stat_modifier_value > 0:
				stat_modifier_label.modulate = Color.GREEN
			else:
				stat_modifier_label.modulate = Color.RED
		else:
			stat_modifier_label.text = ' '


@onready var stat_name_label := %StatNameLabel
@onready var stat_value_label := %StatValueLabel
@onready var stat_modifier_label := %StatModifierLabel


func get_stat_string() -> String:
	return custom_stat_text if custom_stat_text else stat.to_upper()


func render_stat(unit: Unit) -> void:
	stat_value = unit.base_stats()[stat]


func render_stat_growth(unit: Unit) -> void:
	render_stat(unit)

	var stat_growth := 'stat_growth_%d' % (unit.get_bond() + 1)

	if stat_growth in unit.unit_type():
		stat_modifier_value = unit.unit_type().get(stat_growth)[stat]
	else: 
		stat_modifier_value = 0
