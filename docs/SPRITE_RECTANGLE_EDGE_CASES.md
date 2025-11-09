# Sprite Rectangle Overflow Edge Cases

This document catalogs edge cases that can cause sprite rectangle overflow errors in Factorio 2.0.

## Issue Description

Error: `The given sprite rectangle (left_top=Xx0, right_bottom=YxZ) is outside the actual sprite size`

This occurs when Factorio tries to read sprite data from a location that exceeds the actual image dimensions.

## Root Causes

### 1. Deepcopy Sprite Layout Inheritance

**Problem**: When using `util.table.deepcopy()` on base game entities, sprite layout properties are copied:
- `variation_count` - Number of visual variants (multiplies sprite width)
- `repeat_count` - Pattern repetition
- Frame and line layout properties

**Example Error**:
- Image: 220×108 pixels
- variation_count inherited: 2
- Factorio calculates: width = 220 × 2 = 440
- Tries to read rectangle: (0, 0) to (440, 108)
- **Result**: Rectangle exceeds image bounds!

### 2. Partial Property Reset

**Problem**: Resetting only some sheet properties while leaving others intact:

```lua
-- WRONG: Only sheets[1]
pollutioncollector.pictures.picture.sheets[1].width = 220
-- sheets[2] (shadow) still has base game layout!

-- WRONG: Setting variation_count = 1 instead of nil
sheet.variation_count = 1  -- Still tells Factorio there's a variation system
```

### 3. Multiple Sheets

**Problem**: Base game entities like storage-tank have multiple sprite sheets:
1. Main picture (219×235)
2. Shadow layer (291×153)

Both sheets may have incompatible layout properties.

## Test Cases

### Test 1: Deepcopy Sprite Reset Validation
Verifies that sprite structure is completely replaced, not patched.

**Edge Case**: Entity has deeply nested `pictures.picture.sheets[*]` structure with multiple layers.

### Test 2: Variation Count Removal
Ensures `variation_count` is properly removed.

**Edge Cases**:
- `variation_count = 1` (incorrect - still activates variation system)
- `variation_count = nil` (correct - disables variations)
- Omitted (acceptable if no variations needed)

### Test 3: All Sheets Reset
Verifies ALL sheets are reset, not just sheets[1].

**Edge Case**: Shadow layers or additional sheets aren't reset, causing errors for shadows/glows.

### Test 4: Frame Count and Line Length
Validates animation frame layout properties.

**Edge Cases**:
- Missing `frame_count`
- Missing `line_length`
- Wrong values causing frame overflow

### Test 5: HR Version Handling
Ensures high-resolution variants don't cause issues.

**Edge Cases**:
- HR version defined but not provided
- HR version with incompatible dimensions
- Scale properties conflicting

### Test 6: Headless Factorio Validation
Final integration test using actual Factorio engine.

**Edge Cases**:
- Cache causing old sprite data to persist
- Mod loading order issues
- Conditional sprite definitions

## Solutions

### Solution 1: Complete Picture Replacement (RECOMMENDED)

Instead of patching deepcopy result, completely replace the pictures structure:

```lua
local pollutioncollector = util.table.deepcopy(data.raw["storage-tank"]["storage-tank"])

-- REPLACE the pictures structure entirely
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

**Advantages**:
- No inherited base game properties
- Clear and explicit definition
- Easy to understand and maintain
- No risk of missing a property

### Solution 2: Comprehensive Property Reset

If you need to preserve some base game properties, reset ALL layout properties:

```lua
for _, sheet in ipairs(pollutioncollector.pictures.picture.sheets) do
  sheet.filename = GRAPHICS .. "entity/my-entity.png"
  sheet.width = 220
  sheet.height = 108
  sheet.x = 0
  sheet.y = 0
  sheet.frame_count = 1
  sheet.line_length = 1
  sheet.variation_count = nil      -- CRITICAL: nil, not 1!
  sheet.repeat_count = nil
  sheet.scale = nil
  sheet.hr_version = nil           -- Remove if not providing
end
```

**Advantages**:
- Preserves other properties (collision_mask, fluid_box, etc.)
- Explicitly controls each aspect

## Prevention Strategies

1. **Use headless Factorio validation** - Test against real engine, not mocks
2. **Test with verbose logging** - Log sprite properties before/after
3. **Check actual image dimensions** - Verify sprite definitions match files
4. **Avoid partial patching** - Complete replacement is safer
5. **Document all properties** - Comment why each property is set
6. **Test all sheet variations** - Verify all layers (main, shadow, etc.)

## Files Affected

- `prototypes/pollutioncollector.lua` - Uses complete picture replacement

## Related Issues

- Factorio 2.0 Migration Issue #11: Sprite Rectangle Overflow (deepcopy)
- Factorio 2.0 Migration Issue #12: Sprite Variation Count (storage-tank)

## Testing

Run sprite rectangle tests:
```bash
python tests/test_sprite_rectangles.py
```

Run full migration tests:
```bash
python tests/test_factorio_2_headless.py
```
