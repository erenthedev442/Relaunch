-----------------------------------
-- The Name Beyond the Ferry
-- Persistent state, story data, and progression rules for the Eren quest.
--
-- All durable state is held in integer charVars.  This file deliberately has
-- no Module overrides, so commands, menus, tests, and the private-instance
-- runtime can share the same rules without depending on module load order.
-----------------------------------
local KEY = 'modules/custom/lua/eren_quest_catalog'
local C = package.loaded[KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[KEY] = C

local FN = require('modules/custom/lua/fellow_name')

C.title = 'The Name Beyond the Ferry'
C.instanceId = 14001
C.instanceZone = 140 -- Ghelsba Outpost hybrid instance
C.entranceZone = 44  -- Abdhaljs Isle-Purgonorgo

C.stage =
{
    LOCKED       = 0,
    SECOND_SHADOW = 1,
    PILGRIMAGE   = 2,
    REMEMBRANCES = 3,
    BOND         = 4,
    EREN         = 5,
    CROSSING     = 6,
    DECISION     = 7,
    COMPLETE     = 8,
}

C.vars =
{
    access       = 'ErenQuestTester',
    stage        = 'ErenQuestStage',
    sites        = 'ErenQuestSites',
    memories     = 'ErenQuestMemories',
    encounter    = 'ErenQuestEncounter',
    pending      = 'ErenQuestPending',
    active       = 'ErenQuestActive',
    savedRole    = 'ErenQuestSavedRole',
    legacy       = 'Fellow_ErenLegacy',
    legacyNotice = 'Fellow_ErenLegacyNotice',
    unlocked     = 'Fellow_ErenUnlocked',
    oldNameFlag  = 'Fellow_ErenOldName',
}

C.oldNameWords =
{
    'Fellow_ErenOldNameW0',
    'Fellow_ErenOldNameW1',
    'Fellow_ErenOldNameW2',
    'Fellow_ErenOldNameW3',
}

C.roleIndex =
{
    vanguard  = 1,
    berserker = 2,
    bulwark   = 3,
    oracle    = 4,
    magus     = 5,
    hunter    = 6,
    mastered  = 7,
}

C.siteOrder = { 'gusgen', 'feiyin', 'xarcabard', 'echoes' }
C.sites =
{
    gusgen =
    {
        bit = 0,
        encounter = 1,
        label = 'The Broken Memorial',
        packetName = 'Old Memorial',
        zone = 'Gusgen_Mines',
        zoneId = 196,
        direction = 'Gusgen Mines: search beside the first descent, near the old memorial lamps.',
        pos = { x = 51.0, y = -67.0, z = -333.0, rot = 126 },
        look = 240,
    },
    feiyin =
    {
        bit = 1,
        encounter = 2,
        label = 'The First Promise',
        packetName = 'Frozen Echo',
        zone = 'FeiYin',
        zoneId = 204,
        direction = "Fei'Yin: listen where the entrance hall first gives way to ice.",
        pos = { x = -173.0, y = -24.0, z = -181.0, rot = 198 },
        look = 236,
    },
    xarcabard =
    {
        bit = 2,
        encounter = 3,
        label = 'The Consuming Shade',
        packetName = 'Cold Trace',
        zone = 'Xarcabard',
        zoneId = 112,
        direction = 'Xarcabard: follow the cold trace just beyond the southern approach.',
        pos = { x = 164.0, y = -21.0, z = -39.0, rot = 132 },
        look = 239,
    },
    echoes =
    {
        bit = 3,
        encounter = 4,
        label = 'The Final Footprint',
        packetName = 'Echoing Scar',
        zone = 'Walk_of_Echoes',
        zoneId = 182,
        direction = 'Walk of Echoes: the thread answers near the first echoing platform.',
        pos = { x = -406.0, y = 14.0, z = -58.0, rot = 64 },
        look = 238,
    },
}

C.memoryOrder = { 'resolve', 'guardianship', 'discernment', 'insight', 'fury', 'mercy' }
C.memories =
{
    resolve =
    {
        bit = 0,
        encounter = 10,
        role = 'vanguard',
        label = 'Resolve',
        summary = 'Breach the ward while your partner creates the opening.',
    },
    guardianship =
    {
        bit = 1,
        encounter = 11,
        role = 'bulwark',
        label = 'Guardianship',
        summary = 'Hold the Warden while three bound souls are released.',
    },
    discernment =
    {
        bit = 2,
        encounter = 12,
        role = 'hunter',
        label = 'Discernment',
        summary = 'Find the true shade among healing decoys.',
    },
    insight =
    {
        bit = 3,
        encounter = 13,
        role = 'magus',
        label = 'Insight',
        summary = 'Break clustered elemental seals before their ward reforms.',
    },
    fury =
    {
        bit = 4,
        encounter = 14,
        role = 'berserker',
        label = 'Fury',
        summary = 'Overcome the devourer during brief wound windows.',
    },
    mercy =
    {
        bit = 5,
        encounter = 15,
        role = 'oracle',
        label = 'Mercy',
        summary = 'Survive crossing decay while the rifts are closed.',
    },
}

C.encounters =
{
    [1]  = { key = 'gusgen',       label = 'The Broken Memorial', role = nil,         kind = 'waves',      hp = 400000,  level = 99,  time = 12 },
    [2]  = { key = 'feiyin',       label = 'The First Promise',   role = nil,         kind = 'defense',    hp = 900000,  level = 99,  time = 15 },
    [3]  = { key = 'xarcabard',    label = 'The Consuming Shade', role = nil,         kind = 'boss',       hp = 2500000, level = 99,  time = 15 },
    [4]  = { key = 'echoes',       label = 'The Final Footprint', role = nil,         kind = 'waves',      hp = 1000000, level = 99,  time = 15 },
    [5]  = { key = 'gusgen',       label = 'A Corrective Memory', role = nil,         kind = 'correction', hp = 600000,  level = 99,  time = 10, checkpoint = false },
    [10] = { key = 'resolve',      label = 'Remembrance: Resolve',      role = 'vanguard',  kind = 'resolve',  hp = 4000000, level = 105, time = 18 },
    [11] = { key = 'guardianship', label = 'Remembrance: Guardianship', role = 'bulwark',   kind = 'warden',   hp = 5000000, level = 105, time = 18 },
    [12] = { key = 'discernment',  label = 'Remembrance: Discernment',  role = 'hunter',    kind = 'decoys',   hp = 5000000, level = 105, time = 18 },
    [13] = { key = 'insight',      label = 'Remembrance: Insight',      role = 'magus',     kind = 'seals',    hp = 4000000, level = 105, time = 18 },
    [14] = { key = 'fury',         label = 'Remembrance: Fury',         role = 'berserker', kind = 'wounds',   hp = 6000000, level = 105, time = 18 },
    [15] = { key = 'mercy',        label = 'Remembrance: Mercy',        role = 'oracle',    kind = 'decay',    hp = 3000000, level = 105, time = 18 },
    [20] = { key = 'bond',         label = 'The Bond That Remains', kind = 'bond',     hp = 3000000, level = 110, time = 22 },
    [30] = { key = 'eren',         label = 'Eren, Unwhole',         kind = 'eren',     hp = 6000000, level = 115, time = 22 },
    [40] = { key = 'crossing',     label = 'The Last Crossing',     kind = 'crossing', hp = 8000000, level = 120, time = 25 },
}

C.encounterPos =
{
    entry = { x = -165.357, y = -11.672, z = 77.771, rot = 191 },
    player = { x = -183.0, y = -10.0, z = 45.0, rot = 64 },
    center = { x = -202.0, y = -10.0, z = 45.0, rot = 192 },
}

local function getN(player, variable)
    return player:getCharVar(variable) or 0
end

local function setN(player, variable, value)
    player:setCharVar(variable, math.max(0, math.floor(tonumber(value) or 0)))
end

local function hasBit(value, bitIndex)
    return bit.band(value, bit.lshift(1, bitIndex)) ~= 0
end

local function setBit(value, bitIndex)
    return bit.bor(value, bit.lshift(1, bitIndex))
end

local packWords

function C.getStage(player)
    return getN(player, C.vars.stage)
end

function C.setStage(player, value)
    setN(player, C.vars.stage, value)
end

function C.isUnlocked(player)
    return getN(player, C.vars.unlocked) == 1
end

function C.hasAccess(player)
    if not player then
        return false
    end

    local gm = 0
    pcall(function() gm = player:getGMLevel() or 0 end)
    return gm > 0 or getN(player, C.vars.access) == 1
end

function C.isMastered(player)
    if xi.fellow and xi.fellow.isMastered then
        return xi.fellow.isMastered(player)
    end

    local stats =
    {
        'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND',
        'Ferocity', 'Critical', 'Frenzy', 'Onslaught',
        'Sorcery', 'Celerity', 'Warding', 'Vigor',
    }
    for _, stat in ipairs(stats) do
        if getN(player, 'Fellow_' .. stat) < 100 then
            return false
        end
    end
    return true
end

function C.fellowName(player)
    if xi.fellow and xi.fellow.resolveName then
        return xi.fellow.resolveName(player)
    end
    return FN.read(player) or 'Fellow'
end

function C.hasLivingFellow(player)
    local fellow = xi.fellow and xi.fellow.getTrust and xi.fellow.getTrust(player) or nil
    if not fellow then
        return false
    end

    local hp = 0
    local valid = pcall(function() hp = fellow:getHP() end)
    return valid and hp > 0
end

function C.canAccept(player)
    if not C.hasAccess(player) then
        return false, 'access'
    elseif C.isUnlocked(player) or C.getStage(player) >= C.stage.COMPLETE then
        return false, 'complete'
    elseif C.getStage(player) ~= C.stage.LOCKED then
        return false, 'started'
    elseif not C.isMastered(player) then
        return false, 'mastery'
    end
    return true
end

-- Repair interrupted multi-charVar writes monotonically.  No completed bit is
-- ever removed, and a partially-written transformation always resolves toward
-- the irreversible completed state once Fellow_ErenUnlocked was persisted.
function C.reconcile(player)
    local stage = C.getStage(player)
    local sites = getN(player, C.vars.sites)
    local memories = getN(player, C.vars.memories)
    local unlocked = C.isUnlocked(player)

    if unlocked or stage >= C.stage.COMPLETE then
        if getN(player, C.vars.oldNameFlag) == 0 then
            packWords(player, C.vars.oldNameFlag, C.oldNameWords, C.fellowName(player))
        end
        player:setCharVar(C.vars.unlocked, 1)
        player:setCharVar(C.vars.legacy, 0)
        FN.pack(player, 'Eren')
        C.setStage(player, C.stage.COMPLETE)
        return C.stage.COMPLETE
    end

    if stage >= C.stage.PILGRIMAGE and bit.band(sites, 0x0F) == 0x0F and stage < C.stage.REMEMBRANCES then
        stage = C.stage.REMEMBRANCES
    end
    if stage >= C.stage.REMEMBRANCES and bit.band(memories, 0x3F) == 0x3F and stage < C.stage.BOND then
        stage = C.stage.BOND
    end
    if stage ~= C.getStage(player) then
        C.setStage(player, stage)
    end
    return stage
end

function C.shouldShowOfficer(player)
    if not C.hasAccess(player) then
        return false
    end
    return C.isUnlocked(player) or C.getStage(player) > 0 or C.isMastered(player)
end

function C.accept(player)
    local ok, reason = C.canAccept(player)
    if not ok then
        return false, reason
    end
    C.setStage(player, C.stage.SECOND_SHADOW)
    return true
end

function C.beginPilgrimage(player)
    if not C.hasAccess(player) or C.getStage(player) ~= C.stage.SECOND_SHADOW then
        return false
    end
    C.setStage(player, C.stage.PILGRIMAGE)
    return true
end

function C.siteComplete(player, key)
    local site = C.sites[key]
    return site ~= nil and hasBit(getN(player, C.vars.sites), site.bit)
end

function C.creditSite(player, key)
    C.reconcile(player)
    local site = C.sites[key]
    if not site or C.getStage(player) ~= C.stage.PILGRIMAGE then
        return false
    end

    local mask = getN(player, C.vars.sites)
    if hasBit(mask, site.bit) then
        return false
    end

    mask = setBit(mask, site.bit)
    setN(player, C.vars.sites, mask)
    if bit.band(mask, 0x0F) == 0x0F then
        C.setStage(player, C.stage.REMEMBRANCES)
    end
    return true
end

function C.memoryComplete(player, key)
    local memory = C.memories[key]
    return memory ~= nil and hasBit(getN(player, C.vars.memories), memory.bit)
end

function C.creditMemory(player, key)
    C.reconcile(player)
    local memory = C.memories[key]
    if not memory or C.getStage(player) ~= C.stage.REMEMBRANCES then
        return false
    end

    local mask = getN(player, C.vars.memories)
    if hasBit(mask, memory.bit) then
        return false
    end

    mask = setBit(mask, memory.bit)
    setN(player, C.vars.memories, mask)
    if bit.band(mask, 0x3F) == 0x3F then
        C.setStage(player, C.stage.BOND)
    end
    return true
end

function C.creditEncounter(player, encounterId)
    local definition = C.encounters[encounterId]
    if not definition then
        return false
    elseif encounterId >= 1 and encounterId <= 4 then
        return C.creditSite(player, definition.key)
    elseif encounterId >= 10 and encounterId <= 15 then
        return C.creditMemory(player, definition.key)
    elseif encounterId == 20 and C.getStage(player) == C.stage.BOND then
        C.setStage(player, C.stage.EREN)
        return true
    elseif encounterId == 30 and C.getStage(player) == C.stage.EREN then
        C.setStage(player, C.stage.CROSSING)
        return true
    elseif encounterId == 40 and C.getStage(player) == C.stage.CROSSING then
        C.setStage(player, C.stage.DECISION)
        return true
    end
    return false
end

function C.encounterAvailable(player, encounterId)
    C.reconcile(player)
    local definition = C.encounters[encounterId]
    if not definition or not C.hasAccess(player) or not C.isMastered(player) then
        return false
    end

    local stage = C.getStage(player)
    if encounterId >= 1 and encounterId <= 4 then
        return stage == C.stage.PILGRIMAGE and not C.siteComplete(player, definition.key)
    elseif encounterId == 5 then
        return stage == C.stage.PILGRIMAGE and not C.siteComplete(player, 'gusgen')
    elseif encounterId >= 10 and encounterId <= 15 then
        return stage == C.stage.REMEMBRANCES and not C.memoryComplete(player, definition.key)
    elseif encounterId == 20 then
        return stage == C.stage.BOND
    elseif encounterId == 30 then
        return stage == C.stage.EREN
    elseif encounterId == 40 then
        return stage == C.stage.CROSSING
    end
    return false
end

packWords = function(player, flag, words, name)
    local bytes = { tostring(name or 'Fellow'):byte(1, FN.MAXLEN) }
    for word = 0, 3 do
        local value = 0
        for byte = 0, 3 do
            value = bit.bor(value, bit.lshift(bytes[word * 4 + byte + 1] or 0, byte * 8))
        end
        player:setCharVar(words[word + 1], value)
    end
    player:setCharVar(flag, 1)
end

local function unpackWords(player, flag, words)
    if getN(player, flag) == 0 then
        return nil
    end

    local chars = {}
    for word = 0, 3 do
        local value = getN(player, words[word + 1])
        for byte = 0, 3 do
            local char = bit.band(bit.rshift(value, byte * 8), 0xFF)
            if char == 0 then
                return #chars > 0 and table.concat(chars) or nil
            end
            chars[#chars + 1] = string.char(char)
        end
    end
    return #chars > 0 and table.concat(chars) or nil
end

function C.formerName(player)
    return unpackWords(player, C.vars.oldNameFlag, C.oldNameWords) or 'your old companion'
end

function C.transform(player)
    if
        not C.hasAccess(player) or
        C.getStage(player) ~= C.stage.DECISION or
        not C.isMastered(player)
    then
        return false
    end

    packWords(player, C.vars.oldNameFlag, C.oldNameWords, C.fellowName(player))
    player:setCharVar(C.vars.unlocked, 1)
    player:setCharVar(C.vars.legacy, 0)
    FN.pack(player, 'Eren')
    C.setStage(player, C.stage.COMPLETE)
    return true
end

function C.migrateLegacy(player, notify)
    if C.isUnlocked(player) then
        return false
    end

    local name = FN.read(player)
    if type(name) ~= 'string' or name:lower() ~= 'eren' then
        return false
    end

    player:setCharVar(C.vars.legacy, 1)
    if notify and getN(player, C.vars.legacyNotice) == 0 then
        player:setCharVar(C.vars.legacyNotice, 1)
        local message = '[Fellow] The name Eren remains, but its old name-only powers have faded. Naming alone no longer unlocks that form.'
        if C.hasAccess(player) then
            message = message .. ' Complete The Name Beyond the Ferry to make the transformation real.'
        end
        player:printToPlayer(message, xi.msg.channel.SYSTEM_3)
    end
    return true
end

function C.statusLines(player)
    local stage = C.reconcile(player)
    local lines = { '[Eren Quest] ' .. C.title }
    if C.isUnlocked(player) then
        lines[#lines + 1] = string.format('Complete. %s and Eren now answer as one.', C.formerName(player))
    elseif stage == C.stage.LOCKED then
        lines[#lines + 1] = 'Not begun. Master every Fellow stat track and speak with the Fellow Officer.'
    elseif stage == C.stage.SECOND_SHADOW then
        lines[#lines + 1] = 'The Officer saw a second shadow. Speak with Hades on the northeastern beach.'
    elseif stage == C.stage.PILGRIMAGE then
        lines[#lines + 1] = 'Follow the Thread of the Uncrossed:'
        for _, key in ipairs(C.siteOrder) do
            local site = C.sites[key]
            lines[#lines + 1] = string.format('  %s %s', C.siteComplete(player, key) and '[Done]' or '[ ]', site.direction)
        end
    elseif stage == C.stage.REMEMBRANCES then
        lines[#lines + 1] = 'Hades can open the six Remembrance trials:'
        for _, key in ipairs(C.memoryOrder) do
            local memory = C.memories[key]
            lines[#lines + 1] = string.format(
                '  %s %s (%s)', C.memoryComplete(player, key) and '[Done]' or '[ ]', memory.label, memory.role)
        end
    elseif stage == C.stage.BOND then
        lines[#lines + 1] = 'Six memories are whole. Ask Hades to open The Bond That Remains.'
    elseif stage == C.stage.EREN then
        lines[#lines + 1] = 'Your Fellow chose to continue. Ask Hades to face Eren, Unwhole.'
    elseif stage == C.stage.CROSSING then
        lines[#lines + 1] = 'Eren consented to the merger. Ask Hades to open the Last Crossing.'
    elseif stage == C.stage.DECISION then
        lines[#lines + 1] = 'The crossing is clear. Return to Hades for the permanent choice.'
    end
    return lines
end

return C
