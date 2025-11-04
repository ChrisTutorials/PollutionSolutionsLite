# Development Documentation

This document contains detailed technical information for developers working on Pollution Solutions Lite.

## File Structure

```
PollutionSolutionsLite/
├── control.lua              # Runtime logic and event handlers
├── data.lua                 # Prototype loading
├── data-updates.lua         # Late-stage prototype modifications
├── data-final-fixes.lua     # Final prototype adjustments
├── constants.lua            # Global constants and configuration
├── util.lua                 # Utility functions for prototypes
├── settings.lua             # Mod settings definitions
├── info.json               # Mod metadata
├── prototypes/             # Prototype definitions
│   ├── category.lua        # Recipe and damage categories
│   ├── entity.lua          # Buildings and structures
│   ├── fluid.lua           # Polluted air and toxic sludge
│   ├── hevsuit.lua         # HEV suit equipment
│   ├── item.lua            # Items and intermediate products
│   ├── pollutioncollector.lua  # Pollution collector entity
│   ├── projectiles.lua     # Toxic projectiles and clouds
│   ├── recipe.lua          # Crafting recipes
│   └── technology.lua      # Research technologies
├── migrations/             # Save game migrations
├── graphics/              # Sprites and icons
└── locale/               # Translations
```

## Code Organization

### control.lua
Main runtime script with event handlers:
- Entity lifecycle management
- Tick-based processing loops
- Pollution conversion mechanics

### prototypes/
All game prototype definitions:
- Separated by type for maintainability
- Uses util.lua helper functions for prototype creation

### constants.lua
Central configuration:
- All magic numbers defined here
- Settings-based runtime values

## Key Systems

### Pollution Collector

The pollution collector system runs periodically to collect pollution from chunks:

- Runs every N ticks (configurable, default 60)
- Scans 3x3 chunk grid for pollution
- Calculates collectible amount: `(pollution - minimum) / divisor`
- Converts to polluted-air fluid

**Implementation Details:**
- Registered in global.pollutioncollectors table
- Each collector tracks its position and entity
- Processes on tick event when interval expires
- Checks each chunk in 3x3 grid (96x96 tiles total)
- Respects minimum pollution threshold setting
- Outputs to fluidbox [1]

### Toxic Dump

The toxic dump periodically releases stored fluids as pollution:

- Runs every 30 seconds (1800 ticks)
- Releases fluids when above fill threshold
- Applies consumption percentage (destroys portion)
- Creates visual effects (smoke, toxic clouds)

**Implementation Details:**
- Registered in global.toxicdumps table
- Checks fluidbox contents each cycle
- Converts fluids back to pollution using ratios
- Creates visual entities (smoke, toxic-cloud)
- Partial destruction prevents pollution loops

### Xenomass Drops

When alien entities die, they drop xenomass materials:

- Hooks entity death events
- Checks if entity is from alien force
- Calculates random drop based on type and settings
- Spawns items at death position

**Implementation Details:**
- Checks entity.force.name for alien forces
- Supports vanilla "enemy" force
- Supports Biter Factions mod forces
- Biters/worms drop blue xenomass
- Spawners drop red xenomass
- Diminishing returns on spawner farming
- Artillery kills properly assign to killing force

### Pollution Dispersal

Prevents pollution deletion by releasing stored pollution when entities are destroyed:

- Hooks pre-removal events (mining, death, destruction)
- Scans fluidboxes for pollution fluids
- Calculates total pollution amount
- Releases to atmosphere at entity position

**Implementation Details:**
- Uses on_pre_player_mined_item and on_entity_died events
- Checks all fluidboxes in entity
- Converts fluids to pollution using constants
- Prevents players from "cheating" by destroying storage

## Event Flow

### Initialization
1. `script.on_init()` - First time mod is added
2. `InitGlobals()` - Initialize global tables
3. Scan existing entities for collectors/dumps

### Configuration Change
1. `script.on_configuration_changed()` - Mod update or change
2. `InitGlobals()` - Reinitialize global state
3. Rescan world for entities

### Tick Processing
1. `OnTick(event)` - Called every game tick
2. Check if collection interval elapsed
3. Process all registered collectors
4. Check if dump interval elapsed (every 1800 ticks)
5. Process all registered dumps

### Entity Lifecycle
1. **Built**: `OnBuiltEntity()` - Register collector/dump
2. **Destroyed**: `OnEntityPreRemoved()` - Unregister and disperse pollution
3. **Died**: `EntityDied()` - Handle xenomass drops

## Testing

See [TESTING.md](TESTING.md) for comprehensive testing guide including:
- Unit tests
- Integration tests
- Manual testing procedures
- Performance testing
- Compatibility testing

## Validation

See [VALIDATION_REPORT.md](VALIDATION_REPORT.md) for Factorio 2.0 compatibility validation results.

## Version History

See `changelog.txt` for detailed version history.

## Contributing

When making changes:

1. Update tests for new functionality
2. Document new constants in constants.lua
3. Follow existing code style and patterns
4. Test with both vanilla and modded games
5. Update TESTING.md with new test cases
6. Update this document with architectural changes

## Support

For bug reports and feature requests, please use the mod portal or GitHub repository.
