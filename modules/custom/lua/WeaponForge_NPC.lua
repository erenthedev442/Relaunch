-----------------------------------
-- WeaponForge_NPC.lua
-- Retail-style 3-stage weapon upgrade path: 119I → 119II → 119III.
--
-- HOW IT WORKS (like retail FFXI Oboro reforging)
--   1. Talk to the Weapon Forger in Leafallia.
--   2. The NPC scans your main inventory and lists every weapon you own that
--      is upgradeable to the next stage.
--   3. Select a weapon. The NPC shows the full upgrade chain (I → II → III)
--      and the materials required for YOUR step.
--   4. Confirm: the NPC takes your current weapon + materials and hands you
--      the next stage weapon. Nothing is lost on failure; all checks happen
--      before anything is removed.
--
-- CHAINS (see weapon_forge_catalog.lua for full list):
--   119I  (Bronze vendor)  →  119II (forge-exclusive or Silver vendor shortcut)
--   119II                  →  119III (Stage-5 Relic; also via Dynamis/Relic Forge)
--
-- GATE CHECKS (applied before any item transfer)
--   119I → II : HL Rank ≥ 3 (Elite)  +  25× Kindreds Medal
--   119II → III: HL Rank ≥ 5 (Legend) +  50× Demons Medal
--                                     +  2000 Reforge Marks (any pool, drained)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Leafallia/Zone')

local m       = Module:new('weapon_forge_npc')
local catalog = require('modules/custom/lua/weapon_forge_catalog')

local NPC_POS = { x = -15.000, y = 0.000, z = 20.000, rot = 128 }

m:addOverride('xi.zones.Leafallia.Zone.onInitialize', function(zone)
    super(zone)

    local function sendMenu(player, title, options)
        local snap = { title = title, options = options }
        player:timer(30, function(p) p:customMenu(snap) end)
    end

    -- -------------------------------------------------------------------------
    -- Reforge-mark helpers
    -- -------------------------------------------------------------------------

    local function totalMarks(player)
        local total = 0
        for _, var in ipairs(catalog.markVars) do
            total = total + player:getCharVar(var)
        end
        return total
    end

    -- Drain `needed` marks across pools (AF → Relic → Empy order). Returns
    -- true if successful, false with no side-effects if insufficient.
    local function drainMarks(player, needed)
        if totalMarks(player) < needed then
            return false
        end
        local remaining = needed
        for _, var in ipairs(catalog.markVars) do
            local have = player:getCharVar(var)
            if have >= remaining then
                player:setCharVar(var, have - remaining)
                remaining = 0
                break
            elseif have > 0 then
                player:setCharVar(var, 0)
                remaining = remaining - have
            end
        end
        return remaining == 0
    end

    -- -------------------------------------------------------------------------
    -- Upgrade execution
    -- -------------------------------------------------------------------------

    -- Check and execute the upgrade. Prints a failure reason on any shortfall;
    -- does NOT remove any items until all checks pass.
    local function doUpgrade(player, chain, fromStage)
        local fromItem = fromStage == 1 and chain.s1 or chain.s2
        local toItem   = fromStage == 1 and chain.s2 or chain.s3
        local cost     = fromStage == 1 and catalog.costs.toStage2 or catalog.costs.toStage3

        -- Free inventory slot required (we take one weapon, give one weapon).
        -- The slot is freed by delItem before addItem, so no net slot needed IF
        -- the player has at least the weapon in inventory. Guard anyway.
        if player:getItemCount(fromItem.id) < 1 then
            player:printToPlayer(
                string.format('[Weapon Forge] You no longer have the %s.', fromItem.name),
                xi.msg.channel.SYSTEM_3)
            return false
        end

        local hlRank = player:getCharVar('HL_Rank')
        if hlRank < cost.hlRank then
            player:printToPlayer(
                string.format('[Weapon Forge] You need Hunting League Rank %d or higher (you are Rank %d).',
                    cost.hlRank, hlRank),
                xi.msg.channel.SYSTEM_3)
            return false
        end

        if player:getItemCount(cost.medals.id) < cost.medals.qty then
            player:printToPlayer(
                string.format('[Weapon Forge] You need %d %s (you have %d).',
                    cost.medals.qty, cost.medals.name,
                    player:getItemCount(cost.medals.id)),
                xi.msg.channel.SYSTEM_3)
            return false
        end

        if cost.reforgeMarks then
            if totalMarks(player) < cost.reforgeMarks then
                player:printToPlayer(
                    string.format(
                        '[Weapon Forge] You need %d Reforge Marks total across all pools (you have %d).',
                        cost.reforgeMarks, totalMarks(player)),
                    xi.msg.channel.SYSTEM_3)
                return false
            end
        end

        if player:getFreeInventorySlots() == 0 then
            player:printToPlayer(
                '[Weapon Forge] Free an inventory slot before forging.',
                xi.msg.channel.SYSTEM_3)
            return false
        end

        -- All checks passed — consume items.
        player:delItem(fromItem.id, 1)
        player:delItem(cost.medals.id, cost.medals.qty)
        if cost.reforgeMarks then
            drainMarks(player, cost.reforgeMarks)
        end

        player:addItem({ id = toItem.id, quantity = 1 })
        player:printToPlayer(
            string.format(
                '[Weapon Forge] The %s shimmers and transforms — behold the %s!',
                fromItem.name, toItem.name),
            xi.msg.channel.SYSTEM_3)
        return true
    end

    -- -------------------------------------------------------------------------
    -- Menu builders
    -- -------------------------------------------------------------------------

    local function chainLine(chain, fromStage)
        -- e.g.  "119I: Ajja Sword  ►  119II: Flametongue  ►  119III: Caliburnus"
        --  (only the relevant step highlighted with the cost label)
        local stages = {
            string.format('119I: %s', chain.s1.name),
            string.format('119II: %s', chain.s2.name),
            string.format('119III: %s', chain.s3.name),
        }
        -- Mark the upgrade arrow the player is about to cross.
        local arrows = { ' > ', ' > ' }
        arrows[fromStage] = ' => '
        return stages[1] .. arrows[1] .. stages[2] .. arrows[2] .. stages[3]
    end

    local function costLine(fromStage)
        local cost = fromStage == 1 and catalog.costs.toStage2 or catalog.costs.toStage3
        local parts = {
            string.format('%dx %s', cost.medals.qty, cost.medals.name),
            string.format('HL Rank %d', cost.hlRank),
        }
        if cost.reforgeMarks then
            parts[#parts + 1] = string.format('%d Reforge Marks (any pool)', cost.reforgeMarks)
        end
        return table.concat(parts, '  |  ')
    end

    local showUpgrades  -- forward decl

    local function showConfirm(player, entry)
        local chain     = entry.chain
        local fromStage = entry.fromStage
        local fromItem  = fromStage == 1 and chain.s1 or chain.s2
        local toItem    = fromStage == 1 and chain.s2 or chain.s3

        local options =
        {
            {
                string.format('Forge %s into %s', fromItem.name, toItem.name),
                function(p)
                    doUpgrade(p, chain, fromStage)
                    showUpgrades(p)
                end,
            },
            { 'Go back.', function(p) showUpgrades(p) end },
        }

        sendMenu(player,
            string.format('Forge %s?', fromItem.name),
            options)

        -- Print chain + cost to chat so the player sees the full picture
        -- before committing (customMenu title is too short for this).
        player:printToPlayer(chainLine(chain, fromStage),   xi.msg.channel.SYSTEM_3)
        player:printToPlayer('Cost: ' .. costLine(fromStage), xi.msg.channel.SYSTEM_3)
    end

    local function showDetail(player, entry)
        local chain     = entry.chain
        local fromStage = entry.fromStage
        local fromItem  = fromStage == 1 and chain.s1 or chain.s2
        local toItem    = fromStage == 1 and chain.s2 or chain.s3

        local options =
        {
            {
                string.format('Upgrade to %s', toItem.name),
                function(p) showConfirm(p, entry) end,
            },
            { 'View full chain.', function(p)
                p:printToPlayer(
                    string.format('%s  |  Jobs: %s', chainLine(chain, fromStage), chain.type),
                    xi.msg.channel.SYSTEM_3)
                p:printToPlayer('Cost: ' .. costLine(fromStage), xi.msg.channel.SYSTEM_3)
                showDetail(p, entry)
            end },
            { 'Go back.', function(p) showUpgrades(p) end },
        }

        sendMenu(player,
            string.format('%s > %s', fromItem.name, toItem.name),
            options)
    end

    -- Scan main inventory for upgradeable weapons and present the list.
    showUpgrades = function(player)
        local upgradeable = {}
        for id, entry in pairs(catalog.byId) do
            if player:getItemCount(id) > 0 then
                upgradeable[#upgradeable + 1] = entry
            end
        end

        if #upgradeable == 0 then
            player:printToPlayer(
                '[Weapon Forge] I see no upgradeable weapons in your inventory. '
                .. 'Begin a forge chain by obtaining a 119I weapon from the gear vendors in Escha - Zi\'Tah.',
                xi.msg.channel.SYSTEM_3)
            player:printToPlayer(
                '[Weapon Forge] Chain overview: 119I (Bronze vendor) => 119II (forge) => 119III (Stage-5 Relic).',
                xi.msg.channel.SYSTEM_3)
            return
        end

        local options = {}
        -- Sort by weapon type label for consistent ordering.
        table.sort(upgradeable, function(a, b)
            return a.chain.type < b.chain.type
        end)
        for _, entry in ipairs(upgradeable) do
            local fromItem = entry.fromStage == 1 and entry.chain.s1 or entry.chain.s2
            local toItem   = entry.fromStage == 1 and entry.chain.s2 or entry.chain.s3
            options[#options + 1] =
            {
                string.format('%s > %s', fromItem.name, toItem.name),
                function(p) showDetail(p, entry) end,
            }
        end
        options[#options + 1] = { 'Not today.', function() end }

        sendMenu(player, 'Weapon Forge -- choose a weapon', options)
    end

    -- -------------------------------------------------------------------------
    -- NPC placement
    -- -------------------------------------------------------------------------

    local WeaponForger = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Weapon_Forger',
        packetName = string.format('%sWeapon Forger', xi.icon.STAR_LARGE),
        look       = 3000,
        x          = NPC_POS.x,
        y          = NPC_POS.y,
        z          = NPC_POS.z,
        rotation   = NPC_POS.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer(
                '[Weapon Forge] No need to trade -- speak with me and choose a weapon from the menu.',
                xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:printToPlayer(
                '[Weapon Forge] Bring me your weapon and the required materials and I will reforge it into a more powerful form. '
                .. 'The path: 119I (Bronze vendor) => 119II (25 Kindreds Medals, HL Rank III) '
                .. '=> 119III / Stage-5 Relic (50 Demons Medals + 2000 Reforge Marks, HL Rank V).',
                xi.msg.channel.SYSTEM_3)
            showUpgrades(player)
        end,
    })
    utils.unused(WeaponForger)
end)

return m
