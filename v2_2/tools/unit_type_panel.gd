class_name UnitTypePanel
extends Control


func initialize(u: UnitType):
	clear_info()
	if not u:
		return
	$VBoxContainer2/Label.text = str(u.stats.maxhp)
	if u.stats.maxhp <= 0:
		$VBoxContainer2/Label.modulate()
	$VBoxContainer2/Label2.text = str(u.stats.mov)
	$VBoxContainer2/Label3.text = str(u.stats.dmg)
	$VBoxContainer2/Label4.text = str(u.stats.rng)
	
	$VBoxContainer3/Label.text = stat_growth_text(u.stat_growth_1.maxhp)
	$VBoxContainer3/Label2.text = stat_growth_text(u.stat_growth_1.mov)
	$VBoxContainer3/Label3.text = stat_growth_text(u.stat_growth_1.dmg)
	$VBoxContainer3/Label4.text = stat_growth_text(u.stat_growth_1.rng)
	
	$VBoxContainer4/Label.text = stat_growth_text(u.stat_growth_2.maxhp)
	$VBoxContainer4/Label2.text = stat_growth_text(u.stat_growth_2.mov)
	$VBoxContainer4/Label3.text = stat_growth_text(u.stat_growth_2.dmg)
	$VBoxContainer4/Label4.text = stat_growth_text(u.stat_growth_2.rng)
	
	$Label.text = u.basic_attack.name if u.basic_attack else 'none'
	$Label/Label3.text = u.basic_attack.description if u.basic_attack else ''
	
	$Label2.text = u.special_attack.name if u.special_attack else 'none'
	$Label2/Label3.text = u.special_attack.description if u.special_attack else ''
	
	
func stat_growth_text(v: int) -> String:
	return str(v) if v != 0 else ''
	

func clear_info():
	$VBoxContainer2/Label.text = ''
	$VBoxContainer2/Label2.text = ''
	$VBoxContainer2/Label3.text = ''
	$VBoxContainer2/Label4.text = ''
	
	$VBoxContainer3/Label.text = ''
	$VBoxContainer3/Label2.text = ''
	$VBoxContainer3/Label3.text = ''
	$VBoxContainer3/Label4.text = ''
	
	$VBoxContainer4/Label.text = ''
	$VBoxContainer4/Label2.text = ''
	$VBoxContainer4/Label3.text = ''
	$VBoxContainer4/Label4.text = ''
	
	$Label.text = ''
	$Label/Label3.text = ''
	
	$Label2.text = ''
	$Label2/Label3.text = ''
	
