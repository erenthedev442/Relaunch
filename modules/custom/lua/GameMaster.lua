-----------------------------------
-- GameMaster.lua
-- A "Game Master" NPC that spawns themed enemy waves around the player.
--
-- Player flow:
--   1. Talk to the Game Master at GM Home.
--   2. Pick a difficulty (Easy / Normal / Hard / Insane).
--   3. Confirm Start. After a short grace period, mobs spawn in a ring
--      around the player. Kill them all to trigger the next wave.
--   4. Survive all waves to earn the completion bonus (HL_Points +
--      each kill bumps Custom_NM_Kills for the leaderboards).
--
-- The session is tied to the player who started it:
--   - If the player leaves the zone, the session ends and live mobs
--     get despawned.
--   - If the player dies, the session ends (with no completion bonus).
--   - Talking to the Game Master mid-session aborts cleanly.
--
-- Mob data comes from modules/custom/lua/game_master_catalog.lua.
-- The mob groupIds reuse the Hunting League mob pool registered by
-- modules/custom/sql/hunting_league_gm_home_mobs.sql, so this module
-- doesn't need its own SQL.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/game_master_catalog')
local wh      = require('modules/custom/lua/weekly_hunts')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))
-----------------------------------
local m = Module:new('game_master')

-- Per-player session state. Keyed by char name.
--   playerName -> {
--     difficulty   = 'Easy' | 'Normal' | ...
--     waveIndex    = current wave number (1..wavesTotal)
--     wavesTotal   = total waves for this difficulty
--     mobsAlive    = { mobEntityId -> mobEntity } - current-wave-only.
--                    Doubles as the "is wave cleared" set (empty = cleared)
--                    AND the abort-despawn list. NOTE: we deliberately do
--                    NOT keep a cumulative cross-wave entity list - mobs
--                    spawn with releaseIdOnDisappear=true, so any retained
--                    reference to a previous-wave mob points at a freed
--                    CMobEntity. Calling :getHP() or :setHP(0) on a
--                    dangling ref crashes the map server inside the C++
--                    setHP path (ACCESS_VIOLATION at lua_baseentity.cpp
--                    line 10105) - and pcall can't catch native faults.
--     zoneId       = where the session is running (must match current zone)
--     kills        = total mobs killed this session (for end-message)
--     markBonus    = per-kill HL_Points awarded
--   }
local sessions = {}

local function getSession(player)
    return sessions[player:getName()]
end

local function clearSession(player)
    sessions[player:getName()] = nil
end


-----------------------------------
-- Forward declarations
-----------------------------------
local showStartMenu
local startWave
local endSession


-----------------------------------
-- Spawn helpers
-----------------------------------

-- Pick `count` mobs from the difficulty's pool, with replacement.
local function pickMobsForWave(diffDef, count)
    local picks = {}
    local pool = diffDef.mobs
    for i = 1, count do
        picks[i] = pool[math.random(#pool)]
    end
    return picks
end


-- Spawn one mob at an offset from the player and wire its death to
-- the wave-clear counter. The `owner` arg is captured in the death
-- closure so the wave still advances even if someone else lands the
-- killing blow (otherwise multi-player chaos could leave the owner
-- stuck on a wave that's already been cleared by a passerby).
--
-- `diffDef` provides minLevel/maxLevel - REQUIRED. Without them the
-- engine's GenerateDynamicEntity defaults the mob to level 255 and
-- logs "No minLevel set for mob ..." per spawn; the spawned mob is
-- unhittable garbage. See the same handling in HuntingLeague.lua.
local function spawnWaveMob(owner, mobDef, ring, diffDef)
    local px = owner:getXPos()
    local py = owner:getYPos()
    local pz = owner:getZPos()

    local angle = math.random() * math.pi * 2
    local dist  = ring.minRadius + math.random() * (ring.maxRadius - ring.minRadius)
    local mx    = px + math.cos(angle) * dist
    local mz    = pz + math.sin(angle) * dist

    local ownerName = owner:getName()

    local zone = owner:getZone()
    local rot  = math.random(0, 255)
    local mob = zone:insertDynamicEntity({
        objtype              = xi.objType.MOB,
        groupId              = mobDef.groupId,
        groupZoneId          = catalog.npcPos.zoneId,
        name                 = mobDef.name,
        x                    = mx,
        y                    = py,
        z                    = mz,
        rotation             = rot,
        minLevel             = diffDef.minLevel,
        maxLevel             = diffDef.maxLevel,
        -- Detection bitfield from xi.detects. Without this, the engine
        -- logs "has no detection methods!" per spawn AND the wave mob
        -- never auto-aggros - players have to /target + /engage each
        -- one manually, which trashes the wave-mode flow. Custom field
        -- read in src/map/lua/luautils.cpp insertDynamicEntity.
        detection            = xi.detects.SIGHT_AND_HEARING,
        isAggroable          = true,
        releaseIdOnDisappear = true,

        onMobDeath = function(deadMob, killer)
            -- Look up the OWNER's session, not the killer's. If a
            -- friend nukes the mob the owner's wave still advances.
            local sess = sessions[ownerName]
            if not sess then return end

            sess.mobsAlive[deadMob:getID()] = nil
            sess.kills = sess.kills + 1

            -- Per-kill points go to the actual killer (might be the
            -- owner, might be a friend helping out). Custom_NM_Kills
            -- bumps for whoever got the killing blow.
            -- Guard against non-PC killers (trusts, pets, DoT ticks):
            -- setCharVar/printToPlayer are PC-only; calling them on a
            -- trust entity throws a Lua error that silently skips the
            -- wave-clear check below → session freezes permanently.
            if killer and killer:getObjType() == xi.objType.PC then
                killer:setCharVar('HL_Points',
                    (killer:getCharVar('HL_Points') or 0) + sess.markBonus)
                killer:setCharVar('Custom_NM_Kills',
                    (killer:getCharVar('Custom_NM_Kills') or 0) + 1)
                killer:printToPlayer(
                    string.format('[Game Master] %s down! +%d points.',
                        mobDef.name, sess.markBonus),
                    xi.msg.channel.SYSTEM_3)
            end

            -- Wave cleared?
            -- pendingSpawns tracks mobs that are scheduled but haven't
            -- materialised yet (staggered spawn). Don't advance the wave
            -- until BOTH all live mobs are dead AND all delayed spawns
            -- have fired - otherwise the first kill in a multi-mob wave
            -- could end the wave before the later mobs even appear.
            local stillAlive = false
            for _ in pairs(sess.mobsAlive) do
                stillAlive = true
                break
            end
            if not stillAlive and (sess.pendingSpawns or 0) == 0 then
                -- Resolve owner from the live player list before
                -- progressing the wave - the captured `owner` ref
                -- may be stale if they zoned + came back.
                local resolved = GetPlayerByName(ownerName)
                if not resolved then
                    -- Owner offline; abandon session quietly.
                    sessions[ownerName] = nil
                    return
                end
                if sess.waveIndex >= sess.wavesTotal then
                    endSession(resolved, true)
                else
                    resolved:printToPlayer(
                        string.format('[Game Master] Wave %d cleared! Next wave in %d seconds...',
                            sess.waveIndex, catalog.difficulties[sess.difficulty].waveDelay),
                        xi.msg.channel.SYSTEM_3)
                    resolved:timer(catalog.difficulties[sess.difficulty].waveDelay * 1000,
                        function(p) startWave(p) end)
                end
            end
        end,
    })

    -- insertDynamicEntity REGISTERS the mob with the engine but does
    -- NOT place it in the world - that takes a setSpawn + spawn pair.
    -- Without these the wave is silently empty: chat says "Wave N
    -- incoming!" and nothing appears. Same pattern HuntingLeague.lua
    -- uses to put its NMs on the field (see line ~566).
    if mob then
        mob:setSpawn(mx, py, mz, rot)
        mob:spawn()

        -- Block capacity points on kill. Game Master is a challenge
        -- mode, not a CP farm - wave mobs at L200 x EXP_RATE=10 would
        -- dump ~16k+ CP per kill, turning Insane runs into a degenerate
        -- JP grind. Requires MOBMOD_NO_CAPACITY_POINTS=200 in the
        -- engine + the early-return in charutils::DistributeCapacityPoints
        -- (already shipped for HL).
        mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)

        -- Apply difficulty-scaled combat mods AFTER spawn() - spawn()
        -- recalculates stats from the mob pool, so anything set before
        -- it would be wiped. Mirrors the post-spawn pattern in
        -- HuntingLeague.lua / Reforge_System.lua so all three systems
        -- behave the same way.
        if diffDef.mods then
            for modId, value in pairs(diffDef.mods) do
                mob:setMod(modId, value)
            end
        end

        -- Slight HP boost per difficulty (1.5x Easy -> 3x Insane).
        -- Wave fights are meant to be tempo events, not endurance -
        -- big HP would just drag them out without raising threat.
        if diffDef.hpBoost then
            local newMax = mob:getMaxHP() * diffDef.hpBoost
            mob:setMaxHP(newMax)
            mob:setHP(newMax)
        end

        -- Lock the mob to the session owner. Two-step:
        --   updateClaim - gives the owner the kill credit + claim
        --                 lock, so other players can't steal claim
        --                 by interrupting.
        --   addEnmity   - puts a huge enmity entry on the owner so
        --                 the mob immediately pursues them instead
        --                 of waiting for detection range. CE=30000
        --                 VE=30000 matches the "force this target"
        --                 pattern used by Hraesvelg.
        --
        -- Detection (SIGHT_AND_HEARING) and isAggroable stay enabled
        -- so other players helping out can still grab the mob's
        -- attention with Provoke / nukes - the owner just gets the
        -- starting aggro for free.
        mob:updateClaim(owner)
        mob:addEnmity(owner, 30000, 30000)
    end

    return mob
end


-----------------------------------
-- Wave + session lifecycle
-----------------------------------

startWave = function(player)
    local sess = getSession(player)
    if not sess then return end

    -- Safety: if player zoned away, end the session.
    if player:getZoneID() ~= sess.zoneId then
        endSession(player, false)
        return
    end

    sess.waveIndex = sess.waveIndex + 1
    local diffDef  = catalog.difficulties[sess.difficulty]
    local mobsThisWave = pickMobsForWave(diffDef, diffDef.mobsPerWave)

    player:printToPlayer(
        string.format('[Game Master] Wave %d of %d - incoming!', sess.waveIndex, sess.wavesTotal),
        xi.msg.channel.SYSTEM_3)

    -- Reset mobsAlive at wave start. Prior-wave entries (whose
    -- underlying CMobEntity has been freed by releaseIdOnDisappear)
    -- would otherwise hang around as dangling references and crash
    -- the abort-despawn loop in endSession. See the session header
    -- comment for the full story.
    sess.mobsAlive     = {}
    sess.pendingSpawns = #mobsThisWave   -- counts mobs not yet spawned

    local staggerMs     = (diffDef.spawnStagger or catalog.spawnStagger or 0) * 1000
    local capturedWave  = sess.waveIndex  -- snapshot so timer closures can detect wave change

    for i, mobDef in ipairs(mobsThisWave) do
        local delay = (i - 1) * staggerMs

        if delay == 0 then
            -- First mob spawns immediately.
            local mobEntity = spawnWaveMob(player, mobDef, catalog.spawnRing, diffDef)
            if mobEntity then
                sess.mobsAlive[mobEntity:getID()] = mobEntity
            end
            sess.pendingSpawns = sess.pendingSpawns - 1
        else
            -- Subsequent mobs arrive after a stagger delay.
            -- Capture loop variables explicitly - Lua closures capture by
            -- reference, so using `mobDef` directly inside a timer would
            -- always see the LAST value of the loop variable, not the
            -- per-iteration value. Assign to locals here to freeze them.
            local capturedMobDef = mobDef
            player:timer(delay, function(p)
                local s = sessions[p:getName()]
                -- If the session ended or the player advanced to a new wave
                -- while this timer was pending, silently discard the spawn.
                if not s or s.waveIndex ~= capturedWave then return end

                p:printToPlayer(
                    string.format('[Game Master] New threat incoming! (%s)', capturedMobDef.name),
                    xi.msg.channel.SYSTEM_3)

                local mobEntity = spawnWaveMob(p, capturedMobDef, catalog.spawnRing, diffDef)
                if mobEntity then
                    s.mobsAlive[mobEntity:getID()] = mobEntity
                end
                s.pendingSpawns = (s.pendingSpawns or 1) - 1

                -- Edge case: all previously-spawned mobs were already dead
                -- before this one arrived. Check if the wave is now complete.
                local stillAlive = false
                for _ in pairs(s.mobsAlive) do stillAlive = true; break end
                if not stillAlive and s.pendingSpawns == 0 then
                    local resolved = GetPlayerByName(p:getName())
                    if not resolved then sessions[p:getName()] = nil; return end
                    if s.waveIndex >= s.wavesTotal then
                        endSession(resolved, true)
                    else
                        resolved:printToPlayer(
                            string.format('[Game Master] Wave %d cleared! Next wave in %d seconds...',
                                s.waveIndex, catalog.difficulties[s.difficulty].waveDelay),
                            xi.msg.channel.SYSTEM_3)
                        resolved:timer(catalog.difficulties[s.difficulty].waveDelay * 1000,
                            function(p2) startWave(p2) end)
                    end
                end
            end)
        end
    end
end


endSession = function(player, completed)
    local sess = getSession(player)
    if not sess then return end

    -- Snapshot mobsAlive before we clear the session, so the abort
    -- branch can still despawn live mobs after sessions[name] is nil.
    local mobsToDespawn = sess.mobsAlive

    -- IMPORTANT: clear the session BEFORE we touch any mob. Calling
    -- mob:setHP(0) below synchronously fires CMobEntity::Die ->
    -- DistributeRewards -> OnMobDeath -> our onMobDeath callback. If
    -- the session is still alive at that point, the callback would
    -- re-enter endSession (via the wave-clear path) and we'd loop.
    -- With sessions[name] cleared first, the callback hits its
    -- `if not sess then return end` guard and bails cleanly.
    clearSession(player)

    if completed then
        local diffDef = catalog.difficulties[sess.difficulty]
        local bonus   = diffDef.completionBonus
        local ach     = require('modules/custom/lua/achievements')

        -- Build recipient list: session owner first, then any party members
        -- who are in the same zone. getParty() includes the caller, so skip
        -- the owner in the party loop to avoid a double-award.
        local recipients = { player }
        local party = player:getParty()
        if party then
            for _, member in ipairs(party) do
                if member and member:getID() ~= player:getID() then
                    recipients[#recipients + 1] = member
                end
            end
        end

        -- Per-difficulty FULL-CLEAR bit (Easy=1, Normal=2, Hard=4, Insane=8,
        -- Nightmare=16; all five = 31). Stored in the GM_Wave_Clears charvar,
        -- read by the Augment Moogle's tier gates. Derived from difficultyOrder
        -- so a new difficulty automatically gets the next bit.
        local diffBit = 0
        for di, dname in ipairs(catalog.difficultyOrder) do
            if dname == sess.difficulty then
                diffBit = bit.lshift(1, di - 1)
            end
        end

        for i, recipient in ipairs(recipients) do
            recipient:setCharVar('HL_Points',
                (recipient:getCharVar('HL_Points') or 0) + bonus)

            if diffBit ~= 0 then
                local clears = recipient:getCharVar('GM_Wave_Clears') or 0
                if bit.band(clears, diffBit) == 0 then
                    recipient:setCharVar('GM_Wave_Clears', bit.bor(clears, diffBit))
                end
            end

            if i == 1 then
                -- Session owner gets the full kill-count summary.
                recipient:printToPlayer(
                    string.format('[Game Master] ALL WAVES CLEARED! %s complete. +%d bonus points (total kills: %d).',
                        sess.difficulty, bonus, sess.kills),
                    xi.msg.channel.SYSTEM_3)
            else
                recipient:printToPlayer(
                    string.format('[Game Master] ALL WAVES CLEARED! %s complete. +%d bonus points.',
                        sess.difficulty, bonus),
                    xi.msg.channel.SYSTEM_3)
            end

            wh.fire(recipient, 'gm_wave_clear', { difficulty = sess.difficulty })
            local waveTotalCv = recipient:getCharVar('Wave_Clears_Total') or 0
            recipient:setCharVar('Wave_Clears_Total', waveTotalCv + 1)
            ach.onWaveClear(recipient)
        end

        -- No despawn loop on the completion path. mobsAlive is empty
        -- by definition (that's what triggered completion), and the
        -- previous implementation walked a *cumulative* mobEntities
        -- list including freed prior-wave entities - which crashed
        -- the map server in CLuaBaseEntity::setHP. See the session
        -- header comment for the gory details.
    else
        player:printToPlayer(
            string.format('[Game Master] Session aborted. Final kills: %d.', sess.kills),
            xi.msg.channel.SYSTEM_3)

        -- Despawn whatever's currently alive in the active wave.
        -- mobsAlive is reset at the start of every wave (see startWave)
        -- so it only contains entities from THIS wave - entities from
        -- prior waves have been GC'd by releaseIdOnDisappear and would
        -- crash if we tried to setHP on them.
        for _, mobEntity in pairs(mobsToDespawn or {}) do
            -- type() guard is paranoia in case anything ever drops
            -- a non-userdata value in here. getHP() > 0 ensures we
            -- don't double-kill a mob that died on the same tick.
            if type(mobEntity) == 'userdata' and mobEntity:getHP() > 0 then
                pcall(function() mobEntity:setHP(0) end)
            end
        end
    end
end


-----------------------------------
-- Menus
-----------------------------------

-- Each call creates a fresh per-player table so concurrent interactions
-- never share state.  The 30ms timer defers the send outside onTrigger.
local function sendMenu(player, options, title)
    local m = { title = title or 'Game Master', options = options }
    player:timer(30, function(p) p:customMenu(m) end)
end


-- Confirm screen shown when a difficulty is picked.
local function buildConfirmOptions(difficulty, page)
    local diffDef = catalog.difficulties[difficulty]
    return {
        {
            string.format('Yes - Start %s (%d waves)', difficulty, diffDef.wavesTotal),
            function(p)
                if getSession(p) then
                    p:printToPlayer('[Game Master] You already have a session running.', xi.msg.channel.SYSTEM_3)
                    return
                end
                sessions[p:getName()] = {
                    difficulty = difficulty,
                    waveIndex  = 0,
                    wavesTotal = diffDef.wavesTotal,
                    mobsAlive  = {},
                    zoneId     = p:getZoneID(),
                    kills      = 0,
                    markBonus  = diffDef.markBonus,
                }
                p:printToPlayer(
                    string.format('[Game Master] %s session armed. First wave in %d seconds!',
                        difficulty, diffDef.graceDelay),
                    xi.msg.channel.SYSTEM_3)
                p:timer(diffDef.graceDelay * 1000, function(pp) startWave(pp) end)
            end,
        },
        {
            'No - Back',
            function(p) showStartMenu(p, page) end,
        },
    }
end


showStartMenu = function(player, page)
    -- If a session is already live, the only valid action is to abort it (every
    -- difficulty button would just reject with "already running"). Show ONLY that
    -- and return.
    if getSession(player) then
        sendMenu(player, { {
            'Abort current session',
            function(p) endSession(p, false) end,
        } })
        return
    end

    -- Top-level menu lists each difficulty, PAGINATED. The whole menu ships as one
    -- 150-byte chat packet (title + every quoted label) and the client renders only
    -- a handful of rows, so each page shows at most PER tiers + up to two nav rows
    -- (<< Back / More >>). PER=5 keeps every page <= 7 options with margin, so the
    -- menu scales cleanly no matter how many tiers difficultyOrder grows to. Labels
    -- are the tier NAME only (a '(N waves)' suffix would bloat the packet); the wave
    -- count shows on the confirm screen + the carrot line below.
    page = page or 1
    local order = catalog.difficultyOrder
    local PER   = 5
    local pages = math.max(1, math.ceil(#order / PER))
    if page < 1 then page = 1 elseif page > pages then page = pages end

    local options = {}
    for i = (page - 1) * PER + 1, math.min(page * PER, #order) do
        local diff    = order[i]
        local diffDef = catalog.difficulties[diff]
        table.insert(options, {
            diff,
            function(p)
                -- Show the carrot up front: the full-clear payout + per-kill rate.
                p:printToPlayer(
                    string.format('[ Game Master ] Clear all %d waves for %d marks! (+%d per kill along the way.)',
                        diffDef.wavesTotal, diffDef.completionBonus, diffDef.markBonus),
                    xi.msg.channel.SYSTEM_3)
                -- Pass the current page so "No - Back" returns here, not to page 1.
                sendMenu(p, buildConfirmOptions(diff, page))
            end,
        })
    end

    -- Navigation: add only the arrows that apply, so single-page menus stay clean
    -- and any middle page (3+ pages) gets BOTH a previous and a next step.
    if page > 1 then
        table.insert(options, { '<< Back', function(p) showStartMenu(p, page - 1) end })
    end
    if page < pages then
        table.insert(options, { 'More >>', function(p) showStartMenu(p, page + 1) end })
    end

    local title = (pages > 1) and string.format('Game Master %d/%d', page, pages) or 'Game Master'
    sendMenu(player, options, title)
end


-----------------------------------
-- NPC entity
-----------------------------------
m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)

    -- One interchangeable Game Master per position so several players can each
    -- run their own wave session at once. All copies share name/look/menu.
    for _, pos in ipairs(catalog.npcPositions or { catalog.npcPos }) do
        local GameMaster = zone:insertDynamicEntity({
            objtype    = xi.objType.NPC,
            name       = 'Game_Master',
            packetName = string.format('%sGame Master', xi.icon.STAR_LARGE),
            look       = 64,                -- Trust: Prishe (visible/distinctive)
            x          = pos.x,
            y          = pos.y,
            z          = pos.z,
            rotation   = pos.rot or 128,
            widescan   = 1,

            onTrigger = function(player, npc)
                player:printToPlayer(
                    '[ Game Master ] Choose your difficulty. Mobs will spawn around you, kupo!',
                    xi.msg.channel.SYSTEM_3)
                showStartMenu(player)
            end,
        })
        utils.unused(GameMaster)
    end
end)

-- Player death hook: if a player dies mid-session, end the session and
-- despawn every live wave mob. Without this the mobs would either:
--   * sit idle (claim is on the dead owner, no one else to chase), or
--   * wander toward another player and chew on them after the owner's
--     intent has already failed.
-- Either outcome is bad UX. `endSession(player, false)` already handles
-- the despawn loop + sessions[] cleanup, so this hook is a one-liner.
--
-- addOverride composes with other modules' onPlayerDeath handlers
-- (weekly_hunts resets WH_KillStreak; world_first_announcements posts
-- death notifications). All three fire on every death without
-- interfering - that's the LSB override system's job.
m:addOverride('xi.player.onPlayerDeath', function(player, ...)
    super(player, ...)
    if getSession(player) then
        player:printToPlayer(
            '[Game Master] Owner down - session aborted, waves despawned.',
            xi.msg.channel.SYSTEM_3)
        endSession(player, false)
    end
end)

-----------------------------------
-- Exposed for the !gmreset GM command (clean up a stuck / leaked session).
--   xi._gm_endSession(player, false) -> despawn this run's mobs + clear it.
--   xi._gm_sessions[name] = nil       -> clear a leaked entry for an OFFLINE owner.
-----------------------------------
xi._gm_sessions   = sessions
xi._gm_endSession = endSession

return m
