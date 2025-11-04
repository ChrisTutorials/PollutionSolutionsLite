# Testing Guide for Pollution Solutions Lite

This document explains how to test the Pollution Solutions Lite mod for Factorio 2.0+ compatibility.

## Table of Contents

1. [Testing Overview](#testing-overview)
2. [Test Types](#test-types)
3. [Setup Instructions](#setup-instructions)
4. [Running Tests](#running-tests)
5. [Manual Testing](#manual-testing)
6. [Automated Testing](#automated-testing)
7. [Factorio 2.0 Compatibility Checklist](#factorio-20-compatibility-checklist)

## Testing Overview

Testing Factorio mods requires a different approach than typical software testing because mods run within the Factorio game engine. We support both manual in-game testing and automated testing using community frameworks.

### Test Environment Requirements

- **Factorio 2.0+**: Latest stable version recommended
- **Operating System**: Windows, Linux, or macOS
- **Test Framework** (optional): factorio-test, factorio-check, or manual scenarios

## Test Types

### 1. Unit Tests

Unit tests verify individual functions and calculations work correctly in isolation.

**Location**: `tests/test_*.lua`

**Coverage**:
- `test_constants.lua`: Validates all constants are properly defined
- `test_util.lua`: Tests utility functions for prototype creation

**Running**:
```lua
-- In Factorio console or test script
require("tests.test_constants")
require("tests.test_util")
```

### 2. Integration Tests

Integration tests verify that mod systems work together correctly within the game.

**Test Areas**:
- Entity lifecycle (build, destroy, damage)
- Pollution collection and conversion
- Toxic dump behavior
- Xenomass drops from aliens
- Fluid system interactions

### 3. Scenario Tests

Full gameplay scenarios that test the mod in realistic conditions.

**Scenarios**:
- Early game pollution management
- Mid game scaling with multiple collectors
- Late game incinerator power systems
- Biter combat with toxic weapons

## Setup Instructions

### Method 1: Manual In-Game Testing

1. **Install the Mod**:
   ```bash
   # Copy mod to Factorio mods folder
   # Windows: %APPDATA%/Factorio/mods/
   # Linux: ~/.factorio/mods/
   # macOS: ~/Library/Application Support/factorio/mods/
   
   cp -r PollutionSolutionsLite "$FACTORIO_MODS_DIR/"
   ```

2. **Launch Factorio**: Start Factorio 2.0+ and enable the mod in the mods menu

3. **Create Test World**: Start a new game or load a save to test

### Method 2: factorio-test Framework

factorio-test provides automated testing within Factorio.

1. **Install factorio-test**:
   ```bash
   # Download factorio-test from mod portal or GitHub
   # https://mods.factorio.com/mod/factorio-test
   # or https://github.com/GlassBricks/FactorioTest
   ```

2. **Setup Test Files**: Place test files in `tests/` directory

3. **Run Tests**: Use factorio-test CLI or in-game commands

### Method 3: factorio-check (Python-based)

factorio-check allows headless testing with Python scripts.

1. **Install factorio-check**:
   ```bash
   pip install factorio-check
   ```

2. **Create Test Scenarios**: Write scenario scripts

3. **Run Tests**:
   ```bash
   factorio-check run --mod-directory . --scenario test-scenario
   ```

## Running Tests

### In-Game Console Testing

1. Open Factorio console (~ key)
2. Run test files:
   ```lua
   /c require("tests.test_bootstrap")
   /c require("tests.test_constants")
   /c require("tests.test_util")
   ```

### Unit Test Execution

Run unit tests standalone (requires mocking game environment):

```lua
-- test_runner.lua
dofile("tests/test_bootstrap.lua")
dofile("tests/test_constants.lua")
dofile("tests/test_util.lua")
```

### Automated Test Suite

If using factorio-test:

```lua
-- In factorio-test environment
local test_runner = require("__factorio-test__/test-runner")
test_runner.run_file("tests/test_constants.lua")
test_runner.run_file("tests/test_util.lua")
```

## Manual Testing

### Test Checklist

#### Basic Functionality

- [ ] Mod loads without errors in Factorio 2.0+
- [ ] All items, entities, and technologies appear in game
- [ ] Graphics and icons display correctly
- [ ] Recipes are craftable and balanced
- [ ] Technologies unlock properly

#### Pollution Collector

- [ ] Place pollution collector building
- [ ] Verify it collects pollution from surrounding chunks
- [ ] Check polluted-air fluid is produced
- [ ] Test collection rate settings
- [ ] Verify collector stops when full
- [ ] Destroy collector and verify pollution disperses

#### Toxic Dump

- [ ] Place toxic dump building
- [ ] Pipe polluted-air or toxic-sludge into dump
- [ ] Verify periodic pollution release
- [ ] Check visual effects (smoke, toxic clouds)
- [ ] Verify partial consumption mechanic
- [ ] Test different fill levels

#### Incinerator

- [ ] Build incinerator entity
- [ ] Feed toxic sludge as fuel
- [ ] Verify power generation
- [ ] Check efficiency setting works
- [ ] Measure pollution output
- [ ] Test with different sludge types

#### Xenomass System

- [ ] Kill small biters → blue xenomass drops
- [ ] Kill big biters → more blue xenomass
- [ ] Kill worms → blue xenomass drops
- [ ] Kill spawners → red xenomass drops
- [ ] Verify diminishing returns on spawners
- [ ] Test artillery kills assign to force

#### HEV Suit & Toxic Weapons

- [ ] Craft HEV suit components
- [ ] Equip HEV suit
- [ ] Use toxic turrets on biters
- [ ] Throw toxic capsules
- [ ] Verify damage application
- [ ] Check resistance system

#### Pollution Dispersal

- [ ] Fill tank with polluted-air
- [ ] Mine/destroy tank
- [ ] Verify pollution released to air
- [ ] Test with toxic-sludge
- [ ] Test with mixed fluids

### Performance Testing

- [ ] Test with 10+ collectors active
- [ ] Monitor tick time impact
- [ ] Test with 20+ toxic dumps
- [ ] Check memory usage
- [ ] Verify no lag spikes on dump cycle

### Mod Compatibility

- [ ] Test with base game only
- [ ] Test with Biter Factions mod
- [ ] Test with K2 Flare Stack
- [ ] Verify incompatibility with conflicting mods

## Automated Testing

### Example Test Script

```lua
-- scenario_test.lua
-- Place in scenarios/pollution-solutions-test/

script.on_init(function()
  local TestUtils = require("__PollutionSolutionsLite__/tests/test_bootstrap")
  
  -- Test 1: Create pollution collector
  local surface = game.surfaces[1]
  local pos = {x=0, y=0}
  local collector = surface.create_entity{
    name="pollutioncollector",
    position=pos,
    force="player"
  }
  TestUtils.assertNotNil(collector, "Collector should be created")
  
  -- Test 2: Add pollution
  surface.pollute(pos, 1000)
  local pollution_before = surface.get_pollution(pos)
  TestUtils.assert(pollution_before > 0, "Pollution should be added")
  
  -- Test 3: Wait and check collection
  -- (Would need tick-based testing here)
  
  TestUtils.log("All scenario tests passed!")
end)
```

### Continuous Integration

For CI/CD pipelines:

```yaml
# .github/workflows/test.yml (example)
name: Factorio Mod Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Download Factorio
        run: |
          # Download Factorio headless
          wget https://factorio.com/get-download/stable/headless/linux64
          
      - name: Install Mod
        run: |
          mkdir -p ~/.factorio/mods
          cp -r . ~/.factorio/mods/PollutionSolutionsLite
          
      - name: Run Tests
        run: |
          # Run factorio with test scenario
          factorio --start-server-load-scenario test-scenario
```

## Factorio 2.0 Compatibility Checklist

### Mandatory Changes ✓

- [x] Update `info.json` factorio_version to "2.0"
- [x] Update base dependency to "base >= 2.0"
- [x] Review changelog for breaking API changes
- [x] Test all prototype definitions load correctly

### API Changes to Verify

- [ ] **Recipe Format**: Ensure recipes use results array format
  ```lua
  -- Old: result = "item-name", result_count = 5
  -- New: results = {{type="item", name="item-name", amount=5}}
  ```

- [ ] **Fluid System**: Verify fluid prototypes work in 2.0
- [ ] **Entity Definitions**: Check entity prototypes for deprecated fields
- [ ] **Technology**: Verify tech tree unlocks work
- [ ] **Damage Types**: Confirm custom damage type "toxic" works
- [ ] **Forces**: Test alien force detection with 2.0 changes

### Testing Priorities

1. **Critical**: Mod loads without errors
2. **High**: Core gameplay (collectors, dumps, conversion)
3. **Medium**: Xenomass drops and loot
4. **Low**: Visual effects and polish

### Known Issues to Check

- Recipe result format changes in 2.0
- Deprecated API functions
- Entity collision mask changes
- Fluid flow mechanics updates
- Technology prerequisites structure

## Troubleshooting

### Common Issues

**Mod won't load**:
- Check factorio-current.log for errors
- Verify info.json syntax
- Ensure all dependencies are correct

**Entities don't appear**:
- Check data stage logs
- Verify prototype definitions
- Test with minimal mod list

**Runtime errors**:
- Check control.lua for API usage
- Verify event handlers
- Test entity lifecycle

**Performance issues**:
- Profile tick functions
- Check collection intervals
- Optimize neighbor scanning

### Debug Mode

Enable debug in Factorio:
1. Options → Other → Show debug info
2. F4 → Enable various debug overlays
3. F5 → Show entity info
4. F6 → Show chunks and pollution

### Log Analysis

Check logs in:
- Windows: `%APPDATA%/Factorio/factorio-current.log`
- Linux: `~/.factorio/factorio-current.log`
- macOS: `~/Library/Application Support/factorio/factorio-current.log`

Look for:
- Error messages
- Stack traces
- Performance warnings
- Desync reports (multiplayer)

## Contributing Tests

When adding new features:

1. Write unit tests for new functions
2. Add integration tests for new systems
3. Document test scenarios
4. Update this guide with new test procedures

## Resources

- [Factorio 2.0 API Documentation](https://lua-api.factorio.com/latest/)
- [Factorio Mod Portal](https://mods.factorio.com/)
- [factorio-test Framework](https://github.com/GlassBricks/FactorioTest)
- [factorio-check Tool](https://github.com/danpf/factorio-check)
- [Mod Porting Guide](https://github.com/tburrows13/factorio-2.0-mod-porting-guide)
- [Alt-F4: Testing Article](https://alt-f4.blog/ALTF4-48/)

## Version-Specific Notes

### Factorio 2.0.x

- Space Age expansion changes tech tree
- New surfaces and planets available
- Quality system introduced
- Rail system overhaul
- Recipe format standardization

Ensure mod works both with and without Space Age DLC enabled.

---

For questions or issues, consult the Factorio modding community or open an issue on the mod repository.
