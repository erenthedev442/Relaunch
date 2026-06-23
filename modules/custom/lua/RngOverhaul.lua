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

-- == Tunables (all flat; "massive" tier -- dial any of these to taste) =========
local CONFIG =
{
    ratt            = 80000, -- Mod.RATT  (24)  : flat ranged attack. Must reach DEF*pDIF_cap; with damageLimit=1400 the cap is 48.75 so need RATT >= NM_DEF*48.75. 80k covers DEF up to ~1640; raise further if needed.
    rattp           = 2100,  -- Mod.RATTP (66)  : +% ranged attack (10x previous 210). Adds to ratio margin.
    racc            = 4000,  -- Mod.RACC  (26)  : land on high-EVA Legendary NMs
    rangedDmgRating = 5000,  -- Mod.RANGED_DMG_RATING (376) : flat damage on every shot (10x previous 500)
    damageLimit     = 1400,  -- Mod.DAMAGE_LIMITP (1081) : 10x ranged pDIF CAP. Formula: 3.25*(100+DLP)/100 -- was 4.875 at DLP=50, now 48.75 at DLP=1400 = exactly 10x. Applies to BOTH auto-attacks AND ranged WS pDIF component.
    storeTP         = 100,   -- Mod.STORETP (73): faster TP gain -> more weaponskills
    snapshot        = 50,    -- Mod.SNAPSHOT (365) : % ranged-delay reduction (faster shots)
    rapidShot       = 50,    -- Mod.RAPID_SHOT (359) : % chance of an instant shot
    doubleShotRate  = 50,    -- Mod.DOUBLE_SHOT_RATE (422) : +% Double Shot proc (extra arrow)
}

-- Lay the whole bundle on a main-job Ranger. addMod is additive; the zone reload
-- that fires before each onGameIn has already wiped the previous copy, so re-applying
-- here keeps exactly one copy on the player (no growth across zones).
local function applyRngBoost(player)
    player:addMod(xi.mod.RATT,              CONFIG.ratt)
    player:addMod(xi.mod.RATTP,             CONFIG.rattp)
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
        applyRngBoost(player)
    end
end)

return m
