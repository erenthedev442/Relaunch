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
--   2. NM Affinities (13 bits). Trading the right NM-drop trophy
--      permanently unlocks a per-category bonus multiplier (default 1.5x).
--
-- All numbers, trophies, and titles live in:
--   modules/custom/lua/augment_sage_catalog.lua
--   modules/custom/lua/augment_affinity_catalog.lua
-----------------------------------
require('modules/module_utils')

local sage     = require('modules/custom/lua/augment_sage_catalog')
local affinity = require('modules/custom/lua/augment_affinity_catalog')

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
            'Your augments are now %.0f%% stronger and crit %.0f%% of trades.',
            (sage.masteryMult[nextRank + 1] - 1.0) * 100,
            sage.critChance[nextRank + 1] * 100),
            xi.msg.channel.SYSTEM_3)

        buildMainMenu(player)
    end

    -----------------------------------
    -- Try to register an NM affinity. Trades trophy for the affinity bit.
    -----------------------------------
    local function tryRegisterAffinity(player, row)
        if affinity.hasAffinity(player, row.cat) then
            player:printToPlayer(string.format(
                'You already hold the %s affinity.', row.label),
                xi.msg.channel.SYSTEM_3)
            buildAffinityMenu(player)
            return
        end

        local has = player:getItemCount(row.trophy.id)
        if has < row.trophy.qty then
            player:printToPlayer(string.format(
                'You need %d x %s (you have %d). Slay %s!',
                row.trophy.qty, row.trophy.name, has, row.nm),
                xi.msg.channel.SYSTEM_3)
            buildAffinityMenu(player)
            return
        end

        player:delItem(row.trophy.id, row.trophy.qty)
        affinity.grantAffinity(player, row.cat)

        player:printToPlayer(string.format(
            '%s affinity registered! Augments in this category are now %.0f%% stronger.',
            row.label, (affinity.affinityMult - 1.0) * 100),
            xi.msg.channel.SYSTEM_3)
        buildAffinityMenu(player)
    end

    -----------------------------------
    -- Affinity submenu (paginated). Shows unlocked-state on each row.
    -- 13 entries + nav = need pagination to fit the 150-byte cap.
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
            local marker = affinity.hasAffinity(player, row.cat) and '[*]' or '[ ]'
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
                local maxPL = 0
                for jobId = 1, 22 do
                    local lv = player:getCharVar(string.format('Prestige_Level_%d', jobId)) or 0
                    if lv > maxPL then maxPL = lv end
                end
                local ok = maxPL >= req.prestigeLevel
                if not ok then met = false end
                table.insert(options, {
                    string.format('Prestige %d/%d %s', maxPL, req.prestigeLevel, ok and '[OK]' or ''),
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
        player:printToPlayer(string.format(
            '  Mastery multiplier: %.2fx | Crit chance: %.0f%%',
            mult, crit * 100), xi.msg.channel.SYSTEM_3)
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
        look       = 2401,
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
