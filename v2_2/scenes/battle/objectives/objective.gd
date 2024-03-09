class_name Objective
extends Trigger
## Player objectives.


enum Status {
	NONE = -1,
	FAILED = 0,
	COMPLETED = 1,
}


## The objective type.[br]
## Main objectives will emit battle results while bonus objectives will only be evaluated when the battle ends.
@export_enum("Main Objective", "Bonus Objective") var objective_type: String = "Main Objective"

## How many turns to fulfill the objective.
##
## This will automatically call [method objective_failed] when cycle reaches countdown.
@export var countdown: int = -1

## Whether to automatically call [method deactivate] after completing (or failing) once.
@export var one_shot: bool = true

## Whether this objective is shown in the ui.
@export var hidden: bool = false


var _status: Status = Status.NONE


func _to_string() -> String:
	return description()


## Returns the status of this objective.
##
## If status is not [constant Status.NONE], it can be used in if statements like so: [code]if objective.status():[/code].
func status() -> Status:
	return _status


## Returns the description.
func description() -> String:
	return "Lorem ipsum dolor sit amet"


## A special suffix for countdown.
func countdown_suffix() -> String:
	var turns := turns_remaining()
	if countdown < 0:
		return '.'
	elif turns == 1:
		return ' within 1 turn.'
	else:
		return ' within %d turns.' % turns


## Returns the number of turns remaining.
func turns_remaining() -> int:
	return countdown - Battle.instance().cycle()


## Notifies the battle event system that the description has changed.
func notify_description_changed() -> void:
	if not hidden:
		BattleEvents.objective_updated.emit(self)


## Sets the status to [constant Status.COMPLETED] and stops the battle if it's a main objective and result != [constant BattleResult.NONE].
func objective_completed(result: int) -> void:
	_status = Status.COMPLETED
	BattleEvents.objective_updated.emit(self)

	if objective_type == "Main Objective" and result != BattleResult.NONE:
		Battle.instance().stop_battle(result)

	if one_shot:
		deactivate()


## Sets the status to [constant Status.FAILED] and stops the battle if it's a main objective and result != [constant BattleResult.NONE].
func objective_failed(result: int) -> void:
	_status = Status.FAILED
	BattleEvents.objective_updated.emit(self)
	
	if objective_type == "Main Objective" and result != BattleResult.NONE:
		Battle.instance().stop_battle(result)

	if one_shot:
		deactivate()


## Activates the objective.
func activate() -> void:
	if _active:
		return
	_active = true
	BattleEvents.cycle_ended.connect(_on_cycle_ended)
	_activated()


## Deactivates the objective.
func deactivate() -> void:
	if not _active:
		return
	_deactivated()
	BattleEvents.cycle_ended.disconnect(_on_cycle_ended)
	_active = false


func _on_cycle_ended(cycle: int) -> void:
	if countdown >= 0:
		notify_description_changed()
		if cycle >= countdown:
			objective_failed(BattleResult.empire_defeat(Battle.instance().player()))
