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
    flatATT = 5600,
    flatACC = 2600,
    flatSTR = 360,
    flatHP  = 140000,

    -- Gear-scaling: the pet inherits this share of the MASTER's stats, so it
    -- gets stronger as the BST gears/augments up (the "scales toward the cap" bit).
    masterSTRShare = 0.60,  -- + masterSTRShare * master STR  (into STR and ATT)
    masterATTShare = 0.80,  -- + masterATTShare * master's ATT mods
    masterACCShare = 0.70,  -- + masterACCShare * master's ACC mods
    masterHPShare  = 1.00,  -- + masterHPShare  * master max HP

    attp = 25,   -- +25% attack (Mod.ATTP, percent)

    -- Survivability (DMGPHYS/DMGMAGIC are /100: -3000 = -30% damage taken).
    pdt = -3000,
    mdt = -2500,

    -- Melee throughput (percent).
    doubleAttack = 50,
    tripleAttack = 50,

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

    local mSTR = master:getStat(xi.mod.STR)
    local mATT = master:getMod(xi.mod.ATT)
    local mACC = master:getMod(xi.mod.ACC)

    local strFromMaster = math.floor(mSTR * CONFIG.masterSTRShare)

    pet:addMod(xi.mod.ATT, CONFIG.flatATT + math.floor(mATT * CONFIG.masterATTShare) + strFromMaster)
    pet:addMod(xi.mod.ACC, CONFIG.flatACC + math.floor(mACC * CONFIG.masterACCShare))
    pet:addMod(xi.mod.STR, CONFIG.flatSTR + strFromMaster)
    pet:addMod(xi.mod.ATTP, CONFIG.attp)

    pet:addMod(xi.mod.DMGPHYS, CONFIG.pdt)
    pet:addMod(xi.mod.DMGMAGIC, CONFIG.mdt)

    pet:addMod(xi.mod.DOUBLE_ATTACK, CONFIG.doubleAttack)
    pet:addMod(xi.mod.TRIPLE_ATTACK, CONFIG.tripleAttack)

    -- HP: raise max AND heal into it (setMaxHP alone doesn't refill the new room).
    local bonusHP = CONFIG.flatHP + math.floor(master:getMaxHP() * CONFIG.masterHPShare)
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
