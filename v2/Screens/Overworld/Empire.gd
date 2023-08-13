class_name Empire

var leader: String
var territories: Array[Territory]


func get_adjacent() -> Array[Territory]:
	var re: Array[Territory] = []
	var tmp: Array[int] = []
	# append everything
	for e in territories:
		tmp.append_array(e.adjacent)
	# add unique
	for i in tmp:
		if Territory.all[i] not in re:
			re.append(Territory.all[i])
	return re
	
