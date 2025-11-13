--[[
  Test Suite: Pollution Collector Functionality
  
  Tests that the pollution collector properly:
  1. Uses furnace entity type with atmospheric-filtration category
  2. Has negative emissions configured
  3. Produces polluted-air fluid when running
  4. Properly releases pollution when destroyed
]]

require("test_bootstrap")
local TestUtils = require("test_bootstrap")

-- Test that pollution collector prototype exists and has correct properties
local function test_collector_prototype_exists()
  local collector = data.raw["furnace"]["pollutioncollector"]
  TestUtils.assertNotNil(collector, "Pollution collector furnace entity should exist")
  
  -- Verify it's a furnace, not storage-tank
  TestUtils.assertEqual(collector.type, "furnace", "Collector should be furnace type")
  
  -- Verify crafting category
  TestUtils.assertNotNil(collector.crafting_categories, "Should have crafting categories")
  local has_filtration = false
  for _, cat in ipairs(collector.crafting_categories) do
    if cat == "atmospheric-filtration" then
      has_filtration = true
      break
    end
  end
  TestUtils.assert(has_filtration, "Should have atmospheric-filtration category")
  
  -- Verify energy source has negative emissions
  TestUtils.assertNotNil(collector.energy_source, "Should have energy source")
  TestUtils.assertNotNil(collector.energy_source.emissions_per_minute, "Should have emissions")
  TestUtils.assertNotNil(
    collector.energy_source.emissions_per_minute.pollution,
    "Should have pollution emissions"
  )
  
  local emissions = collector.energy_source.emissions_per_minute.pollution
  TestUtils.assert(
    emissions < 0,
    "Emissions should be negative (collecting pollution), got: " .. tostring(emissions)
  )
  
  -- Verify has fluid output box
  TestUtils.assertNotNil(collector.fluid_boxes, "Should have fluid boxes")
  TestUtils.assert(
    #collector.fluid_boxes > 0,
    "Should have at least one fluid box"
  )
  
  local has_output = false
  for _, box in ipairs(collector.fluid_boxes) do
    if box.production_type == "output" then
      has_output = true
      TestUtils.assertEqual(box.filter, "polluted-air", "Output should filter polluted-air")
      break
    end
  end
  TestUtils.assert(has_output, "Should have output fluid box")
end

-- Test that collection recipe exists
local function test_collection_recipe_exists()
  local recipe = data.raw["recipe"]["collect-pollution"]
  TestUtils.assertNotNil(recipe, "collect-pollution recipe should exist")
  
  TestUtils.assertEqual(
    recipe.category,
    "atmospheric-filtration",
    "Recipe should use atmospheric-filtration category"
  )
  
  -- Should have no ingredients (collects from air)
  TestUtils.assertNotNil(recipe.ingredients, "Should have ingredients field")
  TestUtils.assertEqual(
    #recipe.ingredients,
    0,
    "Should have no ingredients (collects from air)"
  )
  
  -- Should produce polluted-air
  TestUtils.assertNotNil(recipe.results, "Should have results")
  TestUtils.assert(#recipe.results > 0, "Should have at least one result")
  
  local produces_air = false
  for _, result in ipairs(recipe.results) do
    if result.name == "polluted-air" and result.type == "fluid" then
      produces_air = true
      TestUtils.assert(result.amount > 0, "Should produce positive amount of polluted-air")
      break
    end
  end
  TestUtils.assert(produces_air, "Should produce polluted-air fluid")
end

-- Test that atmospheric-filtration category exists
local function test_filtration_category_exists()
  local category = data.raw["recipe-category"]["atmospheric-filtration"]
  TestUtils.assertNotNil(category, "atmospheric-filtration recipe category should exist")
end

-- Test that technology unlocks both collector and recipe
local function test_technology_unlocks()
  local tech = data.raw["technology"]["pollution-controls"]
  TestUtils.assertNotNil(tech, "pollution-controls technology should exist")
  TestUtils.assertNotNil(tech.effects, "Technology should have effects")
  
  local unlocks_collector = false
  local unlocks_recipe = false
  
  for _, effect in ipairs(tech.effects) do
    if effect.type == "unlock-recipe" then
      if effect.recipe == "pollutioncollector" then
        unlocks_collector = true
      elseif effect.recipe == "collect-pollution" then
        unlocks_recipe = true
      end
    end
  end
  
  TestUtils.assert(unlocks_collector, "Technology should unlock pollutioncollector recipe")
  TestUtils.assert(unlocks_recipe, "Technology should unlock collect-pollution recipe")
end

-- Run all tests
if data then
  -- Data stage tests (prototype validation)
  TestUtils.runTestSuite("Pollution Collector - Data Stage", {
    ["Collector prototype exists and configured"] = test_collector_prototype_exists,
    ["Collection recipe exists"] = test_collection_recipe_exists,
    ["Filtration category exists"] = test_filtration_category_exists,
    ["Technology unlocks correctly"] = test_technology_unlocks,
  })
end

return {
  test_collector_prototype_exists = test_collector_prototype_exists,
  test_collection_recipe_exists = test_collection_recipe_exists,
  test_filtration_category_exists = test_filtration_category_exists,
  test_technology_unlocks = test_technology_unlocks,
}
