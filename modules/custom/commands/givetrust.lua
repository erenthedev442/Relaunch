-----------------------------------
-- func: givetrust
-- desc: [GM] Grant a paid Void Keeper trust to a player, free of charge --
--       the same trusts the Void Keeper sells for gil, but bestowed at will.
--       Trusts: gemma (901), meat (899), corvus (902), cornelia (1002),
--       matsui-p / matsui (1004 = Excenmille S slot).
--
-- Usage:  !givetrust <gemma|meat|corvus|cornelia|matsui> <player>
--         !givetrust <gemma|meat|corvus|cornelia|matsui>  (grant to yourself)
--
-- The player casts it from their Trust menu under the repurposed client name
-- shown below (e.g. Gemma is cast as "Nanaa Mihgo").
-----------------------------------
local TRUSTS =
{
    gemma     = { spell = 901,  client = 'Nanaa Mihgo' },
    meat      = { spell = 899,  client = 'Excenmille'  },
    corvus    = { spell = 902,  client = 'Curilla'     },
    cornelia  = { spell = 1002, client = 'Cornelia'    },
    matsui    = { spell = 1004, client = 'Excenmille (S)' },
    ['matsui-p'] = { spell = 1004, client = 'Excenmille (S)' },
    matsuip   = { spell = 1004, client = 'Excenmille (S)' },
}

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,   -- Owner/developer GM only
    parameters = 'ss',
}

commandObj.onTrigger = function(player, trustName, name)
    local CH  = xi.msg.channel.SYSTEM_3
    local def = trustName and TRUSTS[string.lower(trustName)]
    if not def then
        player:printToPlayer('Usage: !givetrust <gemma|meat|corvus|cornelia|matsui> [player]', CH)
        return
    end

    -- Recipient: a named online player, or the GM if no name given.
    local target = player
    if name ~= nil then
        target = GetPlayerByName(name)
        if target == nil then
            player:printToPlayer(string.format('!givetrust: player "%s" not found or not online.', tostring(name)), CH)
            return
        end
    end

    if target:hasSpell(def.spell) then
        player:printToPlayer(string.format('%s already has the %s trust.', target:getName(), string.lower(trustName)), CH)
        return
    end

    if xi.trustGrant and xi.trustGrant.grantSpell then
        xi.trustGrant.grantSpell(target, def.spell)
    else
        target:addSpell(def.spell)
    end
    target:printToPlayer(string.format('A trust has been bestowed upon you! Cast "%s" from your Trust menu to summon it.', def.client), CH)

    if target:getID() ~= player:getID() then
        player:printToPlayer(string.format('Granted the %s trust (cast "%s") to %s.', string.lower(trustName), def.client, target:getName()), CH)
    end
end

return commandObj
