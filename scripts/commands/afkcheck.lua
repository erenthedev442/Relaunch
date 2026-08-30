-----------------------------------
-- func: afkcheck
-- desc: Sends a custom menu to the cursor target,
--     : with some very simple but randomized questions.
--     : If the target doesn't respond with a correct answer
--     : within 30 seconds, they will be set to 0hp.
--     : A late click after death/raise cannot pass the check.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = ''
}

local CAPTCHA_IDLE    = 0
local CAPTCHA_PENDING = 1
local CAPTCHA_FAILED  = 2

local function failCheck(playerArg, reason)
    playerArg:setLocalVar('CAPTCHA', CAPTCHA_FAILED)
    playerArg:printToPlayer(reason, xi.msg.channel.NS_SAY)
    if playerArg:isAlive() then
        playerArg:setHP(0)
    end
end

commandObj.onTrigger = function(player)
    -- Validate target
    local target = player:getCursorTarget()

    if not target then
        player:printToPlayer('No target selected target, using self')
        target = player
    end

    if target:getObjType() ~= xi.objType.PC then
        player:printToPlayer('Invalid target')
        return
    end

    -- Generate options
    local function getCorrectOption()
        local a = math.random(1, 10)
        local b = math.random(1, 10)
        local c = a + b

        return
        {
            string.format('%2i + %2i = %2i', a, b, c),
            function(playerArg)
                -- Timeout already failed this check. The GMTELL box can survive
                -- death + Legendary Ring raise; do not let a late click pass.
                if playerArg:getLocalVar('CAPTCHA') ~= CAPTCHA_PENDING then
                    playerArg:printToPlayer('AFK Check already expired', xi.msg.channel.NS_SAY)
                    return
                end

                playerArg:printToPlayer('AFK Check passed', xi.msg.channel.NS_SAY)
                playerArg:setLocalVar('CAPTCHA', CAPTCHA_IDLE)
            end,
        }
    end

    local function getIncorrectOption()
        local a = math.random(1, 10)
        local b = math.random(1, 10)
        local randomChange = math.random(1, 3)
        if math.random(0, 1) == 1 then
            randomChange = randomChange * -1
        end

        local c = a + b + randomChange

        return
        {
            string.format('%2i + %2i = %2i', a, b, c),
            function(playerArg)
                failCheck(playerArg, 'AFK Check failed')
            end,
        }
    end

    local options = {}
    table.insert(options, getCorrectOption())
    table.insert(options, getIncorrectOption())
    table.insert(options, getIncorrectOption())

    options = utils.shuffle(options)

    -- Present menu
    local menu =
    {
        title = 'AFK Check: Please pick true statement (30s)',
        onStart = function(playerArg)
            playerArg:setLocalVar('CAPTCHA', CAPTCHA_PENDING)
        end,

        options = options,
        onCancelled = function(playerArg)
            if playerArg:getLocalVar('CAPTCHA') == CAPTCHA_PENDING then
                failCheck(playerArg, 'AFK Check failed!')
            end
        end,
    }
    target:customMenu(menu)

    -- Add timer
    target:timer(30000, function(playerArg)
        if playerArg:getLocalVar('CAPTCHA') == CAPTCHA_PENDING then
            failCheck(playerArg, 'AFK Check failed (timed out)')
        end
    end)
end

return commandObj
