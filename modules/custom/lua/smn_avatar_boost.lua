-----------------------------------
-- smn_avatar_boost.lua
--
-- Applies endgame BP_DAMAGE / MATT / MACC / INT to player-summoned avatars at
-- spawn time, via xi.pet.spawnPet override.
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

    -- BP_DAMAGE: +25900 = 260x multiplier on Blood Pact Rage/Ward damage.
    -- +40 per summoning-skill point over cap so gear/skillups matter.
    -- BP damage bypasses the 131k on-screen cap; full value lands on HP.
    pet:addMod(xi.mod.BP_DAMAGE, 25900 + skillOverCap * 40)

    -- Magic stats so magical BPs (Inferno, Judgment Bolt, Geocrush...) aren't
    -- crushed by the (100+MATT)/(100+MDEF) ratio vs Legendary NMs. Avatars have
    -- ~32 base MATT from C++; these flat values lift that to strongly favourable.
    pet:addMod(xi.mod.MATT, 6000)
    pet:addMod(xi.mod.MACC, 2500)
    pet:addMod(xi.mod.INT,  1000)
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
