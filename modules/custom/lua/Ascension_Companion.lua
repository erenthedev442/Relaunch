-----------------------------------
-- Ascension_Companion.lua
-- Gives ascended players a permanent "shadow companion" -- a small pet that
-- trails them around. This is the Ascension marker that lives ON
-- the character (the nameplate only exposes the locked master-star flag + a
-- title, both of which the admin ruled out).
--
-- Tier source: account-wide Prestige_Total_Ascensions (>0 = ascended).
--
-- Mechanism: spawns a pet (default DIABOLOS, the dark winged demon); the engine
-- makes pets auto-follow their owner. A keeper loop re-checks every CHECK_MS and
-- (re)spawns the companion ONLY when the player currently has NO pet, so it:
--   * survives zoning / death / despawn (it keeps coming back), and
--   * YIELDS to real job pets -- a SMN/BST/DRG/PUP/GEO who calls their own pet
--     simply replaces the companion; when they dismiss it, the companion returns
--     within CHECK_MS.
-- It's cosmetic: a non-pet job has no pet commands, so the avatar just idles and
-- follows (SMN avatars don't auto-assist -- they act only on Blood Pact orders).
--
-- Re-armed on every onGameIn (login + each zone-in) with a per-name generation
-- guard so stale loops self-terminate -- same pattern as the other Ascension hooks.
--
-- *** TUNING (swap the model) ***  COMPANION_PET takes any xi.petId. Options:
--   LYNX_FAMILIAR / HARE_FAMILIAR / SHEEP_FAMILIAR / etc. - small ground-level
--     BST jug-pet animals (default). Full list: scripts/enum/pet_id.lua.
--     NOTE: jug pets follow AND auto-engage in combat (avatars only follow).
--   CARBUNCLE / CAIT_SITH / DIABOLOS - SMN avatars (bigger, cosmetic-only)
-- Change the one constant below, redeploy, restart.
--
-- *** OPT-OUT ***  A character skips the companion entirely if its name is in
-- OPTED_OUT below, or if it sets the AscensionCompanion_Off charVar (any player
-- can self-exempt with: !setplayervar AscensionCompanion_Off 1).
--
-- Override module -> needs a server RESTART to take effect (a hot file-reload
-- does NOT re-apply onGameIn overrides). Lives in modules/custom/ (merge-safe).
-----------------------------------
require('modules/module_utils')

local m = Module:new('ascension_companion')

local ASCENSION_VAR = 'Prestige_Total_Ascensions'
local OPTOUT_VAR    = 'AscensionCompanion_Off'       -- per-char opt-out charVar (>0 = no companion)
local OPTED_OUT     = { ['Jbae'] = true }            -- hard opt-out by character name, e.g. { ['Name'] = true }
local COMPANION_PET = xi.petId.LYNX_FAMILIAR -- small BST jug-pet cat; swap to taste (see header)
local CHECK_MS      = 10000              -- keeper re-check interval
local FIRST_MS      = 5000               -- first spawn, after a zone-in settles

local genByName = {}

local function isAscended(player)
    return (player:getCharVar(ASCENSION_VAR) or 0) > 0
end

-- Per-character opt-out: a hard-coded name (admin request) OR the AscensionCompanion_Off
-- charVar > 0 (any player can self-exempt with !setplayervar AscensionCompanion_Off 1).
local function optedOut(player)
    return OPTED_OUT[player:getName()] == true
        or (player:getCharVar(OPTOUT_VAR) or 0) > 0
end

local function keeper(player, name, gen)
    if not player or genByName[name] ~= gen then
        return  -- entity gone, or superseded by a newer onGameIn -- stop.
    end

    if optedOut(player) then
        return  -- opted out (name or charVar) -- stop the keeper, no respawn.
    end

    -- (Re)spawn only when they have NO pet (yields to real job pets) and pets are
    -- allowed here (skips Mog House / cutscenes / no-pet zones). pcall guards any
    -- transient-state spawn failure.
    if isAscended(player) and not player:hasPet() and player:canUseMisc(xi.zoneMisc.PET) then
        pcall(function() player:spawnPet(COMPANION_PET) end)
    end

    player:timer(CHECK_MS, function(p) keeper(p, name, gen) end)
end

m:addOverride('xi.player.onGameIn', function(player, gameLogin, zoning)
    super(player, gameLogin, zoning)

    if optedOut(player) then
        return  -- opted out of the shadow companion (name or charVar) -- no companion.
    end
    if not isAscended(player) then
        return  -- not ascended -- no companion.
    end

    local name = player:getName()
    local gen  = (genByName[name] or 0) + 1
    genByName[name] = gen
    player:timer(FIRST_MS, function(p) keeper(p, name, gen) end)
end)

return m
