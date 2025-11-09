# Development Version Notice

## Current Status: DEVELOPMENT BUILD

This mod is currently in **development/testing phase** with incremental versioning.

### Current Version Scheme
- **Version Format**: `1.1.X` (e.g., `1.1.1`, `1.1.2`, `1.1.3`)
- **Increments**: Automatically incremented on each export via `scripts/export_mod.py`
- **Purpose**: Internal testing and development builds

### Important: Reset to 1.1.0 Before Release

Before releasing this mod publicly or to the Factorio mod portal, **you must reset the version to `1.1.0`** in `info.json`:

```json
{
  "version": "1.1.0"
}
```

### How to Reset Before Release

1. **Stop all exports** - Don't run the export script anymore
2. **Update info.json**:
   ```bash
   sed -i 's/"version": "1.1.[0-9]*"/"version": "1.1.0"/' info.json
   ```
3. **Commit the reset**:
   ```bash
   git add info.json
   git commit -m "release: reset version to 1.1.0 for public release"
   git tag v1.1.0
   ```
4. **Continue with release process** (changelog, publish to mod portal, etc.)

### Export Script Behavior

The export script (`scripts/export_mod.py`):
- Automatically increments the patch version (1.1.1 → 1.1.2 → 1.1.3, etc.)
- Updates both source and exported `info.json` files
- Creates versioned zip files: `PollutionSolutionsLite_1.1.X.zip`

**Do not use these development versions for public release without resetting to 1.1.0 first.**
