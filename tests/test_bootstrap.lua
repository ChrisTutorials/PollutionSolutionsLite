--[[
  Test Bootstrap for Pollution Solutions Lite
  
  This file provides the basic testing infrastructure for the mod.
  Since we're targeting Factorio 2.0+, tests should be run using
  either factorio-test or manual in-game scenario testing.
  
  Test Categories:
  - Unit Tests: Test individual functions and calculations
  - Integration Tests: Test entity interactions and systems
  - Scenario Tests: Full gameplay scenarios
  
  Usage:
  1. Copy this mod into your Factorio mods folder
  2. Use factorio-test framework or create test scenarios
  3. Run tests through Factorio debug mode or test framework
]]

-- Test framework detection
local test_framework = nil
if script and script.active_mods then
  if script.active_mods["factorio-test"] then
    test_framework = "factorio-test"
  elseif script.active_mods["testorio"] then
    test_framework = "testorio"
  end
end

-- Basic test utilities
TestUtils = {}

---Print a test message
---@param message string The message to print
function TestUtils.log(message)
  if game then
    game.print("[TEST] " .. message)
  end
  log("[TEST] " .. message)
end

---Assert a condition is true
---@param condition boolean The condition to check
---@param message string Error message if condition is false
function TestUtils.assert(condition, message)
  if not condition then
    local error_msg = "Assertion failed: " .. (message or "no message")
    TestUtils.log(error_msg)
    error(error_msg)
  end
end

---Assert two values are equal
---@param actual any The actual value
---@param expected any The expected value
---@param message string Optional error message
function TestUtils.assertEqual(actual, expected, message)
  if actual ~= expected then
    local error_msg = string.format(
      "Values not equal: expected %s, got %s%s",
      tostring(expected),
      tostring(actual),
      message and (" - " .. message) or ""
    )
    TestUtils.log(error_msg)
    error(error_msg)
  end
end

---Assert a value is not nil
---@param value any The value to check
---@param message string Optional error message
function TestUtils.assertNotNil(value, message)
  if value == nil then
    local error_msg = "Value is nil" .. (message and (" - " .. message) or "")
    TestUtils.log(error_msg)
    error(error_msg)
  end
end

---Run a test function with error handling
---@param name string Test name
---@param testFn function Test function to run
function TestUtils.runTest(name, testFn)
  TestUtils.log("Running test: " .. name)
  local success, error_message = pcall(testFn)
  if success then
    TestUtils.log("✓ PASSED: " .. name)
    return true
  else
    TestUtils.log("✗ FAILED: " .. name)
    TestUtils.log("  Error: " .. tostring(error_message))
    return false
  end
end

---Run a suite of tests
---@param suiteName string Test suite name
---@param tests table Table of test functions with names as keys
function TestUtils.runTestSuite(suiteName, tests)
  TestUtils.log("========================================")
  TestUtils.log("Test Suite: " .. suiteName)
  TestUtils.log("========================================")
  
  local passed = 0
  local failed = 0
  
  for testName, testFn in pairs(tests) do
    if TestUtils.runTest(testName, testFn) then
      passed = passed + 1
    else
      failed = failed + 1
    end
  end
  
  TestUtils.log("========================================")
  TestUtils.log(string.format("Results: %d passed, %d failed", passed, failed))
  TestUtils.log("========================================")
  
  return passed, failed
end

return TestUtils
