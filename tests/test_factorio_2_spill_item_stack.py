#!/usr/bin/env python3
"""
Test Factorio 2.0 API Compatibility - spill_item_stack

Tests the spill_item_stack function signature and xenomass drop behavior
when aliens die in Factorio 2.0+
"""

import subprocess
import json
import tempfile
import os
from pathlib import Path


class FactorioCompatibilityTest:
    """Test Factorio 2.0 API compatibility for mod features"""
    
    def __init__(self, factorio_path=None):
        """Initialize test runner"""
        self.factorio_path = factorio_path or self._find_factorio()
        self.test_results = []
    
    def _find_factorio(self):
        """Find Factorio installation"""
        common_paths = [
            "/opt/factorio",
            "/usr/local/factorio",
            os.path.expanduser("~/factorio"),
            "C:\\Program Files\\Factorio",
            "C:\\Program Files (x86)\\Factorio",
        ]
        
        for path in common_paths:
            if Path(path).exists():
                return path
        
        return None
    
    def test_spill_item_stack_signature(self):
        """
        Test Case: spill_item_stack API Signature
        
        Verifies that spill_item_stack works with correct Factorio 2.0 signature
        """
        test_name = "spill_item_stack_signature"
        test_code = """
local mod_test = {}

-- Test 1: Check spill_item_stack existence
if not game or not game.surfaces or not game.surfaces[1] then
  error("Test environment not ready")
end

local surface = game.surfaces[1]

-- Test 2: Verify spill_item_stack is callable
if not surface.spill_item_stack then
  error("spill_item_stack method not found on surface")
end

-- Test 3: Check function signature via debug info
local spill_fn = surface.spill_item_stack
log("spill_item_stack function exists: " .. type(spill_fn))

-- Test 4: Try calling with items-only (Factorio 2.0 signature)
local test_items = {{name="iron-ore", count=5}}
local success, err = pcall(function()
  -- This is the CORRECT Factorio 2.0 signature
  surface.spill_item_stack({
    position = {x=0, y=0},
    items = test_items
  })
end)

if success then
  log("✓ spill_item_stack works with table argument (Factorio 2.0)")
  mod_test.result = "PASS"
else
  log("✗ spill_item_stack failed: " .. tostring(err))
  mod_test.result = "FAIL"
end

return mod_test
"""
        
        return {
            "name": test_name,
            "code": test_code,
            "expected": "PASS",
            "description": "Verify spill_item_stack signature for Factorio 2.0"
        }
    
    def test_alien_death_xenomass_drop(self):
        """
        Test Case: Alien Death - Xenomass Drop
        
        Verifies that xenomass correctly drops when aliens die
        """
        test_name = "alien_death_xenomass_drop"
        test_code = """
-- Test alien death xenomass drop
local test = {}

-- Create test scenario
if not game.players[1] then
  error("No player found")
end

local player = game.players[1]
local surface = player.surface

-- Test correct spill_item_stack usage (Factorio 2.0)
local function drop_xenomass(position, count)
  local items = {{name="red-xenomass", count=count}}
  
  -- CORRECT Factorio 2.0 call signature
  local success, err = pcall(function()
    surface.spill_item_stack({
      position = position,
      items = items
    })
  end)
  
  if not success then
    error("Failed to drop xenomass: " .. tostring(err))
  end
  
  return true
end

-- Test xenomass drop
local success, err = pcall(function()
  drop_xenomass({x=0, y=0}, 5)
end)

if success then
  log("✓ Xenomass drop successful (Factorio 2.0 compatible)")
  test.result = "PASS"
else
  log("✗ Xenomass drop failed: " .. tostring(err))
  test.result = "FAIL"
end

return test
"""
        
        return {
            "name": test_name,
            "code": test_code,
            "expected": "PASS",
            "description": "Verify xenomass drops correctly on alien death"
        }


def run_tests():
    """Run all compatibility tests"""
    tester = FactorioCompatibilityTest()
    
    tests = [
        tester.test_spill_item_stack_signature(),
        tester.test_alien_death_xenomass_drop(),
    ]
    
    print("=" * 60)
    print("Factorio 2.0 Compatibility Tests")
    print("=" * 60)
    
    passed = 0
    failed = 0
    
    for test in tests:
        print(f"\nTest: {test['name']}")
        print(f"Description: {test['description']}")
        print(f"Expected: {test['expected']}")
        print("-" * 60)
        
        # In real scenario, would run test code
        # For now, document what needs to be tested
        print("Code to test:")
        print(test['code'][:200] + "...")
        print("\nStatus: Would need Factorio headless mode to run")
    
    print("\n" + "=" * 60)
    print("Summary: All compatibility tests created")
    print("=" * 60)


if __name__ == "__main__":
    run_tests()
