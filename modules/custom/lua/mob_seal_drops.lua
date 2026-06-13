-----------------------------------
-- mob_seal_drops.lua
-- Server-wide gear-vendor seal drops. EVERY mob killed by a player drops at
-- least one Hunting League seal, with an escalating quantity. The seal TYPE
-- scales with the mob's level (NMs bump up a tier); the QUANTITY follows the
-- owner-specified distribution below.
--
--   9539 Beastmens Medal = BRONZE tier (entry gear,  ~12 / piece)
--   9541 Kindreds Medal  = SILVER tier (mid gear,    ~25 / piece)
--   9543 Demons Medal    = GOLD   tier (BiS gear,  50-500 / piece)
--
-- QUANTITY distribution (independent rolls; the largest tier that procs wins,
-- floor 1):  100% -> 1 | 50% -> 2 | 33% -> 3 | 25% -> 4 | 5% -> 10
--
-- TYPE tiering (tune in baseTier / the SEALS table):
--   mob level <90  -> Beastmens (bronze)
--   mob level >=90 -> Kindreds  (silver)
--   any NM         -> +1 tier   (so a 90+ NM yields Demons / gold)
-- Gold is deliberately kept behind high-level NMs so the 100% faucet doesn't
-- flood the BiS economy. Bump baseTier to return 3 at some level if you want
-- regular high mobs to drop gold too.
--
-- Hooks the GLOBAL xi.mob.onMobDeathEx so it covers EVERY mob with no per-mob
-- droplist edits. The custom logic is pcall-wrapped because it runs on every
-- death server-wide -- a stray error must never spam the log or break the
-- stock death handler.
-----------------------------------
require('modules/module_utils')

local m = Module:new('mob_seal_drops')

-- Seal tiers, low -> high. Level picks the base index; NMs add +1 (capped).
local SEALS =
{
    { id = 9539, name = 'Beastmens Medal' },  -- 1 BRONZE
    { id = 9541, name = 'Kindreds Medal'  },  -- 2 SILVER
    { id = 9543, name = 'Demons Medal'    },  -- 3 GOLD
}

-- Mob level -> base tier index.
local function baseTier(lvl)
    if lvl >= 90 then
        return 2  -- silver
    end
    return 1      -- bronze
end

-- Only announce drops this size or larger (100% drop rate, so per-kill chat
-- would spam). Set to 5 => only the 10-jackpot announces; common 1-4 drops
-- land silently (the seals still appear in the player's inventory).
local ANNOUNCE_MIN = 5

-- Quantity roll. Each tier is an independent chance; the largest that procs
-- wins (floor 1). Matches: 100%->1, 50%->2, 33%->3, 25%->4, 5%->10.
local function rollQuantity()
    local qty = 1
    if math.random(100) <= 50 then qty = 2  end
    if math.random(100) <= 33 then qty = 3  end
    if math.random(100) <= 25 then qty = 4  end
    if math.random(100) <=  5 then qty = 10 end
    return qty
end

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    pcall(function()
        if not isKiller or player == nil then return end
        if player:getObjType() ~= xi.objType.PC then return end

        local tier = baseTier(mob:getMainLvl() or 0)
        if mob:isNM() then
            tier = math.min(tier + 1, #SEALS)
        end
        local seal = SEALS[tier]

        local qty = rollQuantity()
        if not pcall(function() player:addItem(seal.id, qty) end) then
            return  -- inventory full / add failed: skip silently
        end

        if qty >= 10 then
            player:printToPlayer(string.format('JACKPOT! The fallen foe yields %d %s!', qty, seal.name), xi.msg.channel.SYSTEM_3)
        elseif qty >= ANNOUNCE_MIN then
            player:printToPlayer(string.format('The fallen foe yields %d %s!', qty, seal.name), xi.msg.channel.SYSTEM_3)
        end
    end)
end)

return m
