--[[
  Test suite for Factorio 2.0 API migration validation
  
  This test ensures all prototypes are compatible with Factorio 2.0 API changes:
  - Recipe ingredients must have explicit 'type' field
  - Collision masks must be dictionaries with 'layers' key
  - Optional fields are handled gracefully
  
  Run with: lua tests/test_factorio_2_migration.lua
]]
--

-- Test framework setup
local test_count = 0
local passed_count = 0
local failed_tests = {}

local function assert_test(condition, test_name, error_message)
  test_count = test_count + 1
  if condition then
    passed_count = passed_count + 1
    print(string.format("✓ [%d] %s", test_count, test_name))
  else
    print(string.format("✗ [%d] %s", test_count, test_name))
    print(string.format("  Error: %s", error_message))
    table.insert(failed_tests, { name = test_name, error = error_message })
  end
end

-- Bootstrap Factorio data environment (minimal stub for data loading)
-- Mock the Factorio data environment
data = {
  raw = {},
  extend = function(self, prototypes)
    for _, prototype in ipairs(prototypes) do
      local ptype = prototype.type
      if not self.raw[ptype] then
        self.raw[ptype] = {}
      end
      self.raw[ptype][prototype.name] = prototype
    end
  end,
}

-- Mock util
util = {
  table = {
    deepcopy = function(obj)
      if type(obj) ~= "table" then
        return obj
      end
      local copy = {}
      for k, v in pairs(obj) do
        if type(v) == "table" then
          copy[k] = util.table.deepcopy(v)
        else
          copy[k] = v
        end
      end
      return copy
    end,
  },
  by_pixel = function(x, y)
    return { x, y }
  end,
}

-- Mock defines
defines = {
  direction = {
    north = 0,
    east = 2,
    south = 4,
    west = 6,
  },
}

-- Mock settings
settings = {
  startup = {
    ["air-per-filter"] = { value = 100 },
    ["water-per-filter-percent"] = { value = 50 },
    ["sludge-per-filter"] = { value = 10 },
    ["toxic-damage-mult"] = { value = 1.0 },
    ["pollution-per-cloud"] = { value = 100 },
    ["tick-cloud-lifetime"] = { value = 300 },
    ["incinerator-radius"] = { value = 10 },
  },
}

-- Mock log function
function log(msg)
  -- Silent during testing unless needed
end

-- Load mod files
package.path = package.path .. ";./?.lua"

-- Load the actual mod data
local success, err = pcall(function()
  require("data")
end)

if not success then
  print("ERROR: Failed to load mod data: " .. tostring(err))
  print("Note: This test requires being run from the mod root directory")
  os.exit(1)
end

print("=" .. string.rep("=", 70))
print("Factorio 2.0 Migration Validation Tests")
print("=" .. string.rep("=", 70))
print("")

--
-- Test Suite 1: Recipe Ingredient Format Validation
--

print("Test Suite 1: Recipe Ingredient Format (Factorio 2.0)")
print("-" .. string.rep("-", 70))

-- Helper function to validate ingredient format
local function validate_ingredient(ingredient, recipe_name, index)
  if type(ingredient) ~= "table" then
    return false, string.format("Ingredient %d is not a table", index)
  end

  -- In Factorio 2.0, ingredients MUST have explicit 'type' field
  if not ingredient.type then
    return false,
      string.format(
        "Ingredient %d missing 'type' field (name: %s)",
        index,
        ingredient.name or "unknown"
      )
  end

  -- Validate type is either "item" or "fluid"
  if ingredient.type ~= "item" and ingredient.type ~= "fluid" then
    return false,
      string.format(
        "Ingredient %d has invalid type '%s' (must be 'item' or 'fluid')",
        index,
        ingredient.type
      )
  end

  -- Must have name
  if not ingredient.name then
    return false, string.format("Ingredient %d missing 'name' field", index)
  end

  -- Must have amount
  if not ingredient.amount then
    return false, string.format("Ingredient %d (%s) missing 'amount' field", index, ingredient.name)
  end

  return true, nil
end

-- Test all recipes for proper ingredient format
if data and data.raw and data.raw.recipe then
  local recipe_count = 0
  local issues_found = {}

  for recipe_name, recipe in pairs(data.raw.recipe) do
    recipe_count = recipe_count + 1

    if recipe.ingredients then
      for idx, ingredient in ipairs(recipe.ingredients) do
        local valid, error_msg = validate_ingredient(ingredient, recipe_name, idx)
        if not valid then
          table.insert(issues_found, {
            recipe = recipe_name,
            error = error_msg,
          })
        end
      end
    end

    -- Also check normal/expensive variants
    if recipe.normal and recipe.normal.ingredients then
      for idx, ingredient in ipairs(recipe.normal.ingredients) do
        local valid, error_msg = validate_ingredient(ingredient, recipe_name .. " (normal)", idx)
        if not valid then
          table.insert(issues_found, {
            recipe = recipe_name .. " (normal)",
            error = error_msg,
          })
        end
      end
    end

    if recipe.expensive and recipe.expensive.ingredients then
      for idx, ingredient in ipairs(recipe.expensive.ingredients) do
        local valid, error_msg = validate_ingredient(ingredient, recipe_name .. " (expensive)", idx)
        if not valid then
          table.insert(issues_found, {
            recipe = recipe_name .. " (expensive)",
            error = error_msg,
          })
        end
      end
    end
  end

  local error_details = ""
  if #issues_found > 0 then
    error_details = "\n  Issues found:"
    for _, issue in ipairs(issues_found) do
      error_details = error_details
        .. string.format("\n    - Recipe '%s': %s", issue.recipe, issue.error)
    end
  end

  assert_test(
    #issues_found == 0,
    string.format(
      "All recipes have valid Factorio 2.0 ingredient format (%d recipes checked)",
      recipe_count
    ),
    string.format("%d recipe(s) with invalid ingredients%s", #issues_found, error_details)
  )
else
  assert_test(false, "Recipe data loaded", "data.raw.recipe not found")
end

print("")

--
-- Test Suite 2: Collision Mask Format Validation
--

print("Test Suite 2: Collision Mask Format (Factorio 2.0)")
print("-" .. string.rep("-", 70))

-- Helper function to validate collision_mask format
local function validate_collision_mask(entity_type, entity_name, collision_mask)
  if not collision_mask then
    -- nil is valid - entity uses default
    return true, nil
  end

  -- In Factorio 2.0, collision_mask must be a table with 'layers' key (dictionary format)
  -- Old format was array: { "item-layer", "object-layer" }
  -- New format is: { layers = { item = true, object = true } }

  if type(collision_mask) ~= "table" then
    return false, "collision_mask must be a table"
  end

  -- Check if it's the old array format (should fail)
  if collision_mask[1] and type(collision_mask[1]) == "string" then
    return false, "collision_mask uses old array format, must be dictionary with 'layers' key"
  end

  -- Check for proper dictionary format
  if not collision_mask.layers then
    return false, "collision_mask missing 'layers' key (must be dictionary format)"
  end

  if type(collision_mask.layers) ~= "table" then
    return false, "collision_mask.layers must be a table"
  end

  return true, nil
end

-- Entity types that commonly have collision_mask
local entity_types_with_collision = {
  "storage-tank",
  "assembling-machine",
  "furnace",
  "reactor",
  "boiler",
  "generator",
  "mining-drill",
  "turret",
  "ammo-turret",
  "electric-turret",
  "fluid-turret",
  "car",
  "locomotive",
  "cargo-wagon",
  "fluid-wagon",
  "container",
  "logistic-container",
  "wall",
  "gate",
  "pipe",
  "pipe-to-ground",
  "pump",
  "heat-pipe",
  "inserter",
}

local collision_issues = {}
local entities_checked = 0

for _, entity_type in ipairs(entity_types_with_collision) do
  if data and data.raw and data.raw[entity_type] then
    for entity_name, entity in pairs(data.raw[entity_type]) do
      entities_checked = entities_checked + 1

      if entity.collision_mask then
        local valid, error_msg =
          validate_collision_mask(entity_type, entity_name, entity.collision_mask)
        if not valid then
          table.insert(collision_issues, {
            type = entity_type,
            name = entity_name,
            error = error_msg,
          })
        end
      end
    end
  end
end

local collision_error_details = ""
if #collision_issues > 0 then
  collision_error_details = "\n  Issues found:"
  for _, issue in ipairs(collision_issues) do
    collision_error_details = collision_error_details
      .. string.format("\n    - %s '%s': %s", issue.type, issue.name, issue.error)
  end
end

assert_test(
  #collision_issues == 0,
  string.format(
    "All entities use valid Factorio 2.0 collision_mask format (%d entities checked)",
    entities_checked
  ),
  string.format(
    "%d entity(ies) with invalid collision_mask%s",
    #collision_issues,
    collision_error_details
  )
)

print("")

--
-- Test Suite 3: Results Format Validation
--

print("Test Suite 3: Recipe Results Format (Factorio 2.0)")
print("-" .. string.rep("-", 70))

-- Helper function to validate results format
local function validate_result(result, recipe_name, index)
  if type(result) ~= "table" then
    return false, string.format("Result %d is not a table", index)
  end

  -- Results should also have explicit 'type' field in Factorio 2.0
  if not result.type then
    return false,
      string.format("Result %d missing 'type' field (name: %s)", index, result.name or "unknown")
  end

  if result.type ~= "item" and result.type ~= "fluid" then
    return false, string.format("Result %d has invalid type '%s'", index, result.type)
  end

  if not result.name then
    return false, string.format("Result %d missing 'name' field", index)
  end

  -- Amount is optional for results (defaults to 1), but if present must be valid
  if result.amount and type(result.amount) ~= "number" then
    return false, string.format("Result %d (%s) has non-numeric amount", index, result.name)
  end

  return true, nil
end

-- Test all recipes for proper results format
if data and data.raw and data.raw.recipe then
  local result_issues = {}

  for recipe_name, recipe in pairs(data.raw.recipe) do
    local function check_results(results_table, variant_name)
      if results_table then
        for idx, result in ipairs(results_table) do
          local valid, error_msg = validate_result(result, variant_name, idx)
          if not valid then
            table.insert(result_issues, {
              recipe = variant_name,
              error = error_msg,
            })
          end
        end
      end
    end

    -- Check main results
    if recipe.results then
      check_results(recipe.results, recipe_name)
    end

    -- Check normal variant
    if recipe.normal and recipe.normal.results then
      check_results(recipe.normal.results, recipe_name .. " (normal)")
    end

    -- Check expensive variant
    if recipe.expensive and recipe.expensive.results then
      check_results(recipe.expensive.results, recipe_name .. " (expensive)")
    end
  end

  local result_error_details = ""
  if #result_issues > 0 then
    result_error_details = "\n  Issues found:"
    for _, issue in ipairs(result_issues) do
      result_error_details = result_error_details
        .. string.format("\n    - Recipe '%s': %s", issue.recipe, issue.error)
    end
  end

  assert_test(
    #result_issues == 0,
    "All recipe results have valid Factorio 2.0 format",
    string.format("%d recipe(s) with invalid results%s", #result_issues, result_error_details)
  )
else
  assert_test(false, "Recipe data loaded for results validation", "data.raw.recipe not found")
end

print("")

--
-- Test Suite 4: Mod-Specific Entity Validation
--

print("Test Suite 4: Mod-Specific Entity Validation")
print("-" .. string.rep("-", 70))

-- Test that our custom entities exist and have required fields
local mod_entities = {
  { type = "reactor", name = "toxic-incinerator" },
  { type = "ammo-turret", name = "toxic-turret" },
  { type = "boiler", name = "low-heat-exchanger" },
  { type = "storage-tank", name = "dump-site" },
  { type = "storage-tank", name = "pollutioncollector" },
}

for _, entity_def in ipairs(mod_entities) do
  local entity = data.raw[entity_def.type] and data.raw[entity_def.type][entity_def.name]

  assert_test(
    entity ~= nil,
    string.format("Entity '%s' (%s) exists", entity_def.name, entity_def.type),
    string.format("Entity not found in data.raw.%s", entity_def.type)
  )

  if entity then
    -- Validate icon
    assert_test(
      entity.icon ~= nil or entity.icons ~= nil,
      string.format("Entity '%s' has icon definition", entity_def.name),
      "Missing both 'icon' and 'icons' fields"
    )

    -- Validate minable
    assert_test(
      entity.minable ~= nil,
      string.format("Entity '%s' is minable", entity_def.name),
      "Missing 'minable' field"
    )
  end
end

print("")

--
-- Test Suite 5: Mod-Specific Recipe Validation
--

print("Test Suite 5: Mod-Specific Recipe Validation")
print("-" .. string.rep("-", 70))

local mod_recipes = {
  "toxic-incinerator",
  "toxic-turret",
  "low-heat-exchanger",
  "dump-site",
  "pollutioncollector",
  "blue-xenomass",
  "red-xenomass",
  "liquify-pollution",
  "toxic-waste-treatment",
}

for _, recipe_name in ipairs(mod_recipes) do
  local recipe = data.raw.recipe and data.raw.recipe[recipe_name]

  assert_test(
    recipe ~= nil,
    string.format("Recipe '%s' exists", recipe_name),
    "Recipe not found in data.raw.recipe"
  )

  if recipe then
    -- Validate has ingredients
    local has_ingredients = recipe.ingredients
      or (recipe.normal and recipe.normal.ingredients)
      or (recipe.expensive and recipe.expensive.ingredients)

    assert_test(
      has_ingredients ~= nil,
      string.format("Recipe '%s' has ingredients", recipe_name),
      "Missing ingredients definition"
    )

    -- Validate has results
    local has_results = recipe.results
      or recipe.result
      or (recipe.normal and (recipe.normal.results or recipe.normal.result))
      or (recipe.expensive and (recipe.expensive.results or recipe.expensive.result))

    assert_test(
      has_results ~= nil,
      string.format("Recipe '%s' has results/result", recipe_name),
      "Missing results or result definition"
    )
  end
end

print("")

--
-- Test Suite 6: Fluid Validation
--

print("Test Suite 6: Fluid Prototype Validation")
print("-" .. string.rep("-", 70))

local mod_fluids = {
  "polluted-air",
  "toxic-sludge",
}

for _, fluid_name in ipairs(mod_fluids) do
  local fluid = data.raw.fluid and data.raw.fluid[fluid_name]

  assert_test(
    fluid ~= nil,
    string.format("Fluid '%s' exists", fluid_name),
    "Fluid not found in data.raw.fluid"
  )

  if fluid then
    -- Validate icon
    assert_test(
      fluid.icon ~= nil or fluid.icons ~= nil,
      string.format("Fluid '%s' has icon definition", fluid_name),
      "Missing both 'icon' and 'icons' fields"
    )

    -- Validate base_color
    assert_test(
      fluid.base_color ~= nil,
      string.format("Fluid '%s' has base_color", fluid_name),
      "Missing 'base_color' field"
    )

    -- Validate flow_color
    assert_test(
      fluid.flow_color ~= nil,
      string.format("Fluid '%s' has flow_color", fluid_name),
      "Missing 'flow_color' field"
    )
  end
end

print("")

--
-- Test Results Summary
--

print("=" .. string.rep("=", 70))
print("Test Results Summary")
print("=" .. string.rep("=", 70))
print(string.format("Total tests: %d", test_count))
print(string.format("Passed: %d", passed_count))
print(string.format("Failed: %d", test_count - passed_count))

if #failed_tests > 0 then
  print("")
  print("Failed Tests:")
  for _, test in ipairs(failed_tests) do
    print(string.format("  ✗ %s", test.name))
    print(string.format("    %s", test.error))
  end
  print("")
  os.exit(1)
else
  print("")
  print("✓ All tests passed!")
  print("")
  os.exit(0)
end
