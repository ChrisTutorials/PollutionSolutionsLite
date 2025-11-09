--[[ 
  Factorio API Type Definitions and Global Stubs
  
  This file provides type annotations and stub definitions for Factorio's
  global API objects. These are not actual implementations but definitions
  that help Lua language servers (Pylance/Sumneko) understand Factorio
  specific types and globals.
  
  DO NOT require this file in production code - it's only for IDE support
]]

---@class LuaSurface
---@field index integer
---@field name string

---@class MapPosition
---@field x number
---@field y number

---@class LuaEntity
---@field type string
---@field name string

---@class LuaPlayer
---@field index integer
---@field name string

---@class LuaGame
---@field surfaces table<integer, LuaSurface>
---@field players table<integer, LuaPlayer>
---@field print fun(message: string)

---@class LuaScript
---@field active_mods table<string, string>
---@field on_init fun(callback: fun())
---@field on_load fun(callback: fun())
---@field on_configuration_changed fun(callback: fun(event: any))
---@field on_event fun(event_id: integer, callback: fun(event: any))
---@field raise_event fun(event_id: integer, event_data: table)

---@class Commands
---@field add_command fun(options: table)
---@field remove_command fun(name: string)

---Global Factorio game object
---@type LuaGame
game = game or {}

---Global Factorio script object
---@type LuaScript
script = script or {}

---Currently active mods table
---@type table<string, true>
mods = mods or {}

---Global commands interface
---@type Commands
commands = commands or {}

---Factorio data stage global
---@type table
data = data or {}

---Factorio util module
---@type table
util = util or {}

---Factorio global state storage (persisted between ticks)
---@type table
global = global or {}

return {}
