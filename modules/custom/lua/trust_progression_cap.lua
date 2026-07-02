-----------------------------------
-- trust_progression_cap.lua  (relaunch)
--
-- SUMMON-COUNT progression for trusts: every trust stays learnable from day 1
-- (Character_Upgrader's grant-all is untouched), but HOW MANY you can field at
-- once climbs its OWN content ladder -- deliberately DIFFERENT content from
-- BOTH the Augment Tier gates (NM kills / HL rank / Voidspire+GM / Divergence
-- / Maat) AND the five Prime Weapon trials (Abyssea collectibles / Endless
-- Tower / HL voucher / Job Mastery / Aht Urhgan currencies):
--
--   fresh character                          -> 2 trusts
--   earn 1,200 lifetime Unity accolades      -> 3 trusts (Unity_Accolades_Lifetime,
--                                                ~3 tier-1 Wanted NM kills)
--   clear a tier-5 Voidwatch rift            -> 4 trusts (Voidwatch_Tier)
--   raise your Adventuring Fellow to Lv 60   -> 5 trusts (Fellow_Level)
--
-- Theme: your allies earn your allies -- hunt with the Concord, close the
-- rifts, raise your companion, and the full trust party follows.
-- The ladder is CONSECUTIVE (like the augment gates): a Lv60 Fellow without
-- the Voidwatch tier still fields 3.
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
    { cap = 3, unlock = 'earn 1,200 lifetime Unity accolades (Wanted NM hunts)',
      check = function(p) return (p:getCharVar('Unity_Accolades_Lifetime') or 0) >= 1200 end },
    { cap = 4, unlock = 'clear a tier-5 Voidwatch rift',
      check = function(p) return (p:getCharVar('Voidwatch_Tier') or 0) >= 5 end },
    { cap = 5, unlock = 'raise your Adventuring Fellow to level 60',
      check = function(p) return (p:getCharVar('Fellow_Level') or 0) >= 60 end },
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
