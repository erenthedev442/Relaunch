-----------------------------------
-- smn_avatar_boost.lua
--
-- Gives player-summoned avatars a modest Legendary floor at spawn time (via
-- the xi.pet.spawnPet override). Their real endgame strength still comes from
-- summoning skill, BP/Pet gear, augments and the master's weapon progression.
-- The floor lands on EVERY avatar action -- not just Blood Pacts -- it layers:
--   * Blood Pacts: BP_DAMAGE mult + magical (MATT/MACC/INT) + physical (ATT/ACC/
--     STR/DEX) stats.
--   * Auto-attacks / melee: ATTP, Double/Triple Attack (+their damage), Haste.
--   * Survivability: PDT/MDT (capped) + HP -- so it lives to keep swinging.
-- (BP_DAMAGE is engine-gated to Blood-Pact damage; the melee mods cover the rest.)
--
-- WHY NOT onMobSpawn: avatar.lua defines xi.pets.avatar.onMobSpawn but it is
-- not reliably called for player-summoned avatars (confirmed 2026-06-21 after
-- a full C++ rebuild). The xi.pet.spawnPet Lua choke-point (called from every
-- individual summoning/<avatar>.lua) is guaranteed to run, and BST already
-- proves the approach works (BstJugPetOverhaul.lua uses the same hook).
--
-- LEVEL SCALING: endgame floors scale with master level (masterLvl/99), same
-- pattern as BstJugPetOverhaul. Without this, a leveling SMN inherits full
-- endgame ATT/BP_DAMAGE and Blood Pacts peg the 79,999 hard cap.
--
-- petIDs 8-20 = avatars (CARBUNCLE through CAIT_SITH); 76 = SIREN.
-- petIDs 0-7  = spirits -- these DON'T use the same Blood Pact damage path
-- (mobskills.lua bloodPactMultiplier is gated on isAvatar() which excludes
-- spirits) so we skip them here.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/summon')

local m = Module:new('smn_avatar_boost')

local AVATAR_MIN = xi.petId.CARBUNCLE  -- 8
local AVATAR_MAX = xi.petId.CAIT_SITH  -- 20
local SIREN_ID   = xi.petId.SIREN      -- 76

local function isAvatarPet(petID)
    return (petID >= AVATAR_MIN and petID <= AVATAR_MAX) or petID == SIREN_ID
end

-- addMod that can't overflow the engine's int16 mod storage (max 32767).
local function safeAddMod(pet, modId, amount)
    local cur = pet:getMod(modId)
    local add = math.min(amount, 32000 - cur)
    if add > 0 then
        pet:addMod(modId, add)
    end
end

local function applyAvatarBoost(master, pet)
    if not master:isPC() or master:getMainJob() ~= xi.job.SMN then
        return
    end
    if pet:getLocalVar('smnBoostApplied') ~= 0 then
        return
    end
    pet:setLocalVar('smnBoostApplied', 1)

    local skillOverCap = math.max(xi.summon.getSummoningSkillOverCap(pet), 0)
    -- 1.0 at 99, ~0.09 at level 9 — matches BST jug floor scaling.
    local levelScale = math.min((master:getMainLvl() or 1) / 99, 1.0)

    local function scaled(amount)
        return math.floor(amount * levelScale)
    end

    -- Keep the baseline functional but well below a geared avatar. Excess
    -- summoning skill remains an investment-driven contribution.
    safeAddMod(pet, xi.mod.BP_DAMAGE, scaled(20 + math.floor(skillOverCap * 0.25)))

    pet:addMod(xi.mod.MATT, scaled(20))
    pet:addMod(xi.mod.MACC, scaled(120))
    pet:addMod(xi.mod.INT,  scaled(40))

    safeAddMod(pet, xi.mod.ATT, scaled(300 + skillOverCap * 2))
    safeAddMod(pet, xi.mod.ACC, scaled(250 + skillOverCap))
    pet:addMod(xi.mod.STR, scaled(30))
    pet:addMod(xi.mod.DEX, scaled(20))

    pet:addMod(xi.mod.ATTP,              scaled(5))
    pet:addMod(xi.mod.DOUBLE_ATTACK,     scaled(5))
    pet:addMod(xi.mod.TRIPLE_ATTACK,     scaled(2))
    pet:addMod(xi.mod.DOUBLE_ATTACK_DMG, scaled(5))
    pet:addMod(xi.mod.TRIPLE_ATTACK_DMG, scaled(5))
    pet:addMod(xi.mod.HASTE_GEAR,        scaled(200))

    pet:addMod(xi.mod.DMGPHYS,  -scaled(500))
    pet:addMod(xi.mod.DMGMAGIC, -scaled(500))

    -- Keep this as a modifier instead of mutating base max HP. Avatar stat
    -- recalculation rebuilds health.maxhp, while raw spawn modifiers survive
    -- the tracked C++ calculation layer.
    local bonusHP = scaled(5000)
    if bonusHP > 0 then
        pet:addMod(xi.mod.HP, bonusHP)
        pet:updateHealth()
        pet:addHP(bonusHP)
    end
end

m:addOverride('xi.pet.spawnPet', function(caster, petID, state, target)
    super(caster, petID, state, target)

    if caster and caster:isPC() and petID and isAvatarPet(petID) then
        local pet = caster:getPet()
        if pet then
            applyAvatarBoost(caster, pet)
        end
    end
end)

return m
