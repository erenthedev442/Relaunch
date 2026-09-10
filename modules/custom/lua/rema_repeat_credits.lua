-----------------------------------
-- One discounted REMA repeat per proper Weapon Forge finish.
--
-- Relic / Empyrean / Mythic / Aeonic repeaters stay independent. A repeat
-- sale does not count as a proper finish. Prime is unchanged.
--
-- Existing players who already have WF_<Family>_Final and no counters are
-- treated as having one unused credit.
-----------------------------------
local KEY = 'modules/custom/lua/rema_repeat_credits'
local M = package.loaded[KEY]
if type(M) ~= 'table' then
    M = {}
end
package.loaded[KEY] = M

M.FAMILIES =
{
    relic =
    {
        finalVar  = 'WF_Relic_Final',
        properVar = 'WF_Relic_ProperCount',
        spentVar  = 'WF_Relic_RepeatSpent',
        label     = 'Relic',
    },
    empyrean =
    {
        finalVar  = 'WF_Empyrean_Final',
        properVar = 'WF_Empyrean_ProperCount',
        spentVar  = 'WF_Empyrean_RepeatSpent',
        label     = 'Empyrean',
    },
    mythic =
    {
        finalVar  = 'WF_Mythic_Final',
        properVar = 'WF_Mythic_ProperCount',
        spentVar  = 'WF_Mythic_RepeatSpent',
        label     = 'Mythic',
    },
    aeonic =
    {
        finalVar  = 'WF_Aeonic_Final',
        properVar = 'WF_Aeonic_ProperCount',
        spentVar  = 'WF_Aeonic_RepeatSpent',
        label     = 'Aeonic',
    },
}

local function spec(family)
    return M.FAMILIES[family]
end

local function charVar(player, name)
    if not player or not player.getCharVar then
        return 0
    end

    return player:getCharVar(name) or 0
end

local function impliedProper(player, familySpec)
    local proper = charVar(player, familySpec.properVar)
    if proper == 0 and charVar(player, familySpec.finalVar) == 1 then
        return 1
    end

    return proper
end

function M.available(player, family)
    local familySpec = spec(family)
    if not familySpec then
        return 0
    end

    return math.max(0, impliedProper(player, familySpec) - charVar(player, familySpec.spentVar))
end

-- Call after WF_<Family>_Final is set. alreadyHadFinal is the flag value
-- from before this completion so a grandfathered first Relic is not lost
-- when they finish a second one on the real forge.
function M.noteProperCompletion(player, family, alreadyHadFinal)
    local familySpec = spec(family)
    if not familySpec or not player or not player.setCharVar then
        return 0
    end

    local proper = charVar(player, familySpec.properVar)
    if proper == 0 and alreadyHadFinal == 1 then
        proper = 1
    end

    proper = proper + 1
    player:setCharVar(familySpec.properVar, proper)
    player:setCharVar(familySpec.finalVar, 1)
    return proper
end

function M.trySpend(player, family)
    local familySpec = spec(family)
    if not familySpec or not player or not player.setCharVar then
        return false
    end

    local proper = impliedProper(player, familySpec)
    if charVar(player, familySpec.properVar) == 0 and proper == 1 then
        player:setCharVar(familySpec.properVar, 1)
    end

    local spent = charVar(player, familySpec.spentVar)
    if proper - spent <= 0 then
        return false
    end

    player:setCharVar(familySpec.spentVar, spent + 1)
    return true
end

function M.closedMessage(family, prefix)
    local familySpec = spec(family)
    local label = familySpec and familySpec.label or 'ultimate'
    return string.format(
        '%s I have no more work for you at the moment. Come back once you have created more %s weapons the proper way at the Weapon Forge.',
        prefix or '',
        label):gsub('^%s+', '')
end

return M
