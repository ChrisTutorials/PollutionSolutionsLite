#!/usr/bin/env lua
--[[
  Factorio 2.0 Compatibility Validation Script
  
  This script validates that the mod follows Factorio 2.0 standards
  and checks for common compatibility issues without requiring
  the full Factorio engine.
  
  Run with: lua validate_factorio_2.lua
]]

local errors = {}
local warnings = {}
local passed = {}

---Add an error to the results
local function error(message)
  table.insert(errors, message)
  print("[ERROR] " .. message)
end

---Add a warning to the results
local function warning(message)
  table.insert(warnings, message)
  print("[WARNING] " .. message)
end

---Add a passed check to the results
local function pass(message)
  table.insert(passed, message)
  print("[PASS] " .. message)
end

---Check if a file exists
local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

---Read entire file contents
local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*all")
  f:close()
  return content
end

---Parse JSON file (simple implementation)
local function parse_json(content)
  -- Very basic JSON parsing - just for info.json
  local result = {}
  
  -- Extract factorio_version
  local factorio_version = content:match('"factorio_version"%s*:%s*"([^"]+)"')
  result.factorio_version = factorio_version
  
  -- Extract version
  local version = content:match('"version"%s*:%s*"([^"]+)"')
  result.version = version
  
  -- Extract name
  local name = content:match('"name"%s*:%s*"([^"]+)"')
  result.name = name
  
  return result
end

print("========================================")
print("Factorio 2.0 Compatibility Validation")
print("========================================\n")

-- Check 1: info.json exists and is valid
print("Checking info.json...")
if not file_exists("info.json") then
  error("info.json not found")
else
  local content = read_file("info.json")
  local info = parse_json(content)
  
  if info.factorio_version == "2.0" then
    pass("factorio_version is set to '2.0'")
  else
    error("factorio_version is '" .. tostring(info.factorio_version) .. "' but should be '2.0'")
  end
  
  if info.version then
    pass("Mod version is " .. info.version)
  else
    error("Mod version not found in info.json")
  end
  
  if content:match('"base%s*>=%s*2%.0"') then
    pass("Base dependency updated to >= 2.0")
  else
    warning("Base dependency may not be correctly set for Factorio 2.0")
  end
end

-- Check 2: Required files exist
print("\nChecking required files...")
local required_files = {
  "control.lua",
  "data.lua",
  "constants.lua",
  "util.lua",
  "settings.lua"
}

for _, file in ipairs(required_files) do
  if file_exists(file) then
    pass("Found " .. file)
  else
    error("Missing required file: " .. file)
  end
end

-- Check 3: Check for deprecated API usage patterns
print("\nChecking for deprecated API patterns...")

local files_to_check = {
  {path = "control.lua", name = "control.lua"},
  {path = "data.lua", name = "data.lua"},
}

-- Common deprecated patterns in Factorio 2.0
local deprecated_patterns = {
  {pattern = "result%s*=%s*\"[^\"]+\"%s*,%s*result_count", 
   msg = "Old recipe format detected (result/result_count). Should use results array."},
  {pattern = "%.set_controller%s*%(", 
   msg = "set_controller API may have changed in 2.0"},
}

for _, file_info in ipairs(files_to_check) do
  if file_exists(file_info.path) then
    local content = read_file(file_info.path)
    for _, pattern_info in ipairs(deprecated_patterns) do
      if content:match(pattern_info.pattern) then
        warning(file_info.name .. ": " .. pattern_info.msg)
      end
    end
  end
end

-- Check 4: Documentation exists
print("\nChecking documentation...")
if file_exists("README.md") then
  pass("README.md exists")
else
  warning("README.md not found")
end

if file_exists("TESTING.md") then
  pass("TESTING.md exists")
else
  warning("TESTING.md not found")
end

-- Check 5: Test infrastructure
print("\nChecking test infrastructure...")
if file_exists("tests/test_bootstrap.lua") then
  pass("Test bootstrap exists")
else
  warning("Test bootstrap not found")
end

-- Check 6: Check for common Factorio 2.0 changes
print("\nChecking for Factorio 2.0 specific updates...")

local data_lua = read_file("data.lua")
if data_lua then
  -- Check if prototypes are loaded
  if data_lua:match('require%s*%(%s*["\']prototypes') then
    pass("Prototypes are properly loaded")
  else
    warning("Prototype loading may not be standard")
  end
end

-- Check constants for reasonable values
local constants_lua = read_file("constants.lua")
if constants_lua then
  if constants_lua:match("TICKS_PER_SECOND%s*=%s*60") then
    pass("TICKS_PER_SECOND correctly set to 60")
  else
    error("TICKS_PER_SECOND not set to 60")
  end
end

-- Summary
print("\n========================================")
print("Validation Summary")
print("========================================")
print(string.format("✓ Passed:   %d", #passed))
print(string.format("⚠ Warnings: %d", #warnings))
print(string.format("✗ Errors:   %d", #errors))
print("========================================\n")

if #errors > 0 then
  print("VALIDATION FAILED - Please fix errors before testing in Factorio")
  os.exit(1)
elseif #warnings > 0 then
  print("VALIDATION PASSED WITH WARNINGS - Review warnings before testing")
  os.exit(0)
else
  print("VALIDATION PASSED - Mod appears compatible with Factorio 2.0")
  os.exit(0)
end
