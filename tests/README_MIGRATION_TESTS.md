# Factorio 2.0 Migration Tests

## Overview

Comprehensive test suite that validates Factorio 2.0 API compatibility using **real Factorio validation** (headless mode) rather than mocking.

## Quick Start

```bash
# Run all migration tests
python tests/test_factorio_2_headless.py

# View detailed output
python tests/test_factorio_2_headless.py --verbose
```

## What Gets Tested

✅ **Data Loading** - All prototypes load without errors  
✅ **Recipe Format** - Ingredients/results have required `type` field  
✅ **Collision Masks** - Dictionary format with `layers` key  
✅ **Pipe Connections** - Have `direction` and use `flow_direction`  
✅ **Emissions** - Dictionary format for pollution types  
✅ **Fuel Categories** - Proper singular/plural usage  
✅ **Sprite Flags** - No deprecated flags like `compressed`  
✅ **Barrel System** - Correct base barrel references  
✅ **Save Creation** - Runtime validation via test save

## Test Results

Current status: **✓ All tests passing**

```
Total tests: 3
Passed: 3
Failed: 0

✓ PASS: Data Loading
✓ PASS: Save Creation  
✓ PASS: Entity Existence
```

## Why Headless Testing?

Rather than mocking Factorio's API (complex, error-prone, outdated quickly), we:

1. **Export** the mod to Factorio's mods directory
2. **Run** Factorio in headless mode with `--dump-data`
3. **Parse** actual Factorio error output
4. **Validate** against known migration patterns

**Benefits:**
- Source of truth (real Factorio engine)
- Catches issues mocking would miss
- No mock maintenance burden
- Tests actual game behavior

## Migration Issues Caught

The test suite has discovered and validated fixes for **10 distinct API migration issues**:

1. Recipe ingredient `type` field requirement
2. Recipe result `type` field requirement
3. Collision mask format change (array → dictionary)
4. Pipe connection `direction` requirement
5. Pipe connection `flow_direction` vs `type`
6. Sprite flag `compressed` removal
7. Emissions dictionary format
8. Energy source `fuel_categories` plural
9. Item `fuel_category` singular
10. Barrel system `barrel` vs `empty-barrel`

See [FACTORIO_2_MIGRATION_TESTS.md](../docs/FACTORIO_2_MIGRATION_TESTS.md) for detailed documentation of each issue.

## Requirements

- **Python 3.6+**
- **Factorio binary** (headless or full)
- Mod exported to Factorio mods directory (automatic)

## Integration

### Local Development

```bash
# After making changes
python tests/test_factorio_2_headless.py
```

### CI/CD

```yaml
# Example GitHub Actions
- name: Run Factorio 2.0 Migration Tests
  run: python tests/test_factorio_2_headless.py
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
python tests/test_factorio_2_headless.py || exit 1
```

## Test Architecture

```
test_factorio_2_headless.py
├── FactorioMigrationTester class
│   ├── find_factorio() - Locate binary
│   ├── parse_error_output() - Extract patterns
│   ├── run_data_loading_test() - Prototype validation
│   ├── run_save_creation_test() - Runtime validation
│   └── print_results() - Summary report
└── Error Pattern Matching
    ├── Recipe format issues
    ├── Collision mask issues
    ├── Pipe connection issues
    ├── Emission format issues
    └── Fuel category issues
```

## Error Pattern Examples

The test parses specific Factorio error patterns:

```python
# Missing ingredient type
r'Key "type" not found in property tree at ROOT\.recipe\.([^.]+)\.ingredients'

# Invalid collision mask
r'Value must be a dictionary in property tree at ROOT\.[^.]+\.([^.]+)\.collision_mask'

# Deprecated sprite flag
r'compressed is unknown sprite flag'
```

## Adding New Tests

When you discover a new migration issue:

1. **Run test** - See it fail with the actual error
2. **Add pattern** - Update `parse_error_output()` with error regex
3. **Fix issue** - Update mod code
4. **Verify** - Test should now pass
5. **Document** - Add to migration docs with before/after examples

## Troubleshooting

### "Factorio binary not found"

Create `scripts/validate_config.yaml`:

```yaml
factorio_bin: /path/to/factorio/bin/x64/factorio
```

### Tests timeout

Increase timeout in test file (default: 60 seconds):

```python
timeout=120  # Increase if needed
```

### False positives

Check if error is from base game vs mod:

```
Error pattern: "Modifications: Pollution Solutions Lite"
              vs "Modifications: Base mod"
```

## Performance

- **Data loading test**: ~3-5 seconds
- **Save creation test**: ~5-8 seconds  
- **Total runtime**: ~10 seconds

Fast enough for pre-commit hooks and CI/CD.

## Future Enhancements

- [ ] Test optional field handling (structure, hr_version)
- [ ] Mod compatibility matrix
- [ ] Graphics validation (file existence)
- [ ] Performance benchmarking
- [ ] Automated changelog generation from issues found

## Related Files

- [`test_factorio_2_headless.py`](./test_factorio_2_headless.py) - Main test runner
- [`../scripts/validate_mod.py`](../scripts/validate_mod.py) - Factorio validator (used by tests)
- [`../docs/FACTORIO_2_MIGRATION_TESTS.md`](../docs/FACTORIO_2_MIGRATION_TESTS.md) - Detailed issue documentation
- [`test_factorio_2_migration.lua`](./test_factorio_2_migration.lua) - Lua-based tests (experimental)

## License

Part of PollutionSolutionsLite mod. See main README for license information.
