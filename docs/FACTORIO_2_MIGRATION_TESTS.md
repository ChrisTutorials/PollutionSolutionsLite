# Factorio 2.0 Migration Test Cases

This document catalogs all Factorio 2.0 API migration issues discovered during testing and the test cases created to catch them.

**Issues Found and Fixed:** 13

## Test Infrastructure

**Test Tool**: `tests/test_factorio_2_headless.py`
**Approach**: Uses actual Factorio headless mode (source of truth) rather than mocking

**Benefits**:

- Catches real Factorio validation errors
- No need to maintain complex mocks
- Tests against actual game engine

**Limitations**:

- Headless mode doesn't catch GUI-specific issues (see Issue #13)
- Must test actual GUI game for complete validation

## Migration Issues Found and Fixed

### 1. Recipe Ingredient Format (Critical)

**Issue**: Factorio 2.0 requires explicit `type` field in all recipe ingredients

**Old Format**:

```lua

ingredients = {
  {name = "iron-plate", amount = 10}
}

```

**New Format**:

```lua

ingredients = {
  {type = "item", name = "iron-plate", amount = 10}
}

```

**Test Case**: Validates all recipes have `type` field in ingredients
**Pattern**: `Key "type" not found in property tree at ROOT.recipe.*.ingredients`
**Files Affected**: `prototypes/pollutioncollector.lua`

---

### 2. Recipe Result Format (Critical)

**Issue**: Recipe results must also have explicit `type` field
**Old Format**:

```lua

results = {
  {name = "product", amount = 1}
}

```

**New Format**:

```lua

results = {
  {type = "item", name = "product", amount = 1}
}

```

**Test Case**: Validates all recipe results have `type` field
**Pattern**: `Key "type" not found in property tree at ROOT.recipe.*.results`
**Files Affected**: All recipe prototypes were already correct

---

### 3. Collision Mask Format (Critical)

**Issue**: `collision_mask` changed from array to dictionary with `layers` key
**Old Format**:

```lua

collision_mask = {"item-layer", "object-layer", "water-tile"}

```

**New Format**:

```lua

collision_mask = {
  layers = {
    item = true,
    object = true,
    water_tile = true
  }
}

```

**Test Case**: Validates all entities use dictionary format
**Pattern**: `Value must be a dictionary in property tree at ROOT.*.*.collision_mask`
**Files Affected**: `prototypes/entity.lua` (dump-site entity)

---

### 4. Pipe Connection Direction (Critical)

**Issue**: Pipe connections must include `direction` field
**Old Format**:

```lua

pipe_connections = {
  {position = {-2, 0}}
}

```

**New Format**:

```lua

pipe_connections = {
  {position = {-2, 0}, direction = defines.direction.west}
}

```

**Test Case**: Validates pipe connections have direction
**Pattern**: `Key "direction" not found in property tree at ROOT.*.*.fluid_box.pipe_connections`
**Files Affected**: `prototypes/entity.lua` (dump-site)

---

### 5. Pipe Connection Flow Direction (Critical)

**Issue**: `type` field in pipe connections renamed to `flow_direction`
**Old Format**:

```lua

pipe_connections[i].type = "input-output"

```

**New Format**:

```lua

pipe_connections[i].flow_direction = "input-output"

```

**Test Case**: Validates no pipe connections use deprecated `type` field
**Pattern**: `Usage of 'type' which should be migrated to 'flow_direction'`
**Files Affected**: `prototypes/pollutioncollector.lua`

---

### 6. Sprite Flags - Removed 'compressed' (Breaking)

**Issue**: The `compressed` sprite flag was removed in Factorio 2.0
**Old Format**:

```lua

flags = {"compressed"}

```

**New Format**:

```lua

flags = {} -- compressed flag removed

```

**Test Case**: Validates no sprites use `compressed` flag
**Pattern**: `compressed is unknown sprite flag`
**Files Affected**: `prototypes/projectiles.lua` (multiple locations)

---

### 7. Emissions Format (Critical)

**Issue**: `emissions_per_minute` and `emissions_per_second` must be dictionaries with pollution type keys
**Old Format**:

```lua

emissions_per_minute = 100

```

**New Format**:

```lua

emissions_per_minute = {
  pollution = 100
}

```

**Test Case**: Validates emissions use dictionary format
**Pattern**: `Value must be a list or dictionary in property tree at ROOT.*.*.emissions_per_*`
**Files Affected**:

- `prototypes/entity.lua` (incinerator)
- `prototypes/projectiles.lua` (toxic-fire)

---

### 8. Fuel Categories - Energy Sources (Critical)

**Issue**: Energy sources use `fuel_categories` (plural, array) not `fuel_category`
**Old Format**:

```lua

energy_source.fuel_category = "waste"

```

**New Format**:

```lua

energy_source.fuel_categories = {"waste"}

```

**Test Case**: Validates energy sources use plural form
**Pattern**: `'fuel_category' is no longer supported. Please use 'fuel_categories'`
**Files Affected**: `prototypes/entity.lua` (toxic-incinerator)

---

### 9. Fuel Category - Items (Important)

**Issue**: Items still use `fuel_category` (singular), while energy sources use `fuel_categories` (plural)
**Format**:

```lua

-- For items (fuel itself)
item.fuel_category = "chemical"

-- For burners/energy sources
energy_source.fuel_categories = {"chemical"}

```

**Test Case**: Validates items use singular, burners use plural
**Pattern**: `Must have a valid fuel_category when fuel_value is used`
**Files Affected**: `data-final-fixes.lua` (toxic-sludge-barrel)

**Note**: This is a subtle distinction - items that ARE fuel use singular, entities that BURN fuel use plural.

---

### 10. Barrel System Changes (Breaking)

**Issue**: Empty barrel item renamed from `empty-barrel` to `barrel`
**Old Format**:

```lua

burnt_result = "empty-barrel"

```

**New Format**:

```lua

burnt_result = "barrel"

```

**Test Case**: Validates barrel items use correct base item
**Pattern**: `item with name 'empty-barrel' does not exist`
**Files Affected**: `data-final-fixes.lua`

---

## Test Case Patterns

All test cases follow this pattern:

1. **Export mod** - Copy files to Factorio mods directory
2. **Data loading** - Run `--dump-data` to validate prototype loading
3. **Save creation** - Create test save to validate runtime
4. **Error parsing** - Extract specific error patterns from output

## Running Tests

```bash

# Run all migration tests
python tests/test_factorio_2_headless.py

# Run with verbose output
python tests/test_factorio_2_headless.py --verbose

# Run via validate_mod (includes migration tests)
python scripts/validate_mod.py

```

## Adding New Test Cases

When discovering a new migration issue:

1. **Document the pattern** - Add error regex to `parse_error_output()` in test file
2. **Add example** - Document old vs new format in this file
3. **Verify fix** - Ensure test catches the issue before and after fix
4. **Cross-reference** - Link issue to specific files and line numbers

---

### 11. Sprite Rectangle Overflow (Critical)

**Issue**: When copying base game entities with custom graphics, sprite sheet coordinates may not match new image dimensions
**Old Approach** (causes error):

```lua

-- Just change filename, keep base game sprite coordinates
toxicflame.particle.filename = GRAPHICS .. "entity/flamethrower-fire-stream/flamethrower-explosion.png"
-- Base game may have coordinates like: left_top=0x432, right_bottom=124x540
-- But our image is only 512x512!

```

**New Approach** (works correctly):

```lua

-- Change filename AND reset sprite properties
toxicflame.particle.filename = GRAPHICS .. "entity/flamethrower-fire-stream/flamethrower-explosion.png"
toxicflame.particle.width = 512
toxicflame.particle.height = 512
toxicflame.particle.frame_count = 1
toxicflame.particle.line_length = 1

```

**Test Case**: Validates sprite rectangles don't exceed image bounds
**Pattern**: `The given sprite rectangle.*is outside the actual sprite size`
**Files Affected**: `prototypes/projectiles.lua` (toxic-flame-stream)

**Root Cause**: When using `util.table.deepcopy()` on base game entities and only changing the filename, you inherit the original sprite sheet layout (frame count, dimensions, coordinates) which may not match your custom graphics.

**Prevention**: Always verify/reset sprite dimensions when using custom graphics:

- `width` and `height` - Match your actual image dimensions
- `frame_count` - Number of animation frames in your sprite sheet
- `line_length` - Frames per row in sprite sheet layout

---

### 12. Sprite Variation Count (Critical)

**Issue**: Base game entities like storage-tank have multiple sprite variations (e.g., 2 different visual styles). When using `deepcopy()` and providing only a single custom graphic, must reset `variation_count` and `repeat_count`.

**Symptom**: Error shows sprite rectangle trying to read beyond image bounds horizontally:

```text
sprite rectangle (left_top=220x0, right_bottom=440x108) is outside actual sprite size (220x108)
```

**Root Cause**: Base game storage-tank has `variation_count = 2` at MULTIPLE LEVELS (pictures, picture, and sheets). This property multiplies sprite width by 2 to read side-by-side variants. Even when replacing the pictures structure, inherited properties can persist.

**Old Approach** (causes error):

```lua
-- Copy storage-tank and change filename
local pollutioncollector = util.table.deepcopy(data.raw["storage-tank"]["storage-tank"])
pollutioncollector.pictures.picture.sheets[1].filename = "my-single-sprite.png"
pollutioncollector.pictures.picture.sheets[1].width = 220
pollutioncollector.pictures.picture.sheets[1].height = 108
-- MISSING: variation_count inherited at multiple levels, tries to read 440px width!
```

**CRITICAL INSIGHT**: `variation_count` can exist at THREE levels:
1. `pictures.variation_count` (container level)
2. `pictures.picture.variation_count` (picture level)
3. `pictures.picture.sheets[N].variation_count` (sheet level)

**New Approach** (works correctly):

```lua
local pollutioncollector = util.table.deepcopy(data.raw["storage-tank"]["storage-tank"])

-- COMPLETE REPLACEMENT with explicit nil at all levels
pollutioncollector.pictures = {
  picture = {
    sheets = {
      {
        filename = GRAPHICS .. "entity/pollution-collector/pollution-collector.png",
        width = 220,
        height = 108,
        frame_count = 1,
        line_length = 1
        -- Do NOT set variation_count at all
      }
    },
    variation_count = nil,  -- CRITICAL: Explicitly nil at picture level
    repeat_count = nil
  },
  variation_count = nil,  -- CRITICAL: Explicitly nil at pictures level
  repeat_count = nil
}
```

**Test Case**: Enhanced log file checking + sprite rectangle validation test suite
**Pattern**: `sprite rectangle.*is outside the actual sprite size`
**Files Affected**: `prototypes/pollutioncollector.lua`

**Prevention**: When using `deepcopy()` with custom graphics:

1. **BEST**: Completely replace the pictures structure (don't patch)
2. Explicitly set `variation_count = nil` at ALL levels (pictures, picture, sheets)
3. Also reset: `repeat_count`, `frame_count`, `line_length`
- `line_length` - Frames per row (usually 1)  
- `variation_count` - Number of visual variants (usually 1)
- `repeat_count` - Repeat pattern (usually 1)
- `hr_version` - Set to `nil` if not providing high-res version

**Test Enhancement**: Added `check_factorio_log()` function to parse log file for graphics errors that don't appear in stdout/stderr.

---

## Summary Statistics

- **Total Issues Found**: 12
- **Files Modified**: 5
  - `prototypes/entity.lua`
  - `prototypes/pollutioncollector.lua` (issues #1, #12)
  - `prototypes/projectiles.lua` (issues #5, #6, #11)
  - `data-final-fixes.lua` (issue #8, #9)
  - `prototypes/recipe.lua` (issue #1, #2)
- **Test Success Rate**: 100% (all issues caught by headless validation)
- **Test Runtime**: ~10 seconds
- **Test Enhancement**: Log file checking added for graphics validation

---

### 13. Water Reflection Sprite Issues (GUI-Specific, Critical)

**Issue**: Inherited `water_reflection` property from base entities can cause sprite rectangle errors in GUI mode (but not headless mode!)

**Problem**:
- Storage-tank has `water_reflection.pictures.variation_count = 1`
- When deepcopying storage-tank, this property is inherited
- Water reflections are only rendered in GUI mode, NOT in headless mode
- This causes sprite rectangle errors that don't show up in `--dump-data` or `--create` tests

**Error Message**:
```
The given sprite rectangle (left_top=220x0, right_bottom=440x108) is outside 
the actual sprite size (left_top=0x0, right_bottom=220x108).
__PollutionSolutionsLite__/graphics/entity/pollution-collector/pollution-collector.png
```

**Before (causes error)**:
```lua
local pollutioncollector = util.table.deepcopy(data.raw["storage-tank"]["storage-tank"])
-- water_reflection property inherited with variation_count=1
```

**After (fixed)**:
```lua
local pollutioncollector = util.table.deepcopy(data.raw["storage-tank"]["storage-tank"])

-- Remove GUI-only properties that have sprite references
pollutioncollector.water_reflection = nil  -- Critical: has variation_count=1
pollutioncollector.window_background = nil
pollutioncollector.fluid_background = nil
pollutioncollector.circuit_connector = nil  -- Optional removal
```

**Test Challenge**: This issue CANNOT be caught by headless tests because water reflections are GUI-only!

**Detection Strategy**:
1. Add recursive search for `variation_count` in all entity properties
2. Log all sprite-related properties during data stage
3. Test in actual GUI game, not just headless mode

**Debug Approach**:
```lua
-- Search for variation_count anywhere in entity
local function find_variation_count(tbl, path)
  if type(tbl) ~= "table" then return end
  for key, value in pairs(tbl) do
    if key == "variation_count" and value ~= nil then
      log("FOUND at " .. path .. "." .. key .. " = " .. tostring(value))
    end
    if type(value) == "table" then
      find_variation_count(value, path .. "." .. key)
    end
  end
end
find_variation_count(entity, "entity_name")
```

**Pattern**: `The given sprite rectangle .* is outside the actual sprite size`
**Files Affected**: `prototypes/pollutioncollector.lua`
**Documented In**: `docs/SPRITE_RECTANGLE_DEBUG.md` (detailed debugging history)

**Key Takeaway**: When deepcopying base entities, ALWAYS remove GUI-specific rendering properties (water_reflection, window_background, fluid_background) unless you're specifically implementing those features.

---

## Best Practices

1. **Use headless Factorio** - Don't mock the API, test against the real thing
2. **Test in GUI mode** - Some errors only appear in GUI (water reflections, etc.)
3. **Test early, test often** - Run tests after every prototype change
4. **Parse error patterns** - Extract structured data from Factorio errors
5. **Document patterns** - Each discovered issue helps future migrations
6. **Version-specific comments** - Mark all migration changes with "Factorio 2.0:" comments
7. **Remove unused properties** - When deepcopying, remove GUI properties you don't need

## Known Limitations

- Tests require Factorio installation
- Cannot test in-game runtime behavior (only prototype loading)
- Some mod compatibility issues may not be caught (depends on installed mods)

## Future Improvements

- [ ] Add test for optional fields (structure, hr_version, etc.)
- [ ] Test mod compatibility with popular mods
- [ ] Automated CI/CD integration
- [ ] Performance benchmarking
- [ ] Graphics validation (file existence, dimensions)
