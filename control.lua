--[[
  Control Script for Pollution Solutions Lite
  
  This is the main runtime control script that handles all game events and
  entity behavior during gameplay. It manages:
  
  1. Toxic Dumps: Entities that slowly release stored pollution into the air
  2. Pollution Collectors: Entities that collect pollution from chunks and convert it to fluid
  3. Xenomass Loot: Alien entities drop xenomass items when killed
  4. Pollution Dispersal: Prevents pollution deletion by dispersing it when entities are destroyed
  
  Key Systems:
  - Event handlers for entity lifecycle (build, destroy, death)
  - Periodic tick-based updates for collectors and dumps
  - Global state tracking for all managed entities
  - Pollution conversion and dispersal mechanics
]]

require("util")
require("constants")

--==============--
-- Script Hooks --
--==============--
-- Register event handlers with Factorio's event system
script.on_event(defines.events.on_tick, function(event)
  OnTick(event)
end)
script.on_event(defines.events.on_built_entity, function(event)
  OnBuiltEntity(event)
end)
script.on_event(defines.events.on_robot_built_entity, function(event)
  OnBuiltEntity(event)
end)
script.on_event(defines.events.on_pre_player_mined_item, function(event)
  OnEntityPreRemoved(event)
end)
script.on_event(defines.events.on_robot_pre_mined, function(event)
  OnEntityPreRemoved(event)
end)
script.on_event(defines.events.on_entity_died, function(event)
  OnEntityPreRemoved(event)
end)
script.on_event(defines.events.on_entity_died, function(event)
  EntityDied(event)
end)

-- Module table for initialization functions
PollutionSolutions = {}

-- Initialize global state when mod is first added to a save
script.on_init(function()
  local _, err = pcall(PollutionSolutions.InitGlobals)
  if err then
    game.print(err)
  end
end)

-- Reinitialize when mod configuration changes (version updates, mod list changes)
script.on_configuration_changed(function()
  local _, err = pcall(PollutionSolutions.InitGlobals)
  if err then
    game.print(err)
  end
end)

---Initialize global state tables and scan existing entities
---This function sets up tracking for all mod entities and is called
---during mod initialization or when configuration changes
function PollutionSolutions.InitGlobals()
  -- Initialize global tracking tables
  storage.toxicDumps = {} -- Array of toxic dump positions
  storage.collectors = {} -- Map of unit_number -> collector entity
  storage.spilledLoot = {} -- Map of loot entity -> force (for force assignment)
  storage.lootToCheck = {} -- Queue for loot entities to validate

  --[[
  -- Disabled: Force technology refresh (kept for reference)
  for _, force in pairs(game.forces) do
    force.technologies["logistic-robotics"].researched = false
    force.technologies["logistic-robotics"].reload()
    force.technologies["logistic-robotics"].researched = true
  end
  --]]

  -- Scan all surfaces for existing mod entities and register them
  for _, surface in pairs(game.surfaces) do
    -- Register all toxic dumps
    for _, entity in pairs(surface.find_entities_filtered({ name = TOXIC_DUMP_NAME })) do
      AddToxicDump(entity)
    end
    -- Register all pollution collectors
    for _, entity in pairs(surface.find_entities_filtered({ name = POLLUTION_COLLECTOR_NAME })) do
      AddPollutionCollector(entity)
    end
    -- Register xenomass loot entities (disabled domesticated nest feature)
    for _, entity in
      pairs(surface.find_entities_filtered({ name = { "red-xenomass", "blue-xenomass" } }))
    do
      storage.spilledLoot[entity] = game.forces.neutral
    end
  end
end

--====================--
-- Event Handlers     --
--====================--

---Handle entity construction (by player or robot)
---Registers toxic dumps and pollution collectors when built
---@param event EventData Event data containing created_entity
function OnBuiltEntity(event)
  local entity = event.created_entity

  -- Defensive check: ensure entity exists and is valid
  if not entity or not entity.valid then
    return
  end

  if IsToxicDump(entity) then
    AddToxicDump(entity)
  end
  if IsPollutionCollector(entity) then
    AddPollutionCollector(entity)
  end
end

---Handle entity removal (mining, destruction, death)
---Disperses stored pollution before entity is removed
---@param event EventData Event data containing entity
function OnEntityPreRemoved(event)
  if event.entity then
    if IsToxicDump(event.entity) then
      RemoveToxicDump(event.entity)
    elseif IsPollutionCollector(event.entity) then
      RemovePollutionCollector(event.entity)
    else
      -- For any other entity with fluid, disperse pollution to prevent deletion
      DisperseCollectedPollution(event.entity, event.entity.surface, event.entity.position)
    end
  end
end

---Main tick handler - processes periodic updates
---Different systems run at different intervals to balance performance
---@param event EventData Event data containing tick number
function OnTick(event)
  -- Process toxic dumps every 30 seconds (1800 ticks)
  if game.tick % TOXIC_DUMP_INTERVAL == 0 then
    OnTick_ToxicDumps(event)
  end
  -- Process pollution collectors based on mod settings (default: every 60 ticks)
  if game.tick % settings.global["zpollution-collection-interval"].value == 0 then
    OnTick_PollutionCollectors(event)
  end
end

--===================--
-- Utility Functions --
--===================--

---Compare entity positions to check if they match
---Used for finding entities in the global tracking tables
---@param entity LuaEntity The entity to compare
---@param _DatabaseEntity table Table with position and surface fields
---@return boolean True if positions match
function IsPositionEqual(entity, _DatabaseEntity)
  if not entity or not entity.valid or not _DatabaseEntity then
    return false
  end
  --error("Is surface equal: "..tostring(entity.surface == _DatabaseEntity.surface).."\nIs Xpos equal: "..tostring(entity.position.x == _DatabaseEntity.position.x).."\nIs Ypos equal: "..tostring(entity.position.y == _DatabaseEntity.position.y).."\n\nSurface: "..tostring(entity.surface).." == "..tostring(_DatabaseEntity.surface).." ("..tostring(entity.position.x)..", "..tostring(entity.position.y)..") == ("..tostring(_DatabaseEntity.position.x)..", "..tostring(_DatabaseEntity.position.y)..")")
  return entity.surface == _DatabaseEntity.surface
    and entity.position.x == _DatabaseEntity.position.x
    and entity.position.y == _DatabaseEntity.position.y
end

--[[
-- Disabled: Recipe-based pollution calculation (kept for reference)
local pollutionPerRecipe = nil
function GetPollutionPerRecipe()
  if pollutionPerRecipe then return pollutionPerRecipe end
  for k, ingredient in pairs(game.players[1].force.recipes["liquify-pollution"].ingredients) do
    if ingredient.name == POLLUTED_AIR_NAME then
      pollutionPerRecipe = ingredient.amount
      return pollutionPerRecipe
    end
  end
end
--]]

--====================--
-- Loot Functionality --
--====================--

---Handle entity death and spawn xenomass loot from aliens
---This system rewards players for killing biters with blue/red xenomass items
---@param event EventData Event data containing entity that died
function EntityDied(event)
  local alien = event.entity
  --log(alien.name .. " died in force " .. alien.force.name)

  -- Only process alien entities
  if not IsAlienForce(alien) then
    return
  end

  -- Initialize globals if needed
  if storage.nestsKilled == nil then
    storage.nestsKilled = 0
  end
  if storage.spilledLoot == nil then
    storage.spilledLoot = {}
  end
  if storage.lootToCheck == nil then
    storage.lootToCheck = {}
  end

  local loot = { name = "", count = 0 }
  local quantity = 0.0

  -- Calculate loot based on entity type
  if alien.type == "unit" then
    -- Biters drop blue xenomass based on settings
    local blueAverage = settings.global["zpollution-blue-per-alien"].value
    --[[
    -- Disabled: Rampant mod compatibility (kept for reference)
    if mods and mods["Rampant"] then
      blueAverage = blueAverage * 0.5
    end
    --]]
    if blueAverage >= 1 then
      -- Random drop with average based on settings
      quantity = 2 * math.random() * blueAverage
      loot = { name = "blue-xenomass", count = math.floor(quantity + 0.5) }
    elseif blueAverage > math.random() then
      -- Fractional chance for single item
      loot = { name = "blue-xenomass", count = 1 }
    end
  elseif alien.type == "turret" then
    -- Worm turrets always drop blue xenomass
    quantity = 2 * math.random() * 20
    loot = { name = "blue-xenomass", count = math.floor(quantity + 0.5) }
  elseif alien.type == "unit-spawner" then
    -- Spawners drop red xenomass, amount decreases with each nest killed
    storage.nestsKilled = storage.nestsKilled + 1
    quantity = settings.global["zpollution-red-per-alien"].value / storage.nestsKilled
    loot = { name = "red-xenomass", count = math.ceil(quantity) }
  end

  --log(create " .. quantity .. " xenomass")

  -- Check if killed by artillery (for special handling)
  local isArtillery = (event.cause ~= nil)
    and (
      event.cause.type == "artillery-wagon"
      or event.cause.type == "artillery-turret"
      or event.cause.type == "artillery-projectile"
    )

  -- Spawn loot if any was calculated
  if loot.count >= 1 then
    if isArtillery then
      -- Artillery kills assign loot to the force
      if isArtillery then
        log(
          event.cause.type .. " from force " .. event.force.name .. " killed " .. alien.name .. "."
        )
      end
      -- Factorio 2.0+ API: Create ItemStackDefinition with type field
      alien.surface.spill_item_stack({
        position = alien.position,
        stack = { type = "item", name = loot.name, count = loot.count },
        force = alien.force,
      })
      return
    else
      -- Normal kills spawn neutral loot
      -- Factorio 2.0+ API: Create ItemStackDefinition with type field
      alien.surface.spill_item_stack({
        position = alien.position,
        stack = { type = "item", name = loot.name, count = loot.count },
        force = nil,
      })
    end
  end
end

---Check if an entity belongs to an alien force
---Supports vanilla enemy force and Biter Factions mod
---@param entity LuaEntity The entity to check
---@return boolean True if entity is from alien force
function IsAlienForce(entity)
  if not entity or not entity.valid or not entity.force then
    return false
  end

  local force_name = entity.force.name

  -- Vanilla biters
  if force_name == "enemy" then
    return true
  end

  -- Biter factions mod compatibility (Factorio 2.0 API: use mods table instead of active_mods)
  if mods and mods["biter_factions"] then
    return string.find(force_name, "biter_faction") ~= nil
  end

  return false
end
--=================================--
-- Pollution Destruction Functions --
--=================================--

---Convert stored pollution fluids back into air pollution when entities are destroyed
---This prevents players from deleting pollution by simply destroying fluid-containing entities
---@param entity LuaEntity The entity being destroyed
---@param surface LuaSurface The surface to pollute
---@param position MapPosition The position to release pollution
function DisperseCollectedPollution(entity, surface, position)
  if entity.fluidbox then
    -- Check all fluidboxes in the entity
    for k = 1, #entity.fluidbox, 1 do
      if entity.fluidbox[k] then
        local storedFluid = entity.fluidbox[k]
        --error("Fluid Name: "..tostring(entity.fluidbox[k].name))
        --error("Fluid Name: "..tostring(storedFluid.name))
        -- Convert fluid to pollution and release it
        ConvertFluidToPollution(surface, position, storedFluid.name, storedFluid.amount, true)
        -- Empty the fluidbox
        storedFluid.amount = 0.0001
        entity.fluidbox[k] = storedFluid
      end
    end
  end
end

---Convert pollution fluids to actual air pollution
---@param surface LuaSurface The surface to pollute
---@param position MapPosition The position to release pollution
---@param _Type string The fluid type name
---@param _Amount number The amount of fluid
---@param _DoDisperse boolean Whether to actually release the pollution
---@return number The amount of pollution that would be/was released
function ConvertFluidToPollution(surface, position, _Type, _Amount, _DoDisperse)
  _DoDisperse = _DoDisperse or false
  local convertedAmount = _Amount

  if _Type == POLLUTED_AIR_NAME then
    -- Direct conversion: 1 polluted-air = EMISSIONS_PER_AIR pollution
    convertedAmount = _Amount * EMISSIONS_PER_AIR
  elseif _Type == TOXIC_SLUDGE_NAME then
    -- Toxic sludge is more concentrated
    convertedAmount = _Amount * EMISSIONS_PER_AIR * AIR_PER_SLUDGE
  else
    -- Not a pollution fluid, don't disperse
    _DoDisperse = false
  end

  if _DoDisperse then
    surface.pollute(position, convertedAmount)
  end
  return convertedAmount
end

--======================--
-- Toxic Dump Functions --
--======================--

---Add a toxic dump to global tracking
---@param entity LuaEntity The toxic dump entity to track
function AddToxicDump(entity)
  table.insert(storage.toxicDumps, { position = entity.position, surface = entity.surface })
end

---Remove a toxic dump from global tracking and disperse its contents
---@param entity LuaEntity The toxic dump entity to remove
function RemoveToxicDump(entity)
  for key, _DatabaseEntity in pairs(storage.toxicDumps) do
    if IsPositionEqual(entity, _DatabaseEntity) then
      DisperseCollectedPollution(entity, _DatabaseEntity.surface, entity.position)
      table.remove(storage.toxicDumps, key)
      break
    end
  end
end

---Check if an entity is a toxic dump
---@param entity LuaEntity The entity to check
---@return boolean True if entity is a toxic dump
function IsToxicDump(entity)
  if not entity or not entity.valid then
    return false
  end
  return entity.name == TOXIC_DUMP_NAME
end

---Process all toxic dumps each tick interval
---Dumps release stored pollution fluids into the air with visual effects
---@param event EventData Event data from on_tick
function OnTick_ToxicDumps(event)
  if storage.toxicDumps == nil or not next(storage.toxicDumps) then
    return
  end

  for k, v in pairs(storage.toxicDumps) do
    -- Find the toxic dump entity at the stored position
    local entities = v.surface.find_entities_filtered({
      area = {
        { v.position.x - 0.25, v.position.y - 0.25 },
        {
          v.position.x + 0.25,
          v.position.y + 0.25,
        },
      },
      name = TOXIC_DUMP_NAME,
    })

    for _, entity in pairs(entities) do
      if
        entity
        and entity.fluidbox
        and entity.fluidbox[1]
        and (
          entity.fluidbox[1].name == POLLUTED_AIR_NAME
          or entity.fluidbox[1].name == TOXIC_SLUDGE_NAME
        )
      then
        local capacity = entity.fluidbox.get_capacity(1)
        local storedFluid = entity.fluidbox[1]
        local fillPercent = storedFluid.amount / capacity

        -- Only dump if above minimum fill threshold and has enough fluid
        if fillPercent > TOXIC_DUMP_FILLPERCENT and storedFluid.amount > 1 then
          local pollutionToDump = storedFluid.amount

          -- Calculate how much to release based on fluid type and consume percentage
          if storedFluid.name == POLLUTED_AIR_NAME then
            pollutionToDump = storedFluid.amount
              * (1 - (TOXIC_DUMP_CONSUME_PERCENT / AIR_PER_SLUDGE))
          elseif storedFluid.name == TOXIC_SLUDGE_NAME then
            pollutionToDump = storedFluid.amount * (1 - TOXIC_DUMP_CONSUME_PERCENT)
          end

          -- Release pollution into the air
          ConvertFluidToPollution(
            v.surface,
            entity.position,
            storedFluid.name,
            pollutionToDump,
            true
          )

          -- Empty the tank
          storedFluid.amount = 0.0001
          entity.fluidbox[1] = storedFluid

          -- Create visual smoke effects
          local smokeNum = math.max(math.random(TOXIC_DUMP_SMOKE_MIN, TOXIC_DUMP_SMOKE_MAX), 1)
          for i = 1, smokeNum, 1 do
            v.surface.create_trivial_smoke({
              name = "dump-smoke",
              position = {
                entity.position.x + math.random(-0.75, 0.75),
                entity.position.y + math.random(-0.75, 0.75),
              },
            })
          end

          -- Create toxic cloud entities based on fill percentage
          local cloudToUse = TOXIC_DUMP_CLOUD_SMALL
          if fillPercent > TOXIC_DUMP_CLOUD_LARGE_PERCENT then
            cloudToUse = TOXIC_DUMP_CLOUD_LARGE
          elseif fillPercent > TOXIC_DUMP_CLOUD_MEDIUM_PERCENT then
            cloudToUse = TOXIC_DUMP_CLOUD_MEDIUM
          end

          -- Spawn toxic clouds
          for i = 1, math.max(math.ceil(fillPercent * TOXIC_DUMP_CLOUDS), 1), 1 do
            v.surface.create_entity({
              name = cloudToUse,
              amount = 1,
              force = entity.force,
              position = { entity.position.x + 0.01, entity.position.y + 0.01 },
            })
          end
        end
      end
    end
  end
end

--===============================--
-- Pollution Collector Functions --
--===============================--

---Check if an entity is a pollution collector
---@param entity LuaEntity The entity to check
---@return boolean True if entity is a pollution collector
function IsPollutionCollector(entity)
  if not entity or not entity.valid then
    return false
  end
  return entity.name == POLLUTION_COLLECTOR_NAME
end

---Add a pollution collector to global tracking
---@param entity LuaEntity The pollution collector entity to track
function AddPollutionCollector(entity)
  storage.collectors[entity.unit_number] = entity
end

---Remove a pollution collector from tracking and disperse its contents
---@param entity LuaEntity The pollution collector entity to remove
function RemovePollutionCollector(entity)
  DisperseCollectedPollution(entity, entity.surface, entity.position)
  storage.collectors[entity.unit_number] = nil
end

---Collect pollution from surrounding chunks and convert to polluted-air fluid
---Collectors pull pollution from a 3x3 grid of chunks centered on their position
---@param entity LuaEntity The pollution collector entity
---@param surface LuaSurface The surface to collect pollution from
function CollectPollution(entity, surface)
  -- Get or initialize fluid contents
  local contents = entity.fluidbox[1]
  if contents == nil then
    contents = {
      name = POLLUTED_AIR_NAME,
      amount = 0.0000001,
    }
  end

  --log("collecting at " .. GetPositionString(entity))

  -- Calculate remaining capacity in pollution units
  local capacityRemaining = (entity.fluidbox.get_capacity(1) - contents.amount) * EMISSIONS_PER_AIR
  if capacityRemaining <= 0 then
    return
  end

  -- Get pollution levels from 3x3 grid of neighboring chunks
  local neighbors = GetPollutionNeighbors(surface, entity.position)

  -- Calculate total collectible pollution
  local maxCollection = 0
  for x = -1, 1 do
    for y = -1, 1 do
      maxCollection = maxCollection + neighbors[x][y].maxCollection
    end
  end
  --log("    maxCollection=" .. maxCollection)
  if maxCollection <= 0 then
    return
  end

  -- Scale collection if we can't fit all the pollution
  local collectionMultiplier = 1
  if capacityRemaining < maxCollection then
    collectionMultiplier = capacityRemaining / maxCollection
  end

  -- Collect pollution from each neighboring chunk
  for x = -1, 1 do
    for y = -1, 1 do
      local emissionChange = collectionMultiplier * neighbors[x][y].maxCollection
      surface.pollute(neighbors[x][y].position, -1 * emissionChange) -- Remove pollution
      contents.amount = contents.amount + (emissionChange / EMISSIONS_PER_AIR) -- Add fluid
    end
  end

  entity.fluidbox[1] = contents
end

---Get pollution data for neighboring chunks around a position
---Creates a 3x3 grid of chunk data, each chunk is 32x32 tiles
---@param surface LuaSurface The surface to check
---@param position MapPosition The center position
---@return table 2D array of neighbor data with pollution levels and max collection
function GetPollutionNeighbors(surface, position)
  local neighbors = {}
  for nearX = -1, 1 do
    neighbors[nearX] = {}
    for nearY = -1, 1 do
      neighbors[nearX][nearY] = {}
      -- Calculate chunk center position (chunks are 32x32 tiles)
      neighbors[nearX][nearY].position =
        { x = position.x + 32 * nearX, y = position.y + 32 * nearY }
      neighbors[nearX][nearY].pollution = surface.get_pollution(neighbors[nearX][nearY].position)
      -- Calculate how much we can collect: (current - minimum) / collectors_needed
      neighbors[nearX][nearY].maxCollection = math.max(
        0,
        (
          neighbors[nearX][nearY].pollution
          - settings.global["zpollution-pollution-remaining"].value
        ) / settings.global["zpollution-collectors-required"].value
      )
    end
  end
  return neighbors
end

---Process all pollution collectors each tick interval
---@param event EventData Event data from on_tick
function OnTick_PollutionCollectors(event)
  if storage.collectors == nil or not next(storage.collectors) then
    return
  end
  for unit_number, entity in pairs(storage.collectors) do
    if entity.valid then
      CollectPollution(entity, entity.surface)
    else
      -- Entity no longer exists, remove from tracking
      storage.collectors[unit_number] = nil
    end
  end
end
