--[[
  Data Stage Loader for Pollution Solutions Lite
  
  This file is executed during Factorio's data stage (prototype loading).
  It loads all prototype definitions for the mod's items, fluids, entities,
  recipes, and technologies.
  
  The order of requires is important:
  1. Categories (recipe/crafting categories)
  2. Projectiles (damage-dealing entities)
  3. Entities (buildings and structures)
  4. Fluids (polluted-air, toxic-sludge)
  5. Items (all craftable/placeable items)
  6. Recipes (crafting recipes)
  7. Technologies (research unlocks)
  8. Special modules (pollution collector, HEV suit)
  
  Optional Mod Compatibility:
  - K2 Flare Stack: Increases pollution output when flaring pollution fluids
]]

require("util")  -- Load utility functions before prototypes
require("prototypes.category")
require("prototypes.projectiles")
require("prototypes.entity")
require("prototypes.fluid")
require("prototypes.item")
require("prototypes.recipe")
require("prototypes.technology")

require("prototypes.pollutioncollector")
require("prototypes.hevsuit")

-- K2 Flare Stack compatibility: Make pollution fluids more polluting when flared
if mods["k2-flare-stack"] then
	flare_stack.flare_stack_util.addBurnFluidEmissionsMultiplier("polluted-air", 600)
	flare_stack.flare_stack_util.addBurnFluidEmissionsMultiplier("toxic-sludge", 600 * AIR_PER_SLUDGE)
end