---
applyTo: '**'
---

# Factorio Mod Development Practices

## Code Philosophy: Fail Fast, Not Safe Code

When developing code for this Factorio mod, prioritize **fail-fast** error detection over defensive null-checking patterns. Deeply nested if-else structures reduce readability and maintainability.

### ❌ AVOID: Deep Nesting (Defensive Code)

```lua
if lowheater.structure then
  if lowheater.structure.north and lowheater.structure.north.layers then
    if lowheater.structure.north.layers[1] then
      lowheater.structure.north.layers[1].filename = GRAPHICS.."entity/..."
    end
  end
end
```

**Problems:**
- Unclear what the actual requirements are
- Pyramid of doom pattern reduces readability
- Silent failures make debugging harder
- Wastes indentation levels

### ✅ PREFER: Fail-Fast with Assertions

```lua
-- Fail fast: Assert required structure exists
assert(lowheater.structure, "Low-heat-exchanger structure not found")
assert(lowheater.structure.north and lowheater.structure.north.layers, "Structure.north.layers not found")

-- Set filenames
lowheater.structure.north.layers[1].filename = GRAPHICS.."entity/..."

-- Optional: Check only for optional features
if lowheater.structure.north.layers[1].hr_version then
  lowheater.structure.north.layers[1].hr_version.filename = GRAPHICS.."entity/..."
end
```

**Benefits:**
- Clear distinction between required and optional properties
- Explicit error messages when things fail
- Flat code structure, easy to read
- Failures are caught immediately at the problem source

## Guidelines

1. **Required fields**: Use `assert()` to verify required structure exists
2. **Optional fields**: Use `if` conditions only for genuinely optional properties (like `hr_version` which may not exist in all Factorio versions)
3. **Error messages**: Provide meaningful context in assertion messages
4. **Separate concerns**: Group assertions at the start, then straightforward assignments
5. **Comments**: Use comments to explain why a field is optional vs required

## Version Compatibility: Handle Optional Fields Gracefully

When working with Factorio base game entities that may change between versions, distinguish between critical and optional fields:

### Critical Fields (Assert)
Fields that the mod **requires** to function:
```lua
assert(incinerator.picture and incinerator.picture.layers, "Incinerator picture.layers not found")
assert(incinerator.picture.layers[1], "Incinerator picture.layers[1] not found")
```

### Optional/Version-Dependent Fields (Check)
Fields that may not exist in all Factorio versions:
```lua
-- structure field may not exist in Factorio 2.0+
if lowheater.structure then
  setAllDirectionalGraphics(lowheater.structure, "entity/low-heat-exchanger/")
else
  log("WARNING: Low-heat-exchanger has no structure field - entity graphics will use default")
end
```

### Optional Enhancement Fields (Check)
Fields like `hr_version` that enhance but aren't required:
```lua
if layer.hr_version then
  layer.hr_version.filename = hr_filename
end
```

## Extract Dense Logic into Helper Functions

When code becomes repetitive or deeply nested, extract it into helper functions:

### ❌ AVOID: Repetitive Graphics Setup
```lua
lowheater.structure.north.layers[1].filename = GRAPHICS.."entity/low-heat-exchanger/lowheatex-N-idle.png"
if lowheater.structure.north.layers[1].hr_version then
  lowheater.structure.north.layers[1].hr_version.filename = GRAPHICS.."entity/low-heat-exchanger/hr-lowheatex-N-idle.png"
end
lowheater.structure.east.layers[1].filename = GRAPHICS.."entity/low-heat-exchanger/lowheatex-E-idle.png"
if lowheater.structure.east.layers[1].hr_version then
  lowheater.structure.east.layers[1].hr_version.filename = GRAPHICS.."entity/low-heat-exchanger/hr-lowheatex-E-idle.png"
end
-- ...repeat for south and west
```

### ✅ PREFER: Helper Functions
```lua
-- In util.lua
function setLayerGraphics(layer, filename, hr_filename)
  layer.filename = filename
  if hr_filename and layer.hr_version then
    layer.hr_version.filename = hr_filename
  end
end

function setAllDirectionalGraphics(structure, base_path)
  assert(structure.north and structure.north.layers, "Structure.north.layers not found")
  assert(structure.east and structure.east.layers, "Structure.east.layers not found")
  assert(structure.south and structure.south.layers, "Structure.south.layers not found")
  assert(structure.west and structure.west.layers, "Structure.west.layers not found")
  
  setLayerGraphics(structure.north.layers[1], GRAPHICS .. base_path .. "lowheatex-N-idle.png", 
    GRAPHICS .. base_path .. "hr-lowheatex-N-idle.png")
  -- ...east, south, west
end

-- In entity.lua
if lowheater.structure then
  setAllDirectionalGraphics(lowheater.structure, "entity/low-heat-exchanger/")
end
```

**Benefits:**
- DRY principle - Don't Repeat Yourself
- Easier to test helper functions in isolation
- Easier to update graphics paths globally
- Self-documenting code

## Testing Philosophy

1. **Test helper functions** - Unit test utility functions with mock data
2. **Fail-fast tests** - Tests should use assertions and clear error messages
3. **Version compatibility** - Test with different data structures to catch version issues
4. **Mock Factorio structures accurately** - Ensure test mocks match actual game data structure