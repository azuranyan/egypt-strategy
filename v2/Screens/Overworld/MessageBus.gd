extends Node
class_name MessageBus

## Emitted when a transfer of territory ownership has occurred
signal territory_owner_changed(old_owner: Empire, new_owner: Empire, territory: Territory)
# const win_territory := 'overworld.win_territory'

## Emitted when all territories are taken
signal all_territories_taken()

## Emitted when boss is defeated
signal boss_defeated()

## Emit to start an attack event to the engine
signal empire_attack(empire: Empire, target: Territory)
# const invade := 'overworld.invade'

## Emit to end turn
signal turn_end() 

#const click_on_territory := 'overworld.click_on_territory'
#const click_on_map := 'overworld.click_on_map'
#const right_click := 'overworld.right_click'
#const click_on_inspect := 'overworld.click_on_inspect'
#const rest := 'overworld.rest'

