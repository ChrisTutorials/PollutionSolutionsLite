#!/usr/bin/env python3
"""
Export PollutionSolutionsLite mod to Factorio mods directory

This script copies the mod files to the Factorio mods directory, excluding
development files (.git, tests, docs, etc.)

Usage:
    python export_mod.py [destination_path]
    
    If no destination provided, uses symlink (factorio-export/) or 
    default Factorio mods directory based on OS.
"""

import os
import sys
import shutil
import platform
from pathlib import Path
from typing import Optional
import subprocess


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
            '.idea'
        ]
    
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
        
        # Check for symlink
        symlink = self.mod_source_dir / 'factorio'
        if symlink.is_symlink() or (symlink.exists() and symlink.is_dir()):
            return symlink / 'mods'
        
        # Fall back to default based on OS
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
