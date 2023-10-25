extends Node

################################################################################
### Turn order signals
################################################################################

## Emitted at the start of a new turn order cycle
signal cycle_start

## Emitted on start of a turn
signal cycle_turn_start(empire: Empire)

## Signal awaited by main loop to resume overworld cycle
signal cycle_turn_end(empire: Empire)

## Emitted at the end of a turn order cycle
signal cycle_end

################################################################################
### Gameplay signals
################################################################################

## Emitted when a transfer of territory ownership has occurred
signal territory_owner_changed(old_owner: Empire, new_owner: Empire, territory: Territory)

## Emitted when all territories are taken
signal all_territories_taken()

## Emitted when boss is defeated
signal boss_defeated()

## Emitted when player is defeated
signal player_defeated()

