-----------------------------------
-- always_popped_nms.lua
--
-- Forces every NM in Abyssea, Escha Ru'Aun, and Reisenjima to be
-- auto-spawned at server start AND to respawn 30 seconds after each
-- death. No trade pop, no key item, no atmacite - just walk in and fight.
--
-- How it works
-- ------------
--   On each target zone's `Zone.onInitialize`, this module:
--     1. Asks the engine for every mob in the zone via `zone:getMobs()`.
--        This bypasses `zones[zoneId].mob` because many of the later
--        zones (Escha, Reisenjima, some Abyssea expansions) have an
--        empty mob table in IDs.lua - their mobs only exist in the
--        database. `getMobs()` enumerates the live engine list.
--     2. Skips anything that's not an NM (`mob:isNM()`).
--     3. Calls `mob:setRespawnTime(RESPAWN_SECONDS)` so the engine
--        respawns it 30s after death from then on.
--     4. Calls `SpawnMob()` if the mob is currently dead, so it's up
--        the moment the first player zones in after a server restart.
--
-- Excluded zones
-- --------------
--   Reisenjima Henge and Escha - Zi'Tah are both Hunting League hubs.
--   The tier Spawner NPCs there manage NM pops on demand (rank gating,
--   mark rewards, per-mob arenas). Auto-spawning every NM would
--   conflict with the single-entity-per-ID engine constraint and break
--   the spawner's "pop in front of you" UX. Both are intentionally
--   absent from TARGET_ZONES. All native mob_spawn_points in Escha
--   Zi'Tah have also been cleared from the DB so getMobs() returns
--   nothing there even if the entry were re-added.
--
-- Module enable/disable
-- ---------------------
--   This module is enabled by default. Set `setEnabled(false)` to turn
--   it off without removing the file.
-----------------------------------
require('modules/module_utils')

local autoPopNms = Module:new('always_popped_nms')

-----------------------------------
-- Module enable/disable
-----------------------------------
autoPopNms:setEnabled(true)

-----------------------------------
-- Tuning
-----------------------------------
-- Seconds before a dead NM respawns. The engine retains this value
-- across deaths because it's a property of the mob entity, so we only
-- need to set it once per server lifetime (at zone init).
local RESPAWN_SECONDS = 30

-----------------------------------
-- Target zones
--
-- Each entry: { zoneId, friendly name (for logging), Zone init path }.
-- The init path is the addOverride target for that zone's onInitialize
-- callback. It must match the zone's name exactly as recorded in the
-- `zone_settings` SQL table - Abyssea uses dashes, Escha/Reisenjima
-- use underscores. The override path is a STRING (not a Lua
-- identifier) so dashes are legal there.
-----------------------------------
local TARGET_ZONES =
{
    -- Abyssea (all 10) - note the DASH in zone names
    { xi.zone.ABYSSEA_KONSCHTAT,        'Abyssea-Konschtat',        'xi.zones.Abyssea-Konschtat.Zone.onInitialize'        },
    { xi.zone.ABYSSEA_TAHRONGI,         'Abyssea-Tahrongi',         'xi.zones.Abyssea-Tahrongi.Zone.onInitialize'         },
    { xi.zone.ABYSSEA_LA_THEINE,        'Abyssea-La_Theine',        'xi.zones.Abyssea-La_Theine.Zone.onInitialize'        },
    { xi.zone.ABYSSEA_MISAREAUX,        'Abyssea-Misareaux',        'xi.zones.Abyssea-Misareaux.Zone.onInitialize'        },
    { xi.zone.ABYSSEA_VUNKERL,          'Abyssea-Vunkerl',          'xi.zones.Abyssea-Vunkerl.Zone.onInitialize'          },
    { xi.zone.ABYSSEA_ATTOHWA,          'Abyssea-Attohwa',          'xi.zones.Abyssea-Attohwa.Zone.onInitialize'          },
    { xi.zone.ABYSSEA_ALTEPA,           'Abyssea-Altepa',           'xi.zones.Abyssea-Altepa.Zone.onInitialize'           },
    { xi.zone.ABYSSEA_GRAUBERG,         'Abyssea-Grauberg',         'xi.zones.Abyssea-Grauberg.Zone.onInitialize'         },
    { xi.zone.ABYSSEA_ULEGUERAND,       'Abyssea-Uleguerand',       'xi.zones.Abyssea-Uleguerand.Zone.onInitialize'       },
    { xi.zone.ABYSSEA_EMPYREAL_PARADOX, 'Abyssea-Empyreal_Paradox', 'xi.zones.Abyssea-Empyreal_Paradox.Zone.onInitialize' },

    -- Escha Ru'Aun - underscore-separated (Escha Zi'Tah excluded: HL hub)
    { xi.zone.ESCHA_RUAUN,              'Escha_RuAun',              'xi.zones.Escha_RuAun.Zone.onInitialize'              },

    -- Reisenjima main + Sanctorium (Henge excluded - see header note)
    { xi.zone.REISENJIMA,               'Reisenjima',               'xi.zones.Reisenjima.Zone.onInitialize'               },
    { xi.zone.REISENJIMA_SANCTORIUM,    'Reisenjima_Sanctorium',    'xi.zones.Reisenjima_Sanctorium.Zone.onInitialize'    },
}

-----------------------------------
-- Per-zone configuration hook
--
-- Ask the engine for every mob in the zone, force respawn time on each
-- NM, and spawn any that aren't currently alive. Skips non-NM mobs
-- (regular fauna). Uses `zone:getMobs()` rather than the static
-- `zones[zoneId].mob` table because many of these zones have empty
-- mob tables in IDs.lua - their NMs are defined only in mob_groups.
-----------------------------------
local function configureZone(zone, zoneName)
    local mobs = zone:getMobs()
    if not mobs then
        printf('[always_popped_nms] %s: zone:getMobs() returned nil', zoneName)
        return
    end

    local configured = 0
    local spawned    = 0
    for _, mob in pairs(mobs) do
        if mob and mob:isNM() then
            mob:setRespawnTime(RESPAWN_SECONDS)
            configured = configured + 1
            if not mob:isSpawned() then
                SpawnMob(mob:getID())
                spawned = spawned + 1
            end
        end
    end

    printf('[always_popped_nms] %s: %d NM(s) configured (%d freshly spawned)',
        zoneName, configured, spawned)
end

-----------------------------------
-- Register one Zone.onInitialize override per target zone.
--
-- Loop-local copies of zoneId/zoneName are captured by the closure so
-- each override knows which zone it belongs to.
-----------------------------------
for _, info in ipairs(TARGET_ZONES) do
    local zoneId, zoneName, overridePath = info[1], info[2], info[3]
    autoPopNms:addOverride(overridePath, function(zone)
        super(zone)
        configureZone(zone, zoneName)
    end)
end

return autoPopNms
