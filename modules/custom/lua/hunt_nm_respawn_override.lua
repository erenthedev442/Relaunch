-----------------------------------
-- hunt_nm_respawn_override.lua
--
-- Neutralizes per-mob-file setRespawnTime calls that override the
-- 30-minute mob_groups default from hunters_guild_hunt_respawns.sql.
--
-- Background: several vanilla LSB mob files for our hunt targets call
-- mob:setRespawnTime(<hours-or-days>) inside entity.onMobInitialize
-- and/or entity.onMobDespawn -- e.g. Jormungand at 3-5 days, Tiamat at
-- 3-5 days, Cactrot Rapido at 2-3 days, King Vinegarroon at 21h,
-- Cerberus + Khimaira at 48-72h, Bune at 21-24h, and so on. These
-- fire AFTER the mob_groups default is applied, silently shadowing the
-- 1800s SQL row. On top of that, onMobInitialize fires on every server
-- boot, so a mob with a 3-5 day roll RE-ROLLS to a fresh 3-5 days each
-- restart -- if the box restarts inside the window, the NM never
-- appears (Jormungand + Tiamat were both stuck in this loop until
-- 2026-07-14).
--
-- Fix: for every hunt NM in catalog.huntTargets, wrap the mob-file
-- onMobInitialize and onMobDespawn overrides. Each override calls
-- super(mob) first (so any legit stat/immunity setup in the vanilla
-- hook still runs), then re-writes m_RespawnTime to a flat 1800s
-- (30 min) as the LAST writer -- which matches the mob_groups SQL row
-- and the hunt-guild rep cooldown intent.
--
-- Lazy-load safety: mob-file addOverrides fall on empty air unless the
-- target script is cached first (C++ CacheLuaObjectFromFile is lazy).
-- We pre-require every hunt mob's script at module load, same pattern
-- as hunters_guild_hunts.lua:38-51.
--
-- Affinity NM coexistence: King Vinegarroon and Fafnir also have
-- Affinity-NM copies that share these mob scripts. Setting 1800s on
-- them here is harmless -- affinity_nm_autopop.lua's DESPAWN listener
-- fires AFTER the mob-script hook (mobentity.cpp OnDespawn ordering,
-- per its comment at :264-267) and re-writes m_RespawnTime to its own
-- 900s. So affinity copies stay on their 15-min cycle and the real
-- hunt NM keeps our 1800s. No id-check needed.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/hunters_guild_catalog')

local m = Module:new('hunt_nm_respawn_override')

-- Match hunters_guild_hunt_respawns.sql -- keep them equal so the SQL
-- row and this runtime override cannot drift.
local HUNT_RESPAWN_SECONDS = 1800

-- Pre-load every hunt NM's mob script so xi.zones.<zone>.mobs.<name>
-- exists before addOverride tries to attach. Without this the override
-- silently fails to install (see custom_HNM_system.lua for the same
-- class of bug we're routing around here).
local _required = {}
for _guildKey, targets in pairs(catalog.huntTargets) do
    for _, t in ipairs(targets) do
        local mobPath = string.format('scripts/zones/%s/mobs/%s', t.zone, t.name)
        if not _required[mobPath] then
            _required[mobPath] = true
            local ok, err = pcall(require, mobPath)
            if not ok then
                print(string.format(
                    "[hunt_nm_respawn_override] WARNING: failed to require %s - %s",
                    mobPath, tostring(err)))
            end
        end
    end
end

-- Install both hooks for every hunt NM.
local installed, failed = 0, 0
for _guildKey, targets in pairs(catalog.huntTargets) do
    for _, t in ipairs(targets) do
        local initHook    = string.format('xi.zones.%s.mobs.%s.onMobInitialize', t.zone, t.name)
        local despawnHook = string.format('xi.zones.%s.mobs.%s.onMobDespawn',    t.zone, t.name)

        local okInit = pcall(function()
            m:addOverride(initHook, function(mob)
                super(mob)
                mob:setRespawnTime(HUNT_RESPAWN_SECONDS)
            end)
        end)

        local okDespawn = pcall(function()
            m:addOverride(despawnHook, function(mob)
                super(mob)
                mob:setRespawnTime(HUNT_RESPAWN_SECONDS)
            end)
        end)

        if okInit and okDespawn then
            installed = installed + 1
        else
            failed = failed + 1
            print(string.format(
                "[hunt_nm_respawn_override] WARNING: override install failed for %s (init=%s despawn=%s)",
                t.name, tostring(okInit), tostring(okDespawn)))
        end
    end
end

print(string.format(
    '[hunt_nm_respawn_override] installed 30-min respawn on %d hunt NMs (%d failed)',
    installed, failed))

-- Zone.onInitialize stomp: several vanilla zone scripts re-roll hunt NM respawns
-- to multi-hour timers on every zone boot -- e.g. Mount_Zhayolm sets Cerberus
-- to 12-36 hours and Caedarva_Mire sets Khimaira the same way. That runs AFTER
-- mob_groups SQL and silently shadows the 1800s hunt-guild policy (Cerberus was
-- stuck off-pop for weeks when the box restarted inside that window).
local zoneTargets = {}
for _guildKey, targets in pairs(catalog.huntTargets) do
    for _, t in ipairs(targets) do
        zoneTargets[t.zone] = zoneTargets[t.zone] or {}
        table.insert(zoneTargets[t.zone], t)
    end
end

local zoneHooks = 0
for zone, targets in pairs(zoneTargets) do
    pcall(require, string.format('scripts/zones/%s/Zone', zone))

    local hook = string.format('xi.zones.%s.Zone.onInitialize', zone)
    local ok = pcall(function()
        m:addOverride(hook, function(zoneObj)
            super(zoneObj)

            pcall(require, string.format('scripts/zones/%s/IDs', zone))
            local zoneData = zones[targets[1].zoneId]
            if not zoneData or not zoneData.mob then
                return
            end

            for _, hunt in ipairs(targets) do
                local mobId = zoneData.mob[hunt.name:upper()]
                if mobId then
                    local mob = GetMobByID(mobId)
                    if mob then
                        mob:setRespawnTime(HUNT_RESPAWN_SECONDS)
                    end
                end
            end
        end)
    end)

    if ok then
        zoneHooks = zoneHooks + 1
    else
        print(string.format(
            '[hunt_nm_respawn_override] WARNING: zone init override failed for %s',
            zone))
    end
end

print(string.format(
    '[hunt_nm_respawn_override] installed zone-init respawn fix on %d zones',
    zoneHooks))

return m
