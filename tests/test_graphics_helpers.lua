--[[
  Unit Tests for Graphics Helper Functions
  
  Tests the new helper functions for setting entity graphics and layers.
]]

require("tests.test_bootstrap")

-- Mock util.table.deepcopy if needed
if not util then
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
end

-- Mock GRAPHICS constant
GRAPHICS = "__PollutionSolutionsLite__/graphics/"

require("util")

local tests = {}

function tests.test_setLayerGraphics_basic()
  local layer = {}
  setLayerGraphics(layer, "test.png", nil)
  TestUtils.assertEqual(layer.filename, "test.png", "Should set filename")
end

function tests.test_setLayerGraphics_with_hr_version()
  local layer = {
    hr_version = {},
  }
  setLayerGraphics(layer, "test.png", "hr-test.png")
  TestUtils.assertEqual(layer.filename, "test.png", "Should set filename")
  TestUtils.assertEqual(layer.hr_version.filename, "hr-test.png", "Should set HR filename")
end

function tests.test_setLayerGraphics_no_hr_version_field()
  local layer = {}
  setLayerGraphics(layer, "test.png", "hr-test.png")
  TestUtils.assertEqual(layer.filename, "test.png", "Should set filename")
  TestUtils.assertEqual(layer.hr_version, nil, "Should not create hr_version if it doesn't exist")
end

function tests.test_setLayerGraphics_nil_layer_fails()
  local success, err = pcall(function()
    setLayerGraphics(nil, "test.png", "hr-test.png")
  end)
  TestUtils.assert(not success, "Should fail when layer is nil")
  TestUtils.assert(string.find(err, "Layer cannot be nil"), "Should have meaningful error message")
end

function tests.test_setDirectionalGraphics_north()
  local structure = {
    north = {
      layers = {
        [1] = {},
      },
    },
  }
  setDirectionalGraphics(structure, "north", "test-N.png", "hr-test-N.png")
  TestUtils.assertEqual(
    structure.north.layers[1].filename,
    "test-N.png",
    "Should set north filename"
  )
end

function tests.test_setDirectionalGraphics_missing_direction_fails()
  local structure = {}
  local success, err = pcall(function()
    setDirectionalGraphics(structure, "north", "test.png", nil)
  end)
  TestUtils.assert(not success, "Should fail when direction doesn't exist")
  TestUtils.assert(
    string.find(err, "Structure.north.layers not found"),
    "Should have meaningful error message"
  )
end

function tests.test_setAllDirectionalGraphics()
  local structure = {
    north = { layers = { [1] = {} } },
    east = { layers = { [1] = {} } },
    south = { layers = { [1] = {} } },
    west = { layers = { [1] = {} } },
  }

  setAllDirectionalGraphics(structure, "entity/test/")

  TestUtils.assertEqual(
    structure.north.layers[1].filename,
    GRAPHICS .. "entity/test/lowheatex-N-idle.png",
    "Should set north filename"
  )
  TestUtils.assertEqual(
    structure.east.layers[1].filename,
    GRAPHICS .. "entity/test/lowheatex-E-idle.png",
    "Should set east filename"
  )
  TestUtils.assertEqual(
    structure.south.layers[1].filename,
    GRAPHICS .. "entity/test/lowheatex-S-idle.png",
    "Should set south filename"
  )
  TestUtils.assertEqual(
    structure.west.layers[1].filename,
    GRAPHICS .. "entity/test/lowheatex-W-idle.png",
    "Should set west filename"
  )
end

function tests.test_setAllDirectionalGraphics_with_hr_versions()
  local structure = {
    north = { layers = { [1] = { hr_version = {} } } },
    east = { layers = { [1] = { hr_version = {} } } },
    south = { layers = { [1] = { hr_version = {} } } },
    west = { layers = { [1] = { hr_version = {} } } },
  }

  setAllDirectionalGraphics(structure, "entity/test/")

  TestUtils.assertNotNil(
    structure.north.layers[1].hr_version.filename,
    "Should set north HR filename"
  )
  TestUtils.assertNotNil(
    structure.east.layers[1].hr_version.filename,
    "Should set east HR filename"
  )
  TestUtils.assertNotNil(
    structure.south.layers[1].hr_version.filename,
    "Should set south HR filename"
  )
  TestUtils.assertNotNil(
    structure.west.layers[1].hr_version.filename,
    "Should set west HR filename"
  )
end

function tests.test_setAllDirectionalGraphics_missing_direction_fails()
  local structure = {
    north = { layers = { [1] = {} } },
    east = { layers = { [1] = {} } },
    south = { layers = { [1] = {} } },
    -- west is missing
  }

  local success, err = pcall(function()
    setAllDirectionalGraphics(structure, "entity/test/")
  end)
  TestUtils.assert(not success, "Should fail when a direction is missing")
  TestUtils.assert(
    string.find(err, "Structure.west.layers not found"),
    "Should indicate which direction is missing"
  )
end

function tests.test_setAllDirectionalGraphics_nil_structure_fails()
  local success, err = pcall(function()
    setAllDirectionalGraphics(nil, "entity/test/")
  end)
  TestUtils.assert(not success, "Should fail when structure is nil")
  TestUtils.assert(
    string.find(err, "Structure cannot be nil"),
    "Should have meaningful error message"
  )
end

-- Run the test suite
if TestUtils then
  TestUtils.runTestSuite("Graphics Helper Tests", tests)
end

return tests
