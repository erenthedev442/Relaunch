-----------------------------------
-- htbf.lua  -- High-Tier Mission Battlefield registrar (relaunch)
--
-- One call per tier from a tiny battlefield file:
--   return require('modules/custom/lua/htbf').register('trial_by_fire', 2)
--
-- Builds a Battlefield (the engine needs no change): a unique battlefieldId +
-- a unique menu `index` on the existing entrance NPC, gated on the fight's
-- Phantom Gem (consumed on entry), reusing the base boss and scaling it
-- per-instance in setupBattlefield. Data lives in htbf_catalog.lua.
--
-- Loaded from scripts/battlefields/<Zone>/<key>_ht{1,2,3}.lua, so the global
-- Battlefield class + xi.* are already available.
-----------------------------------
local catalog = require('modules/custom/lua/htbf_catalog')

local htbf = {}

-- ---------------------------------------------------------------------------
-- Let players field Trusts inside HTBF battlefields.
-- The engine gates battlefield trust summons on
--   xi.trust.checkBattlefieldTrustCount = (players + trusts) < maxParticipants
-- (enforced both in scripts/globals/trust.lua and in the C++ magic_state).
-- HTBF fights hit that limit, so a summon is rejected with the yellow
--   "You are unable to use Trust magic at this time."
-- We tag HTBF battlefields (localVar HTBF=1, set in setupBattlefield) and, for
-- those only, allow Trusts up to a flat cap regardless of maxParticipants --
-- the same escape-hatch idea the stock code already uses for RoV KI fights.
-- Installed once, the first time this module is required at battlefield load.
-- ---------------------------------------------------------------------------
if xi.trust and xi.trust.checkBattlefieldTrustCount and not xi.trust._htbfTrustPatched then
    xi.trust._htbfTrustPatched = true
    local HTBF_TRUST_CAP = 5   -- max Trusts a party may field inside an HTBF fight
    local _origCheck = xi.trust.checkBattlefieldTrustCount
    xi.trust.checkBattlefieldTrustCount = function(caster)
        local bf = caster:getBattlefield()
        if bf and bf:getLocalVar('HTBF') == 1 then
            local numTrusts = 0
            for _, entity in ipairs(bf:getPlayersAndTrusts()) do
                if entity:getObjType() == xi.objType.TRUST then
                    numTrusts = numTrusts + 1
                end
            end
            return numTrusts < HTBF_TRUST_CAP
        end
        return _origCheck(caster)
    end
end

-- ---------------------------------------------------------------------------
-- Entrance tier legend (cosmetic fix for the "unmarked menu rows").
-- The burning-circle "Which battlefield will you enter?" list draws each row's
-- NAME from the CLIENT's zone dialog DAT, indexed by menu slot (content.index).
-- Retail zones only carry names for their few retail slots, so our custom HTBF
-- tiers -- which sit on indices past those -- render as BLANK ("unmarked") rows.
-- The server cannot inject names into that pre-selection menu, so instead we
-- print a legend to the log the instant the menu is built, telling the player
-- which unnamed rows are which HTBF tiers.
--
-- We hook by wrapping xi.battlefield.getBattlefieldOptions rather than
-- Battlefield.onEntryTrigger: onEntryTrigger looks that function up DYNAMICALLY
-- on the xi.battlefield table right before opening the menu (battlefield.lua),
-- so the wrap fires reliably no matter when each entrance NPC captured
-- onEntryTrigger. (onEntryTrigger is bound BY VALUE at Battlefield:register()
-- time -- and the base retail fight on a shared entrance registers before the
-- HTBF tier files even load this module -- so wrapping it directly would be
-- captured stale. Same reason the trust patch above wraps a dynamically-lookup'd
-- function.) Installed once, guarded so non-HTBF entrances print nothing.
-- ---------------------------------------------------------------------------
function htbf.printEntranceLegend(player, npc)
    local zoneId  = player:getZoneID()
    local npcName = npc:getName()

    -- HTBF fights on THIS entrance that the player can actually enter (holds the
    -- gem = passes the same requiredKeyItems gate that put them in the menu), in
    -- menu (index) order.
    local rows = {}
    for _, f in pairs(catalog.fights) do
        if f.zone == zoneId and player:hasKeyItem(f.gem) then
            local match = (f.entryNpc == npcName)
            if not match and f.entryNpcs then
                for _, n in ipairs(f.entryNpcs) do
                    if n == npcName then match = true break end
                end
            end
            if match then
                rows[#rows + 1] = { idx = f.baseIndex, label = f.label }
            end
        end
    end

    if #rows == 0 then return end
    table.sort(rows, function(a, b) return a.idx < b.idx end)

    player:printToPlayer('[HTBF] Some entries below show no name (client limit). High-Tier Battlefields:', xi.msg.channel.SYSTEM_3)
    for _, r in ipairs(rows) do
        player:printToPlayer(string.format(
            '[HTBF]   %s -- three consecutive rows = Tier I, II, III (easy -> hardest).', r.label),
            xi.msg.channel.SYSTEM_3)
    end
end

-- Wrap the menu-options builder (dynamically dispatched inside onEntryTrigger).
if xi.battlefield and xi.battlefield.getBattlefieldOptions and not xi.battlefield._htbfLegendPatched then
    xi.battlefield._htbfLegendPatched = true
    local _origOptions = xi.battlefield.getBattlefieldOptions
    xi.battlefield.getBattlefieldOptions = function(player, npc, trade)
        local options = _origOptions(player, npc, trade)
        -- Only for gem entry (no trade); printEntranceLegend no-ops on any
        -- entrance without HTBF tiers the player qualifies for.
        if not trade then
            pcall(htbf.printEntranceLegend, player, npc)
        end
        return options
    end
end

function htbf.register(fightKey, tier)
    local f     = catalog.fights[fightKey]
    local scale = catalog.tierScale[tier]
    local rew   = catalog.tierReward[tier]
    if not f or not scale then
        print(string.format('[HTBF] register: bad args (%s, %s)', tostring(fightKey), tostring(tier)))
        return nil
    end

    local content = Battlefield:new({
        zoneId           = f.zone,
        battlefieldId    = f.baseBattlefieldId + (tier - 1),
        index            = f.baseIndex + (tier - 1),
        entryNpc         = f.entryNpc,
        entryNpcs        = f.entryNpcs,
        exitNpc          = f.exitNpc,
        exitNpcs         = f.exitNpcs,
        allowedAreas     = f.allowedAreas,
        maxPlayers       = f.maxPlayers or 6,
        timeLimit        = f.timeLimit or utils.minutes(30),
        canLoseExp       = false,
        requiredKeyItems = { f.gem },   -- consumed on entry (no keep); HTBF is gem-gated
    })

    -- Groups. Simple single-boss fights name the boss (f.mobs). Complex fights
    -- (multi-group, per-arena mobIds, skillchain AI, phase sections) instead
    -- REUSE the base battlefield's full definition via f.reuseBaseId (the base's
    -- xi.battlefield.id) -- we copy its groups + tick/section logic so the fight
    -- runs identically; we only re-gate it (gem) + scale it. The base script
    -- loads alphabetically before <key>_ht*.lua, so it is registered by now.
    local baseSetup = nil
    if f.reuseBaseId then
        local base = xi.battlefield.contents[f.reuseBaseId]
        if base then
            content.groups = base.groups
            -- Carry the base fight's custom hooks so multi-phase / skillchain-AI /
            -- event-driven fights run identically. We keep our OWN onEventFinishWin
            -- (the reward) and chain setupBattlefield (below) for the tier scaling.
            for _, hook in ipairs({
                'onBattlefieldTick', 'sections', 'onExitTrigger', 'onEventFinishExit',
                'onEventUpdate', 'onBattlefieldLoss', 'onBattlefieldRegister', 'paths',
                -- onEventFinishBattlefield drives the PHASE-2 spawn on multi-phase
                -- fights (Dawn spawns Promathia P2 here; Shadow Lord and Celestial
                -- Nexus likewise). Without it those reuse fights play the P1-death
                -- cutscene but never spawn P2 -> unwinnable. The closures capture
                -- the base file's own scope + our shared groups table, so copying
                -- the reference is correct. Guarded by rawget, so single-boss
                -- fights that don't define it are unaffected.
                'onEventFinishBattlefield',
            }) do
                if rawget(base, hook) ~= nil then content[hook] = base[hook] end
            end
            baseSetup = rawget(base, 'setupBattlefield')
        else
            print(string.format('[HTBF] %s tier %d: base id %s not registered (load order?)',
                tostring(fightKey), tier, tostring(f.reuseBaseId)))
            content.groups = {}
        end
    else
        content.groups =
        {
            {
                mobs = f.mobs,
                allDeath = function(battlefield, mob)
                    battlefield:setStatus(xi.battlefield.status.WON)
                end,
            },
        }
    end

    -- Per-instance tier scaling of the reused base boss(es). Runs after the mobs
    -- are spawned for THIS battlefield instance, so concurrent tiers scale
    -- independently. Silent (no player-visible multiplier). int16 mod cap honored
    -- by the catalog values; HP is the int32 lever.
    function content:setupBattlefield(battlefield)
        -- Tag as an HTBF battlefield so the trust-count patch above lets players
        -- summon Trusts here (the engine's default cap would reject them).
        battlefield:setLocalVar('HTBF', 1)
        -- Run the base fight's own setup first (spawns/positions/etc.), then scale.
        if baseSetup then pcall(function() baseSetup(self, battlefield) end) end
        for _, mob in ipairs(battlefield:getMobs(true, true)) do
            pcall(function()
                if scale.lvl and scale.lvl > 1.0 then
                    mob:setMobLevel(math.min(math.floor(mob:getMainLvl() * scale.lvl), 255))
                end
                if scale.hp and scale.hp > 1.0 then
                    local hp = math.floor(mob:getMaxHP() * scale.hp)
                    mob:setMaxHP(hp)
                    mob:setHP(hp)
                end
                if scale.att  and scale.att  > 0 then mob:addMod(xi.mod.ATT,  scale.att)  end
                if scale.def  and scale.def  > 0 then mob:addMod(xi.mod.DEF,  scale.def)  end
                if scale.macc and scale.macc > 0 then mob:addMod(xi.mod.MACC, scale.macc) end
                if scale.meva and scale.meva > 0 then mob:addMod(xi.mod.MEVA, scale.meva) end
            end)
        end
    end

    -- Reward on win: gil + Hunt Marks per tier (catalog.tierReward). Hunt Marks
    -- are the relaunch's HL_Points currency -- the very same marks the Hunting
    -- League pays -- so HTBF clears feed the live progression economy and the
    -- "Marks Earned (Lifetime)" leaderboard. The real retail per-fight item LOOT
    -- still goes in catalog.fights[key].loot[tier] (armoury-crate) as it is
    -- sourced from bg-wiki; this is the guaranteed completion reward on top.
    function content:onEventFinishWin(player, csid, option, npc)
        if not rew then return end
        if rew.gil and rew.gil > 0 then
            pcall(function() player:addGil(rew.gil) end)
        end
        if rew.marks and rew.marks > 0 then
            pcall(function()
                player:setCharVar('HL_Points',
                    (player:getCharVar('HL_Points') or 0) + rew.marks)
                player:setCharVar('HL_Points_Lifetime',
                    (player:getCharVar('HL_Points_Lifetime') or 0) + rew.marks)
            end)
        end
        -- Per-tier clear flag: used as an entry gate for Ambuscade (must have
        -- cleared at least one HTBF at each of T1/T2/T3). tier is the register()
        -- arg captured in this closure -- one flag per player per tier, sticky
        -- (never cleared).
        pcall(function()
            if tier and tier >= 1 and tier <= 3 then
                player:setCharVar('HTBF_Cleared_T' .. tier, 1)
            end
        end)
        -- Item loot. HTBF fights use a custom battlefieldId with NO C++ retail
        -- treasure, and the reuse-base fights end their win in varied ways (most
        -- on a bare setStatus(WON) that never opens an Armoury Crate), so the
        -- stock crate -> handleLootRolls path drops nothing. Roll content.loot
        -- HERE -- the one hook that reliably fires on every fight's win (it's
        -- where gil/marks already land) -- and give the items straight to the
        -- player, per completion. selectFromLootGroups is the same roller the
        -- crate uses, so htbf_loot.lua tables behave identically.
        local looted = 0
        if self.loot then
            pcall(function()
                for _, entry in ipairs(utils.selectFromLootGroups(player, self.loot)) do
                    if entry.itemId and entry.itemId ~= 0 then
                        if entry.itemId == xi.item.GIL then
                            player:addGil(entry.amount or 0)
                        elseif npcUtil.giveItem(player, {{ entry.itemId, entry.amount or 1 }}) then
                            looted = looted + 1
                        end
                    end
                end
            end)
        end
        pcall(function()
            player:printToPlayer(string.format(
                'High-Tier Battlefield cleared! Reward: %d gil and %d Hunt Marks%s.',
                rew.gil or 0, rew.marks or 0,
                looted > 0 and (' + ' .. looted .. ' item(s)') or ''), xi.msg.channel.SYSTEM_3)
        end)
    end

    -- Armoury-crate loot. Priority: a fight's per-tier override (f.loot[tier]),
    -- then its flat retail pool (catalog.fightLoot[fightKey], same pool across
    -- tiers -- retail loot is per-fight, the tiers differ in difficulty + marks),
    -- then the modest tier-scaled default so every fight always drops a crate.
    local loot = (f.loot and f.loot[tier])
        or (catalog.fightLoot and catalog.fightLoot[fightKey])
        or catalog.tierLoot[tier]
    if loot then
        content.loot = loot
    end

    return content:register()
end

return htbf
