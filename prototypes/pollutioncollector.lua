require("constants")
require("util")

local hit_effects = require("__base__.prototypes.entity.hit-effects")
local sounds = require("__base__.prototypes.entity.sounds")

------------
-- Entity --
------------

-- Sprite sheet configuration
local COLLECTOR_SPRITE_WIDTH = 220
local COLLECTOR_SPRITE_HEIGHT = 108
local COLLECTOR_SPRITE_SCALE = 0.4

-- Use furnace entity type with negative emissions to collect pollution
-- This uses Factorio's built-in pollution system instead of scripting
local pollutioncollector = {
  type = "furnace",
  name = "pollutioncollector",
  icon = GRAPHICS .. "icons/pollution-collector.png",
  icon_size = 64,
  flags = { "placeable-neutral", "placeable-player", "player-creation" },
  minable = { mining_time = 0.5, result = "pollutioncollector" },
  fast_replaceable_group = nil,
  max_health = 350,
  corpse = "big-remnants",
  dying_explosion = "medium-explosion",
  resistances = {
    { type = "fire", percent = 70 },
  },
  collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
  selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
  damaged_trigger_effect = hit_effects.entity(),
  
  -- Crafting configuration
  crafting_categories = { "atmospheric-filtration" },
  crafting_speed = 1,
  source_inventory_size = 0,  -- No input items needed
  result_inventory_size = 0,  -- No output items produced
  module_slots = 0,
  allowed_effects = { "consumption", "speed", "pollution" },
  show_recipe_icon = false,
  show_recipe_icon_on_map = false,
  
  -- Energy configuration with negative emissions (pollution collection)
  energy_source = {
    type = "electric",
    usage_priority = "secondary-input",
    emissions_per_minute = {
      pollution = -40,  -- Removes 40 pollution per minute from the chunk
    },
  },
  energy_usage = "150kW",
  
  -- Fluid output for collected pollution
  fluid_boxes = {
    {
      production_type = "output",
      volume = 100,  -- Volume in units (100 units = 100 liters)
      pipe_connections = {
        { flow_direction = "output", direction = defines.direction.north, position = {0, -1} },
        { flow_direction = "output", direction = defines.direction.south, position = {0, 1} },
        { flow_direction = "output", direction = defines.direction.east, position = {1, 0} },
        { flow_direction = "output", direction = defines.direction.west, position = {-1, 0} },
      },
      filter = "polluted-air",
    },
  },
  
  -- Graphics
  graphics_set = {
    animation = {
      layers = {
        {
          filename = GRAPHICS .. "entity/pollution-collector/pollution-collector.png",
          priority = "high",
          width = COLLECTOR_SPRITE_WIDTH,
          height = COLLECTOR_SPRITE_HEIGHT,
          frame_count = 1,
          line_length = 1,
          scale = COLLECTOR_SPRITE_SCALE,
          shift = { 0, 0 },
        },
      },
    },
  },
  
  -- Sounds
  impact_category = "metal",
  open_sound = sounds.machine_open,
  close_sound = sounds.machine_close,
  working_sound = {
    sound = { filename = "__base__/sound/accumulator-working.ogg", volume = 0.4 },
    idle_sound = { filename = "__base__/sound/idle1.ogg", volume = 0.3 },
    audible_distance_modifier = 0.5,
    fade_in_ticks = 4,
    fade_out_ticks = 20,
  },
}

----------
-- Item --
----------

local pollutioncollector_item = util.table.deepcopy(data.raw["item"]["steam-turbine"])
pollutioncollector_item.name = "pollutioncollector"
pollutioncollector_item.place_result = "pollutioncollector"
pollutioncollector_item.stack_size = 50
pollutioncollector_item.icon = GRAPHICS .. "icons/pollution-collector.png"
pollutioncollector_item.icon_size = 64

------------
-- Extend --
------------

------------
-- Recipe --
------------

-- Pollution collection recipe: converts air pollution to polluted-air fluid
-- This recipe runs continuously in the pollution collector furnace
-- The negative emissions on the entity handle the actual pollution removal
local collect_pollution_recipe = {
  type = "recipe",
  name = "collect-pollution",
  category = "atmospheric-filtration",
  enabled = false,
  energy_required = 60,  -- 60 seconds per cycle
  ingredients = {},  -- No input required
  results = {
    { type = "fluid", name = "polluted-air", amount = 40 },  -- Produces 40 units of polluted-air
  },
  icon = GRAPHICS .. "icons/pollution-collector.png",
  icon_size = 64,
  subgroup = "fluid-recipes",
  order = "z[pollution]-a[collect]",
}

data:extend({
  pollutioncollector,
  pollutioncollector_item,
  collect_pollution_recipe,
  {
    type = "recipe",
    name = "pollutioncollector",
    energy_required = 5,
    enabled = false,
    ingredients = {
      { type = "item", name = "red-xenomass", amount = 10 },
      { type = "item", name = "electronic-circuit", amount = 5 },
      { type = "item", name = "iron-gear-wheel", amount = 50 },
      { type = "item", name = "pipe", amount = 50 },
    },
    results = { { type = "item", name = "pollutioncollector", amount = 1 } },
  },
})
