--[[
  Category Prototypes for Pollution Solutions Lite
  
  Defines custom categories used by the mod:
  1. Fuel Category "waste": For burning pollution-based fuels (toxic sludge)
  2. Recipe Category "pollution": For pollution processing recipes
  
  These categories allow the mod to have specialized machines and recipes
  that only work with pollution-related items.
]]

data:extend({
  -- Fuel category for toxic waste materials
  -- Used by incinerators to burn toxic sludge for power
  {
    type = "fuel-category",
    name = "waste",
  },

  -- Recipe category for pollution processing
  -- Used by specialized pollution processing buildings
  {
    type = "recipe-category",
    name = "pollution",
  },

  -- Recipe category for atmospheric filtration (pollution collection)
  -- Used by pollution collectors to convert air pollution to fluid
  {
    type = "recipe-category",
    name = "atmospheric-filtration",
  },
})
