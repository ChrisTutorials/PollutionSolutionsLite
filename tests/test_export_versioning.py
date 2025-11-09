#!/usr/bin/env python3
"""
Test suite for export_mod.py versioning behavior.

Ensures that:
1. Each export increments the zip version
2. Each export increments the mod folder info.json version
3. Versions are always in sync (1.1.XXXX format)
4. Consecutive exports maintain monotonically increasing versions
"""

import unittest
import sys
import json
import tempfile
import shutil
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add parent directory to path to import export_mod
sys.path.insert(0, str(Path(__file__).parent.parent / "scripts"))
from export_mod import ModExporter


class TestExportVersioning(unittest.TestCase):
    """Test export versioning increments"""

    def setUp(self):
        """Set up test fixtures"""
        self.test_dir = tempfile.mkdtemp()
        self.mod_dir = Path(self.test_dir) / "PollutionSolutionsLite"
        self.mod_dir.mkdir()
        
        # Create minimal mod structure
        self.create_test_mod()
        self.exporter = ModExporter()
        self.exporter.mod_source_dir = self.mod_dir
    
    def tearDown(self):
        """Clean up test fixtures"""
        shutil.rmtree(self.test_dir, ignore_errors=True)
    
    def create_test_mod(self):
        """Create minimal valid mod structure for testing"""
        # Create info.json
        info = {
            "name": "PollutionSolutionsLite",
            "version": "1.1.0001",
            "factorio_version": "2.0",
            "title": "Pollution Solutions Lite",
            "description": "Test mod",
            "author": "Test",
            "dependencies": ["base >= 2.0"]
        }
        (self.mod_dir / "info.json").write_text(json.dumps(info, indent=2))
        
        # Create minimal data files
        (self.mod_dir / "data.lua").write_text('require("constants")')
        (self.mod_dir / "control.lua").write_text('-- test')
        (self.mod_dir / "constants.lua").write_text('GRAPHICS = "graphics/"')
        (self.mod_dir / "util.lua").write_text('util = {}')

    def test_get_next_version_first_export(self):
        """Test first export gets version 1.1.0001"""
        version = self.exporter.get_next_version(self.mod_dir)
        self.assertEqual(version, "1.1.0001", "First export should be 1.1.0001")

    def test_get_next_version_increments(self):
        """Test version increments from 1.1.0001 to 1.1.0002"""
        # Create a zip file for version 1.1.0001
        zip_path = self.mod_dir / "PollutionSolutionsLite_1.1.0001.zip"
        zip_path.touch()
        
        version = self.exporter.get_next_version(self.mod_dir)
        self.assertEqual(version, "1.1.0002", "Second export should be 1.1.0002")

    def test_get_next_version_skips_gaps(self):
        """Test version finds highest number even with gaps"""
        # Create zips for versions 0001, 0005 (gap), 0003
        (self.mod_dir / "PollutionSolutionsLite_1.1.0001.zip").touch()
        (self.mod_dir / "PollutionSolutionsLite_1.1.0005.zip").touch()
        (self.mod_dir / "PollutionSolutionsLite_1.1.0003.zip").touch()
        
        version = self.exporter.get_next_version(self.mod_dir)
        self.assertEqual(version, "1.1.0006", "Should find highest version (0005) and increment to 0006")

    def test_get_next_version_format_consistency(self):
        """Test version format is always 1.1.XXXX with 4 digits"""
        # Create several zip files
        for i in range(1, 6):
            (self.mod_dir / f"PollutionSolutionsLite_1.1.{i:04d}.zip").touch()
        
        version = self.exporter.get_next_version(self.mod_dir)
        
        # Check format
        parts = version.split('.')
        self.assertEqual(len(parts), 3, "Version should have 3 parts (1.1.XXXX)")
        self.assertEqual(parts[0], "1", "Major version should be 1")
        self.assertEqual(parts[1], "1", "Minor version should be 1")
        self.assertEqual(len(parts[2]), 4, "Build number should be 4 digits zero-padded")
        self.assertTrue(parts[2].isdigit(), "Build number should be all digits")

    def test_update_info_version_modifies_file(self):
        """Test that update_info_version modifies info.json"""
        new_version = "1.1.0005"
        result = self.exporter.update_info_version(new_version)
        
        self.assertTrue(result, "update_info_version should return True")
        
        # Check that info.json was updated
        info = json.loads((self.mod_dir / "info.json").read_text())
        self.assertEqual(info["version"], new_version, f"info.json version should be {new_version}")

    def test_consecutive_versions_monotonic(self):
        """Test that consecutive versions are monotonically increasing"""
        versions = []
        
        for i in range(1, 6):
            version = self.exporter.get_next_version(self.mod_dir)
            versions.append(version)
            
            # Create zip for this version
            (self.mod_dir / f"PollutionSolutionsLite_{version}.zip").touch()
        
        # Extract build numbers and verify they're sequential
        build_numbers = [int(v.split('.')[-1]) for v in versions]
        expected = [1, 2, 3, 4, 5]
        
        self.assertEqual(build_numbers, expected, 
                        f"Build numbers should be sequential: {build_numbers} vs {expected}")

    def test_version_in_exported_info_json(self):
        """Test that exported mod info.json has updated version"""
        test_version = "1.1.0010"
        result = self.exporter.update_info_version(test_version)
        
        self.assertTrue(result)
        
        info = json.loads((self.mod_dir / "info.json").read_text())
        self.assertEqual(info["version"], test_version,
                        "Exported info.json should have updated version")

    def test_version_preserves_other_fields(self):
        """Test that updating version doesn't lose other fields"""
        original_info = json.loads((self.mod_dir / "info.json").read_text())
        original_author = original_info["author"]
        original_title = original_info["title"]
        
        self.exporter.update_info_version("1.1.0005")
        
        updated_info = json.loads((self.mod_dir / "info.json").read_text())
        
        self.assertEqual(updated_info["author"], original_author, "Author should be preserved")
        self.assertEqual(updated_info["title"], original_title, "Title should be preserved")
        self.assertEqual(updated_info["version"], "1.1.0005", "Version should be updated")

    def test_ignores_old_format_versions(self):
        """Test that old format versions (1.0.x or 1.1.x without 4 digits) are ignored"""
        # Create some old format zips that should NOT count
        (self.mod_dir / "PollutionSolutionsLite_1.0.0.zip").touch()
        (self.mod_dir / "PollutionSolutionsLite_1.1.5.zip").touch()  # Only 1 digit
        (self.mod_dir / "PollutionSolutionsLite_1.1.99.zip").touch()  # Only 2 digits
        
        # Create new format
        (self.mod_dir / "PollutionSolutionsLite_1.1.0003.zip").touch()
        
        version = self.exporter.get_next_version(self.mod_dir)
        self.assertEqual(version, "1.1.0004", "Should skip old format versions and increment from 0003")


class TestExportIntegration(unittest.TestCase):
    """Integration tests for full export cycle"""

    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp()
        self.mod_dir = Path(self.test_dir) / "TestMod"
        self.mod_dir.mkdir()
        self.export_dest = Path(self.test_dir) / "export"
        self.export_dest.mkdir()
        
        self.exporter = ModExporter()
        self.exporter.mod_source_dir = self.mod_dir
        self.exporter.mod_name = "TestMod"
        
        # Create minimal mod
        info = {
            "name": "TestMod",
            "version": "1.1.0001",
            "title": "Test",
            "description": "Test",
            "author": "Test"
        }
        (self.mod_dir / "info.json").write_text(json.dumps(info))
        (self.mod_dir / "control.lua").write_text("-- test")
    
    def tearDown(self):
        """Clean up"""
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_version_sync_between_zip_and_info(self):
        """Test that zip version and info.json version always match after export"""
        # Simulate multiple exports
        for expected_build in range(1, 4):
            expected_version = f"1.1.{expected_build:04d}"
            
            # Get next version
            version = self.exporter.get_next_version(self.export_dest)
            self.assertEqual(version, expected_version)
            
            # Update info.json
            self.exporter.update_info_version(version)
            
            # Verify info.json has the right version
            info = json.loads((self.mod_dir / "info.json").read_text())
            self.assertEqual(info["version"], expected_version,
                           f"info.json should have version {expected_version}")
            
            # Simulate creating the zip
            zip_path = self.export_dest / f"TestMod_{version}.zip"
            zip_path.touch()
            
            # Verify zip version matches
            self.assertTrue(zip_path.exists(), f"Zip {version} should exist")


if __name__ == "__main__":
    unittest.main()
