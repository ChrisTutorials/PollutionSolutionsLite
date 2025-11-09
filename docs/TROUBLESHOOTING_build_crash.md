# Troubleshooting Guide: on_built_entity Crash When Building Objects

**Issue**: Game crashes when trying to build an entity (toxic dump, pollution collector, etc.)  
**Error**: `control.lua:372: attempt to index local 'entity' (a nil value)`  
**Status**: FIXED in latest version

---

## Quick Fix

The crash **has been fixed** in the latest version. To resolve:

### Step 1: Update the Mod

1. Close Factorio completely
2. Download the latest version of Pollution Solutions Lite (v1.1.0+)
3. Replace your old mod folder with the new one
4. Start Factorio and reload your save

### Step 2: Verify the Fix

After updating:
- Build a toxic dump - should work normally
- Build a pollution collector - should work normally
- Cancel placements mid-build - no crashes
- Game should continue normally

**If you still get the error**: The update didn't apply correctly. See "Advanced Troubleshooting" below.

---

## What Was Wrong

### The Bug

When trying to build an entity, the game would crash with:
```
Error while running event PollutionSolutionsLite::on_built_entity (ID 6)
__PollutionSolutionsLite__/control.lua:372: attempt to index local 'entity' (a nil value)
```

### Why It Happened

The `on_built_entity` event can receive a nil `created_entity` in certain scenarios:

1. **You cancelling the placement** - You start placing and cancel
2. **Another mod destroys it instantly** - Race condition
3. **Network lag (multiplayer)** - Desync between clients
4. **Build ghost entities** - Blueprint ghosts not placed

The old code didn't check if the entity was nil:
```lua
function IsToxicDump(entity)
  return entity.name == TOXIC_DUMP_NAME  -- CRASHES if entity is nil
end
```

### The Fix

Now the code checks before accessing:
```lua
function IsToxicDump(entity)
  if not entity or not entity.valid then
    return false
  end
  return entity.name == TOXIC_DUMP_NAME  -- Safe!
end
```

---

## Advanced Troubleshooting

### If the Error Persists

#### Check 1: Confirm You Have the Latest Version

1. Open Factorio
2. Go to Mods → Manage mods
3. Find "Pollution Solutions Lite"
4. Note the version number
5. Should be **1.1.0 or higher**

If lower, manually update:
- Delete the old mod folder
- Download and extract the latest version
- Restart Factorio

#### Check 2: Clear Factorio Cache

1. Close Factorio
2. Find your Factorio user data folder:
   - Windows: `%APPDATA%\Factorio`
   - Linux: `~/.factorio`
   - Mac: `~/Library/Application Support/Factorio`
3. Delete the folder: `script-output`
4. Restart Factorio

#### Check 3: Verify No Mod Conflicts

1. Disable other mods one by one
2. Try building an entity after each disable
3. If it works with a specific mod disabled, that's the conflicting mod
4. Contact that mod's author about compatibility

#### Check 4: Create a New Save

1. Create a completely new game with default settings
2. Enable ONLY Pollution Solutions Lite
3. Try building a toxic dump or collector
4. If it works, your old save might have a conflict

If it doesn't work:
- Completely uninstall and reinstall the mod
- Make sure no old files are left behind

---

## What to Do If Still Having Issues

If you've tried all the above and still get the error:

### Gather Information

When reporting the issue, include:

1. **Exact error message** (copy-paste from Factorio console)
2. **Mod version** (from Mod Manager)
3. **Factorio version** (from main menu)
4. **List of other mods** (screenshot of Mod Manager)
5. **What you were doing** when it crashed
6. **Save file** (if possible, attach it)

### Report Steps

1. Open the mod on the Factorio Mod Portal
2. Click "Discussion" or "Issues"
3. Describe the problem with the gathered info
4. Include steps to reproduce

Or:

1. Go to GitHub: [ChrisTutorials/PollutionSolutionsLite](https://github.com/ChrisTutorials/PollutionSolutionsLite)
2. Create an Issue
3. Include all the gathered information

---

## Testing the Fix

### Scenario 1: Normal Building (Should Work)
1. Start new game with Pollution Solutions Lite
2. Build a toxic dump entity
3. ✅ Should place without error
4. ✅ Continue playing normally

### Scenario 2: Cancel Placement (Should Work)
1. Start building a pollution collector
2. Cancel the placement mid-build
3. ✅ Should not crash
4. ✅ Continue playing normally

### Scenario 3: Multiple Builds (Should Work)
1. Build several toxic dumps
2. Build several pollution collectors
3. ✅ All should work normally
4. ✅ No errors in console

### Scenario 4: Multiplayer (Should Work)
1. Join a multiplayer game
2. Build entities while others are building
3. ✅ Should handle race conditions gracefully
4. ✅ No "attempt to index nil" errors

---

## For Mod Author (Technical Details)

The fix added nil-safety checks to prevent crashes when `event.created_entity` is nil:

**File**: `control.lua`

**Functions Fixed**:
- `OnBuiltEntity()` - Line 113: Early return if entity is nil
- `IsToxicDump()` - Line 375: Return false for nil entities
- `IsPollutionCollector()` - Line 490: Return false for nil entities

**Pattern Used**:
```lua
if not entity or not entity.valid then
  return false  -- Safe default
end
```

**Commit**: `85c63e7`

---

## Documentation

Complete technical documentation available in:
- `BUG_FIX_on_built_entity_crash.md` - Full fix details
- `BUG_REPORT_on_built_entity_nil.md` - Technical analysis
- `tests/test_entity_nil_safety.lua` - Comprehensive tests

---

## Summary

✅ **The crash has been fixed** in the latest version (1.1.0+)  
✅ **Update your mod** to get the fix  
✅ **No gameplay changes** - fix is completely transparent  
✅ **All scenarios safe** - nil entities now handled gracefully  

The mod is now **stable and crash-free** when building entities.

---

**Last Updated**: November 9, 2025  
**Mod**: Pollution Solutions Lite v1.1.0+  
**Factorio**: 2.0+  
**Status**: Fixed and tested
