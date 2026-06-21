-----------------------------------
-- TestDummy.lua
-- A "Test Dummy" NPC at GM Home that spawns docile training targets
-- so players can verify gear/augment stats by whacking something
-- without dying or interrupting Hunting League / Game Master sessions.
--
-- Player flow:
--   1. Talk to the Test Dummy at GM Home (east end of NPC row).
--   2. Pick a tier (Standard L99 / Endgame L150 / Insane L200).
--   3. A dummy with multi-million HP spawns at a random spot in the
--      open training area east of the NPC.
--   4. Whack it. Use weaponskills. Check damage numbers.
--   5. "Reset dummy HP" via menu to top off mid-test.
--   6. "Despawn dummies" via menu when done.
--
-- Behavior of a spawned dummy:
--   - Stands still (NO_MOVE)
--   - Won't aggro on sight (setAggressive(false))
--   - Won't link to nearby mobs (NO_LINK)
--   - Won't drop loot / award capacity points (NO_DROPS / NO_CAPACITY_POINTS)
--   - WILL fight back if attacked, but the underlying pool is a low-
--     tier mob - outgoing damage is tickle-tier vs geared L99 chars,
--     which is what we want for testing PDT / MDT mitigation.
--
-- Multiple dummies can coexist per player - just trigger Spawn N
-- times. Each new dummy lands at a RANDOM point within
-- catalog.spawnArea.radius of the spawn point, so repeat spawns
-- (and dummies from other players) scatter across the training area
-- instead of stacking on one tile - several people can parse at once.
--
-- The dummy entities and per-player session state follow the same
-- "only track CURRENT live dummies" rule as GameMaster.lua - we do
-- NOT keep a cumulative cross-spawn list, because dummies spawn with
-- releaseIdOnDisappear=true and any retained reference to a despawned
-- dummy points at a freed CMobEntity. Calling :setHP or :getHP on a
-- dangling reference crashes the map server inside lua_baseentity.cpp
-- (ACCESS_VIOLATION) - pcall can't catch native faults. See the long
-- comment in GameMaster.lua for the full story.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/test_dummy_catalog')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))
-----------------------------------
local m = Module:new('test_dummy')

-- Per-player session state. Keyed by char name.
--   playerName -> {
--     dummies = { mobEntityId -> mobEntity }   -- live dummies only;
--                                              -- entries are nil'd in
--                                              -- onMobDeath when the
--                                              -- mob dies, so the
--                                              -- table never holds a
--                                              -- dangling reference.
--   }
local sessions = {}

local function getSession(player)
    return sessions[player:getName()]
end

local function ensureSession(player)
    local key = player:getName()
    if not sessions[key] then
        sessions[key] = { dummies = {} }
    end
    return sessions[key]
end

local function clearSession(player)
    sessions[player:getName()] = nil
end


-----------------------------------
-- Forward declarations (the menus reference each other)
-----------------------------------
local showMenu
local showAscensionMenu
local showAbysseaMenu


-----------------------------------
-- Dummy spawn / lifecycle
-----------------------------------

-- Pick a random point within catalog.spawnArea.radius of catalog.spawnPos so
-- dummies don't stack on one tile -- repeat spawns and other players' dummies
-- spread across the training area, letting several testers parse at once. GM
-- Home is a flat lobby, so only x/z are jittered (y stays put) and each dummy
-- faces a random way for natural variety. Returns x, z, rotation.
local function randomSpawnPoint()
    local sp     = catalog.spawnPos
    local radius = (catalog.spawnArea and catalog.spawnArea.radius) or 0
    if radius <= 0 then
        return sp.x, sp.z, sp.rotation
    end
    -- Uniform over the disc: sqrt() keeps density even out to the rim
    -- instead of bunching dummies toward the center.
    local angle = math.random() * 2 * math.pi
    local dist  = radius * math.sqrt(math.random())
    return sp.x + dist * math.cos(angle),
           sp.z + dist * math.sin(angle),
           math.random(0, 255)
end

local function spawnDummy(player, tierName)
    local tier = catalog.tiers[tierName]
    if not tier then return end

    local sess = ensureSession(player)
    local zone = player:getZone()
    if not zone then return end

    -- Capture the owner name in the death closure so a friend killing
    -- the dummy (extremely unlikely given the HP, but possible) still
    -- maintains the owner's session state correctly.
    local ownerName = player:getName()
    local tierLabel = tier.label or tierName

    local sp  = catalog.spawnPos
    local px, pz, prot = randomSpawnPoint()
    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = tier.groupId,
        groupZoneId          = catalog.npcPos.zoneId,
        name                 = string.format('Test_Dummy_%s', tierName),
        x                    = px,
        y                    = sp.y,
        z                    = pz,
        rotation             = prot,
        minLevel             = tier.minLevel,
        maxLevel             = tier.maxLevel,
        -- No detection field - we don't want this thing aggroing on
        -- detection. setAggressive(false) is applied post-spawn for
        -- belt + suspenders.
        isAggroable          = false,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            -- Remove from the live-dummies map so subsequent menu
            -- actions don't try to setHP() on a freed CMobEntity.
            local s = sessions[ownerName]
            if not s then return end
            s.dummies[deadMob:getID()] = nil

            local resolved = GetPlayerByName(ownerName)
            if resolved then
                resolved:printToPlayer(
                    string.format('[Test Dummy] %s dummy down. Re-summon when ready.', tierLabel),
                    xi.msg.channel.SYSTEM_3)
            end
        end,
    })

    -- insertDynamicEntity REGISTERS the mob; setSpawn + spawn() place
    -- it in the world. Without these the dummy is silently absent.
    -- Mirrors HuntingLeague / GameMaster.
    if not mob then
        player:printToPlayer(
            '[Test Dummy] Could not spawn dummy (engine refused the entity).',
            xi.msg.channel.SYSTEM_3)
        return
    end

    mob:setSpawn(px, sp.y, pz, prot)
    mob:spawn()

    -- Pacify the dummy. Order matters: spawn() recalculates stats
    -- from the mob pool, so mob-mods set BEFORE spawn() get wiped.
    -- Mirrors the post-spawn pattern in HuntingLeague / GameMaster.
    mob:setAggressive(false)
    mob:setMobMod(xi.mobMod.NO_MOVE,            1)
    mob:setMobMod(xi.mobMod.NO_LINK,            1)
    mob:setMobMod(xi.mobMod.NO_DROPS,           1)
    mob:setMobMod(xi.mobMod.NO_DESPAWN,         1)
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)

    -- Apply the encounter's DEFENSIVE profile (DEF / EVA / MEVA / MDEF).
    -- These come AFTER spawn() because spawn() recomputes stats from the
    -- mob pool and would otherwise wipe them. Mirrors how Prestige_System
    -- and AbysseaMarks stat-load their real mobs. Offense is left at the
    -- tickle base on purpose, so the dummy stays a safe target.
    if tier.mods then
        for mod, value in pairs(tier.mods) do
            mob:addMod(mod, value)
        end
    end

    -- Bump HP to the configured cap. setMaxHP first so the engine
    -- knows the new ceiling before we top off current HP.
    mob:setMaxHP(tier.hp)
    mob:setHP(tier.hp)

    sess.dummies[mob:getID()] = mob

    player:printToPlayer(
        string.format('[Test Dummy] %s (L%d) dummy spawned. %dM HP, real defense, tickle offense -- swing away.',
            tierLabel, tier.maxLevel, math.floor(tier.hp / 1000000)),
        xi.msg.channel.SYSTEM_3)
end


-- Top off every live dummy's HP. Useful when the player wants to
-- restart a damage-test without re-summoning. Skips dummies whose
-- HP is already 0 (mid-Die) to avoid the same setHP-on-freed-entity
-- crash class that bit GameMaster.lua.
local function resetDummies(player)
    local sess = getSession(player)
    if not sess or not next(sess.dummies) then
        player:printToPlayer(
            '[Test Dummy] No dummies to reset. Spawn one first.',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local reset = 0
    for id, mob in pairs(sess.dummies) do
        if type(mob) == 'userdata' and mob:getHP() > 0 then
            pcall(function()
                mob:setHP(mob:getMaxHP())
            end)
            reset = reset + 1
        else
            -- Defensive: drop any reference whose entity is gone.
            sess.dummies[id] = nil
        end
    end

    player:printToPlayer(
        string.format('[Test Dummy] Reset HP on %d dumm%s.', reset, reset == 1 and 'y' or 'ies'),
        xi.msg.channel.SYSTEM_3)
end


-- Kill every live dummy and clear the session. Snapshot the table
-- first + clear session BEFORE the setHP loop so onMobDeath sees
-- sess=nil and bails (same re-entrancy guard as GameMaster.lua).
local function despawnDummies(player)
    local sess = getSession(player)
    if not sess then
        player:printToPlayer(
            '[Test Dummy] No active dummies.',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local dummiesToKill = sess.dummies
    clearSession(player)

    local killed = 0
    for _, mob in pairs(dummiesToKill) do
        if type(mob) == 'userdata' and mob:getHP() > 0 then
            pcall(function() mob:setHP(0) end)
            killed = killed + 1
        end
    end

    player:printToPlayer(
        string.format('[Test Dummy] Despawned %d dumm%s.', killed, killed == 1 and 'y' or 'ies'),
        xi.msg.channel.SYSTEM_3)
end


-----------------------------------
-- Menus
-----------------------------------

-- Build a fresh snapshot table per send (customMenu's option tables are
-- shared scratch otherwise) and defer 30ms so re-opening a menu from
-- inside a menu callback doesn't race the client packet. Same pattern the
-- Casino / Shop multi-menu NPCs use.
local function sendMenu(player, title, options)
    local snapshot = { title = title, options = options }
    player:timer(30, function(p) p:customMenu(snapshot) end)
end


-- Submenu: the 5 Ascension (Prestige) Courts. All level 150, so the level
-- rides in the title and labels stay short (well under the 150-byte cap).
showAscensionMenu = function(player)
    local options = {}
    for _, key in ipairs(catalog.ascensionOrder) do
        local tier = catalog.tiers[key]
        table.insert(options, { tier.label, function(p) spawnDummy(p, key) end })
    end
    table.insert(options, { 'Back', function(p) showMenu(p) end })
    sendMenu(player, 'Ascension Lv.150', options)
end


-- Submenu: the custom Abyssea NM tiers. Levels differ (135/145/155), so
-- each label carries its own level.
showAbysseaMenu = function(player)
    local options = {}
    for _, key in ipairs(catalog.abysseaOrder) do
        local tier = catalog.tiers[key]
        table.insert(options, {
            string.format('%s Lv.%d', tier.label, tier.maxLevel),
            function(p) spawnDummy(p, key) end,
        })
    end
    table.insert(options, { 'Back', function(p) showMenu(p) end })
    sendMenu(player, 'Abyssea NMs', options)
end


-- Top menu: pick a family, or manage live dummies.
showMenu = function(player)
    sendMenu(player, 'Test Dummy', {
        { 'Ascension Levels', function(p) showAscensionMenu(p) end },
        { 'Abyssea NMs',      function(p) showAbysseaMenu(p)   end },
        { 'Reset dummy HP',   function(p) resetDummies(p)      end },
        { 'Despawn dummies',  function(p) despawnDummies(p)    end },
    })
end


-----------------------------------
-- NPC entity
-----------------------------------
m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)

    local TestDummyNpc = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Test_Dummy',
        packetName = string.format('%sTest Dummy', xi.icon.STAR_LARGE),
        look       = 3018,                -- Trust look; distinct from GameMaster (3017)
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,

        onTrigger = function(player, npc)
            player:printToPlayer(
                '[ Test Dummy ] Want to test your damage against the real endgame? Pick an Ascension Court or an Abyssea NM and swing away, kupo!',
                xi.msg.channel.SYSTEM_3)
            showMenu(player)
        end,
    })
    utils.unused(TestDummyNpc)
end)

return m
