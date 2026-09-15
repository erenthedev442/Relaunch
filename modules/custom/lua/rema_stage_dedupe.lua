-----------------------------------
-- rema_stage_dedupe.lua
--
-- After the equipped-upgrade leak, players could hold more than one stage of
-- the same REMA family (Mandau 119 II + Mandau 119 III). Keep the highest
-- stage they own, and keep a lower stage only if that pilgrimage is still
-- active. Extra copies of a non-final highest stage are trimmed to one.
-- Final 119 III copies are left alone (repeat Relic / Empyrean / Mythic
-- forges are allowed to grant another).
-----------------------------------
require('modules/module_utils')

local forge     = require('modules/custom/lua/weapon_forge_catalog')
local pilgrimage = require('modules/custom/lua/legendary_pilgrimage_catalog')
local consume   = require('modules/custom/lua/consume_upgrade_item')

local m = Module:new('rema_stage_dedupe')

local ACTIVE_VARS = { 'LWP_Active1', 'LWP_Active2' }
local AEONIC_ACTIVE_VAR = 'LWP_AeonicActive'
local SYS = xi.msg.channel.SYSTEM_3

local FOUR = { 'base', '119 I', '119 II', '119 III' }
local THREE = { '119 I', '119 II', '119 III' }

local function uniqueStages(ids, labels)
    local seen, stages, stageLabels = {}, {}, {}
    for i, id in ipairs(ids) do
        if id and id > 0 and not seen[id] then
            seen[id] = true
            stages[#stages + 1] = id
            stageLabels[#stageLabels + 1] = labels[i] or ('stage ' .. #stages)
        end
    end
    return stages, stageLabels
end

local function addFamily(families, family, name, ids, labels)
    local stages, stageLabels = uniqueStages(ids, labels)
    if #stages < 2 then
        return
    end
    families[#families + 1] =
    {
        family = family,
        name   = name,
        stages = stages,
        labels = stageLabels,
        finalId = stages[#stages],
    }
end

local FAMILIES = {}
for _, chain in ipairs(forge.relicChains) do
    addFamily(FAMILIES, 'relic', chain.name, { chain.base, chain.s1, chain.s2, chain.s3 }, FOUR)
end
for _, chain in ipairs(forge.empyreanChains) do
    addFamily(FAMILIES, 'empyrean', chain.name, { chain.base, chain.s1, chain.s2, chain.s3 }, FOUR)
end
for _, chain in ipairs(forge.mythicChains) do
    addFamily(FAMILIES, 'mythic', chain.name, { chain.base, chain.s1, chain.s2, chain.s3 }, FOUR)
end
for _, chain in ipairs(forge.chains) do
    addFamily(FAMILIES, 'prime', chain.s3.name,
        { chain.s1.id, chain.s2.id, chain.s3.id }, THREE)
    local ae = chain.aeonic
    addFamily(FAMILIES, 'aeonic', ae.s3.name,
        { ae.base.id, ae.s1.id, ae.s2.id, ae.s3.id }, FOUR)
end

local function activeEntryFor(player, finalId)
    local want = pilgrimage.byFinalId[finalId]
    if not want then
        return nil
    end
    for _, var in ipairs(ACTIVE_VARS) do
        local entry = pilgrimage.byIndex[player:getCharVar(var) or 0]
        if entry and entry.finalId == finalId then
            return entry
        end
    end
    local aeonic = pilgrimage.byIndex[player:getCharVar(AEONIC_ACTIVE_VAR) or 0]
    if aeonic and aeonic.finalId == finalId then
        return aeonic
    end
    return nil
end

local function workingItemId(player, finalId)
    local entry = activeEntryFor(player, finalId)
    if not entry then
        return 0
    end
    local chapter = pilgrimage.chapter(player, entry)
    if chapter < 1 or chapter > 3 then
        return 0
    end
    return entry.stages[chapter] or 0
end

-- Pure planner: keepIds[id] = 'all' | 1
-- highestIsFinal keeps every copy of the 119 III (repeat forges).
function m.planKeep(stages, highestIdx, workingId)
    local keep = {}
    if not highestIdx or highestIdx < 1 then
        return keep
    end
    local highestId = stages[highestIdx]
    if highestIdx == #stages then
        keep[highestId] = 'all'
    else
        keep[highestId] = 1
    end
    if workingId and workingId > 0 then
        if keep[workingId] ~= 'all' then
            keep[workingId] = 1
        end
    end
    return keep
end

function m.families()
    return FAMILIES
end

function m.sweep(player)
    if not player then
        return 0
    end

    local removed = {}
    for _, fam in ipairs(FAMILIES) do
        local highestIdx = 0
        for i, id in ipairs(fam.stages) do
            if player:getItemCount(id) > 0 then
                highestIdx = i
            end
        end
        if highestIdx > 0 then
            local keep = m.planKeep(fam.stages, highestIdx, workingItemId(player, fam.finalId))
            for i, id in ipairs(fam.stages) do
                local have = player:getItemCount(id)
                if have > 0 then
                    local rule = keep[id]
                    local extra = have
                    if rule == 'all' then
                        extra = 0
                    elseif rule == 1 then
                        extra = have - 1
                    end
                    if extra > 0 and consume.qty(player, id, extra) then
                        removed[#removed + 1] = string.format('%s %s', fam.name, fam.labels[i])
                    end
                end
            end
        end
    end

    if #removed > 0 then
        player:printToPlayer(
            '[REMA] Removed leftover lower-tier copies: ' .. table.concat(removed, ', ')
                .. '. Your highest stage (and any active pilgrimage piece) was kept.',
            SYS)
    end
    return #removed
end

xi.remaStageDedupe = m

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    local isLogin = player:getLocalVar('gameLogin') == 1
    super(player, firstLogin, zoning)
    if not isLogin then
        return
    end
    player:timer(2000, function(p)
        if p then
            m.sweep(p)
        end
    end)
end)

return m
