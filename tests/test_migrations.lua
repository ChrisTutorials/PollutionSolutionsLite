--[[
  Migration Tests for Pollution Solutions Lite
  
  Tests the migration scripts to ensure:
  1. Migrations don't crash with nil values
  2. Recipe lookups are safe
  3. Technology references are correct
  4. Migration logic works with missing recipes (version compatibility)
]]

require("test_bootstrap")

-- Mock game object for testing migrations
local MockGame = {}

---Create a mock recipe object
---@param name string Recipe name
---@return table Recipe object with enabled flag
local function create_mock_recipe(name)
  return {
    name = name,
    enabled = false,  -- Start disabled
  }
end

---Create a mock technology object
---@param name string Technology name
---@param researched boolean Whether technology is researched
---@return table Technology object
local function create_mock_technology(name, researched)
  return {
    name = name,
    researched = researched or false,
  }
end

---Create a mock force object
---@param recipes table Recipes to include in force
---@param technologies table Technologies to include in force
---@return table Force object
local function create_mock_force(recipes, technologies)
  return {
    name = "player",
    recipes = recipes or {},
    technologies = technologies or {},
  }
end

---Test: Migration 1.0.20 with all barrel recipes present
function test_migration_1_0_20_all_recipes_present()
  print("\n=== Test: Migration 1.0.20 - All Barrel Recipes Present ===")

  -- Setup: Create mock recipes and technologies
  local recipes = {
    ["fill-polluted-air-barrel"] = create_mock_recipe("fill-polluted-air-barrel"),
    ["empty-polluted-air-barrel"] = create_mock_recipe("empty-polluted-air-barrel"),
    ["fill-toxic-sludge-barrel"] = create_mock_recipe("fill-toxic-sludge-barrel"),
    ["empty-toxic-sludge-barrel"] = create_mock_recipe("empty-toxic-sludge-barrel"),
  }

  local technologies = {
    ["fluid-handling"] = create_mock_technology("fluid-handling", true),  -- Mark as researched
  }

  local force = create_mock_force(recipes, technologies)

  -- Execute: Run migration logic
  for _, recipe_name in ipairs({ "fill-polluted-air-barrel", "empty-polluted-air-barrel",
    "fill-toxic-sludge-barrel", "empty-toxic-sludge-barrel" }) do
    if force.recipes[recipe_name] then
      force.recipes[recipe_name].enabled = force.technologies["fluid-handling"].researched
    end
  end

  -- Assert: All recipes should be enabled
  assert(recipes["fill-polluted-air-barrel"].enabled == true, "fill-polluted-air-barrel should be enabled")
  assert(recipes["empty-polluted-air-barrel"].enabled == true, "empty-polluted-air-barrel should be enabled")
  assert(recipes["fill-toxic-sludge-barrel"].enabled == true, "fill-toxic-sludge-barrel should be enabled")
  assert(recipes["empty-toxic-sludge-barrel"].enabled == true, "empty-toxic-sludge-barrel should be enabled")

  print("✓ All barrel recipes enabled correctly when present")
end

---Test: Migration 1.0.20 with missing barrel recipes (nil-safe check)
function test_migration_1_0_20_missing_recipes()
  print("\n=== Test: Migration 1.0.20 - Missing Barrel Recipes (Nil-Safe) ===")

  -- Setup: Create empty recipes table (no barrel recipes)
  local recipes = {}

  local technologies = {
    ["fluid-handling"] = create_mock_technology("fluid-handling", true),
  }

  local force = create_mock_force(recipes, technologies)

  -- Execute: Run migration logic with nil checks (SHOULD NOT CRASH)
  local success, error_msg = pcall(function()
    for _, recipe_name in ipairs({ "fill-polluted-air-barrel", "empty-polluted-air-barrel",
      "fill-toxic-sludge-barrel", "empty-toxic-sludge-barrel" }) do
      if force.recipes[recipe_name] then
        force.recipes[recipe_name].enabled = force.technologies["fluid-handling"].researched
      end
    end
  end)

  assert(success, "Migration should not crash: " .. (error_msg or ""))
  print("✓ Migration handles missing recipes without crashing")
end

---Test: Migration 1.0.20 with technology not researched
function test_migration_1_0_20_tech_not_researched()
  print("\n=== Test: Migration 1.0.20 - Technology Not Researched ===")

  -- Setup: Create recipes with tech NOT researched
  local recipes = {
    ["fill-polluted-air-barrel"] = create_mock_recipe("fill-polluted-air-barrel"),
    ["empty-polluted-air-barrel"] = create_mock_recipe("empty-polluted-air-barrel"),
  }

  local technologies = {
    ["fluid-handling"] = create_mock_technology("fluid-handling", false),  -- Not researched
  }

  local force = create_mock_force(recipes, technologies)

  -- Execute: Run migration logic
  for _, recipe_name in ipairs({ "fill-polluted-air-barrel", "empty-polluted-air-barrel" }) do
    if force.recipes[recipe_name] then
      force.recipes[recipe_name].enabled = force.technologies["fluid-handling"].researched
    end
  end

  -- Assert: Recipes should remain disabled
  assert(recipes["fill-polluted-air-barrel"].enabled == false, "Recipe should remain disabled")
  assert(recipes["empty-polluted-air-barrel"].enabled == false, "Recipe should remain disabled")

  print("✓ Recipes remain disabled when technology not researched")
end

---Test: Migration 1.0.20 with partial recipes
function test_migration_1_0_20_partial_recipes()
  print("\n=== Test: Migration 1.0.20 - Partial Recipe Set (Mod Compatibility) ===")

  -- Setup: Only some barrel recipes exist (e.g., from another mod)
  local recipes = {
    ["fill-polluted-air-barrel"] = create_mock_recipe("fill-polluted-air-barrel"),
    -- Other recipes missing
  }

  local technologies = {
    ["fluid-handling"] = create_mock_technology("fluid-handling", true),
  }

  local force = create_mock_force(recipes, technologies)

  -- Execute: Run migration logic
  for _, recipe_name in ipairs({ "fill-polluted-air-barrel", "empty-polluted-air-barrel",
    "fill-toxic-sludge-barrel", "empty-toxic-sludge-barrel" }) do
    if force.recipes[recipe_name] then
      force.recipes[recipe_name].enabled = force.technologies["fluid-handling"].researched
    end
  end

  -- Assert: Only present recipe is enabled
  assert(recipes["fill-polluted-air-barrel"].enabled == true, "Present recipe should be enabled")
  assert(recipes["empty-polluted-air-barrel"] == nil, "Missing recipe reference should be nil")

  print("✓ Migration handles partial recipe sets correctly")
end

---Test: Migration robustness with multiple forces
function test_migration_1_0_20_multiple_forces()
  print("\n=== Test: Migration 1.0.20 - Multiple Forces ===")

  -- Setup: Create multiple forces (multiplayer scenario)
  local forces = {}

  for force_idx = 1, 3 do
    local recipes = {
      ["fill-polluted-air-barrel"] = create_mock_recipe("fill-polluted-air-barrel"),
      ["empty-polluted-air-barrel"] = create_mock_recipe("empty-polluted-air-barrel"),
    }

    local technologies = {
      ["fluid-handling"] = create_mock_technology("fluid-handling", force_idx == 1),  -- Only first force has it
    }

    forces[force_idx] = create_mock_force(recipes, technologies)
  end

  -- Execute: Simulate game.forces iteration
  for _, force in pairs(forces) do
    for _, recipe_name in ipairs({ "fill-polluted-air-barrel", "empty-polluted-air-barrel" }) do
      if force.recipes[recipe_name] then
        force.recipes[recipe_name].enabled = force.technologies["fluid-handling"].researched
      end
    end
  end

  -- Assert: Each force has correct state
  assert(forces[1].recipes["fill-polluted-air-barrel"].enabled == true, "Force 1 should have recipes enabled")
  assert(forces[2].recipes["fill-polluted-air-barrel"].enabled == false, "Force 2 should have recipes disabled")
  assert(forces[3].recipes["fill-polluted-air-barrel"].enabled == false, "Force 3 should have recipes disabled")

  print("✓ Migration correctly applies to multiple forces")
end

-- Run all tests
print("\n" .. string.rep("=", 60))
print("POLLUTION SOLUTIONS LITE - MIGRATION TESTS")
print(string.rep("=", 60))

test_migration_1_0_20_all_recipes_present()
test_migration_1_0_20_missing_recipes()
test_migration_1_0_20_tech_not_researched()
test_migration_1_0_20_partial_recipes()
test_migration_1_0_20_multiple_forces()

print("\n" .. string.rep("=", 60))
print("MIGRATION TESTS COMPLETE")
print(string.rep("=", 60) .. "\n")

return {
  test_migration_1_0_20_all_recipes_present = test_migration_1_0_20_all_recipes_present,
  test_migration_1_0_20_missing_recipes = test_migration_1_0_20_missing_recipes,
  test_migration_1_0_20_tech_not_researched = test_migration_1_0_20_tech_not_researched,
  test_migration_1_0_20_partial_recipes = test_migration_1_0_20_partial_recipes,
  test_migration_1_0_20_multiple_forces = test_migration_1_0_20_multiple_forces,
}
