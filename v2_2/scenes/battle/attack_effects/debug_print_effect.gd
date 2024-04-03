class_name DebugPrintEffect
extends AttackEffect
## Represents an effect that prints the effect details on debug.


## The format for printing. Recognized tags are:
## [codeblock]
## effect 		# the name of the effect
## attack 		# the name of the attack
## user   		# the display name of the user
## target     	# the display name of the target
## *_id 		# the id of the user/target
## *_chara_id 	# the chara id of the user/target
## [/codeblock]
@export var format: String = "{user} effect {target}"
