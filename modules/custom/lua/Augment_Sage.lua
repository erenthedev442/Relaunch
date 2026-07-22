-----------------------------------
-- Augment_Sage.lua
-- The side-quest NPC for the Augment system. Sits next to the Augment Moogle
-- in GM Home and offers two parallel progression tracks:
--
--   1. Sage Mastery (5 ranks). Each rank promotes the player by consuming
--      a seal tier + NM trophy + meeting an augment-count milestone.
--      Each rank raises the mastery multiplier and crit chance the
--      Augment Moogle applies to every augment.
--
--   2. NM Affinities (24 bits). Each NM drops a unique trophy; registering it
--      here costs a Hunting League rank (affinityRankReq) + Hunt Marks
--      (affinityMarkCost) and permanently unlocks a per-category bonus
--      multiplier (default 1.5x). Trophy + marks are consumed on register.
--
-- All numbers, trophies, and titles live in:
--   modules/custom/lua/augment_sage_catalog.lua
--   modules/custom/lua/augment_affinity_catalog.lua
-----------------------------------
require('modules/module_utils')

local sage     = require('modules/custom/lua/augment_sage_catalog')
local affinity = require('modules/custom/lua/augment_affinity_catalog')
local waveProgress = require('modules/custom/lua/game_master_progress')

local _zoneName = sage.zonePath:match('xi%.zones%.(.+)')
require(string.format('scripts/zones/%s/Zone', _zoneName))
-----------------------------------
local m = Module:new('augment_sage')

m:addOverride(sage.zonePath .. '.Zone.onInitialize', function(zone)
    super(zone)

    -----------------------------------
    -- Menu state shared across rebuilds
    -----------------------------------
    local menu = { title = '', options = {} }

    -----------------------------------
    -- Forward decls
    -----------------------------------
    local buildMainMenu, buildRankUpMenu, buildAffinityMenu, buildStatusMenu

    -----------------------------------
    -- Rank-up handler. Validates HL rank or Prestige level requirement,
    -- bumps Augment_Mastery, re-renders main menu. No items consumed.
    -----------------------------------
    local function getMaxPrestigeLevel(player)
        local max = 0
        for jobId = 1, 22 do
            local lv = player:getCharVar(string.format('Prestige_Level_%d', jobId)) or 0
            if lv > max then max = lv end
        end
        return max
    end

    local function getTotalRebirths(player)
        local total = 0
        for jobId = 1, 22 do
            total = total + (player:getCharVar(string.format('Rebirth_Count_%d', jobId)) or 0)
        end
        return total
    end

    local function tryRankUp(player)
        local currentRank = player:getCharVar('Augment_Mastery') or 0
        local nextRank    = currentRank + 1
        local req         = sage.ranks[nextRank]

        if not req then
            player:printToPlayer('You are already at the highest rank, Archon!', xi.msg.channel.SYSTEM_3)
            buildMainMenu(player)
            return
        end

        if req.hlRank then
            local hlTier = player:getCharVar('HL_Tier') or 1
            if hlTier < req.hlRank then
                player:printToPlayer(string.format(
                    'You need Hunting League Rank %d (you are Rank %d).',
                    req.hlRank, hlTier), xi.msg.channel.SYSTEM_3)
                buildMainMenu(player)
                return
            end
        end

        if req.prestigeLevel then
            local maxPL = getMaxPrestigeLevel(player)
            if maxPL < req.prestigeLevel then
                player:printToPlayer(string.format(
                    'You need Prestige Level %d on any job (your best: %d).',
                    req.prestigeLevel, maxPL), xi.msg.channel.SYSTEM_3)
                buildMainMenu(player)
                return
            end
        end

        if req.rebirths then
            local total = getTotalRebirths(player)
            if total < req.rebirths then
                player:printToPlayer(string.format(
                    'You need %d total rebirths across all jobs (you have %d).',
                    req.rebirths, total), xi.msg.channel.SYSTEM_3)
                buildMainMenu(player)
                return
            end
        end

        if req.gauntletClears then
            local clears = player:getCharVar('Gauntlet_Clears') or 0
            if clears < req.gauntletClears then
                player:printToPlayer(string.format(
                    'You need %d Gauntlet clear(s) (you have %d).',
                    req.gauntletClears, clears), xi.msg.channel.SYSTEM_3)
                buildMainMenu(player)
                return
            end
        end

        -- All requirements met - promote.
        player:setCharVar('Augment_Mastery', nextRank)

        -- Speed-board anchor: stamp the timestamp when a player first reaches
        -- rank 5 (Augment Archon). Locked-once so re-promotion can't reset it.
        if nextRank >= 5 and (player:getCharVar('Augment_Archon_At') or 0) == 0 then
            player:setCharVar('Augment_Archon_At', os.time())
        end

        player:printToPlayer(string.format(
            'You have been promoted to %s! (rank %d/5)',
            req.title, nextRank), xi.msg.channel.SYSTEM_3)
        player:printToPlayer(string.format(
            'Your augment rolls now floor +%d within your tier band and crit (perfect roll) %.0f%% of trades.',
            nextRank,
            sage.critChance[nextRank + 1] * 100),
            xi.msg.channel.SYSTEM_3)

        buildMainMenu(player)
    end

    -----------------------------------
    -- Try to register an NM affinity. Trades trophy for the affinity bit.
    -----------------------------------
    local function tryRegisterAffinity(player, row)
        local S = xi.msg.channel.SYSTEM_3

        if affinity.hasAffinity(player, row.cat) then
            player:printToPlayer(string.format(
                '[Augment Sage] %s affinity already unlocked.', row.label), S)
            buildAffinityMenu(player)
            return
        end

        local rankReq  = affinity.affinityRankReq
        local markCost = affinity.affinityMarkCost

        -- Hunting League rank gate.
        local hlTier = player:getCharVar('HL_Tier') or 1
        if hlTier < rankReq then
            player:printToPlayer(string.format(
                '[Augment Sage] The %s affinity requires Hunting League Rank %d (you are Rank %d).',
                row.label, rankReq, hlTier), S)
            buildAffinityMenu(player)
            return
        end

        -- Trophy in inventory?
        if not player:hasItem(row.trophy.id) then
            player:printToPlayer(string.format(
                '[Augment Sage] You need %s to register %s -- defeat %s in %s.',
                row.trophy.name, row.label, row.nm:gsub('_', ' '), row.nmZone), S)
            buildAffinityMenu(player)
            return
        end

        -- Hunt Marks cost.
        local marks = player:getCharVar('HL_Points') or 0
        if marks < markCost then
            player:printToPlayer(string.format(
                '[Augment Sage] Registering %s costs %d Hunt Marks (you have %d).',
                row.label, markCost, marks), S)
            buildAffinityMenu(player)
            return
        end

        -- All requirements met -- consume the trophy + marks, grant the bit.
        player:delItem(row.trophy.id, 1)
        player:setCharVar('HL_Points', marks - markCost)
        affinity.grantAffinity(player, row.cat)
        player:printToPlayer(string.format(
            '[Augment Sage] %s affinity registered! Augments in this category now roll twice and keep the better result.',
            row.label), S)
        buildAffinityMenu(player)
    end

    -----------------------------------
    -- Affinity submenu (paginated). Shows unlocked-state on each row.
    -- #affinity.affinities entries + nav; AFF_PAGE_SZ=4 keeps each page under the 150-byte cap.
    -----------------------------------
    local AFF_PAGE_SZ = 4

    buildAffinityMenu = function(player, page)
        page = page or 1
        local totalPages = math.max(1, math.ceil(#affinity.affinities / AFF_PAGE_SZ))
        page = math.max(1, math.min(page, totalPages))

        local startIdx = (page - 1) * AFF_PAGE_SZ + 1
        local endIdx   = math.min(startIdx + AFF_PAGE_SZ - 1, #affinity.affinities)

        local options = {}
        for i = startIdx, endIdx do
            local row    = affinity.affinities[i]
            local has    = affinity.hasAffinity(player, row.cat)
            -- [*] registered, [!] trophy in hand (ready to register), [ ] locked.
            local marker = has and '[*]'
                or ((player:hasItem(row.trophy.id) and '[!]') or '[ ]')
            -- Short label - 150-byte cap is tight with 4 rows + nav.
            local label  = string.format('%s %s', marker, row.label:sub(1, 18))
            table.insert(options, {
                label,
                function(p) tryRegisterAffinity(p, row) end,
            })
        end

        if totalPages > 1 then
            if page > 1 then
                table.insert(options, {
                    string.format('<< %d/%d', page - 1, totalPages),
                    function(p) buildAffinityMenu(p, page - 1) end,
                })
            end
            if page < totalPages then
                table.insert(options, {
                    string.format('%d/%d >>', page + 1, totalPages),
                    function(p) buildAffinityMenu(p, page + 1) end,
                })
            end
        end

        table.insert(options, { '<< Back', function(p) buildMainMenu(p) end })

        local field    = player:getCharVar('Augment_Affinities') or 0
        local unlocked = 0
        for _, row in ipairs(affinity.affinities) do
            if bit.band(field, bit.lshift(1, row.bit)) ~= 0 then
                unlocked = unlocked + 1
            end
        end

        menu.title   = string.format('Affinities %d/%d', unlocked, #affinity.affinities)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- Rank-up menu - shows next rank's requirements + current progress.
    -----------------------------------
    buildRankUpMenu = function(player)
        local currentRank = player:getCharVar('Augment_Mastery') or 0
        local nextRank    = currentRank + 1
        local req         = sage.ranks[nextRank]

        local options = {}
        if not req then
            table.insert(options, { 'Max rank reached!', function() end })
        else
            local met = true

            if req.hlRank then
                local hlTier = player:getCharVar('HL_Tier') or 1
                local ok     = hlTier >= req.hlRank
                if not ok then met = false end
                table.insert(options, {
                    string.format('HL Rank %d/%d %s', hlTier, req.hlRank, ok and '[OK]' or ''),
                    function(p) buildRankUpMenu(p) end,
                })
            end

            if req.prestigeLevel then
                local maxPL = getMaxPrestigeLevel(player)
                local ok = maxPL >= req.prestigeLevel
                if not ok then met = false end
                table.insert(options, {
                    string.format('Prestige %d/%d %s', maxPL, req.prestigeLevel, ok and '[OK]' or ''),
                    function(p) buildRankUpMenu(p) end,
                })
            end

            if req.rebirths then
                local total = getTotalRebirths(player)
                local ok    = total >= req.rebirths
                if not ok then met = false end
                table.insert(options, {
                    string.format('Rebirths %d/%d %s', total, req.rebirths, ok and '[OK]' or ''),
                    function(p) buildRankUpMenu(p) end,
                })
            end

            if req.gauntletClears then
                local clears = player:getCharVar('Gauntlet_Clears') or 0
                local ok     = clears >= req.gauntletClears
                if not ok then met = false end
                table.insert(options, {
                    string.format('Gauntlet %d/%d %s', clears, req.gauntletClears, ok and '[OK]' or ''),
                    function(p) buildRankUpMenu(p) end,
                })
            end

            local promoteLabel = met
                and string.format('>> Promote to %s', req.title:gsub('Augment ', ''))
                or  '(Requirements not met)'
            table.insert(options, {
                promoteLabel,
                function(p) tryRankUp(p) end,
            })
        end

        table.insert(options, { '<< Back', function(p) buildMainMenu(p) end })

        menu.title   = req
            and string.format('Rank %d: %s', nextRank, req.title:sub(1, 18))
            or  'Maxed out'
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- Status menu - readout of mastery, mult, crit, affinity count.
    -----------------------------------
    buildStatusMenu = function(player)
        local rank   = player:getCharVar('Augment_Mastery') or 0
        local count  = player:getCharVar('Augment_Count')   or 0
        local mult   = sage.masteryMult[rank + 1]
        local crit   = sage.critChance[rank + 1]
        local field  = player:getCharVar('Augment_Affinities') or 0
        local unlocked = 0
        for _, row in ipairs(affinity.affinities) do
            if bit.band(field, bit.lshift(1, row.bit)) ~= 0 then
                unlocked = unlocked + 1
            end
        end

        player:printToPlayer(string.format(
            '[Augment Sage] Rank: %s (%d/5)',
            sage.titleFor(rank), rank), xi.msg.channel.SYSTEM_3)
        if xi.augmentTiers then
            local tier  = xi.augmentTiers.tierOf(player)
            local slice = xi.augmentTiers.slices[tier]
            local nxt   = xi.augmentTiers.nextUnlock(tier)
            if slice then
                player:printToPlayer(string.format(
                    '  Augment Tier: %d/5 (rolls %d-%d)%s',
                    tier, slice.min, slice.max,
                    nxt and (' | next: ' .. nxt) or ' | MAX'), xi.msg.channel.SYSTEM_3)
            else
                player:printToPlayer(string.format(
                    '  Augment Tier: 0/5 — augmenting locked | unlock: %s',
                    nxt or '???'), xi.msg.channel.SYSTEM_3)
            end
            player:printToPlayer(
                '  Wave Master: ' .. waveProgress.summary(player, 1, 4),
                xi.msg.channel.SYSTEM_3)
        end
        player:printToPlayer(string.format(
            '  Roll floor: +%d within your tier band | Crit chance: %.0f%%',
            rank, crit * 100), xi.msg.channel.SYSTEM_3)
        player:printToPlayer(string.format(
            '  Lifetime augments: %d | Affinities unlocked: %d/%d',
            count, unlocked, #affinity.affinities), xi.msg.channel.SYSTEM_3)

        buildMainMenu(player)
    end

    -----------------------------------
    -- Main menu (3 options + close)
    -----------------------------------
    buildMainMenu = function(player)
        local rank  = player:getCharVar('Augment_Mastery') or 0
        local title = sage.titleFor(rank)

        menu.title   = string.format('Sage [%s]', title:sub(1, 16))
        menu.options =
        {
            {
                'Check Status',
                function(p) buildStatusMenu(p) end,
            },
            {
                'Pursue Next Rank',
                function(p) buildRankUpMenu(p) end,
            },
            {
                'Register NM Affinity',
                function(p) buildAffinityMenu(p, 1) end,
            },
            {
                'Close',
                function(p) p:printToPlayer('Hone your craft, augmenter.', xi.msg.channel.SYSTEM_3) end,
            },
        }
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -----------------------------------
    -- NPC ENTITY
    --   Look 2401 = moogle (same as Augment Moogle). Different name +
    --   packetName makes them visually distinguishable in the targeting UI.
    -----------------------------------
    local _p = sage.vendorPos
    local AugmentSage = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Augment_Sage',
        packetName = string.format('%sAugment Sage', xi.icon.STAR_LARGE),
        look       = 82,
        x          = _p.x,
        y          = _p.y,
        z          = _p.z,
        rotation   = _p.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('Use the menu to advance your rank or register affinities, augmenter.',
                xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:timer(50, function(p) buildMainMenu(p) end)
        end,
    })
    utils.unused(AugmentSage)
end)

return m
