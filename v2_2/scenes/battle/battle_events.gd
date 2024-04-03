extends Node


#region Game Signals

## Emitted to send a request to start the battle.
signal start_battle_requested(data: Dictionary)

## Emitted to send a request to stop the battle.
signal stop_battle_requested(result: BattleResult)

#endregion Game Signals


#region Cycle Signals

## Emitted when battle is started, after the context has been initialized but
## before the scene is ready. See [signal battle_scene_entered].
signal battle_started(attacker: Empire, defender: Empire, territory: Territory, map_id: int)

## Emitted when battle ended, immediately before the context is finally destroyed.
signal battle_ended(result: BattleResult)

## Emitted after the map has loaded, but before the transition completely finishes.
## Use this for arranging pre-battle setup before the battle is fully shown.
signal battle_scene_pre_enter

## Emitted after the scene has entered and before the cycle starts.
signal battle_scene_entered

## Emitted before the scene exits.
signal battle_scene_exiting

## Emitted when an empire's prep phase is started.
signal prep_phase_started(empire: Empire)

## Emitted when an empire's prep phase has ended.
signal prep_phase_ended(empire: Empire)

## Emitted when a new cycle starts.
signal cycle_started(cycle: int)

## Emitted when a cycle ends.
signal cycle_ended(cycle: int)

## Emitted when an empire's turn started.
signal turn_started(empire: Empire)

## Emitted when an empire's turn ended.
signal turn_ended(empire: Empire)

## Emitted when attack sequence is started.
signal attack_sequence_started(state: AttackState)

## Emitted when attack sequence has ended.
signal attack_sequence_ended()

#endregion Cycle Signals

## Emitted when objective is updated.
signal objective_updated(objective: Objective)

signal objectives_evaluated