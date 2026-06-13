-----------------------------------
-- Ascension_Aura.lua
-- A cosmetic, always-on "aura" for ascended players -- the Ascension analogue
-- of Master-status stars. While an ascended player is in a zone, they
-- periodically emit a visual via independentAnimation, which pushes to
-- CHAR_INRANGE_SELF -- so EVERYONE nearby sees it, not just the player. Because
-- the effect plays ON the player it follows them with zero tracking and never
-- touches the pet slot (SMN/BST/DRG/PUP/GEO are unaffected).
--
-- Tier comes from the account-wide lifetime ascension count
-- (Prestige_Total_Ascensions, stamped by Prestige_System.tryAscend). Higher
-- tiers use a flashier effect and/or a faster pulse.
--
-- *** TUNING THE LOOK (do this in-game) ***
-- The animId / mode values in TIERS are PLACEHOLDERS. Audition effects live with
-- the GM command:  !aura <animId> <mode>  (modules/custom/commands/aura.lua).
-- Find the ones you like, drop them into TIERS, redeploy + reload.
--
-- LIFECYCLE
-- Re-armed on every xi.player.onGameIn (login + each zone-in). Each arming bumps
-- a per-character generation counter (genByName, in module memory); the pulse
-- loop captures its generation and stops the instant a newer arming supersedes
-- it -- so a zone change can never leave two loops stacked, even if the engine
-- leaked a pending timer across the zone.
--
-- Lives in modules/custom/ (survives upstream LSB merges) and auto-loads via the
-- `custom/lua/` folder entry in modules/init.txt -- no registration line needed.
-----------------------------------
require('modules/module_utils')

local m = Module:new('ascension_aura')

-- Account-wide lifetime ascensions across all jobs (set in Prestige_System
-- tryAscend(); the same value the achievements feed reads).
local ASCENSION_VAR = 'Prestige_Total_Ascensions'

-- Tiers in ASCENDING `min` order; the highest one whose `min` the player meets
-- wins. animId + mode feed independentAnimation(); intervalMs is the pulse gap.
-- >>> PLACEHOLDER VISUALS -- tune animId/mode in-game with the !aura command. <<<
local TIERS =
{
    { min =  1, animId = 122, mode = 0, intervalMs = 12000, label = 'Ascendant'    },
    { min =  5, animId = 122, mode = 0, intervalMs =  9000, label = 'Exalted'      },
    { min = 10, animId = 252, mode = 4, intervalMs =  7000, label = 'Transcendent' },
}

-- First pulse fires this long after a zone-in, so it lands after the zone
-- settles rather than mid-load.
local FIRST_PULSE_MS = 4000

-- Per-character generation, keyed by NAME (stable across zones, unlike the
-- entity id). Bumped on each onGameIn; only the loop holding the current
-- generation keeps pulsing.
local genByName = {}

local function tierFor(count)
    local chosen = nil
    for _, t in ipairs(TIERS) do
        if count >= t.min then
            chosen = t
        end
    end
    return chosen
end

-- One pulse, then re-arm -- unless a newer arming has superseded this loop.
local function pulse(player, name, gen)
    if not player or genByName[name] ~= gen then
        return  -- entity gone, or superseded by a fresher onGameIn -- stop.
    end

    local tier = tierFor(player:getCharVar(ASCENSION_VAR) or 0)
    if not tier then
        return  -- no longer qualifies (shouldn't change mid-session) -- stop.
    end

    player:independentAnimation(player, tier.animId, tier.mode)
    player:timer(tier.intervalMs, function(p) pulse(p, name, gen) end)
end

-----------------------------------
-- Kick (or re-kick) the aura loop on login and every zone-in. A zone-in builds
-- a fresh entity, so we bump the generation and start a new loop; any stale
-- loop self-terminates on its next tick via the generation guard.
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if not tierFor(player:getCharVar(ASCENSION_VAR) or 0) then
        return  -- not ascended -- no aura to show.
    end

    local name = player:getName()
    local gen  = (genByName[name] or 0) + 1
    genByName[name] = gen
    player:timer(FIRST_PULSE_MS, function(p) pulse(p, name, gen) end)
end)

return m
