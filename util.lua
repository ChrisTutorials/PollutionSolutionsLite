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
---@param _args? string|table Optional nested field path (string for single field, table for nested path)
---@return table A deep copy of the requested prototype data
function copyData(_Type, _Name, _args)
  if _args then
    if type(_args) == "table" then
      -- Navigate through nested fields using array of keys
      local result = data.raw[_Type][_Name]
      for i = 1, #_args, 1 do
        result = result[_args[i]]
      end
      return util.table.deepcopy(result)
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
function Set(list)
  local set = {}
  for _, l in ipairs(list) do
    set[l] = true
  end
  return set
end

---Set graphics filename on a layer, with optional high-resolution version
---@param layer table The layer object to modify
---@param filename string The base graphics filename
---@param hr_filename string|nil Optional high-resolution filename
function setLayerGraphics(layer, filename, hr_filename)
  assert(layer, "Layer cannot be nil")
  layer.filename = filename
  if hr_filename and layer.hr_version then
    -- Only set HR dimensions/scale if HR image is actually provided
    layer.hr_version.filename = hr_filename
    -- HR version must be 2x dimensions with 0.5 scale for proper rendering
    if layer.width and layer.height then
      layer.hr_version.width = layer.width * 2
      layer.hr_version.height = layer.height * 2
      layer.hr_version.scale = 0.5
    end
  end
end

---Set graphics for a directional structure (north, east, south, west)
---@param structure table The structure with directional layers
---@param direction string The direction: "north", "east", "south", or "west"
---@param filename string The base graphics filename
---@param hr_filename string|nil Optional high-resolution filename
function setDirectionalGraphics(structure, direction, filename, hr_filename)
  assert(
    structure and structure[direction] and structure[direction].layers,
    "Structure." .. direction .. ".layers not found"
  )
  setLayerGraphics(structure[direction].layers[1], filename, hr_filename)
end

---Set graphics for all four directions of a structure
---@param structure table The structure with directional layers
---@param base_path string Base path for graphics (e.g., "entity/low-heat-exchanger/")
function setAllDirectionalGraphics(structure, base_path)
  assert(structure, "Structure cannot be nil")

  -- Verify all directions exist
  assert(structure.north and structure.north.layers, "Structure.north.layers not found")
  assert(structure.east and structure.east.layers, "Structure.east.layers not found")
  assert(structure.south and structure.south.layers, "Structure.south.layers not found")
  assert(structure.west and structure.west.layers, "Structure.west.layers not found")

  -- Set filenames for each direction
  setLayerGraphics(
    structure.north.layers[1],
    GRAPHICS .. base_path .. "lowheatex-N-idle.png",
    GRAPHICS .. base_path .. "hr-lowheatex-N-idle.png"
  )
  setLayerGraphics(
    structure.east.layers[1],
    GRAPHICS .. base_path .. "lowheatex-E-idle.png",
    GRAPHICS .. base_path .. "hr-lowheatex-E-idle.png"
  )
  setLayerGraphics(
    structure.south.layers[1],
    GRAPHICS .. base_path .. "lowheatex-S-idle.png",
    GRAPHICS .. base_path .. "hr-lowheatex-S-idle.png"
  )
  setLayerGraphics(
    structure.west.layers[1],
    GRAPHICS .. base_path .. "lowheatex-W-idle.png",
    GRAPHICS .. base_path .. "hr-lowheatex-W-idle.png"
  )
end
