--[[
  Data Final Fixes Stage for Pollution Solutions Lite
  
  This file runs during Factorio's data-final-fixes phase, after all other
  prototype modifications. It handles final tweaks that need to happen after
  all mods have loaded their prototypes.
  
  Currently handles:
  - Toxic Sludge Barrel: Makes barreled toxic sludge usable as fuel
    - Sets fuel category to "waste"
    - Assigns fuel value based on sludge energy settings
    - Returns empty barrel after burning
]]

require("constants")

-- Configure toxic sludge barrel as burnable fuel
-- Each barrel holds 50 units of toxic sludge
-- Factorio 2.0: Items use fuel_category (singular), burners use fuel_categories (plural)
data.raw["item"][TOXIC_SLUDGE_NAME .. "-barrel"].fuel_category = "waste"
data.raw["item"][TOXIC_SLUDGE_NAME .. "-barrel"].fuel_value = (50 * MJ_PER_TOXIC_SLUDGE) .. "MJ"
-- Factorio 2.0: barrel system changed, burnt_result returns to "barrel" not "empty-barrel"
data.raw["item"][TOXIC_SLUDGE_NAME .. "-barrel"].burnt_result = "barrel"
