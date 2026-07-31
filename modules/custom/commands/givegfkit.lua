-----------------------------------
-- !givegfkit [player]
-- Gilfarm kit: Sakpata 5/5 + listed accessories. Each piece gets one max
-- T5 Gilfinder augment (aug 148, boost 19 -> Gilfinder +20).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 's',
}

-- Gilfinder augment id 148; maxBoost 19 -> (1+19)*1 = +20
local GF_AUG = 148
local GF_VAL = 19

local KIT =
{
    -- Sakpata 5/5
    { id = 23757, name = "Sakpata's Helm" },
    { id = 23764, name = "Sakpata's Breastplate" },
    { id = 23771, name = "Sakpata's Gauntlets" },
    { id = 23778, name = "Sakpata's Cuisses" },
    { id = 23785, name = "Sakpata's Leggings" },
    -- Accessories / tools
    { id = 15543, name = 'Rajas Ring' },
    { id = 13566, name = 'Defending Ring' },
    { id = 11018, name = 'Thunder Pearl' },
    { id = 11018, name = 'Thunder Pearl' },
    { id = 25419, name = "Warrior's Beads +2" },
    { id = 17386, name = "Lu Shang's Fishing Rod" },
    { id = 17402, name = 'Shrimp Lure' },
    { id = 26268, name = 'Moonbeam Cape' },
    { id = 28460, name = 'Cetl Belt' },
}

local function gfExdata()
    return
    {
        augmentKind    = xi.augment.kind.HAS_AUGMENTS,
        augmentSubKind = xi.augment.subKind.STANDARD,
        augments       =
        {
            { id = GF_AUG, value = GF_VAL },
        },
    }
end

commandObj.onTrigger = function(player, targetName)
    local targ = player
    if targetName and targetName ~= '' then
        targ = GetPlayerByName(targetName)
        if not targ then
            player:printToPlayer(string.format('[givegfkit] Player "%s" not found / offline.', targetName))
            return
        end
    end

    if targ:getFreeSlotsCount() < #KIT then
        player:printToPlayer(string.format(
            '[givegfkit] Need %d free inventory slots (have %d).',
            #KIT, targ:getFreeSlotsCount()))
        return
    end

    local ok = 0
    for _, entry in ipairs(KIT) do
        if targ:addItem({ id = entry.id, quantity = 1, exdata = gfExdata() }) then
            ok = ok + 1
        else
            player:printToPlayer(string.format('[givegfkit] Failed to give %s (%d).', entry.name, entry.id))
        end
    end

    local msg = string.format(
        '[givegfkit] Gave %d/%d pieces to %s (Gilfinder +20 / piece, aug 148 boost 19).',
        ok, #KIT, targ:getName())
    player:printToPlayer(msg)
    if targ:getID() ~= player:getID() then
        targ:printToPlayer(msg)
    end
end

return commandObj
