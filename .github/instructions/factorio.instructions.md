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