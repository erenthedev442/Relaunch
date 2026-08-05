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
    -- Flat endgame floors so even a fresh BST's pet is immediately viable. These
    -- are the LEVEL-99 values; applyEndgameScaling multiplies them by mainLvl/99
    -- so low-level pets aren't overtuned (see floorMult below).
    -- Curve history:
    --   pre-relaunch  flatATT 11200, flatHP 280k (pet was OP outside endgame NMs)
    --   Jun-24 nerf   flatATT 5000,  flatHP 100k (matched post-wipe power curve)
    --   Jul-07 tweak  flatHP 60k (owner: gear/master-share should carry more)
    --   Jul-13 bump   flatATT 8100, flatHP 180k -- halfway back from the Jun-24
    --                 nerf. Owner call: current pet felt undertuned; restore
    --                 half the ATT/HP without going back to fully-OP.
    flatATT = 8100,
    flatACC = 9000,
    flatSTR = 720,
    flatHP  = 180000,

    -- Gear-scaling: the pet inherits this share of the MASTER's stats, so it
    -- gets stronger as the BST gears/augments up (the "scales toward the cap" bit).
    masterSTRShare = 1.20,  -- + masterSTRShare * master STR  (into STR and ATT)
    masterATTShare = 1.20,  -- + masterATTShare * master's ATT mods  (Jul-13: 0.80->1.20 halfway back)
    masterACCShare = 1.40,  -- + masterACCShare * master's ACC mods
    masterHPShare  = 2.00,  -- + masterHPShare  * master max HP

    attp = 50,   -- +50% attack (Mod.ATTP, percent)

    -- Survivability. DMGPHYS/DMGMAGIC are /100 and the engine HARD-CAPS each
    -- at -50% (-5000). Jul-13: -3750 (-37.5%), halfway back from the -25% nerf.
    pdt = -3750,
    mdt = -3750,

    -- Melee throughput (percent). Jul-13: 60 DA / 50 TA -- halfway back from the
    -- 20/5 nerf. Uncapped multi-hit hurts against non-endgame content; the
    -- master's own gear/augment DA/TA still stacks on top.
    doubleAttack = 60,
    tripleAttack = 50,

    -- Magical pet damage floor (Fly/Funguar/Lizard/Slug Ready nukes).
    -- 2026-08-05 retune: Fireball/Purulent Ooze were permanently pinning the
    -- 79,999 (AoE 39,999) companion cap. Aim ~40-55k unaugmented magic Ready
    -- at 99, with Beast Affinity / gear pushing strong pets to the default cap.
    flatMAB  = 1800,
    flatMACC = 2200,
    masterMATTShare = 1.0,
    masterMACCShare = 1.0,

    -- Magical Ready: MAGIC_DAMAGE adds before fTP; BP_DAMAGE is ×(1+BP/100).
    -- Was 500 / 300 (×4) and always hard-capped. Now ~180 / 90 (×1.9).
    flatMagicDamage  = 180,
    flatMagicDMGMult = 90,

    -- Physical Ready uses getWeaponDmg(); jug stock weapon DMG ~= level (~99),
    -- which left tiger/mandy/hippogryph Ready at 3-12k after the ×7-11 curve.
    -- Raise weapon damage so physical Ready benchmarks ~40-55k with augments.
    flatWeaponDamage = 550,

    -- Auto-Ready: pet fires its TP move on its own once it caps TP.
    autoReady           = true,
    autoReadyTP         = 1000,
    autoReadyIntervalMs = 2500,

    -- Auto-Engage (QoL, BST): the jug pet sics itself on the master's target the
    -- moment it is idle or on a stale target -- like a Trust/Fellow -- so AoE
    -- grinding does not need a manual /pet Fight per mob (which carries a recast).
    -- Uses master:petAttack (petutils::AttackTarget), so NO Fight-command cooldown.
    autoEngage           = true,
    autoEngageIntervalMs = 1000,
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

-- ── Auto-Engage loop ───────────────────────────────────────────────────────
-- Mirror Trust/Fellow behavior: while the master is engaged, keep the jug pet on
-- the master's battle target. Re-sic only when the pet is idle or on a different
-- target (kill one, auto-move to the next), so no per-mob /pet Fight is needed.
local function scheduleAutoEngage(pet)
    pet:timer(CONFIG.autoEngageIntervalMs, function(p)
        if not p or not p:isAlive() then
            return
        end
        pcall(function()
            local master = p:getMaster()
            if master and master:isAlive() and master:isEngaged() then
                local tgt = master:getTarget()
                if tgt and not tgt:isDead() then
                    local petTgt = p:getTarget()
                    if not p:isEngaged() or not petTgt or petTgt:getID() ~= tgt:getID() then
                        master:petAttack(tgt) -- petutils::AttackTarget -> no Fight recast
                    end
                end
            end
        end)
        scheduleAutoEngage(p)
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

    -- Endgame floors scale IN with master level, so low-level pets aren't absurd.
    -- Report 2026-07-07 (Herdofturtles): a Lv 27-62 BST's pet was getting the FULL
    -- endgame floor -- ~100k HP, 5000 MATT, 720 STR -- trivializing leveling and
    -- making the pet "the new meat". 1.0 at level 99, ~0.27 at level 27. Master-share
    -- contributions already track the master's real (lower) stats, so they self-scale
    -- and are intentionally NOT level-scaled. All flat floors below use floorMult.
    local levelScale = math.min((master:getMainLvl() or 1) / 99, 1.0)
    local floorMult  = beastAffMult * levelScale

    local strFromMaster = math.floor(mSTR * CONFIG.masterSTRShare)

    pet:addMod(xi.mod.ATT, math.floor(CONFIG.flatATT * floorMult) + math.floor(mATT * CONFIG.masterATTShare) + strFromMaster)
    pet:addMod(xi.mod.ACC, math.floor(CONFIG.flatACC * floorMult) + math.floor(mACC * CONFIG.masterACCShare))
    pet:addMod(xi.mod.STR, math.floor(CONFIG.flatSTR * floorMult) + strFromMaster)
    pet:addMod(xi.mod.ATTP, CONFIG.attp)

    pet:addMod(xi.mod.DMGPHYS, CONFIG.pdt)
    pet:addMod(xi.mod.DMGMAGIC, CONFIG.mdt)

    pet:addMod(xi.mod.MATT, math.floor(CONFIG.flatMAB  * floorMult) + math.floor(mMATT * CONFIG.masterMATTShare))
    pet:addMod(xi.mod.MACC, math.floor(CONFIG.flatMACC * floorMult) + math.floor(mMACC * CONFIG.masterMACCShare))

    -- Magical Ready-move damage: MAGIC_DAMAGE adds to base before fTP in mobMagicalMove;
    -- BP_DAMAGE is a post-MAB multiplier (×4 at 300) now enabled for player pets in
    -- scripts/globals/mobskills.lua. Scales with beastAffMult so Beast Affinity boosts
    -- magical output too.
    pet:addMod(xi.mod.MAGIC_DAMAGE, math.floor(CONFIG.flatMagicDamage  * floorMult))
    pet:addMod(xi.mod.BP_DAMAGE,    math.floor(CONFIG.flatMagicDMGMult * floorMult))

    pet:addMod(xi.mod.DOUBLE_ATTACK, CONFIG.doubleAttack)
    pet:addMod(xi.mod.TRIPLE_ATTACK, CONFIG.tripleAttack)

    -- Physical Ready / AA weapon floor (setDamage writes the jug weapon's DMG).
    local weaponDmg = math.floor(CONFIG.flatWeaponDamage * floorMult)
    if weaponDmg > 0 then
        pet:setDamage(weaponDmg)
    end

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
    local bonusHP = math.floor(CONFIG.flatHP * floorMult) + math.floor(master:getMaxHP() * CONFIG.masterHPShare)
    pet:setMaxHP(pet:getMaxHP() + bonusHP)
    pet:addHP(bonusHP)

    if CONFIG.autoReady then
        scheduleAutoReady(pet)
    end
    if CONFIG.autoEngage then
        scheduleAutoEngage(pet)
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
