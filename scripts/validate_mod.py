#!/usr/bin/env python3
"""
Factorio Mod Validation Script

This script validates that a Factorio mod loads correctly by running
Factorio in headless mode with various validation checks.
"""

import os
import sys
import subprocess
import tempfile
import shutil
from pathlib import Path
from typing import Optional, List
import argparse

# Try to import yaml, fall back to json if not available
try:
    import yaml
    HAS_YAML = True
except ImportError:
    import json
    HAS_YAML = False
    print("Warning: PyYAML not installed. Using fallback config. Install with: pip install pyyaml")


class FactorioValidator:
    def __init__(self, config_path: Optional[str] = None):
        self.script_dir = Path(__file__).parent
        self.mod_dir = self.script_dir.parent
        self.factorio_bin: Optional[Path] = None
        self.mod_name = "PollutionSolutionsLite"
        self.verbose = False
        
        # Load configuration
        self.load_config(config_path)
        
        # Detect Factorio binary
        if not self.factorio_bin:
            self.factorio_bin = self.detect_factorio()
    
    def load_config(self, config_path: Optional[str]):
        """Load configuration from YAML file"""
        if config_path:
            config_file = Path(config_path)
        else:
            # Try validate_config.yaml in scripts dir first, then example
            config_file = self.script_dir / "validate_config.yaml"
            if not config_file.exists():
                config_file = self.script_dir / "validate_config.example.yaml"
        
        if config_file.exists():
            if HAS_YAML:
                with open(config_file) as f:
                    config = yaml.safe_load(f) or {}
            else:
                # Fallback: use default config
                config = {}
            
            if config.get('factorio_bin'):
                self.factorio_bin = Path(os.path.expanduser(config['factorio_bin']))
            
            self.common_paths = config.get('common_paths', [])
            validation = config.get('validation', {})
            self.create_test_save = validation.get('create_test_save', True)
            self.instrument_mod = validation.get('instrument_mod', True)
            self.verbose = validation.get('verbose', False)
        else:
            # Default paths to try
            self.common_paths = [
                # Linux
                '/opt/factorio/bin/x64/factorio',
                '/usr/local/bin/factorio',
                '~/factorio/bin/x64/factorio',
                # macOS
                '/Applications/factorio.app/Contents/MacOS/factorio',
                # Windows
                'C:\\Program Files\\Factorio\\bin\\x64\\factorio.exe',
                'C:\\Program Files (x86)\\Factorio\\bin\\x64\\factorio.exe',
                '/mnt/c/Program Files/Factorio/bin/x64/factorio.exe',
                '/mnt/c/Program Files (x86)/Factorio/bin/x64/factorio.exe',
                # Steam (Linux)
                '~/.steam/steam/steamapps/common/Factorio/bin/x64/factorio',
                '~/.local/share/Steam/steamapps/common/Factorio/bin/x64/factorio',
                '~/Steam/steamapps/common/Factorio/bin/x64/factorio',
                '~/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Factorio/bin/x64/factorio',
                # Steam (macOS)
                '~/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio',
                # Steam (Windows)
                '/mnt/c/Program Files (x86)/Steam/steamapps/common/Factorio/bin/x64/factorio.exe',
            ]
            self.create_test_save = True
            self.instrument_mod = True
    
    def detect_factorio(self) -> Optional[Path]:
        """Detect Factorio binary location"""
        # Try common paths
        for path_str in self.common_paths:
            path = Path(os.path.expanduser(path_str))
            if path.exists():
                return path
        
        # Try to find in PATH
        factorio_path = shutil.which('factorio')
        if factorio_path:
            return Path(factorio_path)
        
        # Try to find in mounted drives (Linux)
        media_paths = Path('/run/media').glob('*/*/factorio/bin/x64/factorio')
        for path in media_paths:
            if path.exists():
                return path
        
        return None
    
    def run_command(self, cmd: List[str], description: str) -> bool:
        """Run a command and return success status"""
        print(f"\n{description}...")
        if self.verbose:
            print(f"Command: {' '.join(cmd)}")
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=120
            )
            
            if self.verbose:
                print(f"STDOUT:\n{result.stdout}")
                if result.stderr:
                    print(f"STDERR:\n{result.stderr}")
            
            # Check for errors in output
            output = result.stdout + result.stderr
            error_keywords = ['Error', 'Failed', 'failed to load', 'error loading']
            
            for keyword in error_keywords:
                if keyword in output:
                    print(f"❌ {description} failed")
                    print(f"\nError found in output:")
                    for line in output.split('\n'):
                        if keyword.lower() in line.lower():
                            print(f"  {line}")
                    return False
            
            print(f"✓ {description} succeeded")
            return True
            
        except subprocess.TimeoutExpired:
            print(f"❌ {description} timed out")
            return False
        except Exception as e:
            print(f"❌ {description} failed with exception: {e}")
            return False
    
    def validate(self) -> bool:
        """Run all validation checks"""
        print("=" * 50)
        print("Factorio Mod Validation")
        print("=" * 50)
        print(f"Mod: {self.mod_name}")
        print(f"Mod directory: {self.mod_dir}")
        
        if not self.factorio_bin:
            print("\n❌ ERROR: Factorio binary not found!")
            print("\nPlease install Factorio or create validate_config.yaml with the path.")
            print("Example config:")
            print("  factorio_bin: /path/to/factorio/bin/x64/factorio")
            return False
        
        print(f"Factorio binary: {self.factorio_bin}")
        
        # Get version
        try:
            version_result = subprocess.run(
                [str(self.factorio_bin), '--version'],
                capture_output=True,
                text=True,
                timeout=10
            )
            version = version_result.stdout.split('\n')[0]
            print(f"Factorio version: {version}")
        except:
            print("Factorio version: unknown")
        
        print("\n" + "=" * 50)
        print("Running Validation Tests")
        print("=" * 50)
        
        mods_dir = self.mod_dir / "factorio" / "mods"
        
        # Ensure mod is exported
        if not (mods_dir / self.mod_name).exists():
            print(f"\nExporting mod to {mods_dir}...")
            export_script = self.script_dir / "export_mod.py"
            if export_script.exists():
                subprocess.run([sys.executable, str(export_script)], check=True)
        
        all_passed = True
        
        # Test 1: Check mod loading with instrument-mod (doesn't open GUI)
        if self.instrument_mod:
            cmd = [
                str(self.factorio_bin),
                '--instrument-mod', self.mod_name,
                '--instrument-mod-data-only',
                '--mod-directory', str(mods_dir)
            ]
            if not self.run_command(cmd, "Test 1: Validate mod data loading"):
                all_passed = False
        
        # Test 2: Create test save (validates runtime)
        if self.create_test_save:
            with tempfile.TemporaryDirectory() as tmpdir:
                test_save = Path(tmpdir) / "test-save"
                cmd = [
                    str(self.factorio_bin),
                    '--create', str(test_save),
                    '--mod-directory', str(mods_dir),
                    '--disable-audio'
                ]
                if not self.run_command(cmd, "Test 2: Create test save"):
                    all_passed = False
        
        print("\n" + "=" * 50)
        if all_passed:
            print("✓ All validation tests passed!")
            print("=" * 50)
            print("\nThe mod is ready to use in Factorio.")
            return True
        else:
            print("❌ Some validation tests failed")
            print("=" * 50)
            return False


def main():
    parser = argparse.ArgumentParser(description='Validate Factorio mod')
    parser.add_argument('--config', '-c', help='Path to config YAML file')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    args = parser.parse_args()
    
    validator = FactorioValidator(args.config)
    if args.verbose:
        validator.verbose = True
    
    success = validator.validate()
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
