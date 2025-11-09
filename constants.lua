--[[
  Constants Module for Pollution Solutions Lite
  
  This file defines all the global constants used throughout the mod.
  Constants are organized into sections for easier maintenance and understanding.
  
  Sections:
  - Graphics paths
  - Control/Runtime constants
  - Toxic Dump configuration
  - Pollution Collector configuration
  - Fluid constants
  - Incinerator configuration
  - Recipe constants
  - Xenomass (alien loot) constants
]]

-- Graphics path for mod assets
GRAPHICS = "__PollutionSolutionsLite__/graphics/"

--=========--
-- Control --
--=========--
-- Number of game ticks per second (Factorio runs at 60 ticks/second)
TICKS_PER_SECOND = 60

--====================--
-- Toxic Dump Config  --
--====================--
-- Entity name identifier for toxic dump sites
TOXIC_DUMP_NAME = "dump-site"

-- How often toxic dumps process their contents (every 30 seconds)
TOXIC_DUMP_INTERVAL = 30 * TICKS_PER_SECOND

-- Minimum fill percentage before the dump releases pollution (0.0 = always release)
TOXIC_DUMP_FILLPERCENT = 0.0

-- Maximum percentage of stored toxic sludge that can be released in one cycle
TOXIC_DUMP_MAX_RELEASED = 1.0

-- Amount of toxic sludge to remove per second when at 100% capacity
TOXIC_DUMP_SLUDGE_PER_SEC = 5

-- Maximum amount of fluid to convert into chunk pollution
TOXIC_DUMP_POLLUTION_RELEASED = 100

-- Number of toxic clouds to create when gas is released
TOXIC_DUMP_CLOUDS = 1

-- Visual effect: minimum number of smoke clouds per release
TOXIC_DUMP_SMOKE_MIN = 1

-- Visual effect: maximum number of smoke clouds per release
TOXIC_DUMP_SMOKE_MAX = 3

-- Names of toxic cloud entities by size
TOXIC_DUMP_CLOUD_SMALL = "toxic-cloud-small"
TOXIC_DUMP_CLOUD_MEDIUM = "toxic-cloud-medium"
TOXIC_DUMP_CLOUD_LARGE = "toxic-cloud-large"

-- Fill percentage thresholds for different cloud sizes
TOXIC_DUMP_CLOUD_MEDIUM_PERCENT = 0.05 -- Above 5% overflow uses medium clouds
TOXIC_DUMP_CLOUD_LARGE_PERCENT = 0.20 -- Above 20% overflow uses large clouds

-- Percentage of pollution destroyed when dumping (remainder is released)
-- Divided by toxic sludge ratio for concentrated pollution
TOXIC_DUMP_CONSUME_PERCENT = 0.5

--============================--
-- Pollution Collector Config --
--============================--
-- Entity name identifier for pollution collector buildings
POLLUTION_COLLECTOR_NAME = "pollutioncollector"

--==================--
-- Fluid Constants  --
--==================--
-- Name of the polluted air fluid
POLLUTED_AIR_NAME = "polluted-air"

-- Conversion rate: air pollution per unit of polluted-air fluid
EMISSIONS_PER_AIR = 1

-- Name of the toxic sludge fluid
TOXIC_SLUDGE_NAME = "toxic-sludge"

-- Energy value per unit of toxic sludge (from startup settings)
MJ_PER_TOXIC_SLUDGE = settings.startup["zpollution-mj-per-sludge"].value

-- Custom damage type for pollution-based attacks
POLLUTION_DAMAGE_TYPE = "toxic"

--=======================--
-- Incinerator Settings  --
--=======================--
-- Efficiency: how much toxic sludge is completely burned (rest becomes pollution)
-- Values from 0.01 to 1.0, default 0.1 (10% burned, 90% becomes pollution)
INCINERATOR_EFFICIENCY = settings.startup["zpollution-incinerator-efficiency"].value

-- Power output of the incinerator in megawatts (MW)
INCINERATOR_OUTPUT = settings.startup["zpollution-incinerator-output"].value

--======================--
-- Conversion Ratios    --
--======================--
-- How much polluted-air is created per unit of toxic sludge
AIR_PER_SLUDGE = settings.startup["zpollution-air-per-sludge"].value

-- Amount of toxic sludge produced per air filter
SLUDGE_PER_FILTER = settings.startup["zpollution-sludge-per-filter"].value

--==================--
-- Recipe Constants --
--==================--
-- Number of air filters needed per liquification recipe
FILTER_PER_LIQUIFY = 1

-- Water consumption as percentage of filter amount
WATER_PER_FILTER_PERCENT = 1

--===========================--
-- Xenomass (Alien Loot)     --
--===========================--
-- Conversion rate: blue xenomass per red xenomass
BLUE_XENOMASS_PER_RED_XENOMASS = settings.startup["zpollution-blue-per-red"].value

-- Time cost for converting blue to red xenomass
BLUE_TO_RED_COST = settings.startup["zpollution-blue-to-red-cost"].value

-- Pollution generated per blue xenomass (for domesticated nests feature)
POLLUTION_PER_BLUE_XENOMASS = 500

-- Toxic sludge generated per red xenomass (for domesticated nests feature)
SLUDGE_PER_RED_XENOMASS = 1000
