class_name Territory

var name: String
var mapscene: String
var adjacent: Array[int]
var units: Array[String]
var owner: String

func _init(name: String):
	self.name = name
	self.owner = ""
	match name:
		"Unused":
			self.mapscene = ""
			self.adjacent = []
			self.units = []
		"Zetennu":
			self.mapscene = ""
			self.adjacent = [2]
			self.units = []
		"Neru-Khisi":
			self.mapscene = ""
			self.adjacent = [1, 3, 7]
			self.units = []
		"Satayi":
			self.mapscene = ""
			self.adjacent = [2, 4]
			self.units = []
		"Khel-Et":
			self.mapscene = ""
			self.adjacent = [3, 5]
			self.units = []
		"Forsaken Temple":
			self.mapscene = ""
			self.adjacent = [4, 6]
			self.units = []
		"Medjed's Beacon":
			self.mapscene = ""
			self.adjacent = [5, 7, 9]
			self.units = []
		"Fort Zaka":
			self.mapscene = ""
			self.adjacent = [2, 6, 8]
			self.units = []
		"Nekhet's Rest":
			self.mapscene = ""
			self.adjacent = [7]
			self.units = []
		"Ruins of Atesh":
			self.mapscene = ""
			self.adjacent = [6]
			self.units = []
		"Cursed Stronghold":
			self.mapscene = ""
			self.adjacent = []
			self.units = []
		_:
			assert(false, "Invalid territory name '" + name + "'")

func get_adjacent() -> Array[Territory]:
	# this needs indirection because we cannot directly
	# reference territory nodes during initialization
	# when some of them hasn't been constructed yet
	var re: Array[Territory] = []
	re.resize(adjacent.size())
	for i in range(adjacent.size()):
		re[i] = all[adjacent[i]]
	return re

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
	Unused,
	Zetennu,
	Neru_Khisi,
	Satayi,
	Khel_Et,
	Forsaken_Temple,
	Medjeds_Beacon,
	Fort_Zaka,
	Nekhets_Rest,
	Ruins_of_Atesh,
	Cursed_Stronghold,
]

static func get_territory(name: String) -> Territory:
	for e in all:
		if e.name == name: return e
	assert(false, "get_territory null")
	return null
