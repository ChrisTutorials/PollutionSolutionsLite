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

### Use Real Factorio Validation (Headless Mode)

**DO NOT** mock the Factorio API - use actual Factorio validation:

```bash
# Run Factorio 2.0 migration tests
python tests/test_factorio_2_headless.py
```

**Benefits:**
- Source of truth - tests against real game engine
- Catches all API changes automatically
- No mock maintenance burden
- Tests actual runtime behavior
- Validates graphics, sprites, and assets

### Test-Driven Debugging

When you encounter an error:

1. **Reproduce in test** - Add test case that catches the issue
2. **Document pattern** - Add error regex to test parser
3. **Fix the issue** - Update mod code
4. **Verify fix** - Test should now pass
5. **Document migration** - Add to `docs/FACTORIO_2_MIGRATION_TESTS.md`

### Testing Categories

1. **Prototype Loading** - All prototypes load without errors (via `--dump-data`)
2. **Runtime Validation** - Save file creation succeeds (via `--create`)
3. **Graphics Validation** - Sprite rectangles within bounds, files exist
4. **Recipe Validation** - Ingredients/results have proper format
5. **Entity Validation** - Collision masks, pipe connections, emissions format

### Test Coverage

Current status: **10 distinct migration issues caught and documented**

See:
- `tests/test_factorio_2_headless.py` - Main test runner
- `docs/FACTORIO_2_MIGRATION_TESTS.md` - Issue catalog
- `tests/README_MIGRATION_TESTS.md` - Usage guide

### CI/CD Integration

Tests run in ~10 seconds, suitable for:
- Pre-commit hooks
- GitHub Actions
- Local development workflow

### Writing New Tests

When discovering a new issue:

```python
# Add error pattern to test parser
{
    'pattern': r'your error regex here',
    'issue': 'issue_identifier',
    'description': 'Human-readable description'
}
```

Then document in migration docs with before/after examples.