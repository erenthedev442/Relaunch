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
-- THE FIX: Call Beast and Bestial Loyalty both route through xi.pet.spawnPet.
-- Layer bounded, level-scaled stats on freshly-spawned PLAYER jug pets:
--   * shared progression from the BST's stats, gear and pet augments,
--   * role-specific HP, mitigation, attack cadence and physical/magical bias,
--   * weapon-tier Ready caps from standard_ws_tuning_catalog,
--   * AUTO-READY: the pet uses its Ready (TP) move on its own whenever it caps
--     TP, so it DDs without the player spamming Sic (Sic still works for burst).
--
-- Pet levels and family resistances are calculated in petutils.cpp. This Lua
-- layer remains hot-tunable after the map has been rebuilt for the C++ changes.
-- Only PLAYER jug pets (petID >= 21) are touched.
--
-- See [[reference_cross_job_trainer]] for the module/override pattern.
-----------------------------------
require('modules/module_utils')

local m = Module:new('bst_jugpet_overhaul')
local jugCatalog = require('modules/custom/lua/jug_power_catalog')

-- ── Tunables ───────────────────────────────────────────────────────────────
local CONFIG =
{
    -- Modest level-99 floors. Beast Affinity, master stats and Pet: augments
    -- must provide the majority of endgame strength.
    -- These shared values are weighted per pet by jug_power_catalog. They are
    -- intentionally modest so unstacked pets do not pin their damage cap.
    flatATT = 500,
    flatACC = 600,
    flatSTR = 45,
    flatHP  = 8000,

    -- Gear-scaling: the pet inherits this share of the MASTER's stats, so it
    -- gets stronger as the BST gears/augments up (the "scales toward the cap" bit).
    masterSTRShare = 0.75,
    masterATTShare = 1.00,
    masterACCShare = 1.00,
    masterHPShare  = 1.50,

    attp = 10,

    -- Survivability. Tank roles multiply this baseline; the engine caps at -50%.
    pdt = -500,
    mdt = -500,

    -- Melee throughput. Fast roles multiply this baseline.
    doubleAttack = 8,
    tripleAttack = 2,

    -- Magical pet floor (Fly/Funguar/Lizard/Slug Ready nukes). Deliberately
    -- restrained so Pet: MAB/MACC, Beast Affinity and master gear dominate.
    flatMAB  = 100,
    flatMACC = 180,
    masterMATTShare = 1.00,
    masterMACCShare = 1.00,

    -- Magical Ready: MAGIC_DAMAGE adds before fTP; BP_DAMAGE is ×(1+BP/100).
    flatMagicDamage  = 40,
    flatMagicDMGMult = 10,

    -- Physical Ready uses getWeaponDmg(). The full physical PET_* investment
    -- is applied once after the stock hit resolves in mobskills.lua.
    flatWeaponDamage = 120,

    -- Ready investment converts the server's long-form pet progression into
    -- actual jug weapon/magic floors. Prestige PET + Paragon Dominion reach
    -- 3000 in each PET_* bucket; ordinary gear contributes before that cap.
    -- Magical Ready keeps its established ×12 maximum. Physical Ready must
    -- overcome high-level target defense before the companion progression
    -- multiplier applies, so a complete Prime-oriented physical build reaches
    -- ×20 through its broader offensive pet-stat package.
    readyInvestmentPerPoint         = 11.0,
    physicalReadyInvestmentPerPoint = 19.0,
    readyInvestmentModCap   = 3000,
    readyInvestmentAffCap   = 100,

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
local AUTO_READY_OFF_VAR = 'BST_AutoReadyOff'

local function cappedProgress(value, cap)
    if cap <= 0 then
        return 0
    end

    return math.min(math.max(value or 0, 0) / cap, 1.0)
end

-- Physical and magical Ready paths use their matching offensive PET_* bundles.
-- Physical builds additionally need Pet: Accuracy to connect against Legendary
-- evasive targets, so it contributes to their damage progression. Multi-attack
-- stats remain throughput choices: they produce more TP/auto-attack DPS, but
-- do not inflate a single Ready hit.
local function getReadyInvestmentMultiplier(master, magical)
    if master == nil then
        return 1.0
    end

    if magical then
        local score =
            (
                cappedProgress(master:getMod(xi.mod.PET_BEAST_AFF), CONFIG.readyInvestmentAffCap) +
                cappedProgress(master:getMod(xi.mod.PET_MAB_MDB), CONFIG.readyInvestmentModCap) +
                cappedProgress(master:getMod(xi.mod.PET_ATTR_BONUS), CONFIG.readyInvestmentModCap) +
                cappedProgress(master:getMod(xi.mod.PET_TP_BONUS), CONFIG.readyInvestmentModCap)
            ) / 4

        return 1.0 + CONFIG.readyInvestmentPerPoint * score
    end

    local score =
        (
            cappedProgress(master:getMod(xi.mod.PET_BEAST_AFF), CONFIG.readyInvestmentAffCap) +
            cappedProgress(master:getMod(xi.mod.PET_ATK_DEF), CONFIG.readyInvestmentModCap) +
            cappedProgress(master:getMod(xi.mod.PET_ACC_EVA), CONFIG.readyInvestmentModCap) +
            cappedProgress(master:getMod(xi.mod.PET_ATTR_BONUS), CONFIG.readyInvestmentModCap) +
            cappedProgress(master:getMod(xi.mod.PET_TP_BONUS), CONFIG.readyInvestmentModCap)
        ) / 5

    return 1.0 + CONFIG.physicalReadyInvestmentPerPoint * score
end

-- Exported on the module for deterministic balance tests.
m.getReadyInvestmentMultiplier = getReadyInvestmentMultiplier

-- ── Auto-Ready loop ────────────────────────────────────────────────────────
-- Self-rescheduling; bails out when the pet dies/despawns.
local function scheduleAutoReady(pet)
    pet:timer(CONFIG.autoReadyIntervalMs, function(p)
        if not p or not p:isAlive() then
            return
        end
        local master = p:getMaster()
        if
            master and
            (master:getCharVar(AUTO_READY_OFF_VAR) or 0) == 0 and
            p:isEngaged() and
            p:getTP() >= CONFIG.autoReadyTP
        then
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

    local entry = jugCatalog.get(pet:getPetID())
    local w = entry.weights
    local power = entry.power or 1.0

    local mSTR  = master:getStat(xi.mod.STR)
    local mATT  = master:getMod(xi.mod.ATT)
    local mACC  = master:getMod(xi.mod.ACC)
    local mMATT = master:getMod(xi.mod.MATT)
    local mMACC = master:getMod(xi.mod.MACC)

    -- Beast Affinity: gear mod PET_BEAST_AFF (1200) scales all CONFIG.flat* values
    -- proportionally. 100 points → +100% to every flat bonus (×2.0). The master-stat
    -- share contributions are intentionally NOT scaled (they already track gear).
    local beastAff     = math.max(0, master:getMod(xi.mod.PET_BEAST_AFF))
    local beastAffMult = math.min(2.0, 1.0 + beastAff / 100)

    -- Endgame floors scale IN with master level, so low-level pets aren't absurd.
    -- Report 2026-07-07 (Herdofturtles): a Lv 27-62 BST's pet was getting the FULL
    -- endgame floor -- ~100k HP, 5000 MATT, 720 STR -- trivializing leveling and
    -- making the pet "the new meat". 1.0 at level 99, ~0.27 at level 27. Master-share
    -- contributions already track the master's real (lower) stats, so they self-scale
    -- and are intentionally NOT level-scaled. All flat floors below use floorMult.
    local levelScale = math.min((master:getMainLvl() or 1) / 99, 1.0)
    local floorMult  = beastAffMult * levelScale * power
    local magicalReadyMult  = getReadyInvestmentMultiplier(master, true)

    local strFromMaster = math.floor(mSTR * CONFIG.masterSTRShare * w.str)

    pet:addMod(xi.mod.ATT, math.floor(CONFIG.flatATT * floorMult * w.att) + math.floor(mATT * CONFIG.masterATTShare * w.att) + strFromMaster)
    pet:addMod(xi.mod.ACC, math.floor(CONFIG.flatACC * floorMult * w.acc) + math.floor(mACC * CONFIG.masterACCShare * w.acc))
    pet:addMod(xi.mod.STR, math.floor(CONFIG.flatSTR * floorMult * w.str) + strFromMaster)
    pet:addMod(xi.mod.ATTP, math.floor(CONFIG.attp * w.att))

    pet:addMod(xi.mod.DMGPHYS, math.max(-5000, math.floor(CONFIG.pdt * w.dt)))
    pet:addMod(xi.mod.DMGMAGIC, math.max(-5000, math.floor(CONFIG.mdt * w.dt)))

    pet:addMod(xi.mod.MATT, math.floor(CONFIG.flatMAB * floorMult * w.matt) + math.floor(mMATT * CONFIG.masterMATTShare * w.matt))
    pet:addMod(xi.mod.MACC, math.floor(CONFIG.flatMACC * floorMult * w.macc) + math.floor(mMACC * CONFIG.masterMACCShare * w.macc))

    -- Magical Ready-move damage: MAGIC_DAMAGE adds to base before fTP in mobMagicalMove;
    -- BP_DAMAGE is a post-MAB multiplier (×4 at 300) now enabled for player pets in
    -- scripts/globals/mobskills.lua. Scales with beastAffMult so Beast Affinity boosts
    -- magical output too.
    pet:addMod(xi.mod.MAGIC_DAMAGE, math.floor(CONFIG.flatMagicDamage * floorMult * w.magic * magicalReadyMult))
    pet:addMod(xi.mod.BP_DAMAGE, math.floor(CONFIG.flatMagicDMGMult * floorMult * w.magic * magicalReadyMult))

    pet:addMod(xi.mod.DOUBLE_ATTACK, math.floor(CONFIG.doubleAttack * levelScale * w.multi))
    pet:addMod(xi.mod.TRIPLE_ATTACK, math.floor(CONFIG.tripleAttack * levelScale * w.multi))

    -- Physical jug weapon floor. The physical investment multiplier is applied
    -- once later in the shared Ready progression path, after pDIF, so it works
    -- even when this setter cannot replace the native jug weapon damage.
    local weaponDmg = math.floor(CONFIG.flatWeaponDamage * floorMult * w.weapon)
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
    local bonusHP = math.floor(CONFIG.flatHP * floorMult * w.hp) + math.floor(master:getMaxHP() * CONFIG.masterHPShare * w.hp)
    pet:setMaxHP(pet:getMaxHP() + bonusHP)
    pet:addHP(bonusHP)

    -- Ready moves receive an asymmetric ecosystem modifier in mobskills.lua.
    -- The correct family gains +50%; using a pet into its predator loses 25%.
    -- Both multiply the result built from gear, augments, stats, TP and weapon
    -- progression rather than supplying flat baseline damage.
    pet:setLocalVar('JugEcosystemFavorableBps', 5000)
    pet:setLocalVar('JugEcosystemUnfavorableBps', 2500)

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
