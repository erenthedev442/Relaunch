-----------------------------------
-- hunters_guild_hunts.lua
--
-- v2 Hunter's Guild rep source: vanilla HNM kills across Vana'diel.
--
-- Walks catalog.huntTargets at module load and installs an
-- `onMobDeath` override on each NM's script. When the NM dies, the
-- killer (and only the killer - see catalog.killerOnly) gets
-- baseRep credited to the matching guild. Rank-up + capstone
-- announcements flow through the existing hunters_guild.bumpRep
-- machinery.
--
-- Why this module exists separately from hunters_guild.lua:
--   * hunters_guild.lua = pure API surface (bumpRep, applyAmplifier,
--     getRank, etc). Called by Reforge / HL / NPCs.
--   * hunters_guild_hunts.lua = the side-effect module that hooks
--     into vanilla mob death events. Only does work at load time
--     (registering overrides); runtime work happens inside each
--     override closure.
-- Keeping them split means a future "scrap the world hunts model"
-- decision only requires deleting this file, not surgery on the
-- core lib.
--
-- Override pattern: Module + addOverride so the install
-- is non-destructive (no edits to vanilla mob scripts).
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/hunters_guild_catalog')
local hg      = require('modules/custom/lua/hunters_guild')

local m = Module:new('hunters_guild_hunts')

-- Pre-load every NM zone's mob script directory so xi.zones.<zone>.mobs.<name>
-- exists in the runtime table before we try to override it. Without this
-- the addOverride path can land before the script is loaded, leaving the
-- override dangling.
local _required = {}
for guildKey, targets in pairs(catalog.huntTargets) do
    for _, t in ipairs(targets) do
        local mobPath = string.format('scripts/zones/%s/mobs/%s', t.zone, t.name)
        if not _required[mobPath] then
            _required[mobPath] = true
            local ok, err = pcall(require, mobPath)
            if not ok then
                print(string.format(
                    "[hunters_guild_hunts] WARNING: failed to require %s - %s",
                    mobPath, tostring(err)))
            end
        end
    end
end

-- Per-player, per-NM rep cooldown (seconds). ANTI-FARM: (1) two hunt targets
-- (King Vinegarroon, Fafnir) double as Affinity NMs in the SAME zone, which
-- the affinity system repops every 30s; (2) hunt NMs themselves respawn every
-- 30 min per hunters_guild_hunt_respawns.sql, letting a determined camper
-- burn through guild rep on a single NM. The 24h floor (86400s, set in
-- catalog.repCooldownSeconds) makes each unique hunt NM a once-a-day rep
-- source, forcing breadth over depth. Kills + augment trophies still drop
-- every time -- only guild rep is gated. Tune in the catalog.
local REP_COOLDOWN = catalog.repCooldownSeconds or 86400

-- Award helper. Pulled out so we can keep the override closures tight.
-- Bumps rep through the existing hunters_guild API (which handles
-- rank-up announcements + capstone checks automatically), then prints
-- a focused hunt-specific line so the player understands WHERE the
-- rep came from. The vanilla mob's own death message still fires
-- separately - this is additive.
local function awardHunt(player, t, guildKey)
    if not player or player:getObjType() ~= xi.objType.PC then return end

    -- Anti-farm cooldown: no guild rep from the SAME NM again until it expires.
    local cdKey   = 'HGRepCD_' .. t.name
    local now     = os.time()
    local expires = player:getCharVar(cdKey) or 0
    if expires > now then
        player:printToPlayer(
            string.format("[Guild] No rep from %s yet -- on cooldown (%dm).",
                t.label, math.ceil((expires - now) / 60)),
            xi.msg.channel.SYSTEM_3)
        return
    end
    player:setCharVar(cdKey, now + REP_COOLDOWN)

    local _newRep, _newRank, didRankUp = hg.bumpRep(player, guildKey, t.baseRep)
    local g = catalog.guilds[guildKey]
    -- Don't repeat the rank-up announcement - bumpRep already did it.
    -- We just confirm the rep landed so the player can correlate it
    -- with the NM they just killed.
    if not didRankUp then
        player:printToPlayer(
            string.format("[Guild] +%d rep with %s for slaying %s.",
                t.baseRep, g.label, t.label),
            xi.msg.channel.SYSTEM_3
        )
    end
end

-- Resolve the killer entity from the (mob, optionalKiller) args that
-- LSB passes to onMobDeath. The vanilla signature is
-- `onMobDeath = function(mob, player, optParams)` but a few mob
-- scripts use slight variants. Use mob:getLastAttacker() as a
-- fallback when `player` is nil.
local function resolveKiller(mob, player)
    if player and player.getObjType then
        if player:getObjType() == xi.objType.PC then return player end
    end
    -- Best-effort fallback. getLastAttacker exists on CMobEntity in
    -- LSB and returns the last entity that landed damage. May be a
    -- pet/trust -> walk up to the master.
    local ok, attacker = pcall(function() return mob:getLastAttacker() end)
    if not (ok and attacker) then return nil end
    if attacker:getObjType() == xi.objType.PC then return attacker end
    -- Pet/trust -> resolve to its master
    local ok2, master = pcall(function() return attacker:getMaster() end)
    if ok2 and master and master:getObjType() == xi.objType.PC then
        return master
    end
    return nil
end

-- Distribute hunt rep to either just the killer or every alliance
-- member, per catalog.killerOnly. Keeps the call sites uniform.
local function distributeRep(mob, killer, target, guildKey)
    if catalog.killerOnly then
        awardHunt(killer, target, guildKey)
        return
    end
    -- Alliance-wide: walk the alliance, award each PC member who
    -- is in the same zone as the mob (cross-zone alliance members
    -- weren't actually present at the kill).
    local zoneId = mob:getZoneID()
    local alliance = killer:getAlliance() or { killer }
    for _, member in ipairs(alliance) do
        if member and member:getObjType() == xi.objType.PC
           and member:getZoneID() == zoneId then
            awardHunt(member, target, guildKey)
        end
    end
end

-- Install one onMobDeath override per hunt target. We DO want to
-- run after the vanilla onMobDeath (drops, BCNM cleanup, etc.),
-- so the override calls super() first and only adds our hook on
-- top.
local _installed = 0
local _failed = 0
for guildKey, targets in pairs(catalog.huntTargets) do
    for _, t in ipairs(targets) do
        local overridePath = string.format(
            'xi.zones.%s.mobs.%s.onMobDeath', t.zone, t.name)
        -- Capture loop-locals into closure params so each NM has
        -- its own (target, guildKey) without shadowing across
        -- iterations.
        local capturedT = t
        local capturedG = guildKey
        local ok, err = pcall(function()
            m:addOverride(overridePath, function(mob, player, optParams)
                -- Vanilla onMobDeath may not exist on every script
                -- (some HNMs have no death handler); super() is a
                -- no-op if the parent function is nil.
                local s = super
                if s then
                    -- protect-call so a bug in vanilla doesn't
                    -- block our rep award
                    pcall(function() s(mob, player, optParams) end)
                end
                local killer = resolveKiller(mob, player)
                if killer then
                    distributeRep(mob, killer, capturedT, capturedG)
                else
                    print(string.format(
                        "[hunters_guild_hunts] %s died but no PC killer resolved - no rep awarded",
                        capturedT.name))
                end
            end)
        end)
        if ok then
            _installed = _installed + 1
        else
            _failed = _failed + 1
            print(string.format(
                "[hunters_guild_hunts] WARNING: failed to install override for %s in %s - %s",
                t.name, t.zone, tostring(err)))
        end
    end
end

print(string.format(
    "[hunters_guild_hunts] installed onMobDeath overrides on %d NMs (%d failed)",
    _installed, _failed))

return m
