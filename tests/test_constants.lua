--[[
  Unit Tests for Constants Module
  
  Tests that all constants are properly defined and have reasonable values.
]]

require("tests.test_bootstrap")

-- Mock settings for testing
if not settings then
  settings = {
    startup = {
      ["zpollution-mj-per-sludge"] = {value = 10},
      ["zpollution-incinerator-efficiency"] = {value = 0.1},
      ["zpollution-incinerator-output"] = {value = 2.0},
      ["zpollution-air-per-sludge"] = {value = 10},
      ["zpollution-sludge-per-filter"] = {value = 100},
      ["zpollution-blue-per-red"] = {value = 10},
      ["zpollution-blue-to-red-cost"] = {value = 10.0},
    }
  }
end

require("constants")

local tests = {}

function tests.test_graphics_path_defined()
  TestUtils.assertNotNil(GRAPHICS, "GRAPHICS path should be defined")
  TestUtils.assert(type(GRAPHICS) == "string", "GRAPHICS should be a string")
end

function tests.test_ticks_per_second()
  TestUtils.assertEqual(TICKS_PER_SECOND, 60, "Factorio runs at 60 ticks per second")
end

function tests.test_toxic_dump_constants()
  TestUtils.assertNotNil(TOXIC_DUMP_NAME, "Toxic dump name should be defined")
  TestUtils.assertEqual(TOXIC_DUMP_NAME, "dump-site", "Toxic dump name should match")
  TestUtils.assertEqual(TOXIC_DUMP_INTERVAL, 1800, "Toxic dump interval should be 30 seconds (1800 ticks)")
  TestUtils.assert(TOXIC_DUMP_FILLPERCENT >= 0 and TOXIC_DUMP_FILLPERCENT <= 1, "Fill percent should be 0-1")
  TestUtils.assert(TOXIC_DUMP_CONSUME_PERCENT >= 0 and TOXIC_DUMP_CONSUME_PERCENT <= 1, "Consume percent should be 0-1")
end

function tests.test_pollution_collector_constants()
  TestUtils.assertNotNil(POLLUTION_COLLECTOR_NAME, "Pollution collector name should be defined")
  TestUtils.assertEqual(POLLUTION_COLLECTOR_NAME, "pollutioncollector", "Pollution collector name should match")
end

function tests.test_fluid_constants()
  TestUtils.assertEqual(POLLUTED_AIR_NAME, "polluted-air", "Polluted air name should match")
  TestUtils.assertEqual(TOXIC_SLUDGE_NAME, "toxic-sludge", "Toxic sludge name should match")
  TestUtils.assertEqual(EMISSIONS_PER_AIR, 1, "Emissions per air should be 1")
end

function tests.test_conversion_ratios()
  TestUtils.assertEqual(AIR_PER_SLUDGE, 10, "Air per sludge should match settings")
  TestUtils.assertEqual(SLUDGE_PER_FILTER, 100, "Sludge per filter should match settings")
  TestUtils.assert(AIR_PER_SLUDGE > 0, "Air per sludge must be positive")
  TestUtils.assert(SLUDGE_PER_FILTER > 0, "Sludge per filter must be positive")
end

function tests.test_incinerator_settings()
  TestUtils.assertEqual(INCINERATOR_EFFICIENCY, 0.1, "Incinerator efficiency should match settings")
  TestUtils.assertEqual(INCINERATOR_OUTPUT, 2.0, "Incinerator output should match settings")
  TestUtils.assert(INCINERATOR_EFFICIENCY > 0 and INCINERATOR_EFFICIENCY <= 1, "Efficiency should be 0-1")
end

function tests.test_xenomass_constants()
  TestUtils.assertEqual(BLUE_XENOMASS_PER_RED_XENOMASS, 10, "Blue per red should match settings")
  TestUtils.assertEqual(POLLUTION_PER_BLUE_XENOMASS, 500, "Pollution per blue should be defined")
  TestUtils.assertEqual(SLUDGE_PER_RED_XENOMASS, 1000, "Sludge per red should be defined")
end

function tests.test_damage_type()
  TestUtils.assertEqual(POLLUTION_DAMAGE_TYPE, "toxic", "Damage type should be toxic")
end

function tests.test_cloud_size_constants()
  TestUtils.assertNotNil(TOXIC_DUMP_CLOUD_SMALL, "Small cloud name should be defined")
  TestUtils.assertNotNil(TOXIC_DUMP_CLOUD_MEDIUM, "Medium cloud name should be defined")
  TestUtils.assertNotNil(TOXIC_DUMP_CLOUD_LARGE, "Large cloud name should be defined")
  TestUtils.assert(TOXIC_DUMP_CLOUD_MEDIUM_PERCENT < TOXIC_DUMP_CLOUD_LARGE_PERCENT, 
    "Medium threshold should be less than large threshold")
end

-- Run the test suite
if TestUtils then
  TestUtils.runTestSuite("Constants Tests", tests)
end

return tests
