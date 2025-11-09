--[[ 
  Factorio API Type Definitions and Global Stubs
  
  This file provides minimal type stubs for the Lua language server.
  The undefined-field diagnostic is disabled globally to allow Factorio's
  runtime-injected APIs to work without type-checking false positives.
  
  DO NOT require this file in production code - it's only for IDE support
]]

-- Type aliases for Factorio objects
---@alias EventData table
---@alias LuaSurface table
---@alias LuaEntity table
---@alias MapPosition table

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
function log(message)
end

return {}

