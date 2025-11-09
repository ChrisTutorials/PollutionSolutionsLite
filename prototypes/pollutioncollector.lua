require("constants")
require("util")

------------
-- Entity --
------------

local pollutioncollector = util.table.deepcopy(data.raw["storage-tank"]["storage-tank"])
pollutioncollector.name = "pollutioncollector"
pollutioncollector.order = "z"
pollutioncollector.minable.result = "pollutioncollector"
pollutioncollector.crafting_categories = { "pollution" }
pollutioncollector.icon = GRAPHICS .. "icons/pollution-collector.png"
pollutioncollector.icon_size = 64
assert(
  pollutioncollector.pictures.picture.sheets,
  "Pollution collector pictures.picture.sheets not found"
)
assert(
  pollutioncollector.pictures.picture.sheets[1],
  "Pollution collector pictures.picture.sheets[1] not found"
)
setLayerGraphics(
  pollutioncollector.pictures.picture.sheets[1],
  GRAPHICS .. "entity/pollution-collector/pollution-collector.png",
  GRAPHICS .. "entity/pollution-collector/hr-pollution-collector.png"
)

-- Reset sprite dimensions to match our custom 220x108 image
-- Base game storage-tank has different dimensions that don't apply
local sheet = pollutioncollector.pictures.picture.sheets[1]
sheet.width = 220
sheet.height = 108
sheet.frame_count = 1
sheet.line_length = 1
if sheet.hr_version then
  sheet.hr_version.width = 220
  sheet.hr_version.height = 108
  sheet.hr_version.frame_count = 1
  sheet.hr_version.line_length = 1
end

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
