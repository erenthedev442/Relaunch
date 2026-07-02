-----------------------------------
-- trust_progression_cap.lua  (relaunch)
--
-- SUMMON-COUNT progression for trusts: every trust stays learnable from day 1
-- (Character_Upgrader's grant-all is untouched), but HOW MANY you can field at
-- once climbs the server's content ladder -- the same five gates as the
-- Augment Tier system (xi.augmentTiers, published by Augment_Moogle.lua):
--
--   Tier 0  fresh character                          -> 2 trusts
--   Tier 1  slay 10 custom NMs                       -> 3 trusts
--   Tier 2  Hunting League Rank 5                    -> 4 trusts
--   Tier 3  Voidspire floor 10 + all GM wave clears  -> 5 trusts (max)
--   Tier 4+                                          -> 5 trusts
--
-- HOW: a pre-check in front of retail xi.trust.canCast (scripts/globals/
-- trust.lua). If the caster's party already fields their tier's cap, block
-- with the retail "maximum number of alter egos" line + a ladder hint.
-- Otherwise fall through to super() -- ALL retail checks (battlefield rules,
-- duplicates, party size 6, enmity) still apply.
--
-- Retail's own cap is 3/4/5 gated by the RoV Rhapsody key items (WHITE =
-- 4th, CRIMSON = 5th). So those retail caps can never bind BELOW the ladder,
-- the pre-check grants the KI the moment the tier entitles the extra slot
-- (idempotent, and harmless on chars that already own them).
--
-- Count semantics mirror retail: trusts are counted across the CASTER's
-- party, and the cap applied is the CASTER's tier -- identical to how the
-- retail KI caps behave.
--
-- Pure Lua override -> needs one map restart, no rebuild. Tune the ladder in
-- TIER_TRUST_CAP below.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')

local m = Module:new('trust_progression_cap')

-- Max simultaneous trusts per Progression (Augment) Tier. TUNE HERE.
local TIER_TRUST_CAP = { [0] = 2, [1] = 3, [2] = 4, [3] = 5, [4] = 5, [5] = 5 }

m:addOverride('xi.trust.canCast', function(caster, spell, notAllowedTrustIds)
    if caster:isPC() and xi.augmentTiers then
        local tier = xi.augmentTiers.tierOf(caster)
        local cap  = TIER_TRUST_CAP[tier] or 5

        local numTrusts = 0
        for _, member in pairs(caster:getPartyWithTrusts()) do
            if member:getObjType() == xi.objType.TRUST then
                numTrusts = numTrusts + 1
            end
        end

        if numTrusts >= cap then
            caster:messageSystem(xi.msg.system.TRUST_MAXIMUM_NUMBER)

            -- Tell them what content buys the next slot (if any).
            local nextTier, nextCap
            for t = tier + 1, 5 do
                if (TIER_TRUST_CAP[t] or 5) > cap then
                    nextTier, nextCap = t, TIER_TRUST_CAP[t]
                    break
                end
            end
            if nextTier then
                local unlock
                for _, g in ipairs(xi.augmentTiers.gates) do
                    if g.tier == nextTier then
                        unlock = g.unlock
                    end
                end
                caster:printToPlayer(string.format(
                    '[Trusts] Tier %d fields up to %d trusts. Your %dth slot unlocks at Tier %d: %s.',
                    tier, cap, nextCap, nextTier, unlock or '???'),
                    xi.msg.channel.SYSTEM_3)
            end
            return -1
        end

        -- The tier entitles this many slots -- make sure retail's RoV key-item
        -- caps (3 base / WHITE 4th / CRIMSON 5th) can't bind below the ladder.
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
