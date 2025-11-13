--[[
  Test Suite: Pollution Collector Functionality
  
  Tests that the pollution collector properly:
  1. Uses furnace entity type with atmospheric-filtration category
  2. Has negative emissions configured
  3. Produces polluted-air fluid ONLY when pollution exists in the chunk
  4. Stops producing when no pollution exists
  5. Properly releases pollution when destroyed
  6. Integrates with existing recipe chain (polluted-air → toxic-sludge)
  7. Maintains compatibility with pipe systems
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

-- Test compatibility with existing recipe chain
local function test_recipe_chain_compatibility()
  local collect_recipe = data.raw["recipe"]["collect-pollution"]
  local liquify_recipe = data.raw["recipe"]["liquify-pollution"]
  
  TestUtils.assertNotNil(collect_recipe, "collect-pollution recipe should exist")
  TestUtils.assertNotNil(liquify_recipe, "liquify-pollution recipe should exist")
  
  -- Verify collect-pollution produces polluted-air
  local produces_air = false
  for _, result in ipairs(collect_recipe.results) do
    if result.name == "polluted-air" and result.type == "fluid" then
      produces_air = true
      break
    end
  end
  TestUtils.assert(produces_air, "collect-pollution must produce polluted-air")
  
  -- Verify liquify-pollution consumes polluted-air
  local consumes_air = false
  for _, ingredient in ipairs(liquify_recipe.ingredients) do
    if ingredient.name == "polluted-air" and ingredient.type == "fluid" then
      consumes_air = true
      break
    end
  end
  TestUtils.assert(consumes_air, "liquify-pollution must consume polluted-air")
  
  -- Verify no changes to liquify-pollution recipe (requirements mandate no changes)
  TestUtils.assertEqual(liquify_recipe.category, "chemistry", "liquify recipe category unchanged")
  
  -- Verify polluted-air fluid exists
  local polluted_air = data.raw["fluid"]["polluted-air"]
  TestUtils.assertNotNil(polluted_air, "polluted-air fluid must exist")
end

-- Test that fluid output is configured correctly
local function test_fluid_output_configuration()
  local collector = data.raw["furnace"]["pollutioncollector"]
  TestUtils.assertNotNil(collector, "Collector must exist")
  TestUtils.assertNotNil(collector.fluid_boxes, "Must have fluid boxes")
  
  -- Check for output fluid box
  local has_output = false
  local output_filter = nil
  for _, box in ipairs(collector.fluid_boxes) do
    if box.production_type == "output" then
      has_output = true
      output_filter = box.filter
      -- Verify pipe connections exist
      TestUtils.assertNotNil(box.pipe_connections, "Output must have pipe connections")
      TestUtils.assert(#box.pipe_connections > 0, "Must have at least one pipe connection")
      break
    end
  end
  
  TestUtils.assert(has_output, "Must have output fluid box for pipe system")
  TestUtils.assertEqual(output_filter, "polluted-air", "Output must be filtered to polluted-air")
end

-- Runtime behavior tests (require game context)
-- These tests document expected behavior but cannot run in data stage
local runtime_test_notes = [[
RUNTIME BEHAVIOR TESTS (require game environment):

1. Test: Collector only runs recipe when pollution exists
   - Place collector in chunk with pollution > 0
   - Verify recipe is active
   - Remove all pollution from chunk
   - Verify recipe stops (entity.get_recipe() returns nil)
   - Re-add pollution
   - Verify recipe resumes

2. Test: Pollution is removed from chunk
   - Place collector in polluted chunk
   - Power the collector
   - Wait for recipe cycle (60 seconds)
   - Verify pollution decreased in chunk
   - Verify polluted-air fluid increased in output

3. Test: Production amount matches pollution removed
   - Record initial pollution level
   - Run one recipe cycle
   - Verify: pollution_removed * EMISSIONS_PER_AIR = fluid_produced
   - Note: Negative emissions (-40/min) should match fluid production

4. Test: Stops when tank/pipe is full
   - Fill output pipe system to capacity
   - Verify collector stops running recipe
   - Drain some fluid
   - Verify collector resumes

5. Test: Entity destruction disperses pollution
   - Run collector until it has fluid in output
   - Destroy the entity
   - Verify pollution was released back to atmosphere
   - Verify amount released matches stored fluid

6. Test: Integration with liquify-pollution recipe
   - Collect polluted-air with collector
   - Pipe to chemical plant
   - Run liquify-pollution recipe
   - Verify toxic-sludge is produced
   - Verify no recipe changes occurred

7. Test: Multiple collectors in same chunk
   - Place 2 collectors in same polluted chunk
   - Verify both collect pollution
   - Verify pollution removal rate scales correctly

8. Test: Collector behavior with no power
   - Place collector in polluted chunk
   - Disconnect power
   - Verify no pollution is removed
   - Verify no fluid is produced
   - Reconnect power
   - Verify operation resumes
]]

-- Run all tests
if data then
  -- Data stage tests (prototype validation)
  TestUtils.runTestSuite("Pollution Collector - Data Stage", {
    ["Collector prototype exists and configured"] = test_collector_prototype_exists,
    ["Collection recipe exists"] = test_collection_recipe_exists,
    ["Filtration category exists"] = test_filtration_category_exists,
    ["Technology unlocks correctly"] = test_technology_unlocks,
    ["Recipe chain compatibility"] = test_recipe_chain_compatibility,
    ["Fluid output configuration"] = test_fluid_output_configuration,
  })
  
  -- Print runtime test notes
  print("\n" .. runtime_test_notes)
end

return {
  test_collector_prototype_exists = test_collector_prototype_exists,
  test_collection_recipe_exists = test_collection_recipe_exists,
  test_filtration_category_exists = test_filtration_category_exists,
  test_technology_unlocks = test_technology_unlocks,
  test_recipe_chain_compatibility = test_recipe_chain_compatibility,
  test_fluid_output_configuration = test_fluid_output_configuration,
}
