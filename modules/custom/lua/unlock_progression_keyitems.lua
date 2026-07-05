-----------------------------------
-- Auto-grant the two progression key items that gate the Merit and Job
-- Point MENUS, so they aren't greyed out for players who reached the level
-- cap through this server's custom systems instead of the retail genkai /
-- Records of Vana'diel unlock quests.
--
--   LIMIT_BREAKER (606)  -> un-greys the Merit Points menu.
--       Client gate (packets/s2c/0x063_miscdata_merits.cpp):
--           canUseMeritMode = mainJobLevel >= 75 AND hasKeyItem(LIMIT_BREAKER)
--   JOB_BREAKER  (2544)  -> un-greys the Job Points menu.
--       Client gate (packets/s2c/0x063_miscdata_job_points.cpp):
--           access = hasKeyItem(JOB_BREAKER)
--
-- Mechanism mirrors unlock_adoulin_jobs.lua: an idempotent onGameIn hook.
-- The hasKeyItem() guard makes it a one-time grant per character -- once a
-- character has both, the hook returns early and never writes again. The
-- hook fires on every login, so existing characters are fixed on their next
-- login and new characters on first login.
--
-- NOTE: granting JOB_BREAKER only un-greys the Job Points MENU. Capacity
-- Points still will NOT ACCRUE while every Lv100+ NM sets NO_CAPACITY_POINTS
-- (the anti-farm CP suppression in charutils.cpp / the HL/Reforge/GM/invasion
-- modules). A sanctioned Capacity Point source is a separate, deliberate task.
-- Merits, by contrast, fully work once un-greyed: at the genkai cap the EXP
-- overflow already converts to limit -> merit points (charutils.cpp:5674).
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('unlock_progression_keyitems')

-- Key items auto-granted to every player. xi.ki.* mirror src/map/enums/key_items.h.
local autoGrantKeyItems =
{
    xi.ki.LIMIT_BREAKER,  -- 606  -> Merit Points menu
    xi.ki.JOB_BREAKER,    -- 2544 -> Job Points menu
}

-- CharVar that guards the one-time subjob unlock grant so we don't write
-- to the DB on every login for characters who already have it.
local SUBJOB_UNLOCKED_VAR = 'SubjobAutoUnlocked'

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    -- ---------------------------------------------------------------
    -- Subjob unlock — auto-grant so players never need to do the
    -- retail quest (Vera/Isacio). One-time write, guarded by charvar.
    -- ---------------------------------------------------------------
    if player:getCharVar(SUBJOB_UNLOCKED_VAR) == 0 then
        player:unlockJob(0)
        player:setCharVar(SUBJOB_UNLOCKED_VAR, 1)
    end

    -- Cheap pre-check: if the player already has everything, do nothing
    -- further (no timer, no packets) for the rest of this character's life.
    local needsGrant = false
    for _, kiId in ipairs(autoGrantKeyItems) do
        if not player:hasKeyItem(kiId) then
            needsGrant = true
            break
        end
    end

    if not needsGrant then
        return
    end

    -- Grant immediately so the key items persist and the login data burst
    -- reflects them. addKeyItem() also sends the key-item list packet.
    local grantedLimitBreaker = false
    for _, kiId in ipairs(autoGrantKeyItems) do
        if not player:hasKeyItem(kiId) then
            player:addKeyItem(kiId)
            if kiId == xi.ki.LIMIT_BREAKER then
                grantedLimitBreaker = true
            end
        end
    end

    -- Live menu refresh for merits: the merit-availability packet is part of
    -- the initial login burst, so re-push it (deferred like unlock_adoulin_jobs
    -- so the client has finished loading) to un-grey the menu THIS session
    -- rather than on the next login. setMerits(getMeritCount()) is a
    -- value-preserving no-op that just re-sends GP_SERV_COMMAND_MISCDATA::MERITS.
    -- (The Job Points packet has no safe no-op re-push binding; its menu
    -- refreshes on the player's next zone-in/login, which only affects the lone
    -- character still missing JOB_BREAKER.)
    if grantedLimitBreaker then
        player:timer(2000, function(playerArg)
            playerArg:setMerits(playerArg:getMeritCount())
        end)
    end
end)

return m
