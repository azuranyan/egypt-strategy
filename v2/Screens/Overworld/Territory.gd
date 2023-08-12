class_name Territory

static var _data_record := {}

class TerritoryData:
	var name: String
	var mapscene: String
	var adjacent: Array[Territory]
	var units: Array[String]
	
	func _init(name: String, mapscene: String):
		self.name = name
		self.mapscene = mapscene

static var _data_loaded := false

static func _ready():
	print('static ready territory')
	# for now they're all separated to easily be spotted later
	# when we finally decide when/where/how to put and initialize the data

static func load_data():
	if not _data_loaded:
		_load_territory_data()
		#_load_territory_adjacency()
		_load_territory_units()
		_data_loaded = true
	
static func _add_territory_data(name: String, mapscene: String):
	_data_record[name] = TerritoryData.new(name, mapscene)
	
static func _load_territory_data():
	_add_territory_data("unused", "")
	
	_add_territory_data("Zetennu", "")
	_add_territory_data("Neru-Khisi", "")
	_add_territory_data("Satayi", "")
	_add_territory_data("Khel-Et", "")
	_add_territory_data("Medjed's Beacon", "")
	
	_add_territory_data("Fort Zaka", "")
	_add_territory_data("Forsaken Temple", "")
	_add_territory_data("Ruins of Atesh", "")
	_add_territory_data("Nekhet's Rest", "")
	
	_add_territory_data("Cursed Stronghold", "")

static func _load_territory_adjacency():
	# graph taken directly from old code hence the difference in ordering
	var territory_names := [
			"unused",
			
			"Zetennu",
			"Neru-Khisi",
			"Satayi",
			"Khel-Et",
			"Forsaken Temple",
			
			"Medjed's Beacon",
			"Fort Zaka",
			"Nekhet's Rest",
			"Ruins of Atesh",
		]
		
	var graph = { 
		# These describe the connections to other nodes, 
		# the first node is Zetennu and it is connected to 2 which is Neru-Khisi
		# There is a list of locations that is defined in Overworld.gd that connects the numbers to locations, this needs to be done there.
		1: [2], # Zetennu
		2: [1, 3, 7], # Neru-Khisi
		3: [2, 4], # Satayo
		4: [3, 5], # Khel-Et
		5: [4, 6], # ForsakenTemple
		6: [5, 7, 9], # Medjed'sBeacon
		7: [2, 6, 8], # FortZaka
		8: [7], # Nekhet'sRest
		9: [6], # RuinsOfAtesh
	}

	for i in range(1, 9 + 1):
		var adj: Array[Territory] = []
		for x in graph[i]:
			adj.append(_data_record[territory_names[x]])
		_data_record[territory_names[i]].adjacent = adj
	
static func _load_territory_units():
	for territory_name in _data_record:
		var arr : Array[String] = []
		_data_record[territory_name].units = arr
	

	var name: String
	var pos: Vector2
	var mapscene: String
	var adjacent: Array[String]
	var units: Array[String]

	
var _data: TerritoryData

var owner: String

var name: String:
	get:
		return name
	set(value):
		name = value
		_data = _data_record[name]
		
var mapscene: String:
	get:
		return _data.mapscene
		
var adjacent: Array[Territory]:
	get:
		return _data.adjacent
		
var units: Array[String]:
	get:
		return _data.units

func _init(name: String, owner: String=""):
	load_data()
	self._data = _data_record[name]
	self.owner = owner
	
