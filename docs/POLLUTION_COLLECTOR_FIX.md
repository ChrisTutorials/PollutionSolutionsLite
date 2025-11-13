# Pollution Collector Fix - Technical Documentation

## Problem Statement

The pollution collector wasn't working. The goal was to make it collect pollution from the chunk it's in and store it (in itself / pipe system), based on reference implementation from [atan-air-scrubbing](https://github.com/atanvarno69/atan-air-scrubbing).

## Requirements

1. Collect pollution from the chunk the collector is in
2. Store collected pollution as fluid (polluted-air)
3. **Must not change existing recipes/ingredients** - maintain compatibility
4. Only generate polluted-air when pollution exists in the environment
5. Work with existing pipe systems

## Solution Architecture

### Entity Type Change: Storage-Tank → Furnace

**Previous Implementation (Broken):**
- Entity type: `storage-tank` 
- Invalid property: `crafting_categories` (storage tanks don't craft)
- Pollution collection: Complex scripted chunk scanning (3x3 grid)
- Problems: Storage tanks can't run recipes, scripting was overly complex

**New Implementation (Working):**
- Entity type: `furnace` with `atmospheric-filtration` category
- Negative emissions: `-40 pollution/minute` (built-in Factorio mechanic)
- Recipe: `collect-pollution` (no inputs → polluted-air output)
- Script control: Recipe enabled/disabled based on chunk pollution

### How It Works

1. **Pollution Removal**: The furnace entity's `emissions_per_minute.pollution = -40` tells Factorio to automatically remove 40 pollution per minute from the chunk while running.

2. **Fluid Production**: The `collect-pollution` recipe produces 40 units of polluted-air per 60-second cycle.

3. **Script Control**: Every 5 seconds, a script checks:
   ```lua
   local pollution = entity.surface.get_pollution(entity.position)
   if pollution > 0 then
     entity.set_recipe("collect-pollution")  -- Enable collection
   else
     entity.set_recipe(nil)  -- Stop collection
   end
   ```

4. **Output**: Polluted-air flows to connected pipes via output fluid boxes.

### Recipe Chain Compatibility

**No changes to existing recipes:**

```
Air Pollution in Chunk
         ↓
   [Pollution Collector]  ← New: furnace with negative emissions
         ↓
   Polluted-Air Fluid
         ↓
   [liquify-pollution]    ← Unchanged: same recipe, same ingredients
         ↓
   Toxic Sludge Fluid
```

The `liquify-pollution` recipe remains identical:
- Ingredients: blue-xenomass + polluted-air + water
- Result: toxic-sludge
- No modifications made

### Key Design Decisions

1. **Single Chunk Collection**: Changed from 3x3 chunk grid to single chunk
   - Matches reference mod behavior
   - Simpler and more predictable
   - Uses Factorio's built-in pollution system
   - More performant (no chunk scanning)

2. **Recipe Control via Script**: Rather than pure built-in mechanics, we add script control to ensure:
   - Recipe only runs when pollution exists
   - No "free" fluid generation
   - Proper resource tracking

3. **Settings Compatibility**: The furnace approach doesn't use the old settings:
   - `zpollution-collection-interval`: Not used (furnace runs continuously)
   - `zpollution-collectors-required`: Not used (1:1 collection rate)
   - `zpollution-pollution-remaining`: Not used (collects all available)
   
   These settings remain in the mod but don't affect the new implementation.

## Testing

### Data Stage Tests (`test_pollution_collector.lua`)

Validates prototype configuration:
- ✅ Furnace entity exists with correct properties
- ✅ Atmospheric-filtration category exists
- ✅ collect-pollution recipe configured correctly
- ✅ Technology unlocks both building and recipe
- ✅ Recipe chain compatibility maintained
- ✅ Fluid output configured for pipe connections

### Runtime Tests (`test_collector_runtime.lua`)

Validates behavior in-game:
- ✅ Recipe only runs when pollution exists in chunk
- ✅ Fluid production requires pollution
- ✅ Integration with liquify-pollution recipe
- ✅ Entity destruction disperses stored pollution
- ✅ No production when pollution = 0
- ✅ Recipe resumes when pollution added

## Performance Considerations

- **Tick Processing**: Script runs every 5 seconds (300 ticks) instead of every 60 ticks
  - Less frequent checks reduce CPU usage
  - 5-second delay acceptable for recipe enable/disable

- **Built-in Pollution Removal**: Factorio's native system handles actual pollution removal
  - No Lua scripting per tick for collection
  - Optimal performance

## Migration Notes

For existing saves:
- Old pollution collectors (storage-tank type) will be removed
- Players need to rebuild collectors with new furnace type
- Stored polluted-air in old collectors should be piped out before replacement
- A migration script could be added if needed

## Comparison with Reference Mod

### Similarities
- Furnace entity type ✓
- Negative emissions for pollution removal ✓
- Recipe with no inputs → fluid output ✓
- Electric power consumption ✓

### Differences
- Reference mod: Fixed collection rate, always runs when powered
- This mod: Script-controlled, only runs when pollution exists
- Reason: Meets requirement "only generate when pollution exists in environment"

## API References

- **Entity Type**: [FurnacePrototype](https://lua-api.factorio.com/latest/prototypes/FurnacePrototype.html)
- **Emissions**: [EnergySource.emissions_per_minute](https://lua-api.factorio.com/latest/types/EnergySource.html#emissions_per_minute)
- **Fluid Boxes**: [FluidBox](https://lua-api.factorio.com/latest/types/FluidBox.html)
- **Recipe Control**: [LuaEntity.set_recipe](https://lua-api.factorio.com/latest/classes/LuaEntity.html#set_recipe)

## Future Enhancements

Possible improvements:
1. Add migration script for old collectors
2. Make collection rate configurable (modify recipe duration)
3. Add visual indicator when pollution is low
4. Add circuit network integration
5. Support for other pollution types (Space Age spores)

## Credits

- Original concept: daniels1989's Pollution Solutions
- Reference implementation: [atan-air-scrubbing](https://github.com/atanvarno69/atan-air-scrubbing) by atanvarno69
- Factorio 2.0 port and fix: ChrisTutorials
