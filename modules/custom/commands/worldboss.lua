-----------------------------------
-- !worldboss [status | spawn | kill | reset]
-- GM command (permission 4) for World Boss management.
--
--   !worldboss            show current boss status
--   !worldboss spawn      force-spawn this week's boss (GM must be in Hall of the Gods)
--   !worldboss kill       force-kill the active boss (no credit awarded)
--   !worldboss reset      clear all WB_ server vars - allows a fresh spawn same week
--
-- State lives in xi._wb (set by world_boss.lua). Server vars are the
-- authoritative persistent record; xi._wb is the live runtime ref.
-----------------------------------
-- xi._wb_bosses / xi._wb_svGet / xi._wb_svSet / xi._wb_spawnBoss are
-- globals set by modules/custom/lua/world_boss.lua (loaded after commands/
-- by init.txt), so we access them inside onTrigger (runtime) not at load time.

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 4,
    parameters = 'ssss',
}

local function BOSSES()    return xi._wb_bosses end
local function svGet(n)    return xi._wb_svGet(n) end
local function svSet(n, v) return xi._wb_svSet(n, v) end

local function currentWeekNum()
    return math.floor((os.time() - 3 * 86400) / (7 * 86400))
end

commandObj.onTrigger = function(player, sub, ...)
    sub = (sub or ''):lower()

    if sub == 'spawn' then
        if svGet('Active') == 1 then
            player:printToPlayer('[World Boss] A boss is already active. Use !worldboss kill first.', xi.msg.channel.SYSTEM_3)
            return
        end

        if player:getZoneID() ~= xi.zone.WEST_RONFAURE then
            player:printToPlayer('[World Boss] You must be in West Ronfaure to force-spawn the boss.', xi.msg.channel.SYSTEM_3)
            return
        end

        local week     = currentWeekNum()
        local bossIdx  = (week % #BOSSES()) + 1
        local bossData = BOSSES()[bossIdx]
        local zone     = player:getZone()

        svSet('WeekNum', week)

        local mob = xi._wb_spawnBoss(zone, bossData, bossIdx, nil)
        if mob then
            player:printToPlayer(string.format(
                '[World Boss] %s force-spawned at %d HP.',
                bossData.name, bossData.hp), xi.msg.channel.SYSTEM_3)
            -- Broadcast to the zone.
            local players = zone:getPlayers() or {}
            for _, p in pairs(players) do
                if p and p:getName() ~= player:getName() then
                    p:printToPlayer(string.format(
                        '[World Boss] %s has been summoned by a GM!', bossData.name),
                        xi.msg.channel.SYSTEM_3)
                end
            end
        else
            svSet('WeekNum', 0)
            svSet('Active', 0)
            player:printToPlayer('[World Boss] ERROR: spawn failed. Check the server log.', xi.msg.channel.SYSTEM_3)
        end

    elseif sub == 'kill' then
        if svGet('Active') ~= 1 then
            player:printToPlayer('[World Boss] No active boss to kill.', xi.msg.channel.SYSTEM_3)
            return
        end
        if xi._wb and xi._wb.boss then
            pcall(function() xi._wb.boss:setHP(0) end)
        end
        -- setHP(0) fires onMobDeath which clears xi._wb and sets Active=2.
        -- If the mob was already gone (edge case), clean up manually.
        if svGet('Active') == 1 then
            svSet('Active', 0)
            svSet('HP', 0)
            xi._wb = nil
        end
        player:printToPlayer('[World Boss] Boss force-killed (no credit awarded).', xi.msg.channel.SYSTEM_3)

    elseif sub == 'reset' then
        if xi._wb and xi._wb.boss then
            pcall(function() xi._wb.boss:setHP(0) end)
            xi._wb = nil
        end
        svSet('Active',  0)
        svSet('HP',      0)
        svSet('MaxHP',   0)
        svSet('WeekNum', 0)
        svSet('BossIdx', 0)
        player:printToPlayer('[World Boss] All WB_ vars cleared. Ready for a fresh spawn.', xi.msg.channel.SYSTEM_3)

    else
        -- Default: status
        local active  = svGet('Active')
        local bossIdx = svGet('BossIdx')
        local bosses  = BOSSES()
        if bossIdx < 1 or bossIdx > #bosses then bossIdx = 1 end
        local bd      = bosses[bossIdx]
        local hp      = svGet('HP')
        local maxhp   = svGet('MaxHP')
        local weekNum = svGet('WeekNum')

        local curWeek    = currentWeekNum()
        local nextIdx    = (curWeek % #bosses) + 1
        local statusStr  = ({ [0]='idle', [1]='ACTIVE', [2]='defeated this week' })[active] or '?'

        player:printToPlayer(string.format(
            '[World Boss] Status: %s | Boss: %s | HP: %d / %d | WeekNum: %d (current: %d) | Next: %s',
            statusStr, bd.name, hp, maxhp, weekNum, curWeek, bosses[nextIdx].name),
            xi.msg.channel.SYSTEM_3)

        if active == 0 then
            local dayOfWeek = math.floor(os.time() / 86400) % 7   -- 3 = Sunday
            local daysUntilSunday = (3 - dayOfWeek + 7) % 7
            if daysUntilSunday == 0 then
                player:printToPlayer('[World Boss] It is Sunday! Boss will spawn when someone enters Hall of the Gods.', xi.msg.channel.SYSTEM_3)
            else
                player:printToPlayer(string.format(
                    '[World Boss] %d day(s) until Sunday auto-spawn.', daysUntilSunday),
                    xi.msg.channel.SYSTEM_3)
            end
        end
    end
end

return commandObj
