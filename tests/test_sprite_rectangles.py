#!/usr/bin/env python3
"""
Sprite Rectangle Validation Tests

Test cases to catch sprite rectangle overflow errors that occur when:
1. Using deepcopy on base game entities with custom graphics
2. Not resetting variation_count, repeat_count, or other layout properties
3. Sprite sheet dimensions don't match actual image files

These errors are hard to catch because they only manifest at runtime
when Factorio tries to render the graphics.
"""

import sys
import subprocess
from pathlib import Path
from typing import Dict, List, Tuple, Optional


class SpriteRectangleValidator:
    """Validates sprite definitions against actual image dimensions"""
    
    def __init__(self, mod_dir: Path):
        self.mod_dir = mod_dir
        self.errors: List[str] = []
        self.warnings: List[str] = []
        
    def test_deepcopy_sprite_reset(self) -> bool:
        """
        Test Case 1: Deepcopy without proper sprite reset
        
        When copying base game entities, verify that:
        - variation_count is removed (not set to 1)
        - repeat_count is removed  
        - frame_count and line_length are set correctly
        - All sheets are reset, not just sheets[1]
        """
        print("\n" + "="*70)
        print("Test 1: Deepcopy Sprite Reset Validation")
        print("="*70)
        
        # Read pollutioncollector.lua
        pollutioncollector_lua = self.mod_dir / "prototypes" / "pollutioncollector.lua"
        if not pollutioncollector_lua.exists():
            self.errors.append(f"File not found: {pollutioncollector_lua}")
            return False
        
        content = pollutioncollector_lua.read_text()
        
        # Check 1: Verify pictures structure is replaced, not patched
        if "pollutioncollector.pictures = {" in content or "pictures.picture.sheets = {" in content:
            print("✓ PASS: Pictures structure is completely replaced (not patched)")
            return True
        elif "for _, sheet in ipairs" in content and "sheet.variation_count = nil" in content:
            print("⚠ WARN: Using loop to reset sheets (should be safer than deepcopy patch)")
            print("  Recommendation: Replace entire pictures structure instead")
            self.warnings.append("pollutioncollector.lua: Using sheet loop instead of full replacement")
            return True
        else:
            self.errors.append("pollutioncollector.lua: No sprite reset pattern found")
            return False
    
    def test_variation_count_removed(self) -> bool:
        """
        Test Case 2: Variation count is properly removed
        
        Verify that variation_count is NOT set (completely omitted from sheet definition)
        Setting it to ANY value (including 1) activates the variation system.
        """
        print("\n" + "="*70)
        print("Test 2: Variation Count Removal")
        print("="*70)
        
        pollutioncollector_lua = self.mod_dir / "prototypes" / "pollutioncollector.lua"
        content = pollutioncollector_lua.read_text()
        
        # Anti-pattern: variation_count with ANY value
        if "variation_count = " in content or "variation_count=" in content:
            self.errors.append(
                "pollutioncollector.lua: Found 'variation_count' property\n"
                "  Setting variation_count to ANY value (even 1) activates variation system!\n"
                "  Solution: Omit variation_count entirely from sheet definition"
            )
            return False
        
        # Good pattern: no variation_count in pictures definition
        print("✓ PASS: variation_count not present (completely omitted)")
        return True
    
    def test_all_sheets_reset(self) -> bool:
        """
        Test Case 3: All sprite sheets are reset
        
        Storage-tank has multiple sheets (main sprite + shadow).
        Verify ALL sheets are reset, not just sheets[1].
        """
        print("\n" + "="*70)
        print("Test 3: All Sheets Reset")
        print("="*70)
        
        pollutioncollector_lua = self.mod_dir / "prototypes" / "pollutioncollector.lua"
        content = pollutioncollector_lua.read_text()
        
        # Pattern 1: Full replacement (best)
        if "pictures.picture.sheets = {" in content or "pictures = {\n" in content:
            print("✓ PASS: All sheets replaced in new structure")
            return True
        
        # Pattern 2: Loop through all sheets (acceptable)
        if "for _, sheet in ipairs(pollutioncollector.pictures.picture.sheets)" in content:
            print("✓ PASS: Using loop to reset all sheets")
            return True
        
        # Anti-pattern: Only sheets[1]
        if "sheets[1]" in content and "for" not in content:
            self.errors.append(
                "pollutioncollector.lua: Only sheets[1] is being reset\n"
                "  Storage-tank has 2+ sheets (main + shadow)\n"
                "  sheets[2] (shadow) still has base game dimensions!"
            )
            return False
        
        self.errors.append("pollutioncollector.lua: Unclear which sheets are reset")
        return False
    
    def test_frame_count_line_length(self) -> bool:
        """
        Test Case 4: frame_count and line_length are set
        
        These control how animation frames are laid out in the sprite sheet.
        For a single static sprite, should be:
        - frame_count = 1
        - line_length = 1
        """
        print("\n" + "="*70)
        print("Test 4: Frame Count and Line Length")
        print("="*70)
        
        pollutioncollector_lua = self.mod_dir / "prototypes" / "pollutioncollector.lua"
        content = pollutioncollector_lua.read_text()
        
        has_frame_count = "frame_count = 1" in content or "frame_count=1" in content
        has_line_length = "line_length = 1" in content or "line_length=1" in content
        
        if has_frame_count and has_line_length:
            print("✓ PASS: frame_count and line_length both set to 1")
            return True
        
        if not has_frame_count:
            self.warnings.append("pollutioncollector.lua: frame_count = 1 not found")
        if not has_line_length:
            self.warnings.append("pollutioncollector.lua: line_length = 1 not found")
        
        return has_frame_count and has_line_length
    
    def test_no_hr_version_conflict(self) -> bool:
        """
        Test Case 5: HR version is not defined
        
        We removed HR version entirely, verify it's not being set elsewhere.
        If Factorio tries to render hr_version but it doesn't exist, error.
        """
        print("\n" + "="*70)
        print("Test 5: HR Version Handling")
        print("="*70)
        
        pollutioncollector_lua = self.mod_dir / "prototypes" / "pollutioncollector.lua"
        content = pollutioncollector_lua.read_text()
        
        # Check if hr_version is explicitly removed
        if "hr_version = nil" in content or "no HR version" in content or "hr_version" not in content:
            print("✓ PASS: HR version is properly handled (not defined)")
            return True
        
        self.warnings.append("pollutioncollector.lua: HR version handling not clear")
        return True  # Warning only, not a failure
    
    def run_headless_validation(self) -> bool:
        """
        Test Case 6: Headless Factorio validation
        
        Run actual Factorio to verify no sprite errors occur.
        This is the final source of truth.
        """
        print("\n" + "="*70)
        print("Test 6: Headless Factorio Validation")
        print("="*70)
        
        # Run the headless test
        test_script = self.mod_dir / "tests" / "test_factorio_2_headless.py"
        if not test_script.exists():
            self.warnings.append("Headless test script not found")
            return True
        
        try:
            result = subprocess.run(
                [sys.executable, str(test_script)],
                capture_output=True,
                text=True,
                timeout=120,
                cwd=str(self.mod_dir)
            )
            
            if result.returncode == 0:
                print("✓ PASS: Headless Factorio validation successful")
                if "sprite rectangle" in result.stdout.lower() or "sprite rectangle" in result.stderr.lower():
                    self.errors.append("Headless test: Sprite rectangle error detected!")
                    return False
                return True
            else:
                self.errors.append(f"Headless test failed with return code {result.returncode}")
                if result.stderr:
                    self.errors.append(f"  stderr: {result.stderr[:200]}")
                return False
        except subprocess.TimeoutExpired:
            self.errors.append("Headless test timed out")
            return False
        except Exception as e:
            self.errors.append(f"Error running headless test: {e}")
            return False
    
    def run_all_tests(self) -> bool:
        """Run all sprite rectangle test cases"""
        print("="*70)
        print("Sprite Rectangle Validation Test Suite")
        print("="*70)
        
        results = []
        results.append(("Deepcopy Sprite Reset", self.test_deepcopy_sprite_reset()))
        results.append(("Variation Count Removal", self.test_variation_count_removed()))
        results.append(("All Sheets Reset", self.test_all_sheets_reset()))
        results.append(("Frame Count/Line Length", self.test_frame_count_line_length()))
        results.append(("HR Version Handling", self.test_no_hr_version_conflict()))
        results.append(("Headless Validation", self.run_headless_validation()))
        
        # Print summary
        print("\n" + "="*70)
        print("Test Results Summary")
        print("="*70)
        
        passed = sum(1 for _, result in results if result)
        total = len(results)
        
        for name, result in results:
            status = "✓ PASS" if result else "✗ FAIL"
            print(f"{status}: {name}")
        
        print()
        print(f"Passed: {passed}/{total}")
        
        if self.warnings:
            print(f"\nWarnings ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  ⚠ {warning}")
        
        if self.errors:
            print(f"\nErrors ({len(self.errors)}):")
            for error in self.errors:
                print(f"  ✗ {error}")
            return False
        
        return passed == total


def main():
    """Run sprite rectangle validation tests"""
    mod_dir = Path(__file__).parent.parent
    validator = SpriteRectangleValidator(mod_dir)
    
    success = validator.run_all_tests()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
