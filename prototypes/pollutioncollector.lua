require("constants")
require("util")

------------
-- Entity --
------------

-- Sprite sheet configuration
local COLLECTOR_SPRITE_WIDTH = 220
local COLLECTOR_SPRITE_HEIGHT = 108
local COLLECTOR_SPRITE_SCALE = 0.4

local pollutioncollector = util.table.deepcopy(data.raw["storage-tank"]["storage-tank"])
pollutioncollector.name = "pollutioncollector"
pollutioncollector.order = "z"
pollutioncollector.minable.result = "pollutioncollector"
pollutioncollector.crafting_categories = { "pollution" }
pollutioncollector.icon = GRAPHICS .. "icons/pollution-collector.png"
pollutioncollector.icon_size = 64

-- Replace main entity sprite with pollution collector sprite
-- Storage-tank entity handles 4-way rotation automatically
-- NOTE: Single sprite used for all 4 rotations - storage-tank repeats it
-- CRITICAL: Override all inherited picture data to prevent frame misinterpretation
assert(
  pollutioncollector.pictures and pollutioncollector.pictures.picture,
  "Collector pictures not found"
)

local base_sheet = {
  filename = GRAPHICS .. "entity/pollution-collector/pollution-collector.png",
  priority = "high",
  width = COLLECTOR_SPRITE_WIDTH,
  height = COLLECTOR_SPRITE_HEIGHT,
  frames = 1,
  frame_count = 1,
  line_length = 1,
  scale = COLLECTOR_SPRITE_SCALE,
}

pollutioncollector.pictures = {
  picture = {
    sheets = { base_sheet },
  },
}

-- Set HR graphics if available (auto-scales to 2x dimensions with 0.5x scale)
if base_sheet.hr_version then
  setLayerGraphics(
    base_sheet,
    GRAPHICS .. "entity/pollution-collector/pollution-collector.png",
    GRAPHICS .. "entity/pollution-collector/hr-pollution-collector.png"
  )
end

-- Remove inherited GUI-only properties that have sprite references
-- These would cause sprite rectangle errors as they reference wrong dimensions
pollutioncollector.window_background = nil -- Storage tank GUI window
pollutioncollector.fluid_background = nil -- Storage tank GUI fluid display
pollutioncollector.water_reflection = nil -- Water reflection rendering (has variation_count=1)
pollutioncollector.circuit_connector = nil -- Circuit network UI (optional removal)

pollutioncollector.fluid_box.filter = "polluted-air"
for i = 1, #pollutioncollector.fluid_box.pipe_connections, 1 do
  pollutioncollector.fluid_box.pipe_connections[i].flow_direction = "input-output"
end
pollutioncollector.fluid_box.base_area = 10

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

data:extend({
  pollutioncollector,
  pollutioncollector_item,
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
