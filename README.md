# Pollution Solutions Lite

A minimalist Factorio mod that turns pollution and combat into an interconnected system you actively engage with. Compatible with Factorio 2.0+.

## Overview

Pollution Solutions Lite adds a pollution management system to Factorio that creates meaningful gameplay around pollution without drastically changing the vanilla experience. Instead of simply placing laser turrets and ignoring pollution, this mod gives you tools to collect, process, and utilize pollution as a resource.

## Features

### Core Systems

#### 1. Pollution Collection
- **Pollution Collectors**: Buildings that actively collect pollution from surrounding chunks
  - Collects from a 3x3 grid of chunks (96x96 tiles)
  - Converts air pollution into "Polluted Air" fluid
  - Configurable collection rate and minimum pollution threshold

#### 2. Pollution Processing
- **Polluted Air → Toxic Sludge**: Concentrate pollution for easier storage/transport
  - Air filters convert polluted air to toxic sludge (10:1 ratio by default)
  - Produces concentrated pollution that can be stored in tanks
  
#### 3. Pollution Disposal
- **Toxic Dumps**: Release stored pollution back into the atmosphere
  - Periodically converts stored fluids back to air pollution
  - Creates visual toxic clouds and smoke effects
  - Partial consumption (50% destroyed by default) makes disposal lossy

- **Incinerators**: Burn toxic sludge for power generation
  - Converts pollution to energy (10 MJ per unit by default)
  - Partial combustion (10% by default) with remainder released as pollution
  - Provides alternative power source with environmental cost

#### 4. Xenomass System
- **Alien Loot**: Killed biters drop xenomass materials
  - **Blue Xenomass**: Dropped by biters and worms
  - **Red Xenomass**: Dropped by spawners (diminishing returns)
  - Used for advanced recipes and HEV suit components
  - Artillery kills properly assign loot to force

#### 5. HEV Suit & Toxic Warfare
- **HEV Suit**: Hazardous Environment Suit provides pollution protection
- **Toxic Turrets**: Use toxic sludge to damage enemies
- **Toxic Capsules**: Throwable pollution weapons
- **Custom Damage Type**: "toxic" damage with resistance system

### Pollution Prevention

The mod includes safeguards to prevent pollution deletion:
- Destroying entities with pollution fluids releases pollution back into the air
- Mining pollution-containing buildings disperses their contents
- Prevents players from "cheating" by destroying pollution storage

## Configuration

### Startup Settings (Require Restart)
- **Air per Sludge**: Conversion ratio (default: 10)
- **Sludge per Filter**: Output per recipe (default: 100)
- **MJ per Sludge**: Energy value (default: 10)
- **Incinerator Efficiency**: Burn rate 0.01-1.0 (default: 0.1)
- **Incinerator Output**: Power generation in MW (default: 2.0)
- **Blue per Red**: Xenomass conversion rate (default: 10)
- **Blue to Red Cost**: Time cost for conversion (default: 10.0)

### Runtime Settings (Change Anytime)
- **Collection Interval**: Ticks between collection (default: 60)
- **Collectors Required**: Divisor for collection rate (default: 8)
- **Pollution Remaining**: Minimum pollution to leave in chunk (default: 50)
- **Blue per Alien**: Average xenomass drop from biters (default: 1)
- **Red per Alien**: Base xenomass from spawners (default: 10)

## Mod Compatibility

### Supported Mods
- **Biter Factions**: Recognizes modded biter forces for xenomass drops
- **K2 Flare Stack**: Increases pollution when flaring pollution fluids (600x multiplier)
- **Rampant Industry**: Tech tree integration
- **Nauvis Melange**: Tech tree integration
- **ModMash Splinter Resources**: Alien ooze compatibility

### Conflicts
Incompatible with:
- PollutionSolutions (original)
- PollutionSolutions_nocombat
- PollutionSolutionsFix
- PollutionSolutionsFixFork

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

## Technology Tree

1. **Pollution Collection**: Unlocks pollution collectors and basic processing
2. **Pollution Liquification**: Advanced pollution processing recipes
3. **Incineration**: Power generation from pollution
4. **Toxic Ammo**: Weaponized pollution
5. **HEV Suit**: Pollution protection equipment

## Tips & Tricks

1. **Early Game**: Don't worry about pollution collection until biters become aggressive
2. **Mid Game**: Set up collectors near high-pollution areas (smelting, oil processing)
3. **Late Game**: Use incinerators as auxiliary power, toxic turrets for defense
4. **Efficiency**: Balance collector placement to maintain pollution below biter evolution thresholds
5. **Storage**: Toxic sludge is 10x more space-efficient than polluted air

## Development

### Code Organization

- **control.lua**: Main runtime script with event handlers
  - Entity lifecycle management
  - Tick-based processing loops
  - Pollution conversion mechanics
  
- **prototypes/**: All game prototype definitions
  - Separated by type for maintainability
  - Uses util.lua helper functions for prototype creation
  
- **constants.lua**: Central configuration
  - All magic numbers defined here
  - Settings-based runtime values
  
### Key Systems

#### Pollution Collector
- Runs every N ticks (configurable, default 60)
- Scans 3x3 chunk grid for pollution
- Calculates collectible amount: `(pollution - minimum) / divisor`
- Converts to polluted-air fluid

#### Toxic Dump
- Runs every 30 seconds (1800 ticks)
- Releases fluids when above fill threshold
- Applies consumption percentage (destroys portion)
- Creates visual effects (smoke, toxic clouds)

#### Xenomass Drops
- Hooks entity death events
- Checks if entity is from alien force
- Calculates random drop based on type and settings
- Spawns items at death position

## Credits

- **Original Author**: daniels1989
- **Contributors**: Tynatyna, Keyboarg91, Thalassicus
- **Forked From**: PollutionSolutionsFork

## Version History

See `changelog.txt` for detailed version history.

Current version: 1.0.21 (Factorio 2.0 compatible)

## License

This mod is released for the Factorio community. See individual file headers for specific attribution.

## Support

For bug reports and feature requests, please use the mod portal or GitHub repository.
