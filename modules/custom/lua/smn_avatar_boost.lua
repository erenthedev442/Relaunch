-----------------------------------
-- smn_avatar_boost.lua
--
-- Turns player-summoned avatars into full endgame DD pets at spawn time (via the
-- xi.pet.spawnPet override). So the boost lands on EVERY avatar action -- not just
-- Blood Pacts -- it layers:
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

-- addMod that can't overflow the engine's int16 mod storage (max 32767). The big
-- BP_DAMAGE / ATT / ACC / HP adds -- especially with a high summoning-skill-over-
-- cap term -- would otherwise wrap NEGATIVE, and a negative BP_DAMAGE makes the
-- Blood Pact multiplier negative (the pact HEALS / zeroes instead of hitting).
-- Clamps the running total to 32000.
local function safeAddMod(pet, modId, amount)
    local cur = pet:getMod(modId)
    local add = math.min(amount, 32000 - cur)
    if add > 0 then
        pet:addMod(modId, add)
    end
end

local function applyAvatarBoost(master, pet)
    -- Guard: skip non-SMN masters and double-applies (zone-in respawn, etc.)
    if not master:isPC() or master:getMainJob() ~= xi.job.SMN then
        return
    end
    if pet:getLocalVar('smnBoostApplied') ~= 0 then
        return
    end
    pet:setLocalVar('smnBoostApplied', 1)

    local skillOverCap = math.max(xi.summon.getSummoningSkillOverCap(pet), 0)

    -- 2026-07-13 owner call: cut every added value below by 80% (SMN avatars were
    -- OP relative to everything on the server outside the endgame NMs the stack
    -- was originally dimensioned against). Every constant here is 20% of what it
    -- used to be; comments call out the pre-cut number in parentheses.

    -- BP_DAMAGE: +140 = 2.4x multiplier on Blood Pact Rage/Ward damage (was +700 / 8x).
    -- formula: finalDmg × (1 + BP_DAMAGE/100); 140 → 2.4x.
    -- +1 per summoning-skill point over cap (was +5) for modest skill-gear progression.
    safeAddMod(pet, xi.mod.BP_DAMAGE, 140 + skillOverCap * 1)

    -- Magic stats so magical BPs (Inferno, Judgment Bolt, Geocrush...) survive
    -- the (100+MATT)/(100+MDEF) ratio vs Legendary NMs. MATT=60 (was 300) gives a
    -- ~1.05-1.15x magicBonusDiff against typical NM MDEF (200-300) — noticeably
    -- less shove than before, still meaningful.
    pet:addMod(xi.mod.MATT, 60)   -- was 300
    pet:addMod(xi.mod.MACC, 500)  -- was 2500
    pet:addMod(xi.mod.INT,  200)  -- was 1000

    -- Physical stats so PHYSICAL Blood Pacts (Predator Claws, Flaming Crush,
    -- Mountain Buster, Chaotic Strike, Spinning Dive, Eclipse Bite...) still land.
    -- A physical BP's damage is pDif = avatarATT / targetDEF; the reduced +1200 flat
    -- (was +6000) still helps vs Legendary's 150-160 NM DEF, but pDif no longer
    -- pegs the 4.25x cap on tap. +per-skill-over-cap so gear/skillups matter.
    safeAddMod(pet, xi.mod.ATT, 1200 + skillOverCap * 8)   -- was 6000 + skillOverCap * 40
    safeAddMod(pet, xi.mod.ACC, 900  + skillOverCap * 2)   -- was 4500 + skillOverCap * 10
    pet:addMod(xi.mod.STR, 100) -- was 500
    pet:addMod(xi.mod.DEX,  60) -- was 300; feeds avatar physical-BP crit rate (getDexCritRate)

    -- ===== EVERY avatar action, not just Blood Pacts =====
    -- These give melee auto-attacks a real damage floor and let the avatar survive
    -- to keep swinging. Cut to 20% too so a raw (non-BP) auto-attacking avatar
    -- contributes but doesn't dominate.
    pet:addMod(xi.mod.ATTP,              10)    -- +10% attack (was +50)
    pet:addMod(xi.mod.DOUBLE_ATTACK,     20)    -- 20% double-attack (was 100/guaranteed)
    pet:addMod(xi.mod.TRIPLE_ATTACK,     20)    -- 20% triple-attack (was 100/guaranteed)
    pet:addMod(xi.mod.DOUBLE_ATTACK_DMG, 20)    -- +20% damage on double (was +100)
    pet:addMod(xi.mod.TRIPLE_ATTACK_DMG, 20)    -- +20% damage on triple (was +100)
    pet:addMod(xi.mod.HASTE_GEAR,        500)   -- +5% attack speed (was 25% engine cap)

    -- Survivability trimmed proportionally. DMGPHYS/DMGMAGIC are /10000 and the
    -- engine HARD-CAPS each at -50% (-5000); -1000 is a real but modest -10%.
    pet:addMod(xi.mod.DMGPHYS,  -1000)  -- was -5000 (-50% cap)
    pet:addMod(xi.mod.DMGMAGIC, -1000)  -- was -5000 (-50% cap)
    -- HP must use setMaxHP/addHP (mirrors BstJugPetOverhaul pattern) because
    -- addMod(HP) stores in the int16 mod array and safeAddMod clamps it to 32,000.
    -- setMaxHP writes the int32 max-HP field directly; addHP fills the new room.
    local bonusHP = 30000 -- was 150000
    pet:setMaxHP(pet:getMaxHP() + bonusHP)
    pet:addHP(bonusHP)
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
