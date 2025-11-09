--[[
  Fluid Prototypes for Pollution Solutions Lite
  
  Defines the two main pollution fluids used throughout the mod:
  1. Polluted Air: Collected from air pollution, gas-like fluid
  2. Toxic Sludge: Concentrated pollution, more dense and dangerous
  
  Both fluids have distinctive colors for easy identification in pipes and tanks.
]]

require("constants")

-- Toxic Sludge: Concentrated pollution liquid
-- Created by processing polluted air through air filters
-- Can be burned for energy or dumped back into the atmosphere
local toxicsludge = {
  type = "fluid",
  name = "toxic-sludge",
  base_color = { r = 0.333, g = 0.063, b = 0.451 }, -- Dark purple
  flow_color = { r = 0.744, g = 0.275, b = 0.867 }, -- Bright purple flow
  icon = GRAPHICS .. "icons/fluid/toxicsludge.png",
  icon_size = 64,
  order = "a[fluid]-b[toxicsludge]",
  default_temperature = 15,
}

-- Polluted Air: Direct pollution capture from atmosphere
-- Collected by pollution collector buildings
-- Can be concentrated into toxic sludge or dumped
-- Displays as gas in storage tanks
local pollution = {
  type = "fluid",
  name = "polluted-air",
  auto_barrel = true, -- Can be barreled for transport
  base_color = { r = 0.500, g = 0.000, b = 0.000 }, -- Dark red
  flow_color = { r = 1.00, g = 0.000, b = 0.000 }, -- Bright red flow
  icon = GRAPHICS .. "icons/fluid/pollution.png",
  icon_size = 64,
  order = "a[fluid]-b[pollution]",
  default_temperature = 15,
  gas_temperature = 15, -- Displays as gas in tanks
}

data:extend({
  toxicsludge,
  pollution,
})
