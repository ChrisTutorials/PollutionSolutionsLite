--[[ 
  Factorio API Type Definitions and Global Stubs
  
  This file provides minimal type stubs for the Lua language server.
  The undefined-field diagnostic is disabled globally to allow Factorio's
  runtime-injected APIs to work without type-checking false positives.
  
  DO NOT require this file in production code - it's only for IDE support
]]

---@diagnostic disable: duplicate-doc-alias

-- Type aliases for Factorio objects
---@alias EventData table
---@alias LuaSurface table
---@alias LuaEntity table
---@alias MapPosition table

-- ============================================================================
-- FACTORIO RUNTIME GLOBALS (injected by game engine)
-- ============================================================================

-- Stub definitions to prevent "undefined" errors for Factorio globals
game = game or {}
script = script or {}
mods = mods or {}
commands = commands or {}
data = data or {}
util = util or {}
global = global or {}
defines = defines or {}

-- Optional mod globals
flare_stack = flare_stack or {}

---Logging function
---@param message string
function log(message) end

-- ============================================================================
-- MOD-SPECIFIC GLOBALS (defined in constants.lua)
-- ============================================================================
-- These constants are loaded from constants.lua during mod initialization
-- They are global constants that can be accessed throughout the mod

--- Graphics path for mod assets
GRAPHICS = GRAPHICS or ""

--- Number of game ticks per second (Factorio runs at 60 ticks/second)
TICKS_PER_SECOND = TICKS_PER_SECOND or 60

--- Entity name for toxic dump sites
TOXIC_DUMP_NAME = TOXIC_DUMP_NAME or "dump-site"

--- Update interval for toxic dumps (every 30 seconds)
TOXIC_DUMP_INTERVAL = TOXIC_DUMP_INTERVAL or 1800

--- Minimum fill percentage before dump releases pollution
TOXIC_DUMP_FILLPERCENT = TOXIC_DUMP_FILLPERCENT or 0.0

--- Maximum pollution released per cycle
TOXIC_DUMP_MAX_RELEASED = TOXIC_DUMP_MAX_RELEASED or 1.0

--- Sludge per second consumption rate
TOXIC_DUMP_SLUDGE_PER_SEC = TOXIC_DUMP_SLUDGE_PER_SEC or 5

--- Pollution released per cycle
TOXIC_DUMP_POLLUTION_RELEASED = TOXIC_DUMP_POLLUTION_RELEASED or 100

--- Number of clouds generated per cycle
TOXIC_DUMP_CLOUDS = TOXIC_DUMP_CLOUDS or 1

--- Minimum smoke particles
TOXIC_DUMP_SMOKE_MIN = TOXIC_DUMP_SMOKE_MIN or 1

--- Maximum smoke particles
TOXIC_DUMP_SMOKE_MAX = TOXIC_DUMP_SMOKE_MAX or 3

--- Small cloud entity name
TOXIC_DUMP_CLOUD_SMALL = TOXIC_DUMP_CLOUD_SMALL or "toxic-cloud-small"

--- Medium cloud entity name
TOXIC_DUMP_CLOUD_MEDIUM = TOXIC_DUMP_CLOUD_MEDIUM or "toxic-cloud-medium"

--- Large cloud entity name
TOXIC_DUMP_CLOUD_LARGE = TOXIC_DUMP_CLOUD_LARGE or "toxic-cloud-large"

--- Fill percentage threshold for medium clouds
TOXIC_DUMP_CLOUD_MEDIUM_PERCENT = TOXIC_DUMP_CLOUD_MEDIUM_PERCENT or 0.05

--- Fill percentage threshold for large clouds
TOXIC_DUMP_CLOUD_LARGE_PERCENT = TOXIC_DUMP_CLOUD_LARGE_PERCENT or 0.20

--- Percentage of pollution consumed (destroyed) by dump
TOXIC_DUMP_CONSUME_PERCENT = TOXIC_DUMP_CONSUME_PERCENT or 0.5

--- Entity name for pollution collectors
POLLUTION_COLLECTOR_NAME = POLLUTION_COLLECTOR_NAME or "pollutioncollector"

--- Fluid name for polluted air
POLLUTED_AIR_NAME = POLLUTED_AIR_NAME or "polluted-air"

--- Pollution emissions per unit of polluted-air
EMISSIONS_PER_AIR = EMISSIONS_PER_AIR or 1

--- Fluid name for toxic sludge
TOXIC_SLUDGE_NAME = TOXIC_SLUDGE_NAME or "toxic-sludge"

--- Megajoules per unit of toxic sludge (fuel value)
MJ_PER_TOXIC_SLUDGE = MJ_PER_TOXIC_SLUDGE or 2

--- Damage type identifier for pollution damage
POLLUTION_DAMAGE_TYPE = POLLUTION_DAMAGE_TYPE or "toxic"

--- Incinerator fuel conversion efficiency
INCINERATOR_EFFICIENCY = INCINERATOR_EFFICIENCY or 0.85

--- Incinerator output rate
INCINERATOR_OUTPUT = INCINERATOR_OUTPUT or 600

--- Air ratio per sludge unit
AIR_PER_SLUDGE = AIR_PER_SLUDGE or 10

--- Sludge per filter unit
SLUDGE_PER_FILTER = SLUDGE_PER_FILTER or 1

--- Filters per liquify recipe
FILTER_PER_LIQUIFY = FILTER_PER_LIQUIFY or 1

--- Water percentage per filter
WATER_PER_FILTER_PERCENT = WATER_PER_FILTER_PERCENT or 1

--- Ratio of blue to red xenomass
BLUE_XENOMASS_PER_RED_XENOMASS = BLUE_XENOMASS_PER_RED_XENOMASS or 1

--- Main module table for initialization functions
PollutionSolutions = PollutionSolutions or {}

return {}
