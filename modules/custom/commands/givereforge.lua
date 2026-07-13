-----------------------------------
-- !givereforge <af|relic|empy|all> <amount> [player]
-- [GM] Grant Reforge Marks (AF / Relic / Empyrean) to a player.
-- Targets yourself if no player name given. Additive to the existing balance.
--
-- The three mark types are separate charVars sourced from the Reforge System's
-- three NM pools (Sky Gods / Unity NMs / Abyssea NMs). Marks also gate the
-- Dynamis-Divergence entry toll (250 of any type per run) and any future
-- reforge upgrades.
--
-- Usage:
--   !givereforge af 1000              (grant 1000 AF Marks to yourself)
--   !givereforge relic 500 Bdr        (grant 500 Relic Marks to Bdr)
--   !givereforge empy 2000            (grant 2000 Empy Marks to yourself)
--   !givereforge all 1000             (grant 1000 of EACH mark type to yourself)
--
-- Balance is visible via !marks (for Hunt Marks) or by checking your
-- Reforge Vendor NPC menu (shows AF/Relic/Empy Marks totals).
-- Mirrors !giveinfamy / !givemarks in shape.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'sss',
}

-- Mark type -> { charVar, display label }.  Keys are what the GM types after
-- !givereforge; accept a couple of common aliases so muscle memory works.
local MARK_TYPES =
{
    af      = { cv = 'RF_AF_Marks',    name = 'AF'    },
    relic   = { cv = 'RF_Relic_Marks', name = 'Relic' },
    empy    = { cv = 'RF_Empy_Marks',  name = 'Empy'  },
    empyrean = { cv = 'RF_Empy_Marks', name = 'Empy'  },  -- alias
}

local ALL_KEYS = { 'af', 'relic', 'empy' }

commandObj.onTrigger = function(player, a1, a2, a3)
    local CH = xi.msg.channel.SYSTEM_3

    -- Signature: (type, amount, [name]).
    local kind   = a1 and string.lower(a1) or nil
    local amount = tonumber(a2)
    local name   = a3  -- may be nil

    if kind == nil or amount == nil or amount <= 0 then
        player:printToPlayer('Usage: !givereforge <af|relic|empy|all> <amount> [player]', CH)
        return
    end

    if kind ~= 'all' and MARK_TYPES[kind] == nil then
        player:printToPlayer(string.format('!givereforge: unknown mark type "%s" (use af, relic, empy, or all).', tostring(a1)), CH)
        return
    end

    amount = math.floor(amount)

    local target = player
    if name ~= nil then
        target = GetPlayerByName(name)
        if target == nil then
            player:printToPlayer(string.format('!givereforge: player "%s" not found or not online.', tostring(name)), CH)
            return
        end
    end

    local granted = {}  -- list of "N X Marks" strings, joined for reporting

    local function grantOne(key)
        local spec    = MARK_TYPES[key]
        local current = target:getCharVar(spec.cv) or 0
        target:setCharVar(spec.cv, current + amount)
        granted[#granted + 1] = string.format('%d %s Marks (total %d)', amount, spec.name, current + amount)
    end

    if kind == 'all' then
        for _, key in ipairs(ALL_KEYS) do
            grantOne(key)
        end
    else
        grantOne(kind)
    end

    local report = table.concat(granted, ', ')
    target:printToPlayer(string.format('[GM] You have been granted: %s.', report), CH)

    if target:getID() ~= player:getID() then
        player:printToPlayer(string.format('Granted %s to %s.', report, target:getName()), CH)
    end
end

return commandObj
