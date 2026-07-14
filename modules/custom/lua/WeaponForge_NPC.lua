-----------------------------------
-- WeaponForge_NPC.lua
-- Retail-style 3-stage weapon upgrade path: 119I → 119II → 119III.
--
-- HOW IT WORKS (like retail FFXI Oboro reforging)
--   1. Talk to the Weapon Forger (zone set in the addOverride below).
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
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m       = Module:new('weapon_forge_npc')
local catalog = require('modules/custom/lua/weapon_forge_catalog')

local NPC_POS = { x = 568.500, y = -3.360, z = 535.400, rot = 64 }

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
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
    -- STAGE GATES (checked BEFORE any material is consumed)
    -- -------------------------------------------------------------------------
    -- Gates match docs/progression/weapon-forge/ verbatim. Each entry is
    -- {label, check(player) -> bool}. checkGate() below prints the label when
    -- a gate fails and returns false; the calling forge site short-circuits.
    -- Owner spec 2026-07-13: enforces the 11 gates surfaced on the widget.
    -- fromStage indexing:
    --   0 = "Base -> Stage I"      (player currently holds nothing / base)
    --   1 = "Stage I -> Stage II"  (player currently holds 119 I)
    --   2 = "Stage II -> Stage III" (player currently holds 119 II)
    local function _anyRebirthCap()
        -- Returns a check(p) that scans job-scoped Rebirth counters for a
        -- single-job total >= 50. The 22 lookup is a hardcoded ceiling
        -- (retail job count) shared with prestige/rebirth catalogs.
        return function(p)
            for jobId = 1, 22 do
                if (p:getCharVar('Rebirth_Count_' .. jobId) or 0) >= 50 then return true end
            end
            return false
        end
    end
    local function _anyAscensionCap()
        return function(p)
            for jobId = 1, 22 do
                if (p:getCharVar(('Prestige_Level_%d'):format(jobId)) or 0) >= 100 then return true end
            end
            return false
        end
    end
    local function _allPrimeTrialsAndApexHunter()
        return function(p)
            for i = 1, 5 do
                if (p:getCharVar('PW_Trial' .. i .. '_Done') or 0) ~= 1 then return false end
            end
            return (p:getCharVar('Title_Apex_Hunter') or 0) == 1
        end
    end
    local function _anyForgeFinal()
        return function(p)
            return (p:getCharVar('WF_Relic_Final')    or 0) == 1
                or (p:getCharVar('WF_Mythic_Final')   or 0) == 1
                or (p:getCharVar('WF_Empyrean_Final') or 0) == 1
                or (p:getCharVar('WF_Aeonic_Final')   or 0) == 1
        end
    end
    local STAGE_GATES = {
        empyrean = {
            [0] = { label = 'All Geas Fete bosses killed at least once',
                    check = function(p)
                        local need = (xi.geasFete and xi.geasFete.uniqueNmCount) or math.huge
                        return (p:getCharVar('GF_Unique_Kills') or 0) >= need
                    end },
            [1] = { label = 'Voidspire Floor 100 reached',
                    check = function(p) return (p:getCharVar('Voidspire_Best_Floor') or 0) >= 100 end },
            [2] = { label = 'Fellow Mastery achieved',
                    check = function(p) return (p:getCharVar('Fellow_Mastered') or 0) == 1 end },
        },
        mythic = {
            [0] = { label = 'Nyzul Isle Floor 100 cleared',
                    check = function(p) return (p:getCharVar('Nyzul_F100_Cleared') or 0) == 1 end },
            [1] = { label = 'All Voidwatch NMs killed',
                    check = function(p)
                        local need = (xi.voidwatch and xi.voidwatch.uniqueNmCount) or math.huge
                        return (p:getCharVar('VW_Unique_Kills') or 0) >= need
                    end },
            [2] = { label = '1 successful win of The Gauntlet',
                    check = function(p) return (p:getCharVar('Gauntlet_Clears') or 0) >= 1 end },
        },
        aeonic = {
            [0] = { label = '50 rebirths on a single job (not combined)',
                    check = _anyRebirthCap() },
            [1] = { label = '100 Ascensions on a single job (not combined)',
                    check = _anyAscensionCap() },
            [2] = { label = 'All Dungeons cleared + 10 wins against Maat\'s Echo',
                    check = function(p)
                        local need = (xi.dungeonInstances and xi.dungeonInstances.uniqueDungeonCount) or math.huge
                        return (p:getCharVar('Dungeon_Unique_Clears') or 0) >= need
                           and (p:getCharVar('Maat_Kills') or 0) >= 10
                    end },
        },
        prime = {
            [0] = { label = 'Built a Relic, Mythic, Empyrean, or Aeonic final weapon',
                    check = _anyForgeFinal() },
            [1] = { label = 'All 5 Prime Armory Trials complete + Apex Hunter in the Hunter\'s Guild',
                    check = _allPrimeTrialsAndApexHunter() },
            -- Stage III has no NEW gate (existing HL_Tier + all-trials + gil
            -- checks in doUpgrade cover it) -- STAGE_GATES[prime][2] omitted.
        },
        -- Relic and Ergon are unchanged from prior tuning: Relic keeps its
        -- Divergence-city-wins gate enforced inline (see doForge below),
        -- Ergon isn't part of this pass.
    }

    local function checkGate(player, category, fromStage)
        local cat = STAGE_GATES[category]
        if not cat then return true end
        local gate = cat[fromStage]
        if not gate then return true end
        if gate.check(player) then return true end
        player:printToPlayer(
            string.format('[Weapon Forge] Gate not met: %s.', gate.label),
            xi.msg.channel.SYSTEM_3)
        return false
    end

    -- Recipe-preview companion to checkGate: returns the gate label suffixed
    -- with a met/not-met marker so players see the target BEFORE they try to
    -- forge instead of eating a "gate not met" line as their only feedback.
    -- Empty string when the (category, fromStage) has no new gate.
    local function gateLine(player, category, fromStage)
        local cat = STAGE_GATES[category]
        if not cat then return '' end
        local gate = cat[fromStage]
        if not gate then return '' end
        local mark = gate.check(player) and '✓' or '✗'
        return string.format('  Gate: %s [%s]', gate.label, mark)
    end

    -- -------------------------------------------------------------------------
    -- Aeonic upgrade execution
    -- -------------------------------------------------------------------------

    local RIFTBORN_BOULDER_ID = 4061

    local function doAeonicUpgrade(player, chain, fromStage)
        -- Owner spec 2026-07-13: new progression gates enforced BEFORE any
        -- inventory / currency / mark inspection so a locked player never
        -- sees "you have 24 of 25 marks" -- they see the actual blocker.
        if not checkGate(player, 'aeonic', fromStage) then return false end
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

        -- Aeonic rank gate (HL_Tier; see note in doUpgrade below).
        if stepCost.hlRank then
            local hlRank = math.max(1, player:getCharVar('HL_Tier'))
            if hlRank < stepCost.hlRank then
                player:printToPlayer(
                    string.format('[Weapon Forge] You need Hunting League Rank %d or higher (you are Rank %d).',
                        stepCost.hlRank, hlRank), S)
                return false
            end
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

        if stepCost.eschaBeads then
            local beads = player:getCurrency('escha_beads') or 0
            if beads < stepCost.eschaBeads then
                player:printToPlayer(
                    string.format('[Weapon Forge] Need %d Escha Beads (you have %d).',
                        stepCost.eschaBeads, beads), S)
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

        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer('[Weapon Forge] Free an inventory slot before forging.', S)
            return false
        end

        -- RARE pre-check: the engine refuses a second copy, and consuming
        -- first would eat the materials with nothing granted (Jbae's Empy
        -- reforge loss, 2026-07-12 — same defect class).
        if player:hasItem(toItem.id) then
            player:printToPlayer(
                string.format('[Weapon Forge] You already hold %s — it is RARE, so a second cannot be forged.',
                    toItem.name), S)
            return false
        end

        -- All checks passed — consume.
        player:delItem(fromItem.id, 1)
        player:delItem(ae.attestationId, stepCost.attestations)
        player:delItem(RIFTBORN_BOULDER_ID, stepCost.riftbornBoulders)
        if stepCost.eschaBeads then
            player:delCurrency('escha_beads', stepCost.eschaBeads)
        end
        if stepCost.reforgeMarks then
            drainMarks(player, stepCost.reforgeMarks)
        end

        if not player:addItem({ id = toItem.id, quantity = 1 }) then
            player:printToPlayer(
                '[Weapon Forge] ERROR: the forge consumed your materials but could not hand over the weapon — contact a GM with this message.', S)
            return true
        end
        player:printToPlayer(
            string.format('[Weapon Forge] The %s resonates with ancient power — behold the %s!',
                fromItem.name, toItem.name), S)
        -- Stage III (final Aeonic) completion flag. Read by the Prime Stage I
        -- preflight ("Built a Relic, Mythic, Empyrean, or Aeonic final weapon").
        -- Persists so trading/losing the weapon doesn't retract the milestone.
        if fromStage == 2 then
            player:setCharVar('WF_Aeonic_Final', 1)
        end
        return true
    end

    -- -------------------------------------------------------------------------
    -- Prime upgrade execution
    -- -------------------------------------------------------------------------

    -- Check and execute the upgrade. Prints a failure reason on any shortfall;
    -- does NOT remove any items until all checks pass.
    local function doUpgrade(player, chain, fromStage)
        -- Owner spec 2026-07-13 gate check. doUpgrade only ever gets
        -- fromStage 1 or 2 (Prime base is issued by Prime Armory NPC, not
        -- Weapon Forge). STAGE_GATES.prime[2] is nil so fromStage=2 short-
        -- circuits with true and falls through to the existing HL_Tier +
        -- all-trials + gil checks below.
        if not checkGate(player, 'prime', fromStage) then return false end
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

        -- Prime pinnacle gate: all five Prime Armory Trials must be complete
        -- (same CharVars PrimeArmory_NPC checks).
        if cost.requireTrials and catalog.primeTrialVars then
            for _, tv in ipairs(catalog.primeTrialVars) do
                if (player:getCharVar(tv) or 0) == 0 then
                    player:printToPlayer(
                        '[Weapon Forge] You must complete all five Prime Armory Trials before forging a Prime Weapon.',
                        xi.msg.channel.SYSTEM_3)
                    return false
                end
            end
        end

        if cost.gil and player:getGil() < cost.gil then
            player:printToPlayer(
                string.format('[Weapon Forge] You need %d gil to forge a Prime Weapon (you have %d).',
                    cost.gil, player:getGil()),
                xi.msg.channel.SYSTEM_3)
            return false
        end

        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer(
                '[Weapon Forge] Free an inventory slot before forging.',
                xi.msg.channel.SYSTEM_3)
            return false
        end

        -- RARE pre-check before anything is consumed.
        if player:hasItem(toItem.id) then
            player:printToPlayer(
                string.format('[Weapon Forge] You already hold %s — it is RARE, so a second cannot be forged.',
                    toItem.name),
                xi.msg.channel.SYSTEM_3)
            return false
        end

        -- All checks passed — consume items.
        player:delItem(fromItem.id, 1)
        player:delItem(cost.medals.id, cost.medals.qty)
        if cost.reforgeMarks then
            drainMarks(player, cost.reforgeMarks)
        end
        if cost.gil then
            player:delGil(cost.gil)
        end

        if not player:addItem({ id = toItem.id, quantity = 1 }) then
            player:printToPlayer(
                '[Weapon Forge] ERROR: the forge consumed your materials but could not hand over the weapon — contact a GM with this message.',
                xi.msg.channel.SYSTEM_3)
            return true
        end
        player:printToPlayer(
            string.format(
                '[Weapon Forge] The %s shimmers and transforms — behold the %s!',
                fromItem.name, toItem.name),
            xi.msg.channel.SYSTEM_3)
        -- Stage III (final Prime) completion flag. Doesn't gate anything today
        -- (the Prime path IS the final ladder) but ships alongside the other
        -- four so a preflight can enumerate "which final tier does this player
        -- own" from CharVars alone -- no item-inventory scan required.
        if fromStage == 2 then
            player:setCharVar('WF_Prime_Final', 1)
        end
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
        if cost.gil then
            parts[#parts + 1] = string.format('%d gil', cost.gil)
        end
        if cost.requireTrials then
            parts[#parts + 1] = 'All 5 Prime Armory Trials'
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
        if sc.eschaBeads   then parts[#parts+1] = string.format('%d Escha Beads', sc.eschaBeads) end
        if sc.reforgeMarks then parts[#parts+1] = string.format('%d Reforge Marks', sc.reforgeMarks) end
        if sc.hlRank       then parts[#parts+1] = string.format('HL Rank %d', sc.hlRank) end
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
            local gl = gateLine(player, 'aeonic', fromStage)
            if gl ~= '' then player:printToPlayer(gl, xi.msg.channel.SYSTEM_3) end
        else
            player:printToPlayer(chainLine(chain, fromStage),   xi.msg.channel.SYSTEM_3)
            player:printToPlayer('Cost: ' .. costLine(fromStage), xi.msg.channel.SYSTEM_3)
            local gl = gateLine(player, 'prime', fromStage)
            if gl ~= '' then player:printToPlayer(gl, xi.msg.channel.SYSTEM_3) end
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


    -- =====================================================================
    -- EMPYREAN / MYTHIC / RELIC forge (flat chains from weapon_forge_catalog;
    -- base provision + 3 upgrade steps; recipes/gates match the docs). Added
    -- 2026-07-06 so the 119 III weapons (Twashtar etc.) are actually earnable.
    -- =====================================================================
    local FM       = catalog.forgeMats
    local NEW_CATS =
    {
        { key = 'empyrean', label = 'Empyrean', chains = catalog.empyreanChains, costs = catalog.empyreanCosts, base = catalog.empyreanBase },
        { key = 'mythic',   label = 'Mythic',   chains = catalog.mythicChains,   costs = catalog.mythicCosts,   base = catalog.mythicBase   },
        { key = 'relic',    label = 'Relic',    chains = catalog.relicChains,    costs = catalog.relicCosts,    base = catalog.relicBase    },
    }
    local STAGE_LBL = { [0] = 'not started', [1] = 'base', [2] = '119 I', [3] = '119 II', [4] = '119 III (complete)' }
    local showForgeRoot  -- forward decl (assigned below; referenced by showNewCat)

    -- Build the requirement list for one step. Each req: {have,take,qty,name}.
    -- Reforge Marks are returned separately (drained across the RF_* pools).
    local function stepReqs(chain, step)
        local list = {}
        local function item(id, qty, name)
            if id and qty and qty > 0 then
                list[#list + 1] = {
                    have = function(p) return p:getItemCount(id) end,
                    take = function(p) p:delItem(id, qty) end, qty = qty, name = name }
            end
        end
        local function cur(c, qty, name)
            if qty and qty > 0 then
                list[#list + 1] = {
                    have = function(p) return p:getCurrency(c) end,
                    take = function(p) p:delCurrency(c, qty) end, qty = qty, name = name }
            end
        end
        cur('cruor',             step.cruor,       'Cruor')
        cur('imperial_standing', step.standing,    'Imperial Standing')
        item(FM.beastcoin,       step.beastcoin,   'Ancient Beastcoin')
        item(FM.riftbornBoulder, step.boulder,     'Riftborn Boulder')
        item(FM.byneBill,        step.byne,        'Byne Bill')
        item(FM.silverpiece,     step.silverpiece, 'M. Silverpiece')
        item(FM.jadeshell,       step.jadeshell,   'L. Jadeshell')
        item(FM.pluton,          step.pluton,      'Pluton')
        item(FM.imperialBronze,  step.bronze,      'Imperial Bronze Piece')
        item(FM.imperialSilver,  step.silver,      'Imperial Silver Piece')
        item(FM.imperialGold,    step.gold,        'Imperial Gold Piece')
        item(FM.beitetsu,        step.beitetsu,    'Beitetsu')
        if step.mat then
            -- Print the REAL item name ("Orthrus's Claw"), not "Twashtar material".
            -- The generic label had players looking up retail info and bringing the
            -- wrong item (Jamesta report, 2026-07-13). Falls back to the old label
            -- if a new mat id was added without a lookup entry -- add one over in
            -- catalog.empyreanMatNames rather than relying on the fallback.
            local matName = catalog.empyreanMatNames[chain.mat] or (chain.name .. ' material')
            item(chain.mat, step.mat, matName)
        end
        return list, step.marks
    end

    -- Held stage: 0 none, 1 base, 2 s1(119I), 3 s2(119II), 4 s3(119III/done).
    local function heldStage(player, chain)
        if player:getItemCount(chain.s3) > 0 then return 4 end
        if player:getItemCount(chain.s2) > 0 then return 3 end
        if player:getItemCount(chain.s1) > 0 then return 2 end
        if player:getItemCount(chain.base) > 0 then return 1 end
        return 0
    end

    local function doNewForge(player, def, chain)
        local S = xi.msg.channel.SYSTEM_3
        local k = heldStage(player, chain)
        if k == 4 then
            player:printToPlayer(string.format('[Weapon Forge] Your %s is already fully forged, kupo!', chain.name), S)
            return
        end
        -- Owner spec 2026-07-13. NEW_CATS held-stage indexing:
        --   k=0 -> issue base (no widget gate; the widget starts at "Base")
        --   k=1 -> base -> 119 I  == widget "Base -> Stage I"      -> STAGE_GATES[0]
        --   k=2 -> 119I -> 119II  == widget "Stage I -> Stage II"  -> STAGE_GATES[1]
        --   k=3 -> 119II -> 119III == widget "Stage II -> Stage III" -> STAGE_GATES[2]
        -- The (k-1) offset lines the code's held-stage counter up with the
        -- widget's forge[i] index so the label the player sees matches the
        -- string in the docs verbatim.
        if k >= 1 and not checkGate(player, def.key, k - 1) then return end
        local fromId, toId, step
        if k == 0 then
            step, toId = def.base, chain.base          -- issue the base weapon
        elseif chain.singleStep then
            -- Retail 2-step mythics (Epeolatry, Idris): the DB only has base +
            -- 119III, no +1/+2 stages. Charge the SUM of all three mythic tier
            -- costs at once (catalog.mythicCostsSum) so the total investment
            -- matches the other mythics and forge directly base -> s3.
            step   = catalog.mythicCostsSum
            fromId = chain.base
            toId   = chain.s3
        else
            step   = def.costs[k]                       -- k=1 base->119I, 2 ->II, 3 ->III
            fromId = ({ chain.base, chain.s1, chain.s2 })[k]
            toId   = ({ chain.s1, chain.s2, chain.s3 })[k]
        end
        local hl = math.max(1, player:getCharVar('HL_Tier'))
        if step.hlRank and hl < step.hlRank then
            player:printToPlayer(string.format('[Weapon Forge] Need Hunting League Rank %d (you are Rank %d).', step.hlRank, hl), S)
            return
        end
        -- Dynamis - Divergence unique-city gate (Relic path 2026-07-13):
        -- N unique city clears required, from xi.divergence.uniqueWins()
        -- which pops the DivergenceSlots bitmask. Multiple runs of the
        -- same city still count as 1.
        if step.divergenceWins then
            local have = 0
            pcall(function() have = xi.divergence.uniqueWins(player) end)
            if have < step.divergenceWins then
                player:printToPlayer(string.format(
                    '[Weapon Forge] Need %d unique Dynamis - Divergence city win(s) (you have %d). Multiple runs of the same city count once.',
                    step.divergenceWins, have), S)
                return
            end
        end
        local reqs, marks = stepReqs(chain, step)
        for _, req in ipairs(reqs) do
            if req.have(player) < req.qty then
                player:printToPlayer(string.format('[Weapon Forge] Need %dx %s (you have %d).', req.qty, req.name, req.have(player)), S)
                return
            end
        end
        if marks and totalMarks(player) < marks then
            player:printToPlayer(string.format('[Weapon Forge] Need %d Reforge Marks (you have %d).', marks, totalMarks(player)), S)
            return
        end
        if fromId and player:getItemCount(fromId) < 1 then
            player:printToPlayer('[Weapon Forge] You no longer have the weapon to forge.', S)
            return
        end
        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer('[Weapon Forge] Free an inventory slot before forging.', S)
            return
        end
        -- RARE pre-check before anything is consumed.
        if player:hasItem(toId) then
            player:printToPlayer(string.format('[Weapon Forge] You already hold the %s stage — it is RARE, so a second cannot be forged.', STAGE_LBL[k + 1]), S)
            return
        end
        for _, req in ipairs(reqs) do req.take(player) end
        if marks then drainMarks(player, marks) end
        if fromId then player:delItem(fromId, 1) end
        if not player:addItem({ id = toId, quantity = 1 }) then
            player:printToPlayer('[Weapon Forge] ERROR: the forge consumed your materials but could not hand over the weapon — contact a GM with this message.', S)
            return
        end
        player:printToPlayer(string.format('[Weapon Forge] Your %s advances to %s!', chain.name, STAGE_LBL[k + 1]), S)
        -- Stage III (final Empyrean / Mythic / Relic) completion flag. Read by
        -- the Prime Stage I preflight; `def.key` is one of 'empyrean',
        -- 'mythic', 'relic'. STAGE_LBL[4] = '119 III (complete)' so k+1 == 4
        -- is the final stage.
        if k + 1 == 4 and def and def.key then
            player:setCharVar('WF_' .. def.key:sub(1,1):upper() .. def.key:sub(2) .. '_Final', 1)
        end
    end

    local function printNewRecipe(player, def, chain)
        local S = xi.msg.channel.SYSTEM_3
        local k = heldStage(player, chain)
        player:printToPlayer(string.format('[%s] %s (%s) -- you hold: %s', def.label, chain.name, chain.jobs, STAGE_LBL[k]), S)
        if k == 4 then return end
        -- singleStep chains (Epeolatry, Idris): quote the combined cost + label
        -- the target as "119 III" directly rather than the intermediate stages
        -- that don't exist for these two weapons.
        local step        = (k == 0) and def.base
                            or (chain.singleStep and catalog.mythicCostsSum)
                            or def.costs[k]
        local reqs, marks = stepReqs(chain, step)
        local parts       = { string.format('HL Rank %d', step.hlRank or 1) }
        for _, req in ipairs(reqs) do parts[#parts + 1] = string.format('%dx %s', req.qty, req.name) end
        if marks then parts[#parts + 1] = string.format('%d Reforge Marks', marks) end
        local what = (k == 0) and 'Obtain base'
                     or (chain.singleStep and '-> 119 III (combined mythic cost)')
                     or ('-> ' .. STAGE_LBL[k + 1])
        player:printToPlayer('  ' .. what .. ':  ' .. table.concat(parts, '  |  '), S)
        if k >= 1 then
            local gl = gateLine(player, def.key, k - 1)
            if gl ~= '' then player:printToPlayer(gl, S) end
        end
    end

    local showNewCat  -- forward decl

    local function showNewWeapon(player, def, chain)
        local k    = heldStage(player, chain)
        local opts = {}
        if k < 4 then
            local verb = (k == 0) and ('Obtain base ' .. chain.name) or ('Forge -> ' .. STAGE_LBL[k + 1])
            opts[#opts + 1] = { verb, function(p) doNewForge(p, def, chain); showNewWeapon(p, def, chain) end }
        end
        opts[#opts + 1] = { 'Show recipe', function(p) printNewRecipe(p, def, chain); showNewWeapon(p, def, chain) end }
        opts[#opts + 1] = { 'Back', function(p) showNewCat(p, def, 1) end }
        sendMenu(player, string.format('%s (%s) [%s]', chain.name, chain.jobs, STAGE_LBL[k]), opts)
    end

    -- 5/page keeps each category page's customMenu string under the ~150-byte
    -- wire cap. At 7 (with the old "(jobs)" label suffix) the Empyrean/Mythic
    -- first pages overflowed and truncated the last label, so its click no
    -- longer matched server-side and the menu silently closed -- that was the
    -- "Twashtar / Terpsichore do nothing" bug (report: Jamesta 2026-07-09).
    local CAT_PAGE = 5
    showNewCat = function(player, def, page)
        page = page or 1
        local n     = #def.chains
        local pages = math.max(1, math.ceil(n / CAT_PAGE))
        page = math.max(1, math.min(page, pages))
        local a, b  = (page - 1) * CAT_PAGE + 1, math.min(page * CAT_PAGE, n)
        local opts  = {}
        for i = a, b do
            local chain = def.chains[i]
            -- Name only (no "(jobs)" suffix) to keep the page under the byte cap;
            -- jobs are shown on the weapon's own screen (showNewWeapon title).
            opts[#opts + 1] = { chain.name,
                function(p) showNewWeapon(p, def, chain) end }
        end
        if pages > 1 and page > 1     then opts[#opts + 1] = { '<< Prev', function(p) showNewCat(p, def, page - 1) end } end
        if pages > 1 and page < pages then opts[#opts + 1] = { 'Next >>', function(p) showNewCat(p, def, page + 1) end } end
        opts[#opts + 1] = { 'Back', function(p) showForgeRoot(p) end }
        sendMenu(player, string.format('%s Forge (%d/%d)', def.label, page, pages), opts)
    end

    showForgeRoot = function(player)
        local opts = {
            { 'My upgradeable weapons (Prime / Aeonic)', function(p) showUpgrades(p) end },
        }
        for _, def in ipairs(NEW_CATS) do
            local d = def
            opts[#opts + 1] = { string.format('%s weapons (%d)', def.label, #def.chains),
                function(p) showNewCat(p, d, 1) end }
        end
        opts[#opts + 1] = { 'Not today.', function() end }
        sendMenu(player, 'Weapon Forge', opts)
    end

    -- -------------------------------------------------------------------------
    -- NPC placement
    -- -------------------------------------------------------------------------

    local WeaponForger = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Weapon_Forger',
        packetName = string.format('%sWeapon Forger', xi.icon.STAR_LARGE),
        look       = 245,
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
            -- Fold the DEAD legacy charVars (Escha_Beads / Escha_Silt, pre-real-
            -- currency) into the unified escha_beads currency so pre-refactor
            -- balances still pay for the Aeonic forge steps. Idempotent. (The real
            -- escha_silt currency is left alone -- it's portal/travel fuel.)
            for _, var in ipairs({ 'Escha_Beads', 'Escha_Silt' }) do
                local old = player:getCharVar(var) or 0
                if old > 0 then
                    player:addCurrency('escha_beads', old)
                    player:setCharVar(var, 0)
                end
            end
            player:printToPlayer(
                '[Weapon Forge] I forge every endgame weapon path. Prime and Aeonic upgrade '
                .. 'from a weapon in your bag; Empyrean, Mythic, and Relic I can start from the '
                .. 'base and forge up through 119 / 119 II / 119 III. Choose a path.',
                xi.msg.channel.SYSTEM_3)
            showForgeRoot(player)
        end,
    })
    utils.unused(WeaponForger)
end)

return m
