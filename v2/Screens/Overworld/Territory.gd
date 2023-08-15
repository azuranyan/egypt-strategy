class_name Territory

var name: String
var battlemap_id: String # id of the battle scene loaded by battle manager
var adjacent: Array[int]
var units: Array[Unit] # territory owns this
var owner: Empire


func _init(name: String):
	self.name = name
	self.owner = null
	# if adjusted, adjust everything with territory_names
	# grep territory_names
	match name:
		"Unused":
			self.battlemap_id = ""
			self.adjacent = []
			self.units = []
		"Zetennu":
			self.battlemap_id = ""
			self.adjacent = [2]
			self.units = []
		"Neru-Khisi":
			self.battlemap_id = ""
			self.adjacent = [1, 3, 7]
			self.units = []
		"Satayi":
			self.battlemap_id = ""
			self.adjacent = [2, 4]
			self.units = []
		"Khel-Et":
			self.battlemap_id = ""
			self.adjacent = [3, 5]
			self.units = []
		"Forsaken Temple":
			self.battlemap_id = ""
			self.adjacent = [4, 6]
			self.units = []
		"Medjed's Beacon":
			self.battlemap_id = ""
			self.adjacent = [5, 7, 9]
			self.units = []
		"Fort Zaka":
			self.battlemap_id = ""
			self.adjacent = [2, 6, 8]
			self.units = []
		"Nekhet's Rest":
			self.battlemap_id = ""
			self.adjacent = [7]
			self.units = []
		"Ruins of Atesh":
			self.battlemap_id = ""
			self.adjacent = [6]
			self.units = []
		"Cursed Stronghold":
			self.battlemap_id = ""
			self.adjacent = []
			self.units = []
		_:
			assert(false, "Invalid territory name '" + name + "'")


## Returns true if territory is player owned.
func is_player_owned() -> bool:
	return owner.is_player_owned()
	
	
## Returns a new(!!) list of adjacent territories.
func get_adjacent() -> Array[Territory]:
	# this needs indirection because we cannot directly
	# reference territory nodes during initialization
	# when some of them hasn't been constructed yet
	var re: Array[Territory] = []
	re.resize(adjacent.size())
	for i in range(adjacent.size()):
		re[i] = all[adjacent[i]]
	return re


## Returns a new(!!) list of leader units.
func get_leaders() -> Array[Unit]:
	var re: Array[Unit] = []
	for e in units:
		if e.is_leader():
			re.append(e)
	return re
	

## Returns the force strength string.
func get_force_strength() -> String:
	# TODO add ratings later
	return "Full"


## Returns the index of the territory.
func get_index() -> int:
	for i in range(Territory.all.size()):
		if Territory.all[i] == self:
			return i
		
	assert(false, "trying to get territory index of an unrecognized territory")
	return 0
	
	
## Connects the territory to another.
func connect_adjacent(other: Territory):
	_connect_adjacent(other)
	other._connect_adjacent(self)

func _connect_adjacent(other: Territory):
	var i := get_index()
	if i not in other.adjacent:
		other.adjacent.append(i)
		
################################################################################
## Territory definition
################################################################################

static var Unused := Territory.new("Unused")
static var Zetennu := Territory.new("Zetennu")
static var Neru_Khisi := Territory.new("Neru-Khisi")
static var Satayi := Territory.new("Satayi")
static var Khel_Et := Territory.new("Khel-Et")
static var Forsaken_Temple := Territory.new("Forsaken Temple")
static var Medjeds_Beacon := Territory.new("Medjed's Beacon")
static var Fort_Zaka := Territory.new("Fort Zaka")
static var Nekhets_Rest := Territory.new("Nekhet's Rest")
static var Ruins_of_Atesh := Territory.new("Ruins of Atesh")
static var Cursed_Stronghold := Territory.new("Cursed Stronghold")

static var all: Array[Territory] = [
	Unused, # 0
	Zetennu,
	Neru_Khisi,
	Satayi,
	Khel_Et,
	Forsaken_Temple,
	Medjeds_Beacon,
	Fort_Zaka,
	Nekhets_Rest,
	Ruins_of_Atesh,
	Cursed_Stronghold, # 10
]

static func get_territory(name: String) -> Territory:
	for e in all:
		if e.name == name: return e
	assert(false, "get_territory <%s> null" % name)
	return null
