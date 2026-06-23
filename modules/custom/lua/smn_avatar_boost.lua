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

    -- BP_DAMAGE: +9400 = 95x multiplier on Blood Pact Rage/Ward damage.
    -- Targets 500k-750k per use on the main endgame BPs (physical and magical).
    -- +5 per summoning-skill point over cap for modest skill-gear progression.
    -- BP damage bypasses the 131k on-screen cap; full value lands on HP.
    safeAddMod(pet, xi.mod.BP_DAMAGE, 9400 + skillOverCap * 5)

    -- Magic stats so magical BPs (Inferno, Judgment Bolt, Geocrush...) survive
    -- the (100+MATT)/(100+MDEF) ratio vs Legendary NMs. MATT=500 gives a 1.25-
    -- 2.5x magicBonusDiff against typical NM MDEF (300-400), landing magical BPs
    -- in the same 500k-750k window as physical BPs with the 95x BP_DAMAGE above.
    pet:addMod(xi.mod.MATT, 500)
    pet:addMod(xi.mod.MACC, 2500)
    pet:addMod(xi.mod.INT,  1000)

    -- Physical stats so PHYSICAL Blood Pacts (Predator Claws, Flaming Crush,
    -- Mountain Buster, Chaotic Strike, Spinning Dive, Eclipse Bite...) work too.
    -- A physical BP's damage is pDif = avatarATT / targetDEF, and a raw avatar's
    -- ATT collapses against Legendary's 150-160 NM DEF -> ~0 damage. These flat
    -- values max pDif (hard-capped at 4.25x); the 95x BP_DAMAGE mult then lands
    -- the hit. +per-skill-over-cap so gear/skillups matter.
    safeAddMod(pet, xi.mod.ATT, 6000 + skillOverCap * 40)
    safeAddMod(pet, xi.mod.ACC, 4500 + skillOverCap * 10)
    pet:addMod(xi.mod.STR, 500)
    pet:addMod(xi.mod.DEX, 300) -- feeds avatar physical-BP crit rate (getDexCritRate)

    -- ===== EVERY avatar action, not just Blood Pacts =====
    -- The boosts above mainly land on Blood Pacts (BP_DAMAGE is BP-ONLY); a raw
    -- avatar otherwise just auto-attacks once for chip damage. These make its
    -- MELEE auto-attacks a real damage source and let it survive to keep swinging,
    -- mirroring the BST jug-pet overhaul (BstJugPetOverhaul.lua) which proves the
    -- model. (ATT above already maxes pDif vs NM DEF; ATTP adds headroom.)
    pet:addMod(xi.mod.ATTP,              50)    -- +50% attack, on top of the flat ATT
    pet:addMod(xi.mod.DOUBLE_ATTACK,     100)   -- guaranteed double...
    pet:addMod(xi.mod.TRIPLE_ATTACK,     100)   -- ...and triple attack -> ~3 hits/round
    pet:addMod(xi.mod.DOUBLE_ATTACK_DMG, 100)   -- +100% damage on those extra...
    pet:addMod(xi.mod.TRIPLE_ATTACK_DMG, 100)   -- ...multi-hit swings
    pet:addMod(xi.mod.HASTE_GEAR,        2500)  -- +25% attack speed (engine gear-haste cap)

    -- Survivability so it lives to keep meleeing a Legendary NM. DMGPHYS/DMGMAGIC
    -- are /10000 and the engine HARD-CAPS each at -50% (-5000).
    pet:addMod(xi.mod.DMGPHYS,  -5000)
    pet:addMod(xi.mod.DMGMAGIC, -5000)
    safeAddMod(pet, xi.mod.HP, 150000)
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
