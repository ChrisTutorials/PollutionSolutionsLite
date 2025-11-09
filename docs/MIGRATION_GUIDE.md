# Migration Development Guide for Pollution Solutions Lite

**Versions**: Factorio 2.0+  
**Last Updated**: November 9, 2025

---

## Overview

Migrations in Factorio run when a player loads a save with an old mod version. They're essential for:
- Updating player data structures
- Unlocking new recipes/technologies
- Fixing broken configurations
- Converting between API versions

**Critical Rule**: Migrations can CRASH a player's save if they access nil values.

---

## The Problem: Why Migrations Crash

### ❌ Unsafe Migration (CRASHES if recipe doesn't exist)

```lua
-- BAD: Direct access - CRASHES if recipe is nil
recipes["fill-polluted-air-barrel"].enabled = true
-- Error: attempt to index field 'fill-polluted-air-barrel' (a nil value)
```

### ✅ Safe Migration (SAFE - checks before accessing)

```lua
-- GOOD: Check before accessing
if recipes["fill-polluted-air-barrel"] then
  recipes["fill-polluted-air-barrel"].enabled = true
end
```

---

## Why This Happens

1. **Different Mod Combinations**: Players install different mods
   - Some might have barreling recipes from other mods
   - Some might not have them at all
   - Base game recipes may not exist in all versions

2. **Mod Load Order**: Mods load in different order
   - Migration runs before all mods are loaded
   - Recipe might be added by another mod that hasn't loaded yet

3. **Version Differences**: Factorio versions change
   - Recipes added/removed between versions
   - Migration must work on ALL versions the mod supports

---

## Safe Migration Patterns

### Pattern 1: Check Recipe Exists

```lua
-- Migration: Unlock a recipe based on technology
for _, force in pairs(game.forces) do
  local recipes = force.recipes
  local technologies = force.technologies
  
  -- SAFE: Check if recipe exists before accessing
  if recipes["my-recipe"] then
    recipes["my-recipe"].enabled = technologies["my-tech"].researched
  end
end
```

### Pattern 2: Check Technology Exists

```lua
-- SAFE: Check if technology exists
if force.technologies["my-tech"] then
  force.technologies["my-tech"].researched = true
end
```

### Pattern 3: Use pcall for Complex Operations

```lua
-- SAFE: Wrap risky operations in pcall
local success, result = pcall(function()
  -- Try risky operation here
  return force.recipes["my-recipe"].category
end)

if success and result then
  -- Safe to use result
  print("Category: " .. result)
else
  log("WARNING: Could not access recipe category")
end
```

### Pattern 4: Iterate Safely

```lua
-- SAFE: Iterate with nil checks
for recipe_name, recipe in pairs(force.recipes) do
  if recipe and recipe.enabled ~= nil then
    -- Safe to use recipe
    recipe.enabled = true
  end
end
```

### Pattern 5: Handle Missing Items

```lua
-- SAFE: Create with default if missing
local my_item = storage[force.index] or {}
my_item.data = my_item.data or {}
storage[force.index] = my_item
```

---

## Common Mistakes to Avoid

### ❌ MISTAKE 1: Direct Table Access Without Check

```lua
-- BAD: Will crash if recipe doesn't exist
recipes["my-recipe"].enabled = true

-- GOOD: Check first
if recipes["my-recipe"] then
  recipes["my-recipe"].enabled = true
end
```

### ❌ MISTAKE 2: Assuming All Mods Are Installed

```lua
-- BAD: Crashes if mod_name isn't installed
data.raw["technology"]["from-other-mod"].effects = {}

-- GOOD: Check if it exists
if data.raw["technology"]["from-other-mod"] then
  data.raw["technology"]["from-other-mod"].effects = {}
end
```

### ❌ MISTAKE 3: Nested Access Without Checking

```lua
-- BAD: Multiple levels - crashes at ANY nil
entity.surface.map_gen_settings.water_tile_set = "test"

-- GOOD: Check each level
if entity and entity.surface and entity.surface.map_gen_settings then
  entity.surface.map_gen_settings.water_tile_set = "test"
end
```

### ❌ MISTAKE 4: Forgetting All Forces

```lua
-- BAD: Only affects "player" force
game.forces.player.recipes["my-recipe"].enabled = true

-- GOOD: Iterate all forces (important for multiplayer)
for _, force in pairs(game.forces) do
  if force.recipes["my-recipe"] then
    force.recipes["my-recipe"].enabled = true
  end
end
```

### ❌ MISTAKE 5: No Logging

```lua
-- BAD: Silent failure - nobody knows something went wrong
if recipes["my-recipe"] then
  -- Operation
end

-- GOOD: Log what you're doing
if recipes["my-recipe"] then
  log("Enabling recipe: my-recipe")
  recipes["my-recipe"].enabled = true
else
  log("WARNING: Could not find recipe 'my-recipe' - possibly optional")
end
```

---

## Migration Checklist

Before creating a migration, verify:

- [ ] **Nil-Safe**: All table accesses check for nil first
- [ ] **Multi-Force**: Works with `game.forces` loop (multiplayer safe)
- [ ] **Optional Checks**: Uses logging for optional features
- [ ] **Error Handling**: No assumptions about mod combinations
- [ ] **Tested**: Created unit tests with missing data scenarios
- [ ] **Documented**: Comments explain what migration does and why
- [ ] **Named Correctly**: File format is `ModName.VERSION.lua` (e.g., `PollutionSolutionsLite.1.0.20.lua`)
- [ ] **Performance**: Doesn't do expensive operations for every player

---

## Migration Testing

### Test 1: Run with All Data Present

```lua
-- Setup: Create all expected recipes/technologies
-- Run: Execute migration logic
-- Assert: All values updated correctly
```

### Test 2: Run with Missing Data

```lua
-- Setup: Create ONLY some recipes/technologies
-- Run: Execute migration logic (MUST NOT CRASH)
-- Assert: Present items updated, missing items ignored
```

### Test 3: Run with Empty Data

```lua
-- Setup: Create empty tables (no recipes, no technologies)
-- Run: Execute migration logic (MUST NOT CRASH)
-- Assert: No errors, operation completes gracefully
```

### Test 4: Run Multiple Times

```lua
-- Run migration multiple times
-- Should be idempotent (same result each time)
-- Should not crash on subsequent runs
```

---

## Real Example: PollutionSolutionsLite v1.0.20

### Problem
Mod wanted to unlock barrel recipes based on "fluid-handling" technology. Original code:

```lua
-- BAD: Crashes if recipes don't exist
recipes["fill-polluted-air-barrel"].enabled = technologies["fluid-handling"].researched
```

### Solution

```lua
-- GOOD: Safe nil-checks
for _, force in pairs(game.forces) do
  local technologies = force.technologies
  local recipes = force.recipes

  if recipes["fill-polluted-air-barrel"] then
    recipes["fill-polluted-air-barrel"].enabled = technologies["fluid-handling"].researched
  end

  if recipes["empty-polluted-air-barrel"] then
    recipes["empty-polluted-air-barrel"].enabled = technologies["fluid-handling"].researched
  end

  if recipes["fill-toxic-sludge-barrel"] then
    recipes["fill-toxic-sludge-barrel"].enabled = technologies["fluid-handling"].researched
  end

  if recipes["empty-toxic-sludge-barrel"] then
    recipes["empty-toxic-sludge-barrel"].enabled = technologies["fluid-handling"].researched
  end
end
```

### Tests

```lua
-- Test 1: All recipes exist, tech researched → all enabled
-- Test 2: No recipes exist → no crash, no changes
-- Test 3: Some recipes exist → only present ones updated
-- Test 4: Multiple forces → all get correct state
```

---

## When NOT to Write a Migration

Migrations should only be used for **save-breaking changes**:

### ✅ DO Write a Migration
- Recipe disabled needs to be enabled
- Technology needs unlocking for old saves
- Player data structure changed
- Global settings need conversion
- Entity IDs changed (must update references)

### ❌ DON'T Write a Migration
- Just balancing numbers (players can recreate recipes)
- Changing mod description (cosmetic)
- Adding new content (players unlock normally)
- Bug fixes that don't affect saves

---

## Migration File Naming

```
Format: ModName.VERSION.lua
Example: PollutionSolutionsLite.1.0.20.lua

Structure in migrations/ directory:
migrations/
  ├── PollutionSolutionsLite.1.0.20.lua  (v1.0.20 migration)
  └── PollutionSolutionsLite.1.1.0.lua   (v1.1.0 migration)
```

Factorio runs migrations in **version order**:
1. `1.0.20` runs first (converts from 1.0.19 to 1.0.20)
2. `1.1.0` runs second (converts from 1.0.20 to 1.1.0)

This matters if your new version needs data from a previous migration.

---

## Debugging Migration Crashes

If a player reports a migration crash:

1. **Get the Error Message**
   ```
   Error: attempt to index field 'X' (a nil value)
   Stack trace shows line number
   ```

2. **Add Nil Check**
   ```lua
   if field["X"] then
     -- Now safe to access
   end
   ```

3. **Add Logging**
   ```lua
   log("Migration: Processing force " .. force.name)
   log("Found recipe: X = " .. tostring(field["X"]))
   ```

4. **Test Scenarios**
   - Test with recipe missing
   - Test with empty tables
   - Test with different mod combinations

5. **Verify Fix**
   - Run migration tests
   - Ask player to try again
   - Monitor for similar issues

---

## Factorio 2.0 Specific Notes

### storage vs global

Factorio 2.0 replaced `global` with `storage`:

```lua
-- Factorio 1.x migration
global.my_data = global.my_data or {}

-- Factorio 2.0 migration
storage.my_data = storage.my_data or {}
```

### API Changes

Check what changed in your version:
- [Factorio 2.0 Migration Guide](https://wiki.factorio.com/Upgrading_to_v2.0)
- [Runtime API Changes](https://lua-api.factorio.com/latest/index-runtime.html)

### Recipe Format

Factorio 2.0 changed recipe format:

```lua
-- Factorio 1.x
recipe.result = "item-name"
recipe.results = nil

-- Factorio 2.0
recipe.results = { { type = "item", name = "item-name", amount = 1 } }
```

Migrations need to handle both if supporting both versions.

---

## Performance Considerations

Migrations run during save load - they must be FAST:

```lua
-- BAD: Expensive loop inside force loop
for _, force in pairs(game.forces) do
  for _, recipe_name in pairs(game.recipe_prototypes) do
    -- O(n²) complexity - slow!
  end
end

-- GOOD: Simple table lookups
for _, force in pairs(game.forces) do
  if force.recipes["specific-recipe"] then
    -- O(1) lookup - fast!
  end
end
```

---

## Complete Migration Template

```lua
--[[
  Migration for Pollution Solutions Lite v1.0.20
  
  Description: What this migration does and why
  
  Changes:
  - What changes (bullet list)
  
  Compatibility: Works with Factorio 2.0+, all mod combinations
]]

-- Iterate all forces (supports multiplayer)
for _, force in pairs(game.forces) do
  local technologies = force.technologies
  local recipes = force.recipes

  -- Check and update each recipe
  if recipes["recipe-name"] then
    -- Safe to access now
    recipes["recipe-name"].enabled = technologies["tech-name"].researched
  else
    -- Optional: Log missing recipe
    log("Note: recipe-name not found (may be from optional mod)")
  end
end

-- If using storage for data
storage.my_data = storage.my_data or {}
storage.my_data.migrated_v1_0_20 = true
```

---

## Related Files

- **Migration Tests**: `tests/test_migrations.lua`
- **Integration Tests**: `tests/test_migrations_integration.py`
- **Example Migration**: `migrations/PollutionSolutionsLite.1.0.20.lua`
- **Changelog**: `changelog.txt`

---

## Further Reading

- [Factorio Mod Structure](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html)
- [Factorio Data Lifecycle](https://wiki.factorio.com/Data-lifecycle)
- [Migration Examples](https://forums.factorio.com/viewforum.php?f=14) (Mod Forums)

---

**Remember**: A good migration is one that never crashes, handles missing data gracefully, and leaves saves in a playable state.

**Test migrations extensively before release.**
