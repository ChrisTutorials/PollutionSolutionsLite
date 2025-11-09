-- Test: Factorio 2.0 spill_item_stack API Compatibility
-- Tests the xenomass drop on alien death functionality

local function test_spill_item_stack_factorio_2()
  print("\n=== Factorio 2.0 spill_item_stack API Test ===\n")
  
  -- Test 1: Verify API signature
  print("Test 1: Checking spill_item_stack signature...")
  local test_results = {}
  
  if not game or not game.surfaces then
    print("✗ FAIL: Game surfaces not available")
    table.insert(test_results, false)
  else
    print("✓ PASS: Game surfaces available")
    table.insert(test_results, true)
  end
  
  -- Test 2: Verify function exists
  print("\nTest 2: Checking spill_item_stack exists...")
  local surface = game.surfaces[1]
  if not surface or not surface.spill_item_stack then
    print("✗ FAIL: spill_item_stack not found on surface")
    table.insert(test_results, false)
  else
    print("✓ PASS: spill_item_stack exists")
    table.insert(test_results, true)
  end
  
  -- Test 3: Correct Factorio 2.0 signature
  print("\nTest 3: Testing Factorio 2.0 table signature...")
  local success, err = pcall(function()
    -- CORRECT Factorio 2.0 signature: single table argument
    surface.spill_item_stack({
      position = {x = 0, y = 0},
      items = {{name = "iron-ore", count = 1}}
    })
  end)
  
  if success then
    print("✓ PASS: Factorio 2.0 API signature works")
    table.insert(test_results, true)
  else
    print("✗ FAIL: " .. tostring(err))
    table.insert(test_results, false)
  end
  
  -- Test 4: Xenomass specific test
  print("\nTest 4: Testing xenomass drop...")
  local xenomass_success, xenomass_err = pcall(function()
    surface.spill_item_stack({
      position = {x = 5, y = 5},
      items = {{name = "red-xenomass", count = 5}}
    })
  end)
  
  if xenomass_success then
    print("✓ PASS: Xenomass drop works")
    table.insert(test_results, true)
  else
    print("✗ FAIL: " .. tostring(xenomass_err))
    table.insert(test_results, false)
  end
  
  -- Summary
  print("\n=== Test Summary ===")
  local passed = 0
  for _, result in ipairs(test_results) do
    if result then passed = passed + 1 end
  end
  
  local total = #test_results
  print("Passed: " .. passed .. "/" .. total)
  
  if passed == total then
    print("\n✓ All tests PASSED - Factorio 2.0 API compatible!")
    return true
  else
    print("\n✗ Some tests FAILED - API incompatibility detected!")
    return false
  end
end

-- Run the test
return test_spill_item_stack_factorio_2()
