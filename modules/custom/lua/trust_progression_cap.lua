-----------------------------------
-- trust_progression_cap.lua  (relaunch)
--
-- SUMMON-COUNT progression for trusts: every trust stays learnable from day 1
-- (Character_Upgrader's grant-all is untouched), but HOW MANY you can field at
-- once climbs its OWN content ladder -- deliberately DIFFERENT content from
-- the Augment Tier ladder, and all three gates are the server's solo-arena
-- systems ("prove you can fight without a full party to earn a bigger one"):
--
--   fresh character                       -> 2 trusts
--   win 3 Colosseum matches               -> 3 trusts   (Col_Wins)
--   reach Endless Tower floor 10          -> 4 trusts   (Tower_Best_Floor)
--   clear The Gauntlet (all 10 levels)    -> 5 trusts   (Gauntlet_Clears)
--
-- The ladder is CONSECUTIVE (like the augment gates): a Gauntlet clear
-- without the Tower floor still fields 3.
--
-- HOW: a pre-check in front of retail xi.trust.canCast (scripts/globals/
-- trust.lua). If the caster's party already fields their cap, block with the
-- retail "maximum number of alter egos" line + a hint naming the content that
-- buys the next slot. Otherwise fall through to super() -- ALL retail checks
-- (battlefield rules, duplicates, party size 6, enmity) still apply.
--
-- Retail's own cap is 3/4/5 gated by the RoV Rhapsody key items (WHITE =
-- 4th, CRIMSON = 5th). So those retail caps can never bind BELOW the ladder,
-- the pre-check grants the KI the moment the ladder entitles the extra slot
-- (idempotent, and harmless on chars that already own them).
--
-- Count semantics mirror retail: trusts are counted across the CASTER's
-- party, and the cap applied is the CASTER's ladder -- identical to how the
-- retail KI caps behave. Cast-time check, so it applies to existing
-- characters automatically.
--
-- Pure Lua override -> needs one map restart, no rebuild. Tune the gates and
-- counts in TRUST_GATES / BASE_CAP below.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')

local m = Module:new('trust_progression_cap')

local BASE_CAP = 2

-- Each gate buys the next simultaneous-trust slot. TUNE HERE.
local TRUST_GATES =
{
    { cap = 3, unlock = 'win 3 Colosseum matches',
      check = function(p) return (p:getCharVar('Col_Wins') or 0) >= 3 end },
    { cap = 4, unlock = 'reach Endless Tower floor 10',
      check = function(p) return (p:getCharVar('Tower_Best_Floor') or 0) >= 10 end },
    { cap = 5, unlock = 'clear The Gauntlet (all 10 levels)',
      check = function(p) return (p:getCharVar('Gauntlet_Clears') or 0) >= 1 end },
}

local function trustCap(player)
    local cap = BASE_CAP
    for _, g in ipairs(TRUST_GATES) do
        if g.check(player) then
            cap = g.cap
        else
            break
        end
    end
    return cap
end

-- Next gate the player hasn't cleared (nil at max). For the hint message.
local function nextGate(player)
    for _, g in ipairs(TRUST_GATES) do
        if not g.check(player) then
            return g
        end
    end
    return nil
end

-- Shared for status displays (e.g. !augstats-style commands or NPCs).
xi.trustCap =
{
    capOf    = trustCap,
    nextGate = nextGate,
    gates    = TRUST_GATES,
    base     = BASE_CAP,
}

m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    if caster:isPC() then
        local cap = trustCap(caster)

        local numTrusts = 0
        for _, member in pairs(caster:getPartyWithTrusts()) do
            if member:getObjType() == xi.objType.TRUST then
                numTrusts = numTrusts + 1
            end
        end

        if numTrusts >= cap then
            caster:messageSystem(xi.msg.system.TRUST_MAXIMUM_NUMBER)
            local g = nextGate(caster)
            if g then
                caster:printToPlayer(string.format(
                    '[Trusts] You can field %d trusts. Your %dth slot: %s.',
                    cap, g.cap, g.unlock), xi.msg.channel.SYSTEM_3)
            end
            return -1
        end

        -- The ladder entitles this many slots -- make sure retail's RoV
        -- key-item caps (3 base / WHITE 4th / CRIMSON 5th) can't bind below it.
        if cap >= 4 and not caster:hasKeyItem(xi.ki.RHAPSODY_IN_WHITE) then
            caster:addKeyItem(xi.ki.RHAPSODY_IN_WHITE)
        end
        if cap >= 5 and not caster:hasKeyItem(xi.ki.RHAPSODY_IN_CRIMSON) then
            caster:addKeyItem(xi.ki.RHAPSODY_IN_CRIMSON)
        end
    end

    return super(caster, spell, notAllowedTrustIds)
end)

return m
