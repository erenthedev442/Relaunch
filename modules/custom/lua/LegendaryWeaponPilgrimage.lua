-----------------------------------
-- Legendary Weapon Pilgrimage runtime
-----------------------------------
require('modules/module_utils')

local C = require('modules/custom/lua/legendary_pilgrimage_catalog')
local m = Module:new('legendary_weapon_pilgrimage')

xi.legendaryPilgrimage = xi.legendaryPilgrimage or {}
local P = xi.legendaryPilgrimage
P.catalog = C

local SYS = xi.msg.channel.SYSTEM_3
local ACTIVE_VARS = { 'LWP_Active1', 'LWP_Active2' }
local ABYSSEA_ZONES =
{
    [xi.zone.ABYSSEA_KONSCHTAT] = true, [xi.zone.ABYSSEA_TAHRONGI] = true,
    [xi.zone.ABYSSEA_LA_THEINE] = true, [xi.zone.ABYSSEA_ATTOHWA] = true,
    [xi.zone.ABYSSEA_MISAREAUX] = true, [xi.zone.ABYSSEA_VUNKERL] = true,
    [xi.zone.ABYSSEA_ALTEPA] = true, [xi.zone.ABYSSEA_GRAUBERG] = true,
    [xi.zone.ABYSSEA_ULEGUERAND] = true,
}
local JOB_NAMES =
{
    [xi.job.WAR] = 'WAR', [xi.job.MNK] = 'MNK', [xi.job.WHM] = 'WHM',
    [xi.job.BLM] = 'BLM', [xi.job.RDM] = 'RDM', [xi.job.THF] = 'THF',
    [xi.job.PLD] = 'PLD', [xi.job.DRK] = 'DRK', [xi.job.BST] = 'BST',
    [xi.job.BRD] = 'BRD', [xi.job.RNG] = 'RNG', [xi.job.SAM] = 'SAM',
    [xi.job.NIN] = 'NIN', [xi.job.DRG] = 'DRG', [xi.job.SMN] = 'SMN',
    [xi.job.BLU] = 'BLU', [xi.job.COR] = 'COR', [xi.job.PUP] = 'PUP',
    [xi.job.DNC] = 'DNC', [xi.job.SCH] = 'SCH', [xi.job.GEO] = 'GEO',
    [xi.job.RUN] = 'RUN',
}

local function activeEntries(player)
    local entries = {}
    for _, var in ipairs(ACTIVE_VARS) do
        local entry = C.byIndex[player:getCharVar(var) or 0]
        if entry then entries[#entries + 1] = entry end
    end
    return entries
end

local function activeEntry(player, index)
    for _, entry in ipairs(activeEntries(player)) do
        if not index or entry.index == index then return entry end
    end
    return nil
end

local function entryUnlocked(player, entry)
    return C.entryUnlocked(player, entry)
end

local function equippedForChapter(player, entry, chapter)
    return entryUnlocked(player, entry)
        and chapter >= 1 and chapter <= 3
        and player:getEquipID(entry.slot) == entry.stages[chapter]
end

local function ownsChain(player, entry)
    for _, itemId in ipairs(entry.stages) do
        if player:getItemCount(itemId) > 0 then return true end
    end
    return false
end

local function displayName(entity)
    local packetName = entity:getPacketName()
    return packetName ~= '' and packetName or entity:getName()
end

local function targetIndex(requirement, mob)
    return C.targetIndex(requirement, mob:getName())
        or C.targetIndex(requirement, mob:getPacketName())
end

function P.register(player, entry)
    if entry and not entryUnlocked(player, entry) then
        return false, 'Forge a final Aeonic weapon before beginning a Prime pilgrimage.'
    end
    if not entry or not ownsChain(player, entry) then
        return false, 'You must possess a weapon from that exact chain.'
    end
    if C.chapter(player, entry) == 4 then
        return false, 'That pilgrimage is already complete.'
    end
    if activeEntry(player, entry.index) then
        return false, 'That pilgrimage is already active.'
    end
    for _, var in ipairs(ACTIVE_VARS) do
        if (player:getCharVar(var) or 0) == 0 then
            player:setCharVar(var, entry.index)
            return true
        end
    end
    return false, 'You may have at most two active pilgrimages.'
end

function P.abandon(player, entry)
    for _, var in ipairs(ACTIVE_VARS) do
        if (player:getCharVar(var) or 0) == entry.index then
            player:setCharVar(var, 0)
            return true
        end
    end
    return false
end

function P.isComplete(player, finalId)
    return C.isComplete(player, finalId)
end

local function markProgress(player, entry, chapter, targetName)
    local requirement = entry.chapters[chapter]
    local progressVar = C.progressVar(entry.index, chapter)
    local current = player:getCharVar(progressVar) or 0
    if current >= requirement.count then return end

    if requirement.distinct then
        local targetIndex = C.targetIndex(requirement, targetName)
        if not targetIndex then return end
        local maskVar = C.maskVar(entry.index, chapter)
        local mask = player:getCharVar(maskVar) or 0
        local flag = bit.lshift(1, targetIndex - 1)
        if bit.band(mask, flag) ~= 0 then return end
        player:setCharVar(maskVar, bit.bor(mask, flag))
    end

    current = math.min(requirement.count, current + 1)
    player:setCharVar(progressVar, current)
    player:printToPlayer(string.format(
        '[Pilgrimage] %s Chapter %s: %d/%d.',
        entry.name, ({ 'I', 'II', 'III' })[chapter], current, requirement.count), SYS)
    if current >= requirement.count then
        player:printToPlayer(string.format(
            '[Pilgrimage] %s Chapter %s complete.',
            entry.name, ({ 'I', 'II', 'III' })[chapter]), SYS)
    end
end

local function targetEligible(player, mob, entry, chapter)
    local requirement = entry.chapters[chapter]
    local function ecosystemMatches()
        local ecosystem = mob:getEcosystem()
        for _, allowed in ipairs(requirement.ecosystems or {}) do
            if ecosystem == allowed then return true end
        end
        return requirement.ecosystems == nil
    end
    if requirement.targets then
        return targetIndex(requirement, mob) ~= nil
    end
    if requirement.tag == 'abyssea_ecology' then
        return ABYSSEA_ZONES[mob:getZoneID()] == true and ecosystemMatches()
    elseif requirement.tag == 'job_mastery' then
        local jobName = JOB_NAMES[player:getMainJob()]
        return jobName ~= nil and entry.jobs:find(jobName, 1, true) ~= nil and mob:isNM()
    elseif requirement.tag == 'magian_family' then
        return mob:getMainLvl() >= requirement.minLevel
            and mob:getMaxHP() >= requirement.minMaxHP
            and ecosystemMatches()
    end
    return false
end

local function setSupportReady(player, entry, chapter, target)
    local sameTarget = player:getLocalVar('LWP_SupportEntry') == entry.index
        and player:getLocalVar('LWP_SupportChapter') == chapter
        and player:getLocalVar('LWP_SupportTarget') == target:getID()
    player:setLocalVar('LWP_SupportEntry', entry.index)
    player:setLocalVar('LWP_SupportChapter', chapter)
    player:setLocalVar('LWP_SupportTarget', target:getID())
    if not sameTarget then
        player:printToPlayer(
            string.format('[Pilgrimage] %s support condition met; defeat %s to earn credit.',
                entry.name, displayName(target)), SYS)
    end
end

local function onDefeatedMob(mob, player, opt)
    if not mob or not player or not opt then return end

    if player:getLocalVar('LWP_SupportTarget') == mob:getID() then
        local entry = activeEntry(player, player:getLocalVar('LWP_SupportEntry'))
        local chapter = player:getLocalVar('LWP_SupportChapter')
        if
            entry and
            chapter == C.chapter(player, entry) and
            entry.chapters[chapter].kind == 'support_ws' and
            equippedForChapter(player, entry, chapter) and
            not player:isDead() and
            player:checkKillCredit(mob)
        then
            markProgress(player, entry, chapter, displayName(mob))
        end
        player:setLocalVar('LWP_SupportEntry', 0)
        player:setLocalVar('LWP_SupportChapter', 0)
        player:setLocalVar('LWP_SupportTarget', 0)
    end

    if not opt.isKiller or not opt.isWeaponSkillKill then return end
    if not opt.weaponskillUsed or not opt.weaponskillDamage or opt.weaponskillDamage <= 0 then return end
    if player:isDead() or not player:checkKillCredit(mob) then return end

    for _, entry in ipairs(activeEntries(player)) do
        local chapter = C.chapter(player, entry)
        local requirement = entry.chapters[chapter]
        if
            chapter <= 3 and
            (requirement.kind == 'ws_kills' or requirement.kind == 'named_ws_kills') and
            opt.weaponskillUsed == entry.wsId and
            equippedForChapter(player, entry, chapter) and
            player:getLocalVar('LWP_SnapEntry') == entry.index and
            player:getLocalVar('LWP_SnapTarget') == mob:getID() and
            player:getLocalVar('LWP_SnapWS') == entry.wsId and
            player:getLocalVar('LWP_SnapPass') == 1 and
            (not entry.archetypeRule.minDamage or
                opt.weaponskillDamage >= entry.archetypeRule.minDamage) and
            targetEligible(player, mob, entry, chapter)
        then
            markProgress(player, entry, chapter, displayName(mob))
        end
    end
end

local function onWeaponskill(attacker, target, skill, tp, action, damage)
    if not attacker or not target or target:getObjType() ~= xi.objType.MOB then return end
    local wsId = skill:getID()
    for _, entry in ipairs(activeEntries(attacker)) do
        local chapter = C.chapter(attacker, entry)
        local requirement = entry.chapters[chapter]
        if
            chapter <= 3 and
            wsId == entry.wsId and
            equippedForChapter(attacker, entry, chapter)
        then
            if requirement.kind == 'support_ws' and requirement.utility == 'atonement' then
                if
                    targetIndex(requirement, target) and
                    damage ~= nil and damage > 0 and
                    attacker:checkKillCredit(target)
                then
                    setSupportReady(attacker, entry, chapter, target)
                end
            end
        end
    end
end

function P.onSupportWs(player, target, wsId, values)
    if not player or not values then return end
    local combatTarget = target
    if not combatTarget or combatTarget:getObjType() ~= xi.objType.MOB then
        local ok, selected = pcall(function() return player:getTarget() end)
        combatTarget = ok and selected or nil
    end
    if
        not combatTarget or
        combatTarget:getObjType() ~= xi.objType.MOB or
        not player:checkKillCredit(combatTarget)
    then
        return
    end

    for _, entry in ipairs(activeEntries(player)) do
        local chapter = C.chapter(player, entry)
        local requirement = entry.chapters[chapter]
        if
            chapter <= 3 and
            requirement.kind == 'support_ws' and
            requirement.utility ~= 'atonement' and
            wsId == entry.wsId and
            equippedForChapter(player, entry, chapter) and
            targetIndex(requirement, combatTarget)
        then
            local qualifies =
                (requirement.utility == 'dagan'
                    and values.hpBeforePct < requirement.hpBelow
                    and values.hpRestored + values.mpRestored >= requirement.restore)
                or
                (requirement.utility == 'myrkr'
                    and values.mpBeforePct < requirement.mpBelow
                    and values.mpRestored >= requirement.restore)
            if qualifies then
                setSupportReady(player, entry, chapter, combatTarget)
            end
        end
    end
end

function P.onNyzulFloorAdvance(player, completedStage)
    if completedStage ~= xi.nyzul.objective.ELIMINATE_SPECIFIED_ENEMY then return end
    for _, entry in ipairs(activeEntries(player)) do
        local chapter = C.chapter(player, entry)
        local requirement = entry.chapters[chapter]
        if
            entry.family == 'mythic' and
            chapter == 2 and
            requirement.kind == 'nyzul_objectives' and
            requirement.objectiveKind == completedStage and
            equippedForChapter(player, entry, chapter)
        then
            markProgress(player, entry, chapter)
        end
    end
end

local function refreshNativeWs(player)
    local desiredMain, desiredRanged = 0, 0
    for _, entry in ipairs(activeEntries(player)) do
        local chapter = C.chapter(player, entry)
        if chapter <= 3 and equippedForChapter(player, entry, chapter) then
            if entry.slot == xi.slot.RANGED then
                desiredRanged = entry.wsId
            else
                desiredMain = entry.wsId
            end
        end
    end

    local changed = player:getLocalVar(C.GRANTED_MAIN_WS_VAR) ~= desiredMain
        or player:getLocalVar(C.GRANTED_RANGED_WS_VAR) ~= desiredRanged
    if changed then
        player:setLocalVar(C.GRANTED_MAIN_WS_VAR, desiredMain)
        player:setLocalVar(C.GRANTED_RANGED_WS_VAR, desiredRanged)
        player:recalculateSkillsTable()
    end
end

local function nativeWsTick(player, generation)
    if player:getLocalVar('LWP_TimerGeneration') ~= generation then return end
    refreshNativeWs(player)
    player:timer(1000, function(p) nativeWsTick(p, generation) end)
end

local function isLowerPilgrimageWs(attacker, wsId, slot)
    for _, entry in ipairs(activeEntries(attacker)) do
        local chapter = C.chapter(attacker, entry)
        if
            chapter <= 3 and entry.wsId == wsId and entry.slot == slot and
            equippedForChapter(attacker, entry, chapter) and
            attacker:getEquipID(slot) ~= entry.finalId
        then
            return true
        end
    end
    return false
end

local function snapshotKillRule(attacker, target, wsId, slot, tp)
    attacker:setLocalVar('LWP_SnapPass', 0)
    for _, entry in ipairs(activeEntries(attacker)) do
        local chapter = C.chapter(attacker, entry)
        local requirement = entry.chapters[chapter]
        if
            chapter <= 3 and
            (requirement.kind == 'ws_kills' or requirement.kind == 'named_ws_kills') and
            entry.wsId == wsId and
            entry.slot == slot and
            equippedForChapter(attacker, entry, chapter)
        then
            attacker:setLocalVar('LWP_SnapEntry', entry.index)
            attacker:setLocalVar('LWP_SnapTarget', target:getID())
            attacker:setLocalVar('LWP_SnapWS', wsId)
            attacker:setLocalVar('LWP_SnapPass',
                C.archetypePass(attacker, target, entry.archetypeRule, tp, nil, true) and 1 or 0)
            return
        end
    end
end

local function withLowerCap(attacker, target, wsId, slot, tp, callback)
    if not isLowerPilgrimageWs(attacker, wsId, slot) then
        local result = callback()
        return unpack(result, 1, result.n)
    end
    snapshotKillRule(attacker, target, wsId, slot, tp)
    local prior = attacker:getLocalVar('StandardWsDamageCap')
    attacker:setLocalVar('StandardWsDamageCap', C.LOWER_WS_CAP)
    local ok, result = pcall(callback)
    attacker:setLocalVar('StandardWsDamageCap', prior)
    if not ok then error(result, 0) end
    return unpack(result, 1, result.n)
end

local function pack(...)
    return { n = select('#', ...), ... }
end

m:addOverride('xi.weaponskills.doPhysicalWeaponskill',
    function(attacker, target, wsId, params, tp, action, primary, taChar)
        local original = super
        return withLowerCap(attacker, target, wsId, xi.slot.MAIN, tp,
            function() return pack(original(attacker, target, wsId, params, tp, action, primary, taChar)) end)
    end)

m:addOverride('xi.weaponskills.doRangedWeaponskill',
    function(attacker, target, wsId, params, tp, action, primary)
        local original = super
        return withLowerCap(attacker, target, wsId, xi.slot.RANGED, tp,
            function() return pack(original(attacker, target, wsId, params, tp, action, primary)) end)
    end)

m:addOverride('xi.weaponskills.doMagicWeaponskill',
    function(attacker, target, wsId, params, tp, action, primary)
        local original = super
        local ranged = params.skill == xi.skill.ARCHERY or params.skill == xi.skill.MARKSMANSHIP
        local slot = ranged and xi.slot.RANGED or xi.slot.MAIN
        return withLowerCap(attacker, target, wsId, slot, tp,
            function() return pack(original(attacker, target, wsId, params, tp, action, primary)) end)
    end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    player:addListener('DEFEATED_MOB', 'LEGENDARY_PILGRIMAGE_KILLS', onDefeatedMob)
    player:addListener('WEAPONSKILL_USE', 'LEGENDARY_PILGRIMAGE_SUPPORT', onWeaponskill)
    local generation = (player:getLocalVar('LWP_TimerGeneration') or 0) + 1
    player:setLocalVar('LWP_TimerGeneration', generation)
    player:timer(1000, function(p) nativeWsTick(p, generation) end)
end)

local function sendMenu(player, title, options)
    local snap = { title = title, options = options }
    player:timer(30, function(p) p:customMenu(snap) end)
end

function P.archetypeText(rule)
    if rule.key == 'h2h_hit_chain' then return string.format('use at %d+ TP', rule.minTp) end
    if rule.key == 'dagger_positional' then return 'strike from behind' end
    if rule.key == 'sword_tactical' then return string.format('use at %d+ TP', rule.minTp) end
    if rule.key == 'great_sword_burst_survival' then return string.format('deal at least %d WS damage', rule.minDamage) end
    if rule.key == 'axe_companion' then return 'keep a pet alive or Berserk active' end
    if rule.key == 'great_axe_armor' then return string.format('deal at least %d WS damage', rule.minDamage) end
    if rule.key == 'scythe_resource' then return string.format('remain at or below %d%% HP', rule.maxHpp) end
    if rule.key == 'polearm_aerial' then return string.format('keep wyvern alive and use at %d+ TP', rule.minTp) end
    if rule.key == 'katana_shadows' then return 'retain at least one copy-image shadow' end
    if rule.key == 'great_katana_skillchain' then return string.format('use at %d+ TP', rule.minTp) end
    if rule.key == 'club_support' then return string.format('remain at or below %d%% HP', rule.maxHpp) end
    if rule.key == 'staff_magic' then return string.format('remain at or below %d%% MP', rule.maxMpp) end
    if rule.key == 'bow_distance' then return string.format('fire from at least %d yalms', rule.minDistance) end
    if rule.key == 'gun_tactical' then
        return string.format('fire from at least %d yalms at %d+ TP', rule.minDistance, rule.minTp)
    end
    return 'satisfy the weapon archetype rule'
end

local function requirementText(entry, chapter)
    local r = entry.chapters[chapter]
    if r.utility == 'dagan' then
        return string.format('%d distinct eligible NMs: Dagan below %d%% HP, >=%d combined restore',
            r.count, r.hpBelow, r.restore)
    elseif r.utility == 'myrkr' then
        return string.format('%d distinct eligible NMs: Myrkr below %d%% MP, >=%d MP restored',
            r.count, r.mpBelow, r.restore)
    elseif r.utility == 'atonement' then
        return string.format('%d distinct eligible boss fights with positive-damage Atonement', r.count)
    elseif r.kind == 'nyzul_objectives' then
        return string.format('%d Nyzul Eliminate Specified Enemy objective clears', r.count)
    elseif r.tag == 'magian_family' then
        return string.format('%d Lv%d+ family exact-WS killing blows (target max HP %d+); %s',
            r.count, r.minLevel, r.minMaxHP, P.archetypeText(entry.archetypeRule))
    elseif r.distinct then
        return string.format('%d distinct %s exact-WS killing blows; %s',
            r.count, r.tag:gsub('_', ' '), P.archetypeText(entry.archetypeRule))
    end
    return string.format('%d %s exact-WS killing blows; %s',
        r.count, r.tag:gsub('_', ' '), P.archetypeText(entry.archetypeRule))
end

local function printCurrentTargets(player, requirement)
    local targets = requirement.targets
    if not targets and requirement.ecosystems then
        targets = {}
        for _, ecosystem in ipairs(requirement.ecosystems) do
            targets[#targets + 1] = C.ECOLOGY_NAMES[ecosystem] or tostring(ecosystem)
        end
    end
    if not targets then return end

    for first = 1, #targets, 4 do
        local names = {}
        for index = first, math.min(#targets, first + 3) do
            names[#names + 1] = targets[index]
        end
        player:printToPlayer('[Pilgrimage] Eligible: ' .. table.concat(names, ', '), SYS)
    end
end

function P.showStatus(player, entry, back)
    local chapter = C.chapter(player, entry)
    if entry.singleStep then
        player:printToPlayer(
            '[Pilgrimage] This direct-final chain completes Chapters I, II, and III sequentially on its base weapon.',
            SYS)
    elseif entry.family == 'prime' then
        player:printToPlayer(
            '[Pilgrimage] Prime Chapters I and II are sequential on Ajja; Chapter III uses the 119 II weapon.',
            SYS)
    end
    for number = 1, 3 do
        local value = math.min(player:getCharVar(C.progressVar(entry.index, number)) or 0,
            entry.chapters[number].count)
        player:printToPlayer(string.format('[Pilgrimage] Chapter %s %d/%d - %s',
            ({ 'I', 'II', 'III' })[number], value, entry.chapters[number].count,
            requirementText(entry, number)), SYS)
    end
    if chapter <= 3 then printCurrentTargets(player, entry.chapters[chapter]) end
    local options = {}
    if activeEntry(player, entry.index) then
        options[#options + 1] = { 'Abandon (progress kept)', function(p)
            P.abandon(p, entry)
            p:printToPlayer('[Pilgrimage] Registration released; chapter progress was preserved.', SYS)
            back(p)
        end }
    elseif chapter <= 3 then
        options[#options + 1] = { 'Register pilgrimage', function(p)
            local ok, reason = P.register(p, entry)
            p:printToPlayer(ok and ('[Pilgrimage] Registered ' .. entry.name .. '.')
                or ('[Pilgrimage] ' .. reason), SYS)
            back(p)
        end }
    end
    options[#options + 1] = { 'Back', back }
    sendMenu(player, entry.name .. ' Pilgrimage', options)
end

function P.showForgeMenu(player, back, page)
    local choices = {}
    for _, entry in ipairs(C.chains) do
        if
            entryUnlocked(player, entry) and
            (ownsChain(player, entry) or activeEntry(player, entry.index))
        then
            choices[#choices + 1] = entry
        end
    end
    if #choices == 0 then
        player:printToPlayer('[Pilgrimage] Carry a lower-stage Legendary weapon to register its chain.', SYS)
        back(player)
        return
    end
    page = math.max(1, page or 1)
    local pageSize = 5
    local pages = math.ceil(#choices / pageSize)
    page = math.min(page, pages)
    local first = (page - 1) * pageSize + 1
    local last = math.min(#choices, first + pageSize - 1)
    local options = {}
    for index = first, last do
        local entry = choices[index]
        local captured = entry
        local capturedPage = page
        options[#options + 1] = { captured.name, function(p)
            P.showStatus(p, captured, function(q) P.showForgeMenu(q, back, capturedPage) end)
        end }
    end
    if page > 1 then
        options[#options + 1] = { '<< Prev', function(p) P.showForgeMenu(p, back, page - 1) end }
    end
    if page < pages then
        options[#options + 1] = { 'Next >>', function(p) P.showForgeMenu(p, back, page + 1) end }
    end
    options[#options + 1] = { 'Back', back }
    sendMenu(player, string.format('Legendary Pilgrimages (%d/%d)', page, pages), options)
end

return m
