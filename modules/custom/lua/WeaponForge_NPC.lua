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

    -- -------------------------------------------------------------------------
    -- Item-resolution helpers shared by Prime and Aeonic paths.
    -- -------------------------------------------------------------------------

    -- Returns the item the player is trading in.
    local function getFromItem(chain, fromStage, path)
        if path == 'aeonic' then
            if fromStage == 0 then return chain.aeonic.base
            elseif fromStage == 1 then return chain.s1
            else return chain.s2 end
        end
        return fromStage == 1 and chain.s1 or chain.s2
    end

    -- Returns the item the player will receive.
    local function getToItem(chain, fromStage, path)
        if path == 'aeonic' then
            if fromStage == 0 then return chain.s1
            elseif fromStage == 1 then return chain.s2
            else return chain.aeonic.s3 end
        end
        return fromStage == 1 and chain.s2 or chain.s3
    end

    -- -------------------------------------------------------------------------
    -- Aeonic upgrade execution
    -- -------------------------------------------------------------------------

    local RIFTBORN_BOULDER_ID = 4061

    local function doAeonicUpgrade(player, chain, fromStage)
        local ae       = chain.aeonic
        local costs    = catalog.aeonicCosts
        local stepCost = fromStage == 0 and costs.toStage1
                      or fromStage == 1 and costs.toStage2
                      or costs.toStage3
        local fromItem = getFromItem(chain, fromStage, 'aeonic')
        local toItem   = getToItem(chain, fromStage, 'aeonic')
        local S        = xi.msg.channel.SYSTEM_3

        if player:getItemCount(fromItem.id) < 1 then
            player:printToPlayer(
                string.format('[Weapon Forge] You no longer have the %s.', fromItem.name), S)
            return false
        end

        local haveAtt = player:getItemCount(ae.attestationId)
        if haveAtt < stepCost.attestations then
            player:printToPlayer(
                string.format('[Weapon Forge] Need %dx %s (you have %d).',
                    stepCost.attestations, ae.attestationName, haveAtt), S)
            return false
        end

        local haveRB = player:getItemCount(RIFTBORN_BOULDER_ID)
        if haveRB < stepCost.riftbornBoulders then
            player:printToPlayer(
                string.format('[Weapon Forge] Need %dx Riftborn Boulder (you have %d).',
                    stepCost.riftbornBoulders, haveRB), S)
            return false
        end

        if stepCost.eschaSilt then
            local silt = player:getCharVar('Escha_Silt')
            if silt < stepCost.eschaSilt then
                player:printToPlayer(
                    string.format('[Weapon Forge] Need %d Escha Silt (you have %d).',
                        stepCost.eschaSilt, silt), S)
                return false
            end
        end

        if stepCost.reforgeMarks then
            if totalMarks(player) < stepCost.reforgeMarks then
                player:printToPlayer(
                    string.format('[Weapon Forge] Need %d Reforge Marks (you have %d).',
                        stepCost.reforgeMarks, totalMarks(player)), S)
                return false
            end
        end

        if player:getFreeInventorySlots() == 0 then
            player:printToPlayer('[Weapon Forge] Free an inventory slot before forging.', S)
            return false
        end

        -- All checks passed — consume.
        player:delItem(fromItem.id, 1)
        player:delItem(ae.attestationId, stepCost.attestations)
        player:delItem(RIFTBORN_BOULDER_ID, stepCost.riftbornBoulders)
        if stepCost.eschaSilt then
            player:setCharVar('Escha_Silt',
                player:getCharVar('Escha_Silt') - stepCost.eschaSilt)
        end
        if stepCost.reforgeMarks then
            drainMarks(player, stepCost.reforgeMarks)
        end

        player:addItem({ id = toItem.id, quantity = 1 })
        player:printToPlayer(
            string.format('[Weapon Forge] The %s resonates with ancient power — behold the %s!',
                fromItem.name, toItem.name), S)
        return true
    end

    -- -------------------------------------------------------------------------
    -- Prime upgrade execution
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

        -- Hunting League rank is tracked in the 'HL_Tier' charVar (1-5), set by
        -- HuntingLeague.lua's setTier(). ('HL_Rank' was a phantom var that was
        -- never written, so this gate always failed and blocked every Prime forge.)
        local hlRank = math.max(1, player:getCharVar('HL_Tier'))
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

    -- Aeonic cost line for chat print.
    local function aeonicCostLine(chain, fromStage)
        local ac = catalog.aeonicCosts
        local sc = fromStage == 0 and ac.toStage1
                or fromStage == 1 and ac.toStage2
                or ac.toStage3
        local parts = {
            string.format('%dx %s', sc.attestations, chain.aeonic.attestationName),
            string.format('%dx Riftborn Boulder', sc.riftbornBoulders),
        }
        if sc.eschaSilt    then parts[#parts+1] = string.format('%d Escha Silt', sc.eschaSilt) end
        if sc.reforgeMarks then parts[#parts+1] = string.format('%d Reforge Marks', sc.reforgeMarks) end
        return table.concat(parts, '  |  ')
    end

    local function showConfirm(player, entry)
        local chain     = entry.chain
        local fromStage = entry.fromStage
        local path      = entry.path
        local fromItem  = getFromItem(chain, fromStage, path)
        local toItem    = getToItem(chain, fromStage, path)

        local options =
        {
            {
                string.format('Forge %s into %s', fromItem.name, toItem.name),
                function(p)
                    if path == 'aeonic' then
                        doAeonicUpgrade(p, chain, fromStage)
                    else
                        doUpgrade(p, chain, fromStage)
                    end
                    showUpgrades(p)
                end,
            },
            { 'Go back.', function(p) showUpgrades(p) end },
        }

        sendMenu(player,
            string.format('Forge %s?', fromItem.name),
            options)

        -- Print chain + cost to chat before player commits.
        if path == 'aeonic' then
            local ae = chain.aeonic
            player:printToPlayer(
                string.format('[Aeonic] %s > %s > %s > %s > %s',
                    ae.base.name, chain.s1.name, chain.s2.name, ae.s3.name, ae.s3.name),
                xi.msg.channel.SYSTEM_3)
            player:printToPlayer('Cost: ' .. aeonicCostLine(chain, fromStage), xi.msg.channel.SYSTEM_3)
        else
            player:printToPlayer(chainLine(chain, fromStage),   xi.msg.channel.SYSTEM_3)
            player:printToPlayer('Cost: ' .. costLine(fromStage), xi.msg.channel.SYSTEM_3)
        end
    end

    local function showDetail(player, entry)
        local chain     = entry.chain
        local fromStage = entry.fromStage
        local path      = entry.path
        local fromItem  = getFromItem(chain, fromStage, path)
        local toItem    = getToItem(chain, fromStage, path)

        local options =
        {
            {
                string.format('Upgrade to %s', toItem.name),
                function(p) showConfirm(p, entry) end,
            },
            { 'View full chain.', function(p)
                if path == 'aeonic' then
                    local ae = chain.aeonic
                    p:printToPlayer(
                        string.format('[Aeonic %s] %s > %s > %s > %s',
                            chain.type, ae.base.name, chain.s1.name, chain.s2.name, ae.s3.name),
                        xi.msg.channel.SYSTEM_3)
                    p:printToPlayer('Cost: ' .. aeonicCostLine(chain, fromStage), xi.msg.channel.SYSTEM_3)
                else
                    p:printToPlayer(
                        string.format('%s  |  Jobs: %s', chainLine(chain, fromStage), chain.type),
                        xi.msg.channel.SYSTEM_3)
                    p:printToPlayer('Cost: ' .. costLine(fromStage), xi.msg.channel.SYSTEM_3)
                end
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
                .. 'Begin a Prime chain with a 119I weapon from the gear vendors in Escha - Zi\'Tah, '
                .. 'or buy a Malformed weapon from Temprix in Reisenjima for the Aeonic path.',
                xi.msg.channel.SYSTEM_3)
            return
        end

        local options = {}
        -- Sort by weapon type label for consistent ordering.
        table.sort(upgradeable, function(a, b)
            local ak = (a.path or '') .. a.chain.type
            local bk = (b.path or '') .. b.chain.type
            return ak < bk
        end)
        for _, entry in ipairs(upgradeable) do
            local fromItem = getFromItem(entry.chain, entry.fromStage, entry.path)
            local toItem   = getToItem(entry.chain, entry.fromStage, entry.path)
            local label    = entry.path == 'aeonic'
                and string.format('[Aeonic] %s > %s', fromItem.name, toItem.name)
                or  string.format('%s > %s', fromItem.name, toItem.name)
            local entryCapture = entry
            options[#options + 1] =
            {
                label,
                function(p) showDetail(p, entryCapture) end,
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
