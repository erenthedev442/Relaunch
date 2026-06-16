-----------------------------------
-- CapacityFarm.lua
-- A shared, always-up Capacity Point farm camp in Bibiki Bay (zone 4).
--
-- A small pool of Lv150-160 mobs that INSTANTLY respawn as each is killed,
-- so there's always a target and the engine's capacity chain (30s window)
-- stays alive for the ~1.5x bonus. Shared NonExclusive claim so everyone at
-- the camp can fight every mob and the killer's alliance earns the CP; no
-- loot/gil so it can't double as a gil/gear farm.
--
-- CP eligibility (engine, charutils.cpp::DistributeCapacityPoints): mob must
-- be Lv100+ (these are 150-160) and the killer needs JOB_BREAKER + lvl99
-- (auto-granted on login). Crucially these mobs do NOT set
-- NO_CAPACITY_POINTS -- that's the whole point of the camp.
--
-- Tune everything in capacity_farm_catalog.lua.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/capacity_farm_catalog')

local _zoneName = catalog.zonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', _zoneName))

local m = Module:new('capacity_farm')

-- The Bibiki Bay zone object, captured at init / on entry. Used by the
-- respawn + top-up logic, which have no player handle of their own.
local campZone

local ensurePopulation  -- forward decl (spawnOne's onMobDeath calls it)

-- Insert one camp mob at a random point in the camp patch.
local function spawnOne()
    if not campZone then
        return
    end

    -- Zone-wide: spawn at a random native walkable point so the farm fills the
    -- WHOLE zone on valid ground (no water/terrain clipping). Fall back to the
    -- campCenter patch if the pool is missing/empty.
    local x, y, z
    local pts = catalog.spawnPoints
    if pts and #pts > 0 then
        local p = pts[math.random(#pts)]
        x, y, z = p.x, p.y, p.z
    else
        local c = catalog.campCenter
        x = c.x + math.random(-catalog.spreadX, catalog.spreadX)
        y = c.y
        z = c.z + math.random(-catalog.spreadZ, catalog.spreadZ)
    end
    local gid = catalog.templates[math.random(#catalog.templates)]
    local rot = math.random(0, 255)

    local mob = campZone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = gid,
        groupZoneId          = catalog.groupZoneId,
        name                 = catalog.mobName,
        x                    = x,
        y                    = y,
        z                    = z,
        rotation             = rot,
        -- REQUIRED: without min/max level the engine defaults to lv255
        -- (unhittable). Range -> the engine rolls a level per spawn.
        minLevel             = catalog.minLv,
        maxLevel             = catalog.maxLv,
        -- Sight+hearing so the camp mobs notice and engage players who walk
        -- up (same field HL/Reforge use; read in luautils CalculateMobStats).
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        -- Instant respawn: each death immediately tops the pool back up to
        -- mobCount, so a kill is replaced on the spot and the capacity chain
        -- never lapses.
        onMobDeath = function(deadMob, killer)
            -- Bonus Capacity Points on top of the engine's level-based award, to
            -- boost the farm. addCapacityPoints self-guards non-PC killers and
            -- applies map EXP_RATE, so a pet/trust kill simply gets no extra (the
            -- engine still credits the master the base CP).
            if killer and catalog.cpBonus and catalog.cpBonus > 0 then
                killer:addCapacityPoints(catalog.cpBonus)
            end
            -- Refresh campZone from the dead mob before refilling. This self-heals
            -- the case where the FileWatcher re-ran this module file (creating a new
            -- module instance with campZone=nil), causing any callback written by a
            -- subsequent spawnOne() to see a nil campZone. By reading deadMob:getZone()
            -- here, we guarantee campZone is always valid when ensurePopulation() runs,
            -- regardless of which module-instance closure is in the Lua cache.
            campZone = deadMob:getZone()
            -- Refill SYNCHRONOUSLY, right here -- do NOT defer through a timer.
            -- History of this bug: deadMob:timer() never fired (the corpse and
            -- any timer on it are freed the instant a releaseIdOnDisappear mob
            -- vanishes), so it was moved to killer:timer() -- but that never
            -- fired either. entity:timer queues the closure onto the entity's PAI
            -- action queue (CLuaBaseEntity::timer -> QueueAction), which does not
            -- run it in the just-killed-something state, so ensurePopulation()
            -- was never reached and the pool never refilled ("not respawning").
            -- Calling it inline is reliable AND truly instant, and it is safe:
            -- the zone mob list is a std::map (node-based, EntityList_t in
            -- zone.h), so inserting a mob while the engine is mid-death-handling
            -- does not invalidate the iterator it is walking. This mirrors the
            -- inline work the dungeon system does in its own onMobDeath.
            ensurePopulation()
        end,
    })
    if not mob then
        print(string.format('[capacity_farm] insertDynamicEntity returned nil (groupId %d, groupZoneId %d) -- mob_groups row missing?',
            gid, catalog.groupZoneId))
        return
    end

    mob:setSpawn(x, y, z, rot)
    mob:spawn()

    -- Shared free-for-all claim so the whole camp can fight every mob and the
    -- killer still gets credit/CP. No loot/gil (CP only). DO NOT set
    -- NO_CAPACITY_POINTS here -- that would defeat the entire purpose.
    mob:setMobMod(xi.mobMod.CLAIM_TYPE, xi.claimType.NON_EXCLUSIVE)
    mob:setMobMod(xi.mobMod.NO_DROPS, 1)

    -- Quick kills: cap HP low. Applied AFTER spawn() because spawn()
    -- recalculates stats from the pool and would wipe a pre-spawn value.
    if catalog.maxHP and catalog.maxHP > 0 then
        mob:setMaxHP(catalog.maxHP)
        mob:setHP(catalog.maxHP)
    end
end

-- Top the live population up to mobCount. Counts only ALIVE camp mobs (by
-- name), so it's safe to call from many places (init, every zone-in, every
-- death) and from several players at once without over-spawning: Lua is
-- single-threaded, so each call fully completes (its spawns become alive)
-- before the next runs. Also self-corrects drift if the zone slept while empty.
ensurePopulation = function()
    if not campZone then
        return
    end
    local alive    = 0
    -- Dynamic entities have their name stored as "DE_<name>" internally (luautils.cpp:5596).
    -- queryEntitiesByName matches against this internal name, and non-"DE_" patterns are
    -- memoized as empty on first miss -- so querying without the prefix never finds them.
    local existing = campZone:queryEntitiesByName('DE_' .. catalog.mobName)
    if existing then
        for _, e in ipairs(existing) do
            if e:getHP() > 0 then
                alive = alive + 1
            end
        end
    end
    local spawned = 0
    for _ = alive + 1, catalog.mobCount do
        spawnOne()
        spawned = spawned + 1
    end
    -- Diagnostic (catalog.debug): log every ensurePopulation call so the live
    -- map log confirms deaths are driving respawns. Flip catalog.debug off once
    -- you've verified kills cycle correctly.
    if catalog.debug then
        print(string.format('[capacity_farm] refill: %d alive -> +%d spawned (target %d)',
            alive, spawned, catalog.mobCount))
    end
end

-- Seed the camp at zone boot.
m:addOverride(catalog.zonePath .. '.Zone.onInitialize', function(zone)
    super(zone)
    campZone = zone
    ensurePopulation()
end)

-- Re-stock whenever someone arrives (self-heals a zone that emptied/slept).
-- Preserves the stock boat/manaclipper onZoneIn behaviour via super().
m:addOverride(catalog.zonePath .. '.Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)
    campZone = player:getZone()
    -- Re-stock inline. A timer here proved as unreliable as the death-respawn
    -- one (see onMobDeath); spawning directly is safe and matches how
    -- onInitialize seeds the camp at boot.
    ensurePopulation()
    return cs
end)

return m
