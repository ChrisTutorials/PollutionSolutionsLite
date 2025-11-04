--[[
  Utility Functions Module for Pollution Solutions Lite
  
  This module provides helper functions for creating and manipulating
  Factorio prototype data. These functions are used during the data stage
  (prototype loading) to create modified versions of existing prototypes.
  
  Functions:
  - copyData: Deep copy prototype data with optional nested field access
  - makeNewDataFromData: Create a new prototype by copying and renaming
  - makeNewEntityFromData: Create a new entity with proper mining results
  - makeNewItemFromData: Create a new item with place_result
  - Set: Convert a list into a set (hash table)
]]

---Deep copy prototype data from data.raw with optional nested field access
---@param _Type string The prototype type (e.g., "item", "entity", "recipe")
---@param _Name string The name of the prototype to copy
---@param _args string|table Optional nested field path (string for single field, table for nested path)
---@return table A deep copy of the requested prototype data
function copyData( _Type, _Name, _args )
  if _args then
    if( type(_args) == 'table' ) then
      -- Navigate through nested fields using array of keys
      local data = data.raw[_Type][_Name]
      for i=1, #_args, 1 do
        data = data[_args[i]]
      end
      return util.table.deepcopy(data)
    else
      -- Single field access
      return util.table.deepcopy(data.raw[_Type][_Name][_args])
    end
  else
    -- No nested fields, copy entire prototype
    return util.table.deepcopy(data.raw[_Type][_Name])
  end
end

---Create a new prototype by copying an existing one and renaming it
---@param _Type string The prototype type (e.g., "item", "entity", "recipe")
---@param _OriginalName string The name of the prototype to copy from
---@param _NewName string The new name for the copied prototype
---@return table The newly created prototype
function makeNewDataFromData(_Type, _OriginalName, _NewName)
  local newDataEntry = copyData(_Type, _OriginalName)
  newDataEntry.name = _NewName
  return newDataEntry
end

---Create a new entity by copying an existing one, with proper order and mining result
---@param _Type string The entity type (e.g., "assembling-machine", "furnace")
---@param _OriginalName string The name of the entity to copy from
---@param _NewName string The new name for the entity
---@param _Order string|nil Optional order string (defaults to "z")
---@return table The newly created entity prototype
function makeNewEntityFromData(_Type, _OriginalName, _NewName, _Order)
  _Order = _Order or "z"
  local newDataEntry = makeNewDataFromData(_Type, _OriginalName, _NewName)
  newDataEntry.order = _Order
  newDataEntry.minable.result = _NewName
  return newDataEntry
end

---Create a new item by copying an existing one, with place_result set
---@param _OriginalName string The name of the item to copy from
---@param _NewName string The new name for the item
---@param _Order string|nil Optional order string (not used in this function)
---@return table The newly created item prototype
function makeNewItemFromData(_OriginalName, _NewName, _Order)
  local newDataEntry = makeNewDataFromData("item", _OriginalName, _NewName)
  newDataEntry.place_result = _NewName
  return newDataEntry
end

---Convert a list into a set (hash table with true values)
---Useful for fast membership testing: if set[item] then ... end
---@param list table Array-like table to convert
---@return table Hash table where keys are list elements and values are true
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end
