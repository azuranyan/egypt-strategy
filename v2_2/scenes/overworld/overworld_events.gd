extends Node

#region Game Signals

## Emitted when an empire is defeated.
signal empire_defeated(empire: Empire)

## Emitted when empire force rating is updated.
signal empire_force_rating_updated(empire: Empire, rating: float)

## Emitted when the empire unit list is updated.
signal empire_unit_list_updated(empire: Empire, units: Array[Unit])

## Emitted when an empire's adjacency list is updated.
signal empire_adjacency_updated(empire: Empire, adjacent: Array[Territory])

## Emitted when a territory ownership changed.
signal territory_owner_changed(territory: Territory, old_owner: Empire, new_owner: Empire)

## Emitted when territory connections changed.
signal territory_adjacency_changed(territory: Territory)

## Emitted when boss is summoned.
signal boss_summoned(empire: Empire, territory: Territory)

#endregion Game Signals


#region Cycle Signals

## Emitted when a player chooses an action.
signal player_action_chosen(action: Dictionary)

## Emitted after the scene has entered.
signal overworld_scene_entered

## Emitted before the scene exits.
signal overworld_scene_exiting

## Emitted when a new cycle starts.
signal cycle_started(cycle: int)

## Emitted when a cycle ends.
signal cycle_ended(cycle: int)

## Emitted when an empire's turn started.
signal turn_started(empire: Empire)

## Emitted when an empire's turn ended.
signal turn_ended(empire: Empire)

## Emitted when strategy room is opened.
signal strategy_room_opened(inspect_mode: bool)

## Emitted when strategy room is closed.
signal strategy_room_closed(event_id: StringName)

#endregion Cycle Signals


#region Misc Signals
## Emitted when marching animations are requested.
signal marching_animation_requested(from: Territory, to: Territory, empire: Empire)

## Emitted when battle result animations are requested.
signal battle_result_banner_requested(result: BattleResult, allow_strategy_room: bool)
#endregion Misc Signals