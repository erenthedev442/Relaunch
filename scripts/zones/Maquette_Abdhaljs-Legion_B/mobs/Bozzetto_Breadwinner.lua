-----------------------------------
-- Bozzetto Breadwinner (Meeble)
-- https://ffxiclopedia.fandom.com/wiki/Ambuscade/Battlefield_Archive/Bozzetto_Breadwinner
--
-- Will Warble approximately once every 30 seconds.
-- Every Warble move has roughly 2 seconds of readying time on Very Easy,
-- shortening as the difficulty setting rises.
-- Warbles have a chance to summon Urchins and activate the Housemaker,
-- and will wake any nearby Urchins. Inflicting Silence on the Breadwinner
-- may (but not reliably so) prevent Warbles from summoning Urchins or
-- activating the Housemaker.
-----------------------------------
mixins = { require('scripts/mixins/job_special') }
-----------------------------------
local ID = zones[xi.zone.MAQUETTE_ABDHALJS_LEGION_B]
local mechanics = require('modules/custom/lua/mob_mechanics_library')
-----------------------------------
local entity = {}

local WARBLE_IDS =
{
    3968, -- fire_meeble_warble
    3969, -- blizzard_meeble_warble
    3970, -- thunder_meeble_warble
    3971, -- stone_meeble_warble
    3972, -- water_meeble_warble
    3973, -- aero_meeble_warble
}

local doWarble
doWarble = function(mob)
    if not mob:isEngaged() then return end

    mob:useMobAbility(WARBLE_IDS[math.random(#WARBLE_IDS)])

    -- Respawn Housemaker if it was killed (gives players a breather between Warbles).
    pcall(function()
        local hm = GetMobByID(ID.mob.AMBUSCADE_HOUSEMAKER)
        if hm and not hm:isAlive() and mob:getLocalVar('hm_buffed') == 0 then
            local zone = mob:getZone()
            -- `zone:getInstance` (method reference w/o call) is a Lua syntax
            -- error next to `and`, so this file failed to load on every
            -- FileWatcher tick. Zone objects always have :getInstance in LSB,
            -- so the defensive nil-guard was superfluous anyway.
            local inst = zone and zone:getInstance() or nil
            if inst then
                SpawnMob(ID.mob.AMBUSCADE_HOUSEMAKER, inst)
            end
        end
    end)

    -- Warp any living Urchins back near the Breadwinner (simulates Urchins "waking").
    for _, urchinId in pairs({ ID.mob.BOZZETTO_URCHIN_1, ID.mob.BOZZETTO_URCHIN_2,
                                ID.mob.BOZZETTO_URCHIN_3, ID.mob.BOZZETTO_URCHIN_4 }) do
        pcall(function()
            local u = GetMobByID(urchinId)
            if u and u:isAlive() and not u:isEngaged() then
                local dx = math.random(-8, 8)
                local dz = math.random(-8, 8)
                u:setPos(mob:getXPos() + dx, mob:getYPos(), mob:getZPos() + dz)
            end
        end)
    end

    -- Schedule next Warble in 30 seconds.
    mob:timer(30000, function(m) doWarble(m) end)
end

entity.onMobInitialize = function(mob)
    -- Clod Spikes: active during Hundred Fists; earth dmg + potent Slow on melee hits.
    mob:addListener('TAKE_DAMAGE', 'BREADWINNER_TAKE_DAMAGE',
        function(mobArg, amount, attacker, attackType, damageType)
            if mobArg:hasStatusEffect(xi.effect.HUNDRED_FISTS) then
                attacker:addStatusEffect(xi.effect.SLOW, { power = 30 * 100, duration = 60, origin = mobArg })
            end
        end)
end

entity.onMobSpawn = function(mob)
    xi.mix.jobSpecial.config(mob, {
        specials =
        {
            { id = xi.mobSkill.HUNDRED_FISTS_1, hpp = 50, duration = 45 },
        },
    })
end

entity.onMobEngage = function(mob, target)
    -- Party HP scaling: scale Breadwinner HP by number of players in the instance.
    pcall(function()
        local instance = target:getInstance()
        if instance then
            local count = math.max(1, #instance:getChars())
            if count > 1 then
                -- +50% HP per extra party member (e.g. 3-man = ×2.0)
                local mult = 1.0 + (count - 1) * 0.5
                local newHP = math.floor(mob:getMaxHP() * mult)
                mob:setMaxHP(newHP)
                mob:setHP(newHP)
            end
        end
    end)

    -- Start Warble cycle after 30 seconds.
    mob:timer(30000, function(m) doWarble(m) end)
end

entity.onMobFight = function(mob, target)
    -- Tier-scaled mechanics attached in instances/ambuscade.lua's
    -- onInstanceProgressUpdate (stance dance / aoe pulses / drain / doom /
    -- phase triggers). No-op if the current tier has no mechCfg attached.
    mechanics.tick(mob, target)
end

entity.onMobWeaponSkill = function(mob, target, skill, action)
end

entity.onMobDeath = function(mob, player, optParams)
    -- Free the mechanics-library state for this mob id BEFORE anything else --
    -- library docstring says cleanup must run at the top of onMobDeath so
    -- despawns of any phase-spawned adds fire cleanly.
    mechanics.cleanup(mob)

    -- Clean up Housemaker buff so mob mod table doesn't leak across runs.
    if mob:getLocalVar('hm_buffed') == 1 then
        pcall(function()
            local hm = GetMobByID(ID.mob.AMBUSCADE_HOUSEMAKER)
            if hm and hm:isAlive() then
                hm:setHP(0)  -- despawn the Housemaker on boss death
            end
        end)
    end
end

return entity
