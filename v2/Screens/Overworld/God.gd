class_name God

# Proper name of the gods
var name: String

# Flavor text from the game doc, unused
var gender: String

# Full avatar name
var avatar: String

# Flavor text
var title: String

# Will be set to actual colors later
var map_color: String

# Path to portrait image
var portrait: String

# Path to baked button image
var button_image: String

# Path to baked button mask
var button_mask: String

# Returns just the avatar name (or Dark Serpent)
func get_avatar_name() -> String:
	if avatar == 'Dark Serpent':
		return avatar
	else:
		# [0] "Avatar/Priestess of"
		# [1] "Osiris"
		return avatar.rsplit(" ", true, 1)[-1]

	
	
static func register_god(name: String, gender: String, avatar: String,
		title: String,
		map_color: String,
		portrait: String,
		button_image: String,
		button_mask: String
	) -> God:
		
	var god = God.new()
	god.name = name
	god.gender = gender
	god.avatar = avatar
	god.title = title
	god.map_color = map_color
	god.portrait = portrait
	god.button_image = button_image
	god.button_mask = button_mask
	
	record[name] = god
	return god

### Player
static var PlayerF := register_god("Lysandra", "F", "Avatar of Ra",
	"Supreme Sun God",
	"Orange",
	"res://Screens/Overworld/Portraits/Player.png",
	"res://Screens/Overworld/ButtonImage/Player.png",
	"res://Screens/Overworld/ButtonImage/Player.bmp")
#static var PlayerM := register_god("Lysandra", "M", "Avatar of Ra",
#	"Supreme Sun God",
#	"Orange",
#	"res://Screens/Overworld/Portraits/Player.png", # TODO
#	"res://Screens/Overworld/ButtonImage/Player.png",
#	"res://Screens/Overworld/ButtonImage/Player.bmp")
static var Player := PlayerF
	
### Maia & Menna
static var Maia := register_god("Maia", "F", "Avatar of Osiris",
	"Dualistic Death God",
	"Emerald Green",
	"res://Screens/Overworld/Portraits/Maia.png",
	"res://Screens/Overworld/ButtonImage/Maia.png",
	"res://Screens/Overworld/ButtonImage/Maia.bmp")
#static var Menna := register_god("Menna", "M", "Avatar of Osiris",
#	"Dualistic Death God",
#	"Emerald Green", 
#	"res://Screens/Overworld/Portraits/Alara.png", # TODO
#	"res://Screens/Overworld/ButtonImage/Alara.png",
#	"res://Screens/Overworld/ButtonImage/Alara.bmp")

### Zahra
static var ZahraF := register_god("Zahra", "F", "Avatar of Sobek",
	"Cruel Crocodile God",
	"Teal",
	"res://Screens/Overworld/Portraits/ZahraF.png",
	"res://Screens/Overworld/ButtonImage/ZahraM.png", # TODO
	"res://Screens/Overworld/ButtonImage/ZahraM.bmp")
#static var ZahraM := register_god("Zahra", "M", "Avatar of Sobek",
#	"Cruel Crocodile God",
#	"Teal",
#	"res://Screens/Overworld/Portraits/ZahraM.png",
#	"res://Screens/Overworld/ButtonImage/ZahraM.png", # TODO
#	"res://Screens/Overworld/ButtonImage/ZahraM.bmp")
static var Zahra := ZahraF

### Ishtar
static var IshtarF := register_god("Ishtar", "F", "Avatar of Isis",
	"Selfless Scorpion Goddess",
	"Purple",
	"res://Screens/Overworld/Portraits/IshtarF.png",
	"res://Screens/Overworld/ButtonImage/IshtarM.png", # TODO
	"res://Screens/Overworld/ButtonImage/IshtarM.bmp")
#static var IshtarM := register_god("Ishtar", "M", "Avatar of Isis",
#	"Selfless Scorpion Goddess",
#	"Purple",
#	"res://Screens/Overworld/Portraits/IshtarM.png",
#	"res://Screens/Overworld/ButtonImage/IshtarM.png", # TODO
#	"res://Screens/Overworld/ButtonImage/IshtarM.bmp")
static var Ishtar := IshtarF

### Alara
static var Alara := register_god("Alara", "M", "Avatar of Horus",
	"Boastful Bird God",
	"Sapphire Blue",
	"res://Screens/Overworld/Portraits/Alara.png",
	"res://Screens/Overworld/ButtonImage/Alara.png",
	"res://Screens/Overworld/ButtonImage/Alara.bmp")

### Sutekh
static var Sutekh := register_god("Sutekh", "M", "Avatar of Seth",
	"Ferocious Fox God",
	"Red",
	"res://Screens/Overworld/Portraits/Sutekh.png",
	"res://Screens/Overworld/ButtonImage/Sutekh.png",
	"res://Screens/Overworld/ButtonImage/Sutekh.bmp")

### Eirene
static var Eirene := register_god("Eirene", "F", "Avatar of Hathor",
	"Caring Cow Goddess",
	"Raspberry Pink",
	"res://Screens/Overworld/Portraits/Eirene.png",
	"res://Screens/Overworld/ButtonImage/Eirene.png",
	"res://Screens/Overworld/ButtonImage/Eirene.bmp")
	
### Nyaraka
static var NyarakaF := register_god("Nyaraka", "F", "Avatar of Hathor",
	"Judicious Jackal God",
	"Dark Grey",
	"res://Screens/Overworld/Portraits/NyarakaF.png",
	"res://Screens/Overworld/ButtonImage/NyarakaM.png", # TODO
	"res://Screens/Overworld/ButtonImage/NyarakaM.bmp") 
#static var NyarakaM :=register_god("Nyaraka", "M", "Avatar of Hathor",
#	"Judicious Jackal God",
#	"Dark Grey",
#	"res://Screens/Overworld/Portraits/NyarakaM.png",
#	"res://Screens/Overworld/ButtonImage/NyarakaM.png",
#	"res://Screens/Overworld/ButtonImage/NyarakaM.bmp")	
static var Nyaraka := NyarakaF

### Tali
static var Tali := register_god("Tali", "F", "Avatar of Bastet",
	"Feisty Feline Goddess",
	"White",
	"res://Screens/Overworld/Portraits/Alara.png", # TODO
	"res://Screens/Overworld/ButtonImage/Alara.png",
	"res://Screens/Overworld/ButtonImage/Alara.bmp")
	
### Sitri
static var Sitri := register_god("Sitri", "F", "Dark Serpent",
	"Vainglorious Viper Goddess",
	"Royal Purple",
	"res://Screens/Overworld/Portraits/Alara.png", # TODO
	"res://Screens/Overworld/ButtonImage/Alara.png",
	"res://Screens/Overworld/ButtonImage/Alara.bmp")
	
### Hesra
static var Hesra := register_god("Hesra", "F", "Priestess of Ra",
	"",
	"",
	"res://Screens/Overworld/Portraits/Alara.png", # TODO
	"res://Screens/Overworld/ButtonImage/Alara.png",
	"res://Screens/Overworld/ButtonImage/Alara.bmp")
	
### Nebet
static var Nebet := register_god("Nebet", "F", "Avatar of Sia",
	"",
	"",
	"res://Screens/Overworld/Portraits/Alara.png", # TODO
	"res://Screens/Overworld/ButtonImage/Alara.png",
	"res://Screens/Overworld/ButtonImage/Alara.bmp")



# Record of all gods name: god
static var record := {}

# List of all gods
static var all: Array[God] = [Player, Maia, Zahra, Ishtar, Alara, Sutekh, Eirene, Nyaraka, Tali, Sitri, Hesra, Nebet]

# Player is fixed, Sitri is last boss, Hesra and Nebet are special side charas
static var territory_selection: Array[God] = [Maia, Zahra, Ishtar, Alara, Sutekh, Eirene, Nyaraka, Tali]
