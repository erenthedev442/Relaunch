-----------------------------------
-- BstJugPetOverhaul.lua
--
-- Endgame DD scaling for Beastmaster jug pets (Legendary).
--
-- THE PROBLEM: retail jug pets get ~300-400 ATT, no PDT, and ZERO master-stat
-- scaling (see src/map/utils/petutils.cpp LoadJugStats/GetJugBase), so against
-- Legendary's 150-160 NMs (high DEF/EVA, big hits) they do ~0 damage and die
-- instantly. SMN avatars work at endgame only because the C++ gives THEM 2x
-- attack, -50% PDT and master contributions -- jug pets get none of that.
--
-- THE FIX: Call Beast and Bestial Loyalty both route through xi.pet.spawnPet,
-- and that Lua runs AFTER the C++ stat calc has finalized -- so we override it
-- and layer endgame DD stats on top of any freshly-spawned PLAYER jug pet:
--   * big flat ATT/ACC/STR  + a SHARE of the master's STR / ATT / ACC mods, so
--     the pet scales with the BST's gear & augments and pushes toward the 131k
--     damage cap (geared master -> stronger pet),
--   * HP + PDT/MDT so it survives endgame hits,
--   * Double/Triple Attack for melee throughput,
--   * AUTO-READY: the pet uses its Ready (TP) move on its own whenever it caps
--     TP, so it DDs without the player spamming Sic (Sic still works for burst).
--
-- Pure Lua + a pet_list level bump (modules/custom/sql/bst_jugpet_overhaul.sql)
-- -- NO C++ rebuild. Override module -> needs ONE map restart to load. Every
-- knob lives in CONFIG so balance is a hot-reload (scp + re-summon), not a
-- 12-minute rebuild. Only PLAYER jug pets (petID >= 21) are touched; SMN
-- avatars (0-20), wyverns, automatons and mob-BST pets are left vanilla.
--
-- See [[reference_cross_job_trainer]] for the module/override pattern.
-----------------------------------
require('modules/module_utils')

local m = Module:new('bst_jugpet_overhaul')

-- ── Tunables ───────────────────────────────────────────────────────────────
local CONFIG =
{
    -- Flat endgame floors so even a fresh BST's pet is immediately viable.
    -- (Relaunch economy pass: flatATT 11200->5000, flatHP 280k->100k to match
    -- the tighter post-wipe power curve. ACC/STR floors unchanged.)
    flatATT = 5000,
    flatACC = 9000,
    flatSTR = 720,
    flatHP  = 100000,

    -- Gear-scaling: the pet inherits this share of the MASTER's stats, so it
    -- gets stronger as the BST gears/augments up (the "scales toward the cap" bit).
    -- Doubled to >1.0, so the pet now inherits MORE than the master itself has.
    masterSTRShare = 1.20,  -- + masterSTRShare * master STR  (into STR and ATT)
    masterATTShare = 0.80,  -- + masterATTShare * master's ATT mods  (relaunch: 1.60->0.80)
    masterACCShare = 1.40,  -- + masterACCShare * master's ACC mods
    masterHPShare  = 2.00,  -- + masterHPShare  * master max HP

    attp = 50,   -- +50% attack (Mod.ATTP, percent)

    -- Survivability. DMGPHYS/DMGMAGIC are /100 and the engine HARD-CAPS each at
    -- -50% (-5000). Relaunch: -25% (-2500), half the old at-cap value.
    pdt = -2500,
    mdt = -2500,

    -- Melee throughput (percent). Relaunch: 20% DA / 5% TA (was 100/100).
    doubleAttack = 20,
    tripleAttack = 5,

    -- Magical pet damage floor (for Fly/Funguar/Cactuar Ready moves like
    -- Cursed Sphere, Dark Spore, 1000 Needles which use magic formulas).
    flatMAB  = 5000,
    flatMACC = 4000,
    masterMATTShare = 1.0,   -- inherit 100% of master's MATT mods
    masterMACCShare = 1.0,   -- inherit 100% of master's MACC mods

    -- Magical Ready-move power (Cursed Sphere / mobMagicalMove path only).
    -- flatMagicDamage: flat additive to base damage before fTP (xi.mod.MAGIC_DAMAGE=311).
    -- flatMagicDMGMult: gives the pet a blood-pact-style multiplier (xi.mod.BP_DAMAGE=126).
    --   mobskills.lua line 1195 now applies this for any player-owned pet (not avatar-only).
    --   Formula: finalDmg × (1 + BP_DAMAGE/100); e.g. 2000 → ×21.
    flatMagicDamage  = 500,
    flatMagicDMGMult = 2000,

    -- Auto-Ready: pet fires its TP move on its own once it caps TP.
    autoReady           = true,
    autoReadyTP         = 1000,
    autoReadyIntervalMs = 2500,
}

-- Jug pets are petID >= SHEEP_FAMILIAR (21). 0-7 = spirits, 8-20 = SMN avatars.
local JUG_MIN = xi.petId.SHEEP_FAMILIAR

-- ── Auto-Ready loop ────────────────────────────────────────────────────────
-- Self-rescheduling; bails out when the pet dies/despawns.
local function scheduleAutoReady(pet)
    pet:timer(CONFIG.autoReadyIntervalMs, function(p)
        if not p or not p:isAlive() then
            return
        end
        if p:isEngaged() and p:getTP() >= CONFIG.autoReadyTP then
            p:useMobAbility() -- no arg = pet picks from its Ready-move list
        end
        scheduleAutoReady(p)
    end)
end

-- ── Stat layer ─────────────────────────────────────────────────────────────
local function applyEndgameScaling(master, pet)
    if pet:getLocalVar('bstOverhaulApplied') ~= 0 then
        return
    end
    pet:setLocalVar('bstOverhaulApplied', 1)

    local mSTR  = master:getStat(xi.mod.STR)
    local mATT  = master:getMod(xi.mod.ATT)
    local mACC  = master:getMod(xi.mod.ACC)
    local mMATT = master:getMod(xi.mod.MATT)
    local mMACC = master:getMod(xi.mod.MACC)

    -- Beast Affinity: gear mod PET_BEAST_AFF (1200) scales all CONFIG.flat* values
    -- proportionally. 100 points → +100% to every flat bonus (×2.0). The master-stat
    -- share contributions are intentionally NOT scaled (they already track gear).
    local beastAff     = math.max(0, master:getMod(xi.mod.PET_BEAST_AFF))
    local beastAffMult = 1.0 + beastAff / 100

    local strFromMaster = math.floor(mSTR * CONFIG.masterSTRShare)

    pet:addMod(xi.mod.ATT, math.floor(CONFIG.flatATT * beastAffMult) + math.floor(mATT * CONFIG.masterATTShare) + strFromMaster)
    pet:addMod(xi.mod.ACC, math.floor(CONFIG.flatACC * beastAffMult) + math.floor(mACC * CONFIG.masterACCShare))
    pet:addMod(xi.mod.STR, math.floor(CONFIG.flatSTR * beastAffMult) + strFromMaster)
    pet:addMod(xi.mod.ATTP, CONFIG.attp)

    pet:addMod(xi.mod.DMGPHYS, CONFIG.pdt)
    pet:addMod(xi.mod.DMGMAGIC, CONFIG.mdt)

    pet:addMod(xi.mod.MATT, math.floor(CONFIG.flatMAB  * beastAffMult) + math.floor(mMATT * CONFIG.masterMATTShare))
    pet:addMod(xi.mod.MACC, math.floor(CONFIG.flatMACC * beastAffMult) + math.floor(mMACC * CONFIG.masterMACCShare))

    -- Magical Ready-move damage: MAGIC_DAMAGE adds to base before fTP in mobMagicalMove;
    -- BP_DAMAGE is a post-MAB multiplier (×21 at 2000) now enabled for player pets in
    -- scripts/globals/mobskills.lua. Scales with beastAffMult so Beast Affinity boosts
    -- magical output too.
    pet:addMod(xi.mod.MAGIC_DAMAGE, math.floor(CONFIG.flatMagicDamage  * beastAffMult))
    pet:addMod(xi.mod.BP_DAMAGE,    math.floor(CONFIG.flatMagicDMGMult * beastAffMult))

    pet:addMod(xi.mod.DOUBLE_ATTACK, CONFIG.doubleAttack)
    pet:addMod(xi.mod.TRIPLE_ATTACK, CONFIG.tripleAttack)

    -- PET AUGMENTS: the engine only forwards the PET_* mods (990-995) to avatars,
    -- wyverns, and automatons -- NEVER jug pets -- so a BST's "Pet: Attack/Accuracy/
    -- Magic/Attributes/TP Bonus" augments + gear do nothing by default. Wire them
    -- onto the jug pet here (mirrors CalculateAvatarStats:913-922) so the existing
    -- catalog pet augments finally work for BST. addMod(x, 0) is a no-op when unrolled.
    local petAtkDef   = master:getMod(xi.mod.PET_ATK_DEF)
    local petAccEva   = master:getMod(xi.mod.PET_ACC_EVA)
    local petMabMdb   = master:getMod(xi.mod.PET_MAB_MDB)
    local petMaccMeva = master:getMod(xi.mod.PET_MACC_MEVA)
    pet:addMod(xi.mod.ATT,      petAtkDef)
    pet:addMod(xi.mod.DEF,      petAtkDef)
    pet:addMod(xi.mod.ACC,      petAccEva)
    pet:addMod(xi.mod.EVA,      petAccEva)
    pet:addMod(xi.mod.MATT,     petMabMdb)
    pet:addMod(xi.mod.MDEF,     petMabMdb)
    pet:addMod(xi.mod.MACC,     petMaccMeva)
    pet:addMod(xi.mod.MEVA,     petMaccMeva)
    pet:addMod(xi.mod.TP_BONUS, master:getMod(xi.mod.PET_TP_BONUS))
    local petAttr = master:getMod(xi.mod.PET_ATTR_BONUS) -- "Pet: Attributes" -> all 7
    if petAttr ~= 0 then
        for _, attr in ipairs({ xi.mod.STR, xi.mod.DEX, xi.mod.VIT, xi.mod.AGI, xi.mod.INT, xi.mod.MND, xi.mod.CHR }) do
            pet:addMod(attr, petAttr)
        end
    end

    -- HP: raise max AND heal into it (setMaxHP alone doesn't refill the new room).
    local bonusHP = math.floor(CONFIG.flatHP * beastAffMult) + math.floor(master:getMaxHP() * CONFIG.masterHPShare)
    pet:setMaxHP(pet:getMaxHP() + bonusHP)
    pet:addHP(bonusHP)

    if CONFIG.autoReady then
        scheduleAutoReady(pet)
    end
end

-- ── Hook ───────────────────────────────────────────────────────────────────
-- xi.pet.spawnPet is the choke point for Call Beast + Bestial Loyalty
-- (beastmaster.lua:378/394). super() runs the original spawn (C++ stat calc
-- included); we then scale PLAYER jug pets only.
m:addOverride('xi.pet.spawnPet', function(caster, petID, state, target)
    super(caster, petID, state, target)

    if caster and caster:isPC() and petID and petID >= JUG_MIN then
        local pet = caster:getPet()
        if pet then
            applyEndgameScaling(caster, pet)
        end
    end
end)

return m
