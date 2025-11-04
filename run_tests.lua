#!/usr/bin/env lua
--[[
  Test Runner for Pollution Solutions Lite
  
  This script runs all unit tests for the mod outside of Factorio.
  Usage: lua run_tests.lua
]]

package.path = package.path .. ";?" .. "/home/chris/gamedev/mods/PollutionSolutionsLite/?.lua"
package.path = package.path .. ";?" .. "/home/chris/gamedev/mods/PollutionSolutionsLite/?/init.lua"

-- Global test results
local testResults = {
  suites = {},
  totalPassed = 0,
  totalFailed = 0
}

-- Mock Factorio environment
if not log then
  function log(message)
    print("[LOG] " .. message)
  end
end

if not _G.error then
  local originalError = error
  _G.error = function(msg)
    print("[ERROR] " .. tostring(msg))
    originalError(msg)
  end
end

print("========================================")
print("PollutionSolutionsLite Test Runner")
print("========================================")
print()

-- Run test_constants
print("Loading test_constants.lua...")
local success_constants, error_constants = pcall(function()
  local test_constants = require("tests.test_constants")
end)

if not success_constants then
  print("✗ FAILED to load test_constants: " .. tostring(error_constants))
  testResults.totalFailed = testResults.totalFailed + 1
else
  print("✓ test_constants completed successfully")
  testResults.totalPassed = testResults.totalPassed + 1
end

print()

-- Run test_util
print("Loading test_util.lua...")
local success_util, error_util = pcall(function()
  local test_util = require("tests.test_util")
end)

if not success_util then
  print("✗ FAILED to load test_util: " .. tostring(error_util))
  testResults.totalFailed = testResults.totalFailed + 1
else
  print("✓ test_util completed successfully")
  testResults.totalPassed = testResults.totalPassed + 1
end

print()
print("========================================")
print("Test Execution Summary")
print("========================================")
print(string.format("Total Suites Passed: %d", testResults.totalPassed))
print(string.format("Total Suites Failed: %d", testResults.totalFailed))
print("========================================")
print()

if testResults.totalFailed > 0 then
  os.exit(1)
end

os.exit(0)
