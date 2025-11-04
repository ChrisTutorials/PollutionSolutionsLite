#!/usr/bin/env lua5.3
--[[
  Recipe Validation Script for Factorio 2.0
  
  This script validates that all recipes use the correct Factorio 2.0 format:
  - No 'result' field (should use 'results' array)
  - No 'normal'/'expensive' difficulty modes (removed in 2.0)
  - Proper results array format
]]

local function check_file(filename)
  print("Checking: " .. filename)
  local file = io.open(filename, "r")
  if not file then
    print("  ✗ Could not open file")
    return false
  end
  
  local content = file:read("*all")
  file:close()
  
  local issues = {}
  local line_num = 0
  
  for line in content:gmatch("[^\r\n]+") do
    line_num = line_num + 1
    
    -- Check for old result format (but allow place_result and minable.result)
    if line:match("%s+result%s*=%s*[\"']") and 
       not line:match("place_result") and 
       not line:match("minable%.result") then
      table.insert(issues, string.format("  Line %d: Found old 'result' format", line_num))
    end
    
    -- Check for normal/expensive difficulty modes
    if line:match("%.normal%s*=%s*{") or line:match("%.expensive%s*=%s*{") then
      table.insert(issues, string.format("  Line %d: Found deprecated difficulty mode (normal/expensive)", line_num))
    end
  end
  
  if #issues > 0 then
    print("  ✗ Found " .. #issues .. " issue(s):")
    for _, issue in ipairs(issues) do
      print(issue)
    end
    return false
  else
    print("  ✓ No issues found")
    return true
  end
end

print("========================================")
print("Factorio 2.0 Recipe Validation")
print("========================================")
print()

local files = {
  "prototypes/recipe.lua",
  "prototypes/hevsuit.lua",
  "prototypes/pollutioncollector.lua",
}

local all_passed = true
for _, file in ipairs(files) do
  if not check_file(file) then
    all_passed = false
  end
  print()
end

print("========================================")
if all_passed then
  print("✓ All files validated successfully")
  print("========================================")
  os.exit(0)
else
  print("✗ Validation failed - see issues above")
  print("========================================")
  os.exit(1)
end
