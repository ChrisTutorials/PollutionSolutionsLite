# Project Structure Documentation

**Last Updated**: November 9, 2025
**Mod Version**: 1.0.21
**Factorio Version**: 2.0+

## Overview

PollutionSolutionsLite is a well-organized Factorio mod that follows standard mod distribution practices. This document describes the complete directory structure and file organization.

## Directory Structure

```text

PollutionSolutionsLite/
├── Root-level Mod Files
│   ├── info.json                 # Mod metadata (version, dependencies, etc.)
│   ├── control.lua               # Runtime logic and event handlers
│   ├── data.lua                  # Prototype loading (data stage)
│   ├── data-updates.lua          # Late-stage prototype modifications
│   ├── data-final-fixes.lua      # Final prototype adjustments
│   ├── settings.lua              # Mod settings definitions
│   ├── constants.lua             # Global constants and configuration
│   ├── util.lua                  # Utility functions for prototypes
│   └── run_tests.lua             # Test runner integration
│
├── Configuration Files
│   ├── .luarc.json               # Lua language server configuration
│   ├── .stylua.toml              # StyLua formatter configuration
│   ├── .vscode/settings.json     # VS Code workspace settings
│   ├── .editorconfig             # EditorConfig for consistency
│   ├── .gitignore                # Git exclusion rules
│   └── factorio_annotations.lua  # Type definitions for IDE support
│
├── prototypes/                   # Prototype definitions (organized by type)
│   ├── category.lua              # Recipe and damage categories
│   ├── entity.lua                # Buildings and structures
│   ├── fluid.lua                 # Fluids (polluted-air, toxic-sludge)
│   ├── hevsuit.lua               # HEV suit equipment
│   ├── item.lua                  # Items and crafted goods
│   ├── pollutioncollector.lua    # Pollution collector entity
│   ├── projectiles.lua           # Toxic projectiles and effects
│   ├── recipe.lua                # Crafting recipes
│   └── technology.lua            # Research technologies
│
├── graphics/                     # Sprites and icons (organized by entity)
│   ├── entity/
│   │   ├── cloud/                # Toxic cloud animations
│   │   ├── emitter/              # Toxic dump site graphics
│   │   ├── fire-flame/           # Fire effect graphics
│   │   ├── flamethrower-fire-stream/
│   │   ├── incinerator/
│   │   ├── low-heat-exchanger/
│   │   ├── pollution-collector/
│   │   └── [other entity graphics]
│   └── icons/
│       └── fluid/                # Fluid item icons
│
├── locale/                       # Localization files
│   ├── en/locale.cfg             # English translations
│   ├── ru/locale.cfg             # Russian translations
│   └── zh-CN/locale.cfg          # Simplified Chinese translations
│
├── migrations/                   # Save game migration scripts
│   └── PollutionSolutionsLite.1.0.20.lua
│
├── tests/                        # Test suite
│   ├── test_bootstrap.lua        # Test framework setup
│   ├── test_constants.lua        # Unit tests for constants
│   ├── test_data_loading.lua     # Data stage integration tests
│   ├── test_factorio_2_migration.lua
│   ├── test_graphics_helpers.lua
│   ├── test_util.lua             # Utility function tests
│   ├── validate_factorio_2.lua   # Factorio 2.0 validation
│   ├── validate_recipes.lua      # Recipe validation
│   ├── run_migration_tests.py    # Python test runner
│   ├── test_factorio_2_headless.py
│   ├── README_MIGRATION_TESTS.md
│   └── scenarios/
│       └── integration_test.lua  # Full integration test scenario
│
├── scripts/                      # Build and validation scripts
│   ├── export_mod.sh             # Export mod to Factorio mods directory
│   ├── validate_mod.py           # Python mod validation script
│   ├── validate_config.example.yaml
│   └── README.md                 # Scripts documentation
│
├── docs/                         # Documentation
│   ├── DEVELOPMENT.md            # Development guide and architecture
│   ├── TESTING.md                # Testing guide and procedures
│   ├── FACTORIO_2_MIGRATION_TESTS.md  # Factorio 2.0 migration info
│   ├── VALIDATION_REPORT.md      # Validation results
│   └── PROJECT_STRUCTURE.md      # This file
│
├── .github/                      # GitHub-specific files
│   └── instructions/
│       └── factorio.instructions.md  # Development guidelines
│
├── Root Documentation
│   ├── README.md                 # Main mod description and features
│   ├── changelog.txt             # Version history
│   └── thumbnail.png             # Mod thumbnail for portal
│
├── .git/                         # Git version control
└── factorio/                     # Symlink to local Factorio mods (git-ignored)

```text

## File Organization Guide

### Root Level Files

These files are required by Factorio to load the mod:

- **info.json**: Mod metadata including name, version, dependencies, and description
- **control.lua**: Main runtime script executed during gameplay
- **data.lua**: Initial prototype loading during data stage
- **data-updates.lua**: Secondary prototype modifications
- **data-final-fixes.lua**: Final adjustments after all mods load

### Helper Modules

- **constants.lua**: All magic numbers and configuration in one place
- **util.lua**: Reusable functions for prototype manipulation
- **settings.lua**: Settings UI definitions
- **run_tests.lua**: Test framework integration

### Prototype Organization

Each prototype type gets its own file for maintainability:

| File | Purpose | Contains |
|------|---------|----------|
| category.lua | Crafting categories | Recipe categories, damage types |
| entity.lua | In-game buildings | Toxic dump, collector, turret |
| fluid.lua | Liquid resources | Polluted air, toxic sludge |
| item.lua | Inventory items | Materials, crafted items |
| recipe.lua | Crafting recipes | All recipes with new Factorio 2.0 format |
| technology.lua | Research trees | Tech unlocks and prerequisites |
| projectiles.lua | Effects and projectiles | Fire, toxic clouds, explosions |
| hevsuit.lua | Equipment | Protective suit |
| pollutioncollector.lua | Special logic | Pollution collector entity |

### Graphics Organization

Graphics are organized by entity type:

```text

graphics/entity/
├── cloud/              # Toxic gas clouds
├── emitter/            # Toxic dump site (emission source)
├── fire-flame/         # Fire animations
├── flamethrower-fire-stream/
├── incinerator/        # Incinerator building
├── low-heat-exchanger/ # Heat processing
├── pollution-collector/# Collection device

```text

### Test Structure

The test suite is organized by module:

```text

tests/
├── Unit Tests
│   ├── test_constants.lua       # Constants validation
│   ├── test_util.lua            # Utility function tests
│   └── test_graphics_helpers.lua
│
├── Integration Tests
│   ├── test_data_loading.lua    # Data stage validation
│   ├── scenarios/integration_test.lua  # Full game simulation
│   └── [scenario files]
│
├── Validation Tests
│   ├── validate_factorio_2.lua  # Factorio 2.0 compatibility
│   ├── validate_recipes.lua     # Recipe format validation
│   └── test_factorio_2_headless.py
│
└── Runners
    ├── test_bootstrap.lua       # Test framework
    └── run_migration_tests.py   # Python test harness

```text

## Configuration Files

### Development Tools Configuration

- **.luarc.json**: Lua language server (Sumneko/Pylance) settings
  - Disables "undefined-field" warnings for Factorio runtime-injected APIs
  - Defines Factorio global types
  - Path to factorio_annotations.lua for IDE support

- **.stylua.toml**: Code formatter configuration
  - 100-column line width
  - 2-space indentation
  - Unix line endings

- **.vscode/settings.json**: VS Code workspace settings
  - Lua language server configuration
  - StyLua formatter integration
  - Spell checker dictionary

- **.editorconfig**: Cross-editor formatting rules
  - Ensures consistent formatting across tools

### Type Support

- **factorio_annotations.lua**: Type definitions for Factorio APIs
  - Provides IDE autocomplete
  - Documents global objects (game, script, surface, etc.)
  - Enables type checking for Factorio mod code

## Documentation Structure

| File | Purpose |
|------|---------|
| README.md | User-facing mod description and features |
| DEVELOPMENT.md | Developer guide, architecture, key systems |
| TESTING.md | Testing procedures and infrastructure |
| FACTORIO_2_MIGRATION_TESTS.md | Factorio 2.0 migration issues and test cases |
| VALIDATION_REPORT.md | Factorio 2.0 compatibility validation results |
| PROJECT_STRUCTURE.md | This file - project organization guide |

## Localization

Strings are localized for:

- **English** (en/locale.cfg)
- **Russian** (ru/locale.cfg)
- **Simplified Chinese** (zh-CN/locale.cfg)

Add new languages by creating `locale/{lang_code}/locale.cfg` files.

## Migrations

Save game migrations ensure mod updates don't break existing saves:

```text

migrations/
└── PollutionSolutionsLite.1.0.20.lua  # Migration for version 1.0.20+

```text

Create new migrations when:

- Renaming entities
- Removing features
- Changing item stack sizes
- Modifying recipe ingredients

## Build Artifacts & Cache (Ignored)

The following are automatically excluded from version control:

```text

.git/          # Git repository
factorio/      # Symlink to local Factorio
__pycache__/   # Python cache
*.pyc          # Compiled Python files
.DS_Store      # macOS metadata
Thumbs.db      # Windows metadata

```text

See `.gitignore` for complete exclusion list.

## Scripts

### export_mod.sh

- **Purpose**: Export mod to Factorio mods directory
- **Usage**: `./export_mod.sh` or `./export_mod.sh /path/to/mods`
- **Platform Support**: Linux, macOS, Windows (Git Bash)

### validate_mod.py

- **Purpose**: Validate mod structure and Factorio 2.0 compatibility
- **Usage**: `python scripts/validate_mod.py`
- **Requirements**: PyYAML (optional, falls back to JSON)

## Factorio Mod Portal Distribution

When distributing this mod:

1. **Excluded from distribution**:
   - `.git/` - Version control
   - `factorio/` - Local symlink
   - `.github/` - Development docs
   - `scripts/` - Build tools
   - `tests/` - Unit tests
   - `*.pyc` - Build artifacts
   - `.vscode/` - IDE config

2. **Include in distribution**:
   - All source code
   - All graphics and assets
   - Localization files
   - Documentation (README.md)
   - Changelog (changelog.txt)
   - Migration files

3. **Distribution script**: `./export_mod.sh` creates proper export format

## Development Workflow

1. **Setup**: Clone repo, install StyLua and Lua language server
2. **Code**: Make changes in appropriate prototype or script file
3. **Format**: `stylua .` to format all Lua files
4. **Test**: `lua run_tests.lua` or `python tests/test_factorio_2_headless.py`
5. **Document**: Update DEVELOPMENT.md with architecture changes
6. **Commit**: Use meaningful commit messages with scope
7. **Release**: Update version in info.json and changelog.txt

## Quick Reference

| Task | Location |
|------|----------|
| Add new item | `prototypes/item.lua` |
| Add new recipe | `prototypes/recipe.lua` |
| Add tech tree | `prototypes/technology.lua` |
| New game entity | `prototypes/entity.lua` |
| Modify at runtime | `control.lua` |
| Add localization | `locale/{lang_code}/locale.cfg` |
| Add asset graphic | `graphics/entity/{type}/` |
| Configure mod option | `settings.lua` |
| Fix compatibility | `data-updates.lua` or `data-final-fixes.lua` |

## Standards & Conventions

### Naming

- Entity names: lowercase with hyphens (e.g., `dump-site`)
- Lua variables: camelCase (e.g., `toxicDump`)
- Constants: UPPERCASE_WITH_UNDERSCORES (in `constants.lua`)

### Code Style

- Formatting: StyLua (2-space indent, 100 cols)
- Comments: Document public functions and complex logic
- Organization: Related code together, high-level first

### Documentation

- Module comments at top of each file
- Function comments with parameters and return values
- Update DEVELOPMENT.md for architectural changes

## Maintenance

### Regular Tasks

- Update constants.lua when balancing gameplay
- Run tests when making changes
- Update changelog.txt for releases
- Test with latest Factorio version

### When Adding Features

- Add prototype(s) in appropriate prototypes/*.lua file
- Add graphics in graphics/entity/{type}/
- Add localization strings
- Add unit tests in tests/
- Document in DEVELOPMENT.md
- Update changelog

### For Mod Portal Releases

1. Bump version in info.json
2. Add entry to changelog.txt
3. Run full test suite
4. Run export_mod.sh to generate distribution
5. Upload to mod portal
6. Tag git commit with version

---

**For detailed development information, see DEVELOPMENT.md**
**For testing procedures, see TESTING.md**
**For contributor guidelines, see .github/instructions/factorio.instructions.md**
