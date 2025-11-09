--[[
  Unit Tests for Utility Functions
  
  Tests the helper functions used for prototype creation.
]]

require("tests.test_bootstrap")

-- Mock data.raw for testing
data = {
  raw = {
    ["item"] = {
      ["iron-plate"] = {
        name = "iron-plate",
        type = "item",
        stack_size = 100,
        icons = {
          { icon = "__base__/graphics/icons/iron-plate.png" },
        },
      },
    },
    ["assembling-machine"] = {
      ["assembling-machine-1"] = {
        name = "assembling-machine-1",
        type = "assembling-machine",
        crafting_speed = 0.5,
        minable = {
          result = "assembling-machine-1",
        },
      },
    },
  },
}

-- Mock util.table.deepcopy
util = {
  table = {
    deepcopy = function(tbl)
      if type(tbl) ~= "table" then
        return tbl
      end
      local result = {}
      for k, v in pairs(tbl) do
        result[k] = util.table.deepcopy(v)
      end
      return result
    end,
  },
}

require("util")

local tests = {}

function tests.test_copyData_simple()
  local copy = copyData("item", "iron-plate")
  TestUtils.assertNotNil(copy, "Copy should not be nil")
  TestUtils.assertEqual(copy.name, "iron-plate", "Name should be copied")
  TestUtils.assertEqual(copy.stack_size, 100, "Stack size should be copied")
end

function tests.test_copyData_single_field()
  local stackSize = copyData("item", "iron-plate", "stack_size")
  TestUtils.assertEqual(stackSize, 100, "Should copy single field")
end

function tests.test_copyData_nested_field()
  local icons = copyData("item", "iron-plate", { "icons" })
  TestUtils.assertNotNil(icons, "Icons should be copied")
  TestUtils.assertEqual(type(icons), "table", "Icons should be a table")
end

function tests.test_makeNewDataFromData()
  local newItem = makeNewDataFromData("item", "iron-plate", "copper-plate")
  TestUtils.assertEqual(newItem.name, "copper-plate", "Name should be changed")
  TestUtils.assertEqual(newItem.stack_size, 100, "Other fields should be copied")
  -- Verify original is unchanged
  TestUtils.assertEqual(
    data.raw["item"]["iron-plate"].name,
    "iron-plate",
    "Original should not change"
  )
end

function tests.test_makeNewEntityFromData()
  local newEntity =
    makeNewEntityFromData("assembling-machine", "assembling-machine-1", "my-machine", "z")
  TestUtils.assertEqual(newEntity.name, "my-machine", "Name should be changed")
  TestUtils.assertEqual(newEntity.order, "z", "Order should be set")
  TestUtils.assertEqual(newEntity.minable.result, "my-machine", "Mining result should match name")
  TestUtils.assertEqual(newEntity.crafting_speed, 0.5, "Other fields should be copied")
end

function tests.test_makeNewEntityFromData_default_order()
  local newEntity =
    makeNewEntityFromData("assembling-machine", "assembling-machine-1", "my-machine")
  TestUtils.assertEqual(newEntity.order, "z", "Order should default to 'z'")
end

function tests.test_makeNewItemFromData()
  local newItem = makeNewItemFromData("iron-plate", "my-item")
  TestUtils.assertEqual(newItem.name, "my-item", "Name should be changed")
  TestUtils.assertEqual(newItem.place_result, "my-item", "place_result should match name")
  TestUtils.assertEqual(newItem.stack_size, 100, "Other fields should be copied")
end

function tests.test_Set()
  local list = { "apple", "banana", "cherry" }
  local set = Set(list)

  TestUtils.assertEqual(set["apple"], true, "apple should be in set")
  TestUtils.assertEqual(set["banana"], true, "banana should be in set")
  TestUtils.assertEqual(set["cherry"], true, "cherry should be in set")
  TestUtils.assertEqual(set["orange"], nil, "orange should not be in set")
end

function tests.test_Set_empty()
  local set = Set({})
  TestUtils.assertEqual(type(set), "table", "Set should be a table")
  TestUtils.assertEqual(next(set), nil, "Empty set should have no entries")
end

-- Run the test suite
if TestUtils then
  TestUtils.runTestSuite("Utility Function Tests", tests)
end

return tests
