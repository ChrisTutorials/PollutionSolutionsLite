--[[
  Data Updates Stage for Pollution Solutions Lite
  
  This file runs during Factorio's data-updates phase, after initial prototype
  loading but before final-fixes. It handles:
  
  1. Mod Compatibility: Integrates with other mods' technology trees
  2. Resistance System: Adds toxic damage resistance to all entities based on fire resistance
  3. Armor Protection: Scales toxic resistance for armor types based on acid resistance
  
  The resistance system ensures that entities with fire resistance are also
  somewhat resistant to toxic damage, maintaining balance across damage types.
]]

require("constants")
require("util")

-------------------
-- Compatibility --
-------------------
-- Integrate with other mods by adding technology prerequisites
-- This ensures proper tech tree progression when multiple mods are active

if mods["RampantIndustry"] then
  -- Link Rampant Industry's air filtering to our pollution controls
  table.insert(
    data.raw["technology"]["rampant-industry-technology-air-filtering"].prerequisites,
    "pollution-controls"
  )
end

if mods["NauvisDay"] then
  -- Link Nauvis Day's pollution technologies to ours
  table.insert(data.raw["technology"]["pollution-capture"].prerequisites, "pollution-controls")
  table.insert(data.raw["technology"]["pollution-processing"].prerequisites, "incineration")
end

if mods["nauvis-melange"] then
  -- Link Nauvis Melange's alien breeding to our incineration tech
  table.insert(data.raw["technology"]["nm-alien-breeding"].prerequisites, "incineration")
end

if mods["modmashsplinterresources"] then
  -- Link ModMash's alien conversion to our incineration tech
  table.insert(data.raw["technology"]["alien-conversion1"].prerequisites, "incineration")
end

---Add resistance to entities for a specific damage type
---@param entityList table Array of entity prototypes
---@param _DamageType string The damage type to add resistance for
---@param _Percent number Percentage damage reduction (0-100)
---@param _Decrease number Flat damage reduction amount
local function addResistance(entityList, _DamageType, _Percent, _Decrease)
  if not entityList or (not _Percent and not _Decrease) or (_Percent == 0 and _Decrease == 0) then
    --log("Failed to make entity list immune.")
    return
  end

  for _, entity in pairs(entityList) do
    -- Create resistance entry
    local resistTable = {
      type = _DamageType,
    }

    if _Percent and _Percent ~= 0 then
      resistTable.percent = _Percent
    end
    if _Decrease and _Decrease ~= 0 then
      resistTable.decrease = _Decrease
    end

    -- Add to entity's resistance table
    if not entity.resistances then
      entity.resistances = { resistTable }
    else
      table.insert(entity.resistances, resistTable)
    end

    log(entity.name .. " resistances: " .. serpent.dump(entity.resistances))
  end
end

-----------------
-- Resistances --
-----------------

-- Add toxic resistance to all armor types based on acid resistance
-- HEV armor gets special handling (not modified here)
for _, armor in pairs(data.raw["armor"]) do
  if armor.name ~= "hev-armor" then
    local value = 0

    -- Find acid resistance value
    for _, resistance in pairs(armor.resistances) do
      if resistance.type == "acid" then
        value = resistance.percent
        break
      end
    end

    -- Scale toxic resistance based on acid resistance
    -- Percent: acid/1.4, rounded to nearest 5
    -- Decrease: min(20, max(5, acid/4))
    addResistance(
      { armor },
      POLLUTION_DAMAGE_TYPE,
      math.floor((value / 1.4) / 5) * 5,
      math.min(20, math.max(5, math.floor(value / 4)))
    )
  end
end

-- Add toxic resistance to all entities with health and resistances
-- Based on their fire resistance (fire-resistant entities resist toxic damage)
for type, typeTable in pairs(data.raw) do
  for name, entity in pairs(typeTable) do
    if entity.max_health ~= nil and entity.resistances ~= nil then
      local fireResistance = { percent = 0, decrease = 0 }

      -- Find fire resistance values
      for _, resistance in pairs(entity.resistances) do
        if resistance.type == "fire" then
          fireResistance = resistance
        end
      end

      -- Apply same fire resistance values to toxic damage
      addResistance(
        { entity },
        POLLUTION_DAMAGE_TYPE,
        fireResistance.percent or 0,
        fireResistance.decrease or 0
      )
    end
  end
end
