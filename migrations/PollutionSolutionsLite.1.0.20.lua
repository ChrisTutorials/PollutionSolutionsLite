-- Migration for version 1.0.20: Unlock barrel recipes based on fluid-handling tech
--
-- This migration unlocks the base game's barreling recipes for polluted air and toxic sludge
-- if the player has already researched "fluid-handling" technology.
--
-- The barrel recipes are provided by the base game, not this mod.
-- We only enable them if the technology is researched.

for _, force in pairs(game.forces) do
  local technologies = force.technologies
  local recipes = force.recipes

  -- Safely check if recipes exist before modifying them
  -- (base game may not always have these recipes in all versions)
  if recipes["fill-polluted-air-barrel"] then
    recipes["fill-polluted-air-barrel"].enabled = technologies["fluid-handling"].researched
  end

  if recipes["empty-polluted-air-barrel"] then
    recipes["empty-polluted-air-barrel"].enabled = technologies["fluid-handling"].researched
  end

  if recipes["fill-toxic-sludge-barrel"] then
    recipes["fill-toxic-sludge-barrel"].enabled = technologies["fluid-handling"].researched
  end

  if recipes["empty-toxic-sludge-barrel"] then
    recipes["empty-toxic-sludge-barrel"].enabled = technologies["fluid-handling"].researched
  end
end
