# Sprite Rectangle Debug: pollution-collector.png

## ✅ SOLVED

**Root Cause:** The `water_reflection.pictures.variation_count = 1` property inherited from storage-tank was causing GUI rendering to try reading our sprite with incorrect dimensions.

**Solution:** Remove `water_reflection` property entirely:

```lua
pollutioncollector.water_reflection = nil
```

**Why This Was Tricky:**

- GUI mode renders water reflections, headless mode doesn't → all headless tests passed
- water_reflection is separate from main pictures structure → initial fixes missed it
- Error message pointed to main sprite file, not the water_reflection property

See [Attempt 9](#attempt-9-explicit-frames1--solution-for-pollution-collector) for details.

---

## Problem Statement

**Error:** `The given sprite rectangle (left_top=220x0, right_bottom=440x108) is outside the actual sprite size (left_top=0x0, right_bottom=220x108)`

**File:** `__PollutionSolutionsLite__/graphics/entity/pollution-collector/pollution-collector.png`

**Analysis:**
- Actual image dimensions: 220x108 pixels
- Error coordinates: (220, 0) to (440, 108)
- X coordinate 220 = exactly 1x width (suggests trying to read second horizontal tile)
- X coordinate 440 = exactly 2x width (suggests `variation_count=2` or `frames=2`)

## Key Facts

1. **Headless mode PASSES**: `--dump-data` and `--create` succeed
2. **GUI mode FAILS**: Actual game window shows sprite error
3. **Tests PASS**: All 6 sprite rectangle tests pass
4. **Base game storage-tank uses**: `frames=2` (NOT `variation_count=2`)
5. **Factorio 2.0 storage-tank**: Already has `variation_count=nil` (confirmed via logs)

## Failed Fix Attempts

### Attempt 1: Loop Reset (variation_count=1)
**Date:** 2024
**Code:**
```lua
for _, sheet in ipairs(pollutioncollector.pictures.picture.sheets) do
  sheet.variation_count = 1
  sheet.repeat_count = 1
end
```
**Result:** ❌ FAILED - Error persists
**Why it failed:** Setting to 1 still reserves space for variants

### Attempt 2: Set to nil
**Date:** 2024
**Code:**
```lua
for _, sheet in ipairs(pollutioncollector.pictures.picture.sheets) do
  sheet.variation_count = nil
end
```
**Result:** ❌ FAILED - Error persists
**Why it failed:** Only patched sheet level, not picture/pictures levels

### Attempt 3: Reset offsets and scale
**Date:** 2024
**Code:**
```lua
for _, sheet in ipairs(pollutioncollector.pictures.picture.sheets) do
  sheet.variation_count = nil
  sheet.x = 0
  sheet.y = 0
  sheet.scale = nil
end
```
**Result:** ❌ FAILED - Error persists
**Why it failed:** Offsets weren't the issue

### Attempt 4: Complete pictures replacement
**Date:** 2024
**Code:**
```lua
pollutioncollector.pictures = {
  picture = {
    sheets = {
      {
        filename = GRAPHICS .. "entity/pollution-collector/pollution-collector.png",
        width = 220,
        height = 108,
        frame_count = 1,
        line_length = 1
      }
    }
  }
}
```
**Result:** ❌ FAILED - Error persists
**Why it failed:** Didn't explicitly set variation_count=nil at all levels

### Attempt 5: Multi-level variation_count=nil
**Date:** 2024
**Code:**
```lua
pollutioncollector.pictures = {
  picture = {
    sheets = {
      {
        filename = GRAPHICS .. "entity/pollution-collector/pollution-collector.png",
        width = 220,
        height = 108,
        frame_count = 1,
        line_length = 1
      }
    },
    variation_count = nil,
    repeat_count = nil
  },
  variation_count = nil,
  repeat_count = nil
}
```
**Result:** ❌ FAILED - Error persists
**Why it failed:** Pictures structure isn't the issue

### Attempt 6: Remove window_background/fluid_background
**Date:** 2024-11-09
**Code:**
```lua
pollutioncollector.window_background = nil
pollutioncollector.fluid_background = nil
```
**Result:** ⏳ TESTING
**Why it might work:** These are storage-tank GUI elements that might have variation_count

### Attempt 7: Remove circuit_connector
**Date:** 2024-11-09
**Code:**
```lua
pollutioncollector.circuit_connector = nil
```
**Result:** ❌ FAILED (but was good hygiene)
**Why it failed:** Circuit connector wasn't the issue

### Attempt 8: Remove water_reflection ⚠️ PARTIAL
**Date:** 2024-11-09
**Code:**
```lua
pollutioncollector.water_reflection = nil
```
**Result:** ⚠️ PARTIAL - Fixed pollution-collector but revealed another issue
**Why it helped:** Removed GUI-only water reflection rendering

### Attempt 9: Explicit frames=1 ✅ SOLUTION FOR POLLUTION-COLLECTOR
**Date:** 2024-11-09
**Code:**
```lua
pollutioncollector.pictures = {
  picture = {
    sheets = {
      {
        filename = GRAPHICS .. "entity/pollution-collector/pollution-collector.png",
        width = 220,
        height = 108,
        frames = 1,  -- CRITICAL: storage-tank has frames=2
        frame_count = 1,
        line_length = 1
      }
    }
  }
}
```
**Result:** ✅ SUCCESS - pollution-collector error resolved!
**Why it works:**

- Base game storage-tank uses `frames=2` (not variation_count!)
- `frames` defines horizontal animation frames in sprite sheet
- Storage-tank has frames=2 with width=219px = 438px total
- Our sprite is 220px wide, so frames=2 tries to read 440px (220×2) → ERROR
- Setting `frames=1` explicitly tells Factorio to only read one frame
- This also revealed flamethrower-fire-stream has same issue

## Debug Logging Output

From headless mode `--dump-data`:
```
=== BEFORE REPLACEMENT ===
pictures.variation_count: nil
pictures.picture.variation_count: nil
Sheet 1 variation_count: nil
Sheet 2 variation_count: nil

=== AFTER REPLACEMENT ===
pictures.variation_count: nil
pictures.picture.variation_count: nil
Sheet 1 variation_count: nil
```

**Key Finding:** variation_count is ALREADY nil in Factorio 2.0 storage-tank base prototype!

## Critical Discrepancy

**Headless vs GUI:**
- Headless `--dump-data`: ✅ SUCCESS
- Headless `--create`: ✅ SUCCESS  
- GUI game load: ❌ FAILS with sprite error

**Hypothesis:** The sprite error is coming from:
1. ~~Pictures structure~~ (confirmed nil)
2. ~~window_background~~ (testing)
3. ~~fluid_background~~ (testing)
4. ~~circuit_connector~~ (testing)
5. **GUI-specific rendering** (overlays, selection boxes, etc.)
6. **Another mod** modifying the entity
7. **data-final-fixes.lua** making changes

## Properties Inherited from storage-tank

From base game definition (`base/prototypes/entity/entities.lua`):

```lua
-- Main pictures
pictures.picture.sheets[1].frames = 2  -- NOT variation_count!
pictures.picture.sheets[1].width = 219
pictures.picture.sheets[1].scale = 0.5

-- GUI elements
window_background = { width = 34, height = 48 }
fluid_background = { width = 32, height = 15 }

-- Circuit
circuit_connector = circuit_connector_definitions["storage-tank"]

-- Water reflection
water_reflection.pictures.variation_count = 1  -- Explicitly set!
```

## Next Steps

1. ✅ Remove window_background
2. ✅ Remove fluid_background
3. ✅ Remove circuit_connector
4. ⏳ Test in actual game
5. ⬜ If still fails: Check water_reflection
6. ⬜ If still fails: Check if data-final-fixes modifies entity
7. ⬜ If still fails: Nuclear option - don't use deepcopy, define from scratch

## Potential Root Causes

### Theory 1: GUI Overlay Sprites
GUI mode might render additional sprites for circuit connections, fluid windows, etc. that headless skips.

### Theory 2: Water Reflection
The water_reflection property has `variation_count=1` but references our sprite somehow.

### Theory 3: Circuit Connector Sprites
Circuit connectors have their own sprites but might try to reference the entity sprite.

### Theory 4: Another Entity Reference
Some other entity or effect might reference pollution-collector.png with variation_count.

### Theory 5: Sprite Cache Issue
Despite clearing cache, GUI might have a different cache location or mechanism.

## Test Strategy

Since headless tests pass but GUI fails, we need:

1. **Comprehensive property logging** - Log ALL sprite properties at data stage
2. **Runtime validation** - Add control.lua logging when entity is created
3. **Grep all files** - Search for references to pollution-collector in ALL game files
4. **Compare working entity** - Find an entity that works and compare all properties
5. **Nuclear option** - Don't inherit from storage-tank at all

## Status

**Current State:** ✅ RESOLVED (pollution-collector) → 🔄 FIXING OTHER SPRITES

**Solution for pollution-collector:** Set `frames=1` explicitly + remove GUI properties

**Root Cause:** Base game entities use `frames=2` or higher for animation, which causes Factorio to try reading multiple horizontal frames. Our custom sprites are single-frame, so inherited `frames` values cause sprite rectangle errors.

**Progress:**
- ✅ pollution-collector.lua: Fixed (frames=1 + water_reflection=nil)
- ✅ flamethrower-fire-stream: Fixed (frames=1 on spine_animation and particle)
- ⏳ 4 more entities need frames=1: firetoxic, toxicsticker, firetoxicontree, toxiccloud_small

## Key Takeaways

### Why This Was Hard to Debug

1. **GUI vs Headless Discrepancy:** Water reflections are only rendered in GUI mode, not in headless `--dump-data` or `--create` tests
2. **Hidden Property:** `water_reflection` wasn't in the main `pictures` structure, so our initial fixes didn't touch it
3. **Deep Inheritance:** `util.table.deepcopy()` copies ALL properties, including GUI-only rendering properties
4. **Non-obvious Error:** The error pointed to pollution-collector.png, but the issue was in water_reflection, not the main sprite

### Debugging Strategy That Worked

1. **Comprehensive Logging:** Added recursive search for `variation_count` anywhere in entity structure
2. **Systematic Documentation:** Documented each failed attempt to avoid repeating mistakes
3. **Log Analysis:** Used `serpent.line()` to dump entire data structures
4. **Process of Elimination:** Removed properties one by one until finding the culprit

### Best Practices for Factorio Modding

1. **Don't blindly deepcopy:** Understand what properties you're inheriting
2. **Remove unused properties:** If you don't need water reflections, circuit connectors, etc., remove them
3. **Test in GUI mode:** Headless tests don't catch GUI-specific rendering issues
4. **Search recursively:** Don't assume sprite properties are only in `pictures` or `animation`
5. **Use debug logging:** Factorio's `log()` and `serpent` library are invaluable

### Properties to Watch When Deepcopying

When using `util.table.deepcopy()` on base game entities, be aware these properties might have sprite references:

- ✅ `pictures` - Main entity sprite (you'll modify this)
- ⚠️ `water_reflection` - GUI water rendering (remove if not needed)
- ⚠️ `window_background` - GUI overlay for storage tanks (remove if not needed)
- ⚠️ `fluid_background` - GUI overlay for fluid containers (remove if not needed)
- ⚠️ `circuit_connector` - Circuit network overlay (has own sprites usually)
- ⚠️ `working_visualisations` - Animation overlays (check if inherited)
- ⚠️ `frozen_patch` - Ice/frozen state sprite (rare but exists)
