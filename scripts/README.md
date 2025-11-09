# PollutionSolutionsLite Scripts

This directory contains Python scripts for developing and validating the PollutionSolutionsLite Factorio mod.

## Scripts Overview

### export_mod.py

Exports the mod to the Factorio mods directory, excluding development files.

**Usage:**
```bash
# Auto-detect destination (checks config, symlink, or OS-specific default)
python scripts/export_mod.py

# Specify custom destination
python scripts/export_mod.py /path/to/factorio/mods
```

**Configuration:**

Create `scripts/export_config.yaml` (copy from `export_config.example.yaml`):

```yaml
# Option 1: Auto-detect from Factorio binary
factorio_bin: /path/to/factorio/bin/x64/factorio

# Option 2: Specify mods directory directly
export:
  mods_directory: /path/to/factorio/mods
```

**What it does:**
- Copies mod files to the Factorio mods directory
- Excludes development files: `.git`, `scripts/`, `tests/`, `docs/`, etc.
- Uses `rsync` if available (faster), otherwise falls back to Python copy
- Removes existing mod directory before copying (clean install)

**Destination resolution (in order):**
1. Path provided as command-line argument
2. `export_config.yaml` (if present)
3. Symlink at `./factorio/` (points to Factorio installation)
4. OS-specific default:
   - **Linux:** `~/.factorio/mods`
   - **macOS:** `~/Library/Application Support/factorio/mods`
   - **Windows:** `%APPDATA%/Factorio/mods`

### validate_mod.py

Validates that the mod loads correctly in Factorio using automated tests.

**Usage:**
```bash
# Run validation with auto-detected Factorio
python scripts/validate_mod.py

# Use custom config file
python scripts/validate_mod.py --config validate_config.yaml

# Verbose output
python scripts/validate_mod.py --verbose
```

**What it does:**
1. Auto-detects Factorio binary (or uses config file)
2. Exports mod to `./factorio/mods/` if not already present
3. **Test 1:** Validates mod data loading (`--instrument-mod`)
4. **Test 2:** Creates a test save file (validates runtime)

**Validation tests:**
- **Data loading:** Checks that all prototypes load without errors
- **Test save creation:** Creates a test game to verify runtime functionality
- **Error detection:** Scans output for error keywords and reports failures

### Configuration

Create `scripts/validate_config.yaml` to customize validation behavior:

```yaml
# Factorio binary location (optional - auto-detects if not set)
factorio_bin: /path/to/factorio/bin/x64/factorio

# Additional paths to try during auto-detection
common_paths:
  - ~/factorio/bin/x64/factorio
  - ~/.steam/steam/steamapps/common/Factorio/bin/x64/factorio

# Validation options
validation:
  create_test_save: true    # Test save file creation
  instrument_mod: true      # Test data loading
  verbose: false            # Show detailed output
```

See `validate_config.example.yaml` for a complete example with all common paths.

## Requirements

### Python Version
- **Python 3.6+** required
- All scripts use only standard library modules (no external dependencies required)

### Optional Dependencies
- **PyYAML** (recommended): For YAML config file support
  ```bash
  pip install pyyaml
  ```
  If not installed, validation will use fallback configuration.

- **rsync** (recommended): For faster mod exports
  - Pre-installed on most Linux/macOS systems
  - If not available, scripts fall back to Python's `shutil`

### Factorio Installation
- **export_mod.py:** Only needs a valid Factorio mods directory
- **validate_mod.py:** Requires Factorio binary (full or headless version)
  - Download headless: https://www.factorio.com/download-headless

## Development Workflow

### 1. Make changes to mod files
Edit Lua files, graphics, prototypes, etc.

### 2. Export to Factorio
```bash
python scripts/export_mod.py
```

### 3. Validate changes
```bash
python scripts/validate_mod.py
```

### 4. Test in-game (optional)
If validation passes, launch Factorio and test manually:
```bash
factorio  # Or use your Factorio launcher
```

## Troubleshooting

### "Factorio binary not found"
1. Install Factorio from https://factorio.com or Steam
2. Create `scripts/validate_config.yaml` with your Factorio path:
   ```yaml
   factorio_bin: /path/to/factorio/bin/x64/factorio
   ```

### "Destination directory does not exist"
The Factorio mods directory doesn't exist. Either:
- Install Factorio (it creates the directory)
- Create it manually: `mkdir -p ~/.factorio/mods`
- Provide explicit path: `python scripts/export_mod.py /path/to/mods`

### "PyYAML not installed" warning
This is non-critical. To remove the warning:
```bash
pip install pyyaml
```

### Validation fails with errors
Check the error output for specific issues:
- **Syntax errors:** Check Lua files for syntax problems
- **Missing dependencies:** Ensure all required base game items exist
- **Graphics errors:** Verify image files exist and paths are correct

## CI/CD Integration

These scripts are designed to work in CI/CD pipelines:

```bash
# Install dependencies
pip install pyyaml

# Run validation (exits with code 1 on failure)
python scripts/validate_mod.py --config ci_config.yaml
```

## File Structure

```
scripts/
├── README.md                      # This file
├── export_mod.py                  # Export mod to Factorio
├── validate_mod.py                # Validate mod functionality
└── validate_config.example.yaml   # Example configuration
```

## Platform Support

All scripts are cross-platform and tested on:
- **Linux** (Ubuntu, Fedora, Arch, etc.)
- **macOS** (Intel and Apple Silicon)
- **Windows** (native Python and WSL)

## License

These scripts are part of the PollutionSolutionsLite mod. See the main README for license information.
