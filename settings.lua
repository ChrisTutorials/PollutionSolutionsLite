--[[
  Settings Module for Pollution Solutions Lite
  
  This file defines all configurable settings for the mod.
  Settings are divided into two categories:
  - Startup settings: Affect prototypes and require game restart to change
  - Runtime-global settings: Can be changed during gameplay via mod settings menu
  
  Setting Types:
  - int-setting: Integer values with min/max constraints
  - double-setting: Floating-point values with min/max constraints
  
  Categories:
  - Fluid/Recipe Settings (a-*): Control conversion rates and energy values
  - Xenomass Settings (b-*): Control alien loot drops and conversions
  - Pollution Collection Settings: Control how pollution collectors work
]]

data:extend({
  --===================--
  -- Startup Settings  --
  --===================--
  -- These settings affect game prototypes and require restart to change

  {
    type = "int-setting",
    name = "zpollution-air-per-sludge",
    setting_type = "startup",
    minimum_value = 1,
    default_value = 10,
    order = "a-a",
  },
  {
    type = "int-setting",
    name = "zpollution-sludge-per-filter",
    setting_type = "startup",
    minimum_value = 1,
    default_value = 100,
    order = "a-b",
  },
  {
    type = "double-setting",
    name = "zpollution-mj-per-sludge",
    setting_type = "startup",
    minimum_value = 0.001,
    default_value = 10,
    order = "a-d",
  },
  {
    type = "double-setting",
    name = "zpollution-incinerator-efficiency",
    setting_type = "startup",
    minimum_value = 0.01,
    default_value = 0.1,
    maximum_value = 1.0,
    order = "a-e",
  },
  {
    type = "double-setting",
    name = "zpollution-incinerator-output",
    setting_type = "startup",
    minimum_value = 0.001,
    default_value = 2.0,
    order = "a-f",
  },
  {
    type = "int-setting",
    name = "zpollution-blue-per-red",
    setting_type = "startup",
    minimum_value = 1,
    default_value = 10,
    order = "b-a",
  },
  {
    type = "double-setting",
    name = "zpollution-blue-to-red-cost",
    setting_type = "startup",
    minimum_value = 1,
    default_value = 10.0,
    order = "b-b",
  },

  --==========================--
  -- Runtime-Global Settings  --
  --==========================--
  -- These settings can be changed during gameplay via mod settings menu

  {
    type = "int-setting",
    name = "zpollution-collection-interval",
    setting_type = "runtime-global",
    minimum_value = 1,
    default_value = 60,
    order = "a-a",
  },
  {
    type = "double-setting",
    name = "zpollution-collectors-required",
    setting_type = "runtime-global",
    minimum_value = 1,
    default_value = 8,
    maximum_value = 100,
    order = "a-b",
  },
  {
    type = "double-setting",
    name = "zpollution-pollution-remaining",
    setting_type = "runtime-global",
    minimum_value = 0,
    default_value = 50,
    order = "a-c",
  },
  {
    type = "double-setting",
    name = "zpollution-blue-per-alien",
    setting_type = "runtime-global",
    minimum_value = 0.01,
    default_value = 1,
    order = "b-a",
  },
  {
    type = "double-setting",
    name = "zpollution-red-per-alien",
    setting_type = "runtime-global",
    minimum_value = 0.01,
    default_value = 10,
    order = "b-b",
  },
})
