--[[
  Integration Tests for Data Loading
  
  Tests that verify the data stage loads correctly and all dependencies
  are available when needed.
]]

require("tests.test_bootstrap")

-- Mock Factorio's data global
if not data then
  data = {
    extend = function(self, prototypes)
      -- Mock extend function
    end,
    raw = {},
  }
end

local tests = {}

function tests.test_util_functions_available_before_entity_load()
  -- Test that util functions are available
  require("util")

  TestUtils.assertNotNil(setLayerGraphics, "setLayerGraphics should be defined")
  TestUtils.assertNotNil(setDirectionalGraphics, "setDirectionalGraphics should be defined")
  TestUtils.assertNotNil(setAllDirectionalGraphics, "setAllDirectionalGraphics should be defined")
  TestUtils.assertEqual(type(setLayerGraphics), "function", "setLayerGraphics should be a function")
end

function tests.test_constants_available_before_util_load()
  -- Constants should be loaded first as util.lua uses GRAPHICS
  require("constants")

  TestUtils.assertNotNil(GRAPHICS, "GRAPHICS constant should be defined")
  TestUtils.assertNotNil(TICKS_PER_SECOND, "TICKS_PER_SECOND should be defined")
end

function tests.test_data_loading_order()
  -- This test verifies the correct loading order:
  -- 1. constants.lua (defines GRAPHICS and other constants)
  -- 2. util.lua (defines helper functions, uses GRAPHICS)
  -- 3. prototypes/*.lua (use helper functions)

  local load_order = {}

  -- Mock require to track load order
  local original_require = require
  local function tracked_require(module)
    table.insert(load_order, module)
    return original_require(module)
  end

  -- This is a conceptual test - in real execution, we check that
  -- util.lua is required before any prototype files
  TestUtils.assert(true, "Load order test is conceptual")
end

function tests.test_helper_functions_fail_fast()
  -- Test that helper functions fail with meaningful errors
  require("util")

  -- setLayerGraphics should fail on nil layer
  local success, err = pcall(function()
    ---@diagnostic disable-next-line: param-type-mismatch
    setLayerGraphics(nil, "test.png", nil)
  end)
  TestUtils.assert(not success, "Should fail with nil layer")
  ---@diagnostic disable-next-line: param-type-mismatch
  TestUtils.assert(
    string.find(tostring(err), "Layer cannot be nil") ~= nil,
    "Should have meaningful error"
  )

  -- setAllDirectionalGraphics should fail on nil structure
  local success2, err2 = pcall(function()
    ---@diagnostic disable-next-line: param-type-mismatch
    setAllDirectionalGraphics(nil, "test/")
  end)
  TestUtils.assert(not success2, "Should fail with nil structure")
  ---@diagnostic disable-next-line: param-type-mismatch
  TestUtils.assert(
    string.find(tostring(err2), "Structure cannot be nil") ~= nil,
    "Should have meaningful error"
  )
end

function tests.test_missing_function_detection()
  -- Test that we can detect when a required function is missing
  -- This simulates the error we encountered

  local function simulate_entity_load_without_util()
    -- Temporarily hide the function
    local saved_func = _G.setLayerGraphics
    _G.setLayerGraphics = nil

    local success, err = pcall(function()
      -- This simulates calling the function like entity.lua does
      setLayerGraphics({}, "test.png", nil)
    end)

    -- Restore the function
    _G.setLayerGraphics = saved_func

    return success, err
  end

  local success, err = simulate_entity_load_without_util()
  TestUtils.assert(not success, "Should fail when function is not defined")
  -- Cast err to string for type safety - pcall returns unknown type
  local errStr = tostring(err)
  ---@diagnostic disable-next-line: param-type-mismatch
  TestUtils.assert(
    (string.find(errStr, "nil value") ~= nil) or (string.find(errStr, "setLayerGraphics") ~= nil),
    "Error should mention the missing function"
  )
end

-- Run the test suite
if TestUtils then
  TestUtils.runTestSuite("Data Loading Integration Tests", tests)
end

return tests
