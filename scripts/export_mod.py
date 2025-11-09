#!/usr/bin/env python3
"""
Export PollutionSolutionsLite mod to Factorio mods directory

This script copies the mod files to the Factorio mods directory, excluding
development files (.git, tests, docs, etc.)

ATTRIBUTION: This mod is based on Pollution Solutions by daniels1989.
The version is a Factorio 2.0 port by ChrisTutorials.

Usage:
    python export_mod.py [destination_path]

    If no destination provided, uses symlink (factorio-export/) or
    default Factorio mods directory based on OS.
"""

import os
import sys
import shutil
import platform
import zipfile
import json
from pathlib import Path
from typing import Optional
import subprocess

try:
    import yaml  # type: ignore
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False


class ModExporter:
    def __init__(self):
        self.mod_name = "PollutionSolutionsLite"
        self.script_dir = Path(__file__).parent
        self.mod_source_dir = self.script_dir.parent
        
        # Files and directories to exclude from export
        self.exclude_patterns = [
            '.git',
            '.gitignore', 
            '.github',
            'scripts',
            'docs',
            'tests',
            'run_tests.lua',
            'factorio',
            '__pycache__',
            '*.pyc',
            '.vscode',
            '.idea',
            '.venv',
            'venv',
            '.editorconfig',
            '.luarc.json',
            '.markdownlintignore',
            '.stylua.toml',
            'PROJECT_STRUCTURE.md',
            'validate_config.sh',
            '*.zip',
            '*.tar.gz'
        ]
        
        # Load config if available
        self.config = self.load_config()
    
    def load_config(self) -> dict:
        """Load configuration from YAML file if available"""
        config_paths = [
            self.script_dir / 'export_config.yaml',
            self.script_dir / 'validate_config.yaml',  # Reuse validate config
            self.mod_source_dir / 'export_config.yaml',
        ]
        
        for config_path in config_paths:
            if config_path.exists():
                if YAML_AVAILABLE:
                    try:
                        with open(config_path) as f:
                            return yaml.safe_load(f) or {}  # type: ignore
                    except Exception as e:
                        print(f"Warning: Could not load config {config_path}: {e}")
                else:
                    print(f"Note: Found config {config_path} but PyYAML not installed")
                    print("  Install with: pip install PyYAML")
        
        return {}
    
    def get_mods_dir_from_config(self) -> Optional[Path]:
        """Get mods directory from config file"""
        if not self.config:
            return None
        
        # Check for export-specific config
        if 'export' in self.config and 'mods_directory' in self.config['export']:
            mods_dir = self.config['export']['mods_directory']
            if mods_dir:
                return Path(mods_dir).expanduser()
        
        # Check if we can derive from factorio_bin path
        if 'factorio_bin' in self.config and self.config['factorio_bin']:
            bin_path = Path(self.config['factorio_bin']).expanduser()
            if bin_path.exists():
                # Factorio structure: factorio/bin/x64/factorio -> factorio/mods
                factorio_root = bin_path.parent.parent.parent
                mods_dir = factorio_root / 'mods'
                if mods_dir.exists():
                    return mods_dir
        
        return None
    
    def get_default_mods_dir(self) -> Optional[Path]:
        """Determine default Factorio mods directory based on OS"""
        system = platform.system()
        
        if system == 'Linux':
            return Path.home() / '.factorio' / 'mods'
        elif system == 'Darwin':  # macOS
            return Path.home() / 'Library' / 'Application Support' / 'factorio' / 'mods'
        elif system == 'Windows':
            appdata = os.environ.get('APPDATA')
            if appdata:
                return Path(appdata) / 'Factorio' / 'mods'
        
        return None
    
    def get_destination_dir(self, user_path: Optional[str] = None) -> Optional[Path]:
        """Determine destination directory for mod export"""
        if user_path:
            # User provided explicit path
            return Path(user_path)
        
        # 1. Check config file first
        config_dir = self.get_mods_dir_from_config()
        if config_dir and config_dir.exists():
            return config_dir
        
        # 2. Check for symlink
        symlink = self.mod_source_dir / 'factorio'
        if symlink.is_symlink() or (symlink.exists() and symlink.is_dir()):
            return symlink / 'mods'
        
        # 3. Fall back to default based on OS
        return self.get_default_mods_dir()
    
    def should_exclude(self, path: Path, base_path: Path) -> bool:
        """Check if a path should be excluded from export"""
        relative = path.relative_to(base_path)
        
        for pattern in self.exclude_patterns:
            if pattern.startswith('*'):
                # Wildcard pattern
                if path.name.endswith(pattern[1:]):
                    return True
            elif str(relative).startswith(pattern) or path.name == pattern:
                return True
        
        return False
    
    def copy_tree(self, src: Path, dst: Path):
        """
        Copy directory tree, excluding patterns
        
        Uses rsync if available for efficiency, otherwise falls back to shutil
        """
        # Try rsync first (more efficient)
        if shutil.which('rsync'):
            exclude_args = []
            for pattern in self.exclude_patterns:
                exclude_args.extend(['--exclude', pattern])
            
            cmd = ['rsync', '-av'] + exclude_args + [f'{src}/', f'{dst}/']
            try:
                result = subprocess.run(cmd, capture_output=True, text=True, check=True)
                if result.returncode == 0:
                    return True
            except subprocess.CalledProcessError:
                pass  # Fall back to Python copy
        
        # Fall back to Python copy
        dst.mkdir(parents=True, exist_ok=True)
        
        for item in src.rglob('*'):
            if self.should_exclude(item, src):
                continue
            
            relative = item.relative_to(src)
            dest_path = dst / relative
            
            if item.is_dir():
                dest_path.mkdir(parents=True, exist_ok=True)
            else:
                dest_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(item, dest_path)
    
    def get_mod_version(self) -> str:
        """Read mod version from info.json"""
        info_path = self.mod_source_dir / 'info.json'
        try:
            with open(info_path) as f:
                info = json.load(f)
                return info.get('version', '1.1.1')
        except Exception:
            return '1.1.1'
    
    def get_next_version(self, dest_dir: Path) -> str:
        """Get next incremental version (e.g., 1.1.1 -> 1.1.2 -> 1.1.3)"""
        # Find all existing zips for this mod
        pattern = f"{self.mod_name}_1.1.*.zip"
        existing_zips = list(dest_dir.glob(pattern))
        
        if not existing_zips:
            # First export
            return "1.1.1"
        
        # Find highest patch number
        max_patch = 0
        for zip_file in existing_zips:
            # Extract version from filename (e.g., "PollutionSolutionsLite_1.1.5.zip")
            filename = zip_file.stem  # Remove .zip
            version_part = filename.replace(f"{self.mod_name}_", "")
            
            # Try to parse version (e.g., "1.1.5")
            try:
                parts = version_part.split('.')
                if len(parts) == 3:
                    patch_num = int(parts[2])
                    max_patch = max(max_patch, patch_num)
            except (ValueError, IndexError):
                pass
        
        return f"1.1.{max_patch + 1}"
    
    def update_info_version(self, version: str) -> bool:
        """Update version in info.json"""
        info_path = self.mod_source_dir / 'info.json'
        try:
            with open(info_path, 'r') as f:
                info = json.load(f)
            
            old_version = info.get('version', '0.0.0')
            info['version'] = version
            
            with open(info_path, 'w') as f:
                json.dump(info, f, indent='\t')
            
            print(f"Updated info.json: {old_version} → {version}")
            return True
        except Exception as e:
            print(f"Warning: Failed to update info.json: {e}")
            return False
    
    def update_exported_info_version(self, mod_dest: Path, version: str) -> bool:
        """Update version in the exported mod's info.json"""
        info_path = mod_dest / 'info.json'
        try:
            with open(info_path, 'r') as f:
                info = json.load(f)
            
            info['version'] = version
            
            with open(info_path, 'w') as f:
                json.dump(info, f, indent='\t')
            
            return True
        except Exception as e:
            print(f"Warning: Failed to update exported info.json: {e}")
            return False
    
    def create_archive(self, mod_dest: Path) -> bool:
        """Create zip archive of the exported mod with incremental versioning"""
        dest_parent = mod_dest.parent
        version = self.get_next_version(dest_parent)
        
        # Update info.json in source directory
        self.update_info_version(version)
        
        # Update info.json in exported directory
        self.update_exported_info_version(mod_dest, version)
        
        archive_name = f"{self.mod_name}_{version}.zip"
        archive_path = dest_parent / archive_name
        
        print(f"\nCreating archive: {archive_name}")
        try:
            with zipfile.ZipFile(archive_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for file_path in mod_dest.rglob('*'):
                    if file_path.is_file():
                        arcname = self.mod_name / file_path.relative_to(mod_dest)
                        zipf.write(file_path, arcname)
            
            print(f"✓ Archive created: {archive_path}")
            return True
        except Exception as e:
            print(f"✗ Failed to create archive: {e}")
            return False
    
    def export(self, destination: Optional[str] = None) -> bool:
        """Export mod to destination directory"""
        dest_dir = self.get_destination_dir(destination)
        
        if not dest_dir:
            print("Error: Could not determine destination directory.")
            print("Please provide destination path as argument.")
            print(f"Usage: {sys.argv[0]} <destination_path>")
            return False
        
        # Check if destination exists
        if not dest_dir.exists():
            print(f"Error: Destination directory does not exist: {dest_dir}")
            return False
        
        # Check if source exists
        if not self.mod_source_dir.exists():
            print(f"Error: Source directory does not exist: {self.mod_source_dir}")
            return False
        
        print("=" * 50)
        print(f"Exporting {self.mod_name}")
        print("=" * 50)
        print(f"Source: {self.mod_source_dir}")
        print(f"Destination: {dest_dir / self.mod_name}")
        print()
        
        # Remove existing mod if present
        mod_dest = dest_dir / self.mod_name
        if mod_dest.exists():
            print("Removing existing mod directory...")
            shutil.rmtree(mod_dest)
        
        # Copy mod files
        print("Copying mod files...")
        try:
            self.copy_tree(self.mod_source_dir, mod_dest)
        except Exception as e:
            print(f"Error copying files: {e}")
            return False
        
        # Verify export
        if mod_dest.exists() and (mod_dest / 'info.json').exists():
            print()
            print("✓ Export successful!")
            print(f"Mod location: {mod_dest}")
            
            # List some files
            print("\nExported files:")
            count = 0
            for item in sorted(mod_dest.iterdir()):
                if count >= 10:
                    print("  ...")
                    break
                print(f"  {item.name}")
                count += 1
            
            # Create tar.gz archive
            self.create_archive(mod_dest)
            
            return True
        else:
            print()
            print("✗ Export failed!")
            return False


def main():
    exporter = ModExporter()
    
    # Get destination from command line if provided
    destination = sys.argv[1] if len(sys.argv) > 1 else None
    
    success = exporter.export(destination)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
