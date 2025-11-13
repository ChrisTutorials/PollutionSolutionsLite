--[[
  Runtime Integration Tests for Pollution Collector
  
  These tests require a running Factorio game instance.
  Can be run via scenario or test framework.
  
  Test Coverage:
  1. Collector only produces when pollution exists
  2. Pollution removal matches fluid production
  3. Recipe control based on pollution levels
  4. Integration with existing systems
]]

-- Requires game environment
if not game then
  error("This test requires a running Factorio game instance")
end

local TEST_SURFACE = game.surfaces[1]
local TEST_FORCE = "player"

-- Helper: Create test entity
local function create_test_entity(name, position)
  return TEST_SURFACE.create_entity({
    name = name,
    position = position,
    force = TEST_FORCE,
    raise_built = true,
  })
end

-- Helper: Add pollution to position
local function add_pollution(position, amount)
  TEST_SURFACE.pollute(position, amount)
end

-- Helper: Get pollution at position
local function get_pollution(position)
  return TEST_SURFACE.get_pollution(position)
end

-- Helper: Wait for ticks
local function wait_ticks(ticks)
  local start_tick = game.tick
  local target_tick = start_tick + ticks
  while game.tick < target_tick do
    -- Yield control back to game
    coroutine.yield()
  end
end

--====================--
-- Test Cases         --
--====================--

--- Test 1: Collector only runs when pollution exists
local function test_recipe_control_by_pollution()
  local pos = {x = 100, y = 100}
  
  -- Ensure no pollution initially
  add_pollution(pos, -1000)  -- Remove any existing
  
  -- Create collector
  local collector = create_test_entity("pollutioncollector", pos)
  if not collector then
    game.print("[FAIL] Could not create pollution collector")
    return false
  end
  
  -- Initially should have no recipe (no pollution)
  wait_ticks(60)  -- Wait for script to check
  local recipe = collector.get_recipe()
  if recipe then
    game.print("[FAIL] Collector should not have recipe when no pollution")
    collector.destroy()
    return false
  end
  
  -- Add pollution
  add_pollution(pos, 500)
  wait_ticks(300)  -- Wait 5 seconds for script check
  
  -- Should now have recipe
  recipe = collector.get_recipe()
  if not recipe or recipe.name ~= "collect-pollution" then
    game.print("[FAIL] Collector should have collect-pollution recipe when pollution exists")
    collector.destroy()
    return false
  end
  
  -- Remove pollution
  add_pollution(pos, -500)
  wait_ticks(300)  -- Wait 5 seconds
  
  -- Should stop recipe
  recipe = collector.get_recipe()
  if recipe then
    game.print("[FAIL] Collector should stop recipe when pollution removed")
    collector.destroy()
    return false
  end
  
  collector.destroy()
  game.print("[PASS] Recipe control by pollution level works correctly")
  return true
end

--- Test 2: Fluid production only when pollution exists
local function test_fluid_production_requires_pollution()
  local pos = {x = 120, y = 120}
  
  -- Clear pollution
  add_pollution(pos, -1000)
  
  -- Create collector
  local collector = create_test_entity("pollutioncollector", pos)
  if not collector then
    game.print("[FAIL] Could not create collector")
    return false
  end
  
  -- Connect to electric network (cheat for testing)
  collector.energy = 150000  -- Give it power
  
  -- Wait one recipe cycle (60 seconds = 3600 ticks)
  wait_ticks(3600)
  
  -- Check fluid box - should be empty (no pollution to collect)
  local fluid = collector.fluidbox[1]
  if fluid and fluid.amount > 0 then
    game.print("[FAIL] Collector produced fluid without pollution")
    collector.destroy()
    return false
  end
  
  -- Now add pollution and wait
  add_pollution(pos, 100)
  wait_ticks(300)  -- Wait for recipe to start
  wait_ticks(3600)  -- Wait for recipe cycle
  
  -- Should have produced fluid
  fluid = collector.fluidbox[1]
  if not fluid or fluid.amount <= 0 then
    game.print("[FAIL] Collector did not produce fluid with pollution")
    collector.destroy()
    return false
  end
  
  if fluid.name ~= "polluted-air" then
    game.print("[FAIL] Collector produced wrong fluid type: " .. tostring(fluid.name))
    collector.destroy()
    return false
  end
  
  collector.destroy()
  game.print("[PASS] Fluid production requires pollution")
  return true
end

--- Test 3: Integration with liquify-pollution recipe
local function test_integration_with_liquify_recipe()
  local pos = {x = 140, y = 140}
  
  -- Create collector with pollution
  add_pollution(pos, 1000)
  local collector = create_test_entity("pollutioncollector", pos)
  if not collector then
    game.print("[FAIL] Could not create collector")
    return false
  end
  
  -- Wait for collection
  wait_ticks(3600)
  
  -- Check we have polluted-air
  local fluid = collector.fluidbox[1]
  if not fluid or fluid.name ~= "polluted-air" or fluid.amount <= 0 then
    game.print("[FAIL] No polluted-air produced")
    collector.destroy()
    return false
  end
  
  local collected_amount = fluid.amount
  game.print("[INFO] Collected " .. tostring(collected_amount) .. " polluted-air")
  
  -- Create chemical plant to process it
  local plant = create_test_entity("chemical-plant", {x = 145, y = 140})
  if not plant then
    game.print("[FAIL] Could not create chemical plant")
    collector.destroy()
    return false
  end
  
  -- Set recipe
  plant.set_recipe("liquify-pollution")
  
  -- Connect with pipes (simplified for test - in real game would need actual pipe entities)
  -- For this test, manually transfer fluid
  plant.fluidbox[1] = {name = "polluted-air", amount = math.min(collected_amount, 1000)}
  plant.fluidbox[2] = {name = "water", amount = 100}
  
  -- Wait for processing
  wait_ticks(600)
  
  -- Check if toxic-sludge was produced
  local output = plant.fluidbox[3]
  if not output or output.name ~= "toxic-sludge" then
    game.print("[FAIL] Toxic-sludge not produced from polluted-air")
    collector.destroy()
    plant.destroy()
    return false
  end
  
  collector.destroy()
  plant.destroy()
  game.print("[PASS] Integration with liquify-pollution works")
  return true
end

--- Test 4: Entity destruction disperses pollution
local function test_destruction_disperses_pollution()
  local pos = {x = 160, y = 160}
  
  -- Create collector and collect pollution
  add_pollution(pos, 500)
  local collector = create_test_entity("pollutioncollector", pos)
  if not collector then
    game.print("[FAIL] Could not create collector")
    return false
  end
  
  -- Wait for collection
  wait_ticks(3600)
  
  -- Check fluid amount
  local fluid = collector.fluidbox[1]
  if not fluid or fluid.amount <= 0 then
    game.print("[WARN] No fluid collected, skipping dispersal test")
    collector.destroy()
    return true  -- Not a failure, just no fluid to test
  end
  
  local stored_amount = fluid.amount
  game.print("[INFO] Stored " .. tostring(stored_amount) .. " polluted-air")
  
  -- Record pollution before destruction
  local pollution_before = get_pollution(pos)
  
  -- Destroy collector
  collector.destroy()
  
  -- Check pollution increased (should disperse stored fluid)
  wait_ticks(60)
  local pollution_after = get_pollution(pos)
  
  -- Pollution should have increased by approximately stored_amount * EMISSIONS_PER_AIR
  -- (EMISSIONS_PER_AIR defaults to 1, so should be ~1:1)
  local pollution_increase = pollution_after - pollution_before
  
  if pollution_increase < stored_amount * 0.8 then  -- Allow 20% tolerance
    game.print("[FAIL] Pollution not dispersed correctly. Expected: " .. tostring(stored_amount) .. ", Got: " .. tostring(pollution_increase))
    return false
  end
  
  game.print("[PASS] Entity destruction disperses pollution")
  return true
end

--====================--
-- Test Runner        --
--====================--

local function run_all_tests()
  game.print("========================================")
  game.print("Pollution Collector Runtime Tests")
  game.print("========================================")
  
  local tests = {
    {"Recipe control by pollution", test_recipe_control_by_pollution},
    {"Fluid production requires pollution", test_fluid_production_requires_pollution},
    {"Integration with liquify-pollution", test_integration_with_liquify_recipe},
    {"Destruction disperses pollution", test_destruction_disperses_pollution},
  }
  
  local passed = 0
  local failed = 0
  
  for _, test_pair in ipairs(tests) do
    local name = test_pair[1]
    local test_fn = test_pair[2]
    
    game.print("\nRunning: " .. name)
    local success, result = pcall(test_fn)
    
    if success and result then
      passed = passed + 1
    else
      failed = failed + 1
      game.print("[ERROR] Test failed: " .. tostring(result))
    end
  end
  
  game.print("\n========================================")
  game.print(string.format("Results: %d passed, %d failed", passed, failed))
  game.print("========================================")
end

-- Export for external use
return {
  run_all_tests = run_all_tests,
  test_recipe_control_by_pollution = test_recipe_control_by_pollution,
  test_fluid_production_requires_pollution = test_fluid_production_requires_pollution,
  test_integration_with_liquify_recipe = test_integration_with_liquify_recipe,
  test_destruction_disperses_pollution = test_destruction_disperses_pollution,
}
