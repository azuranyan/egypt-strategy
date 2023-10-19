@tool
extends Resource

## Flyweight class for a unit.
class_name UnitType

## Dictates how his unit chooses its actions.
enum Behavior {
	## Unit is controlled by player.
	PlayerControlled,
	
	## Always advances towards nearest target and attacks.
	NormalMelee,
	
	## Always attacks nearest target, flees adjacent attackers.
	NormalRanged,
	
	## Always advances and tries to attack target with lowest HP.
	ExploitativeMelee,
	
	## Always tries to attack targets that would not be able to retaliate.
	ExploitativeRanged,
	
	## Holds 1 spot and attacks any who approach.
	DefensiveMelee,
	
	## Holds 1 spot and attacks any who approach, flees adjacent attackers.
	DefensiveRanged,
	
	## Heals allies and self, runs away from attackers.
	SupportHealer,
	
	## Aims to inflict as many enemies with negative status as possible, will choose different target if already afflicted.
	StatusApplier,
}


## The character this unit represents.
@export var chara: Chara = null

## The sprite frames.
@export var sprite_frames: SpriteFrames = preload("res://Screens/Battle/sprites/Placeholder.tres")

## The name of this unit.
@export var name: String = "":
	set(value):
		name = value
	get:
		if name == "" and chara != null:
			return chara.name
		return name
		
## The behavior type.
@export var behavior: Behavior

@export_group("Overrides")

## Avatar override.
@export var avatar: String = "":
	set(value):
		avatar = value
	get:
		if avatar == "" and chara != null:
			return chara.avatar
		return avatar

## Title override.
@export var title: String = "":
	set(value):
		title = value
	get:
		if title == "" and chara != null:
			return chara.title
		return title
		
	
## Color override.
@export var map_color: Color = Color.WHITE:
	set(value):
		map_color = value
	get:
		if map_color == Color.WHITE and chara != null:
			return chara.map_color
		return map_color

@export_group("Stats")

## Base HP stat.
@export var stat_hp: int

## Base MOV stat.
@export var stat_mov: int

## Base DMG stat.
@export var stat_dmg: int

## Base RNG stat.
@export var stat_rng: int

## Stat growth for +1 bond (or story powerup 1).
@export var stat_growth_1: Dictionary = {"hp" = 0, "mov" = 0, "dmg" = 0, "rng" = 0}

## Stat growth for max bond (or story powerup 2).
@export var stat_growth_2: Dictionary ={"hp" = 0, "mov" = 0, "dmg" = 0, "rng" = 0}

## Basic attack.
@export var basic_attack: Attack

## Extra attack you get 
@export var special_attack: Attack
