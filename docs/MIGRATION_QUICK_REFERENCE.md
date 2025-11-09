# Quick Reference: Migration Testing

**For**: Developers working on Pollution Solutions Lite  
**Updated**: November 9, 2025

---

## Run Migration Tests

### Lua Unit Tests
```bash
lua tests/test_migrations.lua
```

**Tests**: 5 scenarios (all recipes, missing recipes, tech state, partial set, multiple forces)  
**Time**: < 1 second

### Python Integration Tests
```bash
python tests/test_migrations_integration.py
```

**Tests**: Syntax validation, nil-safety patterns, Lua unit execution  
**Time**: < 5 seconds

---

## Before Releasing a New Version

1. **Update Migration** (if needed)
   ```bash
   # Edit migrations/PollutionSolutionsLite.NEW_VERSION.lua
   vim migrations/PollutionSolutionsLite.1.2.0.lua
   ```

2. **Follow Patterns**
   - ✓ Use nil-checks: `if recipes["X"] then`
   - ✓ Iterate forces: `for _, force in pairs(game.forces)`
   - ✓ Add comments explaining what/why
   - ✓ Log operations: `log("Migration: doing X")`

3. **Test It**
   ```bash
   lua tests/test_migrations.lua
   python tests/test_migrations_integration.py
   ```

4. **Commit With Tests**
   ```bash
   git add -A
   git commit -m "feat: add migration for vX.Y.Z

   Description of what this migration does.
   
   Tests created:
   - Verify all scenarios work
   - Check nil-safety"
   ```

---

## Common Migration Patterns

### Pattern 1: Enable Recipe Based on Tech
```lua
if force.recipes["my-recipe"] then
  force.recipes["my-recipe"].enabled = force.technologies["my-tech"].researched
end
```

### Pattern 2: Update All Recipes in Category
```lua
for recipe_name, recipe in pairs(force.recipes) do
  if recipe and recipe.category == "smelting" then
    recipe.enabled = true
  end
end
```

### Pattern 3: Handle Missing Technology
```lua
if force.technologies["my-tech"] then
  force.technologies["my-tech"].researched = true
end
```

### Pattern 4: Store Data in Storage
```lua
storage.migration_completed = storage.migration_completed or {}
storage.migration_completed["1.2.0"] = true
```

---

## Debugging a Migration Crash

**Error**: `attempt to index field 'X' (a nil value)`

**Step 1**: Find the line
```lua
-- Add nil check
if field then
  -- operation
end
```

**Step 2**: Add logging
```lua
log("Debug: field = " .. tostring(field))
```

**Step 3**: Test scenarios
```bash
# Test with missing data
lua tests/test_migrations.lua
```

**Step 4**: Verify fix
```bash
# Run both test suites
python tests/test_migrations_integration.py
```

---

## File Reference

| File | Purpose |
|------|---------|
| `migrations/` | Migration scripts (one per version) |
| `tests/test_migrations.lua` | Unit tests with mock data |
| `tests/test_migrations_integration.py` | Integration tests |
| `docs/MIGRATION_GUIDE.md` | Complete migration best practices |
| `MIGRATION_FIX_SUMMARY.md` | User-friendly fix explanation |

---

## Useful Factorio APIs in Migrations

```lua
-- Forces
game.forces                          -- table of forces
force.name                           -- force name
force.recipes                        -- all recipes
force.technologies                   -- all technologies
force.recipes["name"].enabled        -- recipe enabled state
force.technologies["name"].researched -- tech researched state

-- Storage (Factorio 2.0+)
storage.my_key = value              -- persistent data
storage.my_key = storage.my_key or {}  -- with default

-- Logging
log("message")                       -- log message
log("ERROR: " .. error_msg)          -- error logging
```

---

## Version Naming

```
Format: ModName.VERSION.lua
Examples:
  PollutionSolutionsLite.1.0.20.lua  -- v1.0.20 migration
  PollutionSolutionsLite.1.1.0.lua   -- v1.1.0 migration
  PollutionSolutionsLite.2.0.0.lua   -- v2.0.0 migration
```

Factorio runs them in order when loading old saves.

---

## Checklist for New Migrations

- [ ] File named correctly: `ModName.VERSION.lua`
- [ ] Placed in `migrations/` directory
- [ ] All table accesses use nil-checks
- [ ] Iterates all forces (not just "player")
- [ ] Handles missing recipes/technologies gracefully
- [ ] Has comments explaining what it does
- [ ] Logs important operations
- [ ] Tested with `lua tests/test_migrations.lua`
- [ ] Integration tests pass: `python tests/test_migrations_integration.py`
- [ ] Documented in `docs/MIGRATION_GUIDE.md`

---

## Example: Complete Safe Migration

```lua
--[[
  Migration for Pollution Solutions Lite v1.1.0
  
  Description: Unlock new pollution-processing recipes
  when players have researched incineration technology
]]

-- Iterate all forces (multiplayer safe)
for _, force in pairs(game.forces) do
  local recipes = force.recipes
  local technologies = force.technologies
  
  -- Safely unlock recipes based on tech state
  if recipes["advanced-pollution-filtering"] then
    recipes["advanced-pollution-filtering"].enabled = 
      technologies["incineration"].researched
  end
  
  if recipes["pollution-liquification-v2"] then
    recipes["pollution-liquification-v2"].enabled = 
      technologies["incineration"].researched
  end
  
  log("Migration 1.1.0: Updated recipes for " .. force.name)
end

-- Mark migration as complete
storage.migrated_v1_1_0 = true
```

---

## Need Help?

1. Read: `docs/MIGRATION_GUIDE.md` (comprehensive)
2. Check: `migrations/PollutionSolutionsLite.1.0.20.lua` (real example)
3. Test: `tests/test_migrations.lua` (test examples)
4. Debug: Add `log()` statements and check `player-data/` logs

---

**Last Updated**: November 9, 2025  
**Mod Version**: 1.1.0  
**Factorio**: 2.0+
