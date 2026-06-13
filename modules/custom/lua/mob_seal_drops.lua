-----------------------------------
-- mob_seal_drops.lua
-- Server-wide gear-vendor seal drops. Every mob killed by a player has a
-- small, level-tiered chance to yield a Hunting League seal -- the currency
-- the Armor / Weapons NPCs (!hunt) take. NMs are the prime source.
--
--   9539 Beastmens Medal = BRONZE tier (entry gear,  ~12 / piece)
--   9541 Kindreds Medal  = SILVER tier (mid gear,    ~25 / piece)
--   9543 Demons Medal    = GOLD   tier (BiS gear,  50-500 / piece)
--
-- Implemented as an override of the GLOBAL xi.mob.onMobDeathEx hook, so it
-- covers EVERY mob with zero per-mob droplist edits. The custom logic is
-- pcall-wrapped because this runs on every mob death server-wide -- a stray
-- error must never spam the log or interrupt the stock death handler.
--
-- TUNING: everything is in the TIERS table + NM_CHANCE_MULT below. `chance`
-- is a PERCENT and supports two decimals (e.g. 0.25 = a quarter percent).
-----------------------------------
require('modules/module_utils')

local m = Module:new('mob_seal_drops')

local BEASTMENS = 9539  -- bronze
local KINDREDS  = 9541  -- silver
local DEMONS    = 9543  -- gold

-- Checked HIGH -> LOW by mob level; the first bracket the mob's level meets
-- is its tier. `base` = the common seal for that bracket; `rare` (optional) =
-- a rarer roll for the next tier up, so every bracket has a jackpot.
local TIERS =
{
    { minLvl = 125, base = { id = KINDREDS,  name = 'Kindreds Medal',  chance = 5.0 },
                    rare = { id = DEMONS,    name = 'Demons Medal',    chance = 0.5 } },
    { minLvl =  90, base = { id = KINDREDS,  name = 'Kindreds Medal',  chance = 3.0 },
                    rare = { id = DEMONS,    name = 'Demons Medal',    chance = 0.2 } },
    { minLvl =  50, base = { id = BEASTMENS, name = 'Beastmens Medal', chance = 6.0 },
                    rare = { id = KINDREDS,  name = 'Kindreds Medal',  chance = 1.0 } },
    { minLvl =   1, base = { id = BEASTMENS, name = 'Beastmens Medal', chance = 4.0 } },
}

-- NMs are the prime seal farm: every chance above is multiplied by this.
local NM_CHANCE_MULT = 4

-- Percent roll with 2-decimal resolution (chance 0.5 -> 50 / 10000).
local function rolls(chancePercent)
    return math.random(10000) <= math.floor((chancePercent or 0) * 100 + 0.5)
end

local function grant(player, seal)
    if pcall(function() player:addItem(seal.id, 1) end) then
        player:printToPlayer(string.format('The fallen foe yields a %s!', seal.name), xi.msg.channel.SYSTEM_3)
    end
end

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    -- All custom logic guarded: this fires on EVERY mob death server-wide.
    pcall(function()
        if not isKiller or player == nil then return end
        if player:getObjType() ~= xi.objType.PC then return end

        local lvl  = mob:getMainLvl() or 0
        local mult = mob:isNM() and NM_CHANCE_MULT or 1

        local tier
        for _, t in ipairs(TIERS) do
            if lvl >= t.minLvl then
                tier = t
                break
            end
        end
        if not tier then return end

        -- Roll the rarer (better) seal first, then the common one.
        if tier.rare and rolls(tier.rare.chance * mult) then
            grant(player, tier.rare)
        elseif rolls(tier.base.chance * mult) then
            grant(player, tier.base)
        end
    end)
end)

return m
