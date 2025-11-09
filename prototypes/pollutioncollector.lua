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

-- COMPLETE REPLACEMENT of picture structure with single clean sprite
-- Don't try to patch base game structure - replace it entirely
-- CRITICAL: Do NOT include variation_count at all (not even =1)
-- variation_count causes Factorio to read multiple sprites horizontally
pollutioncollector.pictures = {
  picture = {
    sheets = {
      {
        filename = GRAPHICS .. "entity/pollution-collector/pollution-collector.png",
        width = 220,
        height = 108,
        frame_count = 1,
        line_length = 1
        -- NO variation_count - omit it entirely!
      }
    },
    -- CRITICAL: Remove variation_count from picture level too
    variation_count = nil,
    repeat_count = nil
  },
  -- Also remove from pictures level if it exists
  variation_count = nil,
  repeat_count = nil
}

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
