-----------------------------------
-- RngOverhaul.lua
--
-- MASSIVE ranged-DD boost for the RANGER job (Legendary). Owner request 2026-06-21.
--
-- Retail RNG scales off RATT/RACC + shot speed + Double Shot, but against
-- Legendary's lv150-160 NMs (huge DEF/EVA) a stock Ranger falls behind the other
-- boosted jobs. This layers a big flat ranged bundle onto every MAIN-job RNG so
-- they shoot hard, fast, accurately and multi-shot often -- a dominant ranged DD,
-- the ranged counterpart to the SMN/BST overhauls.
--
-- WHAT IT GRANTS (main-job RNG only):
--   * RATT + RATTP     -> bigger every-shot damage AND bigger ranged WS (Last Stand,
--                         Trueflight, Jishnu's...). Ranged WS already ride the uncapped
--                         131k damage, so more RATT = more WS.
--   * RACC             -> land on Legendary's high-EVA endgame NMs.
--   * RANGED_DMG_RATING-> flat damage added to the base D of every shot (compounds w/ RATT).
--   * DAMAGE_LIMITP    -> +50% ranged pDIF CAP. The previous RATT/RATTP boosts were being
--                         clamped at this cap (physical_utilities.lua); raising it +50%
--                         (with RATTP lifted so the ratio reaches it) = +50% overall dmg on
--                         BOTH auto-attacks and ranged weaponskills. 2026-06-23 owner +50%.
--   * STORETP          -> more TP per shot = far more frequent weaponskills.
--   * SNAPSHOT + RAPID_SHOT -> faster / occasionally-instant shots = more sustained DPS.
--   * DOUBLE_SHOT_RATE -> Double Shot fires far more often (each extra arrow can WS-proc).
--
-- HOW IT STAYS APPLIED: re-laid on every onGameIn (login AND every zone-in), exactly
-- like CrossJob_TraitTrainer.lua -- a zone reload wipes in-memory standalone addMods
-- and onGameIn re-applies them, so they are always present and NEVER stack. Gated
-- strictly on getMainJob() == RNG, so /RNG subjobs and every other job are untouched.
-- Silent (no announce), per the server's silent-balance policy.
--
-- CAVEAT: a JOB CHANGE does not fire onGameIn, so a player who switches TO Ranger gets
-- the boost on their next zone or relog (not the instant they swap). Pure Lua, no SQL/C++.
-- New override module -> needs ONE map restart to register; after that the CONFIG block
-- is a hot-reload (scp + zone). Sibling of BstJugPetOverhaul.lua / avatar.lua.
-----------------------------------
require('modules/module_utils')

local m = Module:new('rng_overhaul')

-- == Tunables ================================================================
-- HARD ENGINE LIMIT (the Lant "permanently 1 R-atk" overflow): ranged attack is
-- computed in CBattleEntity::RATT() (battleentity.cpp:1200) and returned through
--   std::max<int16>(1, RATT + RATT*RATTP/100 + ...)
-- so the FINAL ranged attack is capped at int16 = 32,767, AND the Mod::RATT store
-- is itself int16. Therefore:
--   * the RATT mod (our flat + the player's gear) must stay < 32,767, and
--   * the final attack (RATT mod + skill + STR + RATTP%) must stay < 32,767,
-- or it WRAPS NEGATIVE and std::max floors it to 1. The old values (ratt 40000/
-- 80000, rattp 800/2100) blew past BOTH ceilings -> negative/garbage -> R-atk 1.
-- 28,000 flat RATT already MAXES ranged pDIF vs normal NM DEF; RNG's damage then
-- comes from that capped pDIF + RANGED_DMG_RATING + ranged WS (which ride the
-- uncapped 131k path) -- NOT from an impossible >32k attack number.
local RATT_CAP = 29000  -- ceiling for the RATT mod (base + gear); leaves headroom
                        -- for skill/STR so the final RATT() stays under int16.

local CONFIG =
{
    ratt            = 28000, -- Mod.RATT  (24)  : flat ranged attack, CLAMPED to RATT_CAP
    rattp           = 0,     -- Mod.RATTP (66)  : MUST be 0 -- it MULTIPLIES the whole
                             --                   ~28k attack and instantly overflows int16
    racc            = 4000,  -- Mod.RACC  (26)  : land on high-EVA Legendary NMs
    rangedDmgRating = 2000,  -- Mod.RANGED_DMG_RATING (376) : flat damage added to each shot
    damageLimit     = 600,   -- Mod.DAMAGE_LIMITP (1081) : pDIF cap 3.25*(100+600)/100 = 22.75x
    storeTP         = 100,   -- Mod.STORETP (73): faster TP gain -> more weaponskills
    snapshot        = 50,    -- Mod.SNAPSHOT (365) : % ranged-delay reduction (faster shots)
    rapidShot       = 50,    -- Mod.RAPID_SHOT (359) : % chance of an instant shot
    doubleShotRate  = 50,    -- Mod.DOUBLE_SHOT_RATE (422) : +% Double Shot proc (extra arrow)
}

-- Clamp the RATT mod's running TOTAL (our flat + the player's gear RATT) to
-- RATT_CAP so it can never wrap the int16 mod store; also makes re-application
-- idempotent (a second call adds 0).
local function addRattCapped(player, amount)
    local cur = player:getMod(xi.mod.RATT)
    local add = math.min(amount, RATT_CAP - cur)
    if add > 0 then
        player:addMod(xi.mod.RATT, add)
    end
end

-- Lay the whole bundle on a main-job Ranger. addMod is additive; the zone reload
-- that fires before each onGameIn has already wiped the previous copy, so re-applying
-- here keeps exactly one copy on the player (no growth across zones).
local function applyRngBoost(player)
    addRattCapped(player, CONFIG.ratt)
    if CONFIG.rattp > 0 then player:addMod(xi.mod.RATTP, CONFIG.rattp) end
    player:addMod(xi.mod.RACC,              CONFIG.racc)
    player:addMod(xi.mod.RANGED_DMG_RATING, CONFIG.rangedDmgRating)
    player:addMod(xi.mod.DAMAGE_LIMITP,     CONFIG.damageLimit)
    player:addMod(xi.mod.STORETP,           CONFIG.storeTP)
    player:addMod(xi.mod.SNAPSHOT,          CONFIG.snapshot)
    player:addMod(xi.mod.RAPID_SHOT,        CONFIG.rapidShot)
    player:addMod(xi.mod.DOUBLE_SHOT_RATE,  CONFIG.doubleShotRate)
end

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if player:getMainJob() == xi.job.RNG then
        -- Defer past post-login stat finalization, which clobbers a synchronous
        -- onGameIn addMod on a TRUE login (the boost silently fails to apply until
        -- the next zone otherwise). See reference_ongamein_mod_defer; mirrors
        -- CrossJob_TraitTrainer. The zone reload still wipes the prior copy before
        -- onGameIn, so the deferred re-apply keeps exactly one copy (no growth).
        player:timer(3000, function(p)
            if p:getMainJob() == xi.job.RNG then
                applyRngBoost(p)
            end
        end)
    end
end)

return m
