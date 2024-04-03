extends Node


#region Game Signals
signal created(unit: Unit) ## Emitted when a new unit is created and added to the registry.
signal destroying(unit: Unit) ## Emitted when a unit is about to be destroyed.
signal empire_changed(unit: Unit, old: Empire, new: Empire) ## Emitted when unit's empire is changed.
signal behavior_changed(unit: Unit, old: Unit.Behavior, new: Unit.Behavior) ## Emitted when unit behavior is changed.
signal fielded(unit: Unit) ## Emitted when unit is loaded on the map.
signal unfielded(unit: Unit) ## Emitted when unit is loaded on the map.
#endregion Game Signals


#region Unit State Signals
signal state_changed(unit: Unit, old: Unit.State, new: Unit.State) ## Emitted when unit transitions from one state to the next.
signal position_changed(unit: Unit) ## Emitted when unit's position on the map is changed.
signal heading_changed(unit: Unit) ## Emitted when the direction the unit is facing is changed.
signal stat_changed(unit: Unit, stat: StringName) ## Emitted when unit's stat value is changed.
signal bond_changed(unit: Unit) ## Emitted when unit's bond value is changed.
signal damaged(unit: Unit, amount: int, source: Variant) ## Emitted when the unit takes damage.
signal healed(unit: Unit, amount: int, source: Variant) ## Emitted when the unit gets healed.
signal died(unit: Unit) ## Emitted when the unit dies and put on standby.
signal revived(unit: Unit) ## Emitted when the unit comes back from the dead state.
signal status_effect_added(unit: Unit, effect: StringName, duration: int) ## Emitted when status effect is added.
signal status_effect_ticked(unit: Unit, effect: StringName, duration: int) ## Emitted when status effect is applied and duration is decremented.
signal status_effect_removed(unit: Unit, effect: StringName) ## Emitted when status effect is removed.
signal turn_flags_changed(unit: Unit)
#endregion Unit State Signals


#region Unit Actions Signals
signal action_selected(unit: Unit, action: UnitAction) ## Emitted when unit has selected an action.
signal walking_started(unit: Unit, start: Vector2, end: Vector2) ## Emitted when a unit starts walking.
signal walking_finished(unit: Unit) ## Emitted when a unit finishes walking.
signal attack_started(unit: Unit, attack_state: AttackState) ## Emitted when unit begins an attack.
signal attack_finished(unit: Unit) ## Emitted when unit finishes an attack.
#endregion Unit Actions Signals


#region Map and Interaction Signals
signal input_event(unit: Unit, event: InputEvent) ## Emitted when unit is interacted with (controller, keyboard or mouse).
signal mouse_entered(unit: Unit) ## Emitted when mouse enters the unit detection area.
signal mouse_exited(unit: Unit) ## Emitted when mouse exits the unit detection area.
signal clicked(unit: Unit, mouse_pos: Vector2, button_index: int, pressed: bool) ## Emitted when unit is clicked.
signal selected(unit: Unit, is_selected: bool) ## Emitted when unit is (de)selected.
#endregion Map and Interaction Signals


var last_input_event: InputEvent