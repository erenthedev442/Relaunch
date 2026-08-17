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
-- ACCESS REQUIREMENTS (owner request 2026-07-12)
-- To enter ANY High-Tier Battlefield, on the job you are entering with you must
--   1. have MASTERED that job -- getSpentJobPoints() >= MASTER_JP. That binding
--      reads the CURRENT main job and returns 0 below Lv99, and 2100 == every JP
--      gift unlocked (full mastery). We source the bar from job_rebirth_catalog
--      so the server's one mastery number never drifts (JobRebirth uses it too).
--   2. have registered ALL NM affinities (the Augment_Affinities bitfield full).
-- Enforced by overriding each content's entryRequirement (in register), so an
-- unqualified player never sees the fight in the burning-circle menu; the menu
-- wrapper (printEntranceLegend) prints exactly what's missing when they hold the
-- gem but fall short -- silent menu-hiding would otherwise be baffling.
-- ---------------------------------------------------------------------------
local function popcount(n)
    local c = 0
    while n > 0 do c = c + bit.band(n, 1); n = bit.rshift(n, 1) end
    return c
end

local MASTER_JP = 2100  -- fallback; overwritten from job_rebirth_catalog below
do
    local ok, reb = pcall(require, 'modules/custom/lua/job_rebirth_catalog')
    if ok and reb and reb.jpRequired then MASTER_JP = reb.jpRequired end
end

-- Full-affinity mask, derived from the catalog so it tracks the roster (never a
-- hardcoded 0x7FF that rots if a category is added/removed). Fail-SAFE: if the
-- catalog can't be read, keep the 11-bit fallback so the gate stays CLOSED
-- rather than silently letting everyone in.
local AFFINITY_FULL_MASK = 0x7FF
do
    local ok, aff = pcall(require, 'modules/custom/lua/augment_affinity_catalog')
    if ok and aff and aff.affinities then
        local mask = 0
        for _, row in ipairs(aff.affinities) do mask = bit.bor(mask, bit.lshift(1, row.bit)) end
        if mask ~= 0 then AFFINITY_FULL_MASK = mask end
    end
end
local AFFINITY_COUNT = popcount(AFFINITY_FULL_MASK)

-- Returns ok(bool), missing(list of human-readable requirement strings).
function htbf.accessCheck(player)
    local missing = {}
    local spent = player:getSpentJobPoints() or 0
    if spent < MASTER_JP then
        missing[#missing + 1] = string.format(
            'master the job you enter with (Job Points %d/%d)', spent, MASTER_JP)
    end
    local field = bit.band(player:getCharVar('Augment_Affinities') or 0, AFFINITY_FULL_MASK)
    if field ~= AFFINITY_FULL_MASK then
        missing[#missing + 1] = string.format(
            'register all %d NM affinities (have %d/%d)', AFFINITY_COUNT, popcount(field), AFFINITY_COUNT)
    end
    return #missing == 0, missing
end

local function tier3Unlocked(player)
    return catalog.progress.get(player).tier3
end

local function finalTestReady(player)
    return catalog.progress.get(player).finalReady
end

htbf.progress = catalog.progress

local function fightMatchesEntrance(fight, zoneId, npcName)
    if fight.zone ~= zoneId then
        return false
    end
    if fight.entryNpc == npcName then
        return true
    end

    return fight.entryNpcs and utils.contains(npcName, fight.entryNpcs) or false
end

function htbf.getMatchingFightKeys(player, npc)
    local matches = {}
    local zoneId = player:getZoneID()
    local npcName = npc:getName()
    for fightKey, fight in pairs(catalog.fights) do
        if
            fightMatchesEntrance(fight, zoneId, npcName) and
            player:hasKeyItem(fight.gem)
        then
            matches[#matches + 1] = fightKey
        end
    end
    table.sort(matches)
    return matches
end

local function getRegisteredChoices(player, npc, fightKey)
    local choices = {}
    for _, content in ipairs(
        xi.battlefield.contentsByZone[player:getZoneID()] or {})
    do
        if
            content.customEntryFight == fightKey and
            content:isValidEntry(player, npc) and
            content:checkRequirements(player, npc, true) and
            not player:battlefieldAtCapacity(content.battlefieldId)
        then
            choices[#choices + 1] = content
        end
    end
    table.sort(choices, function(left, right)
        return left.customEntryOrder < right.customEntryOrder
    end)
    return choices
end
htbf.getRegisteredChoices = getRegisteredChoices

local namedMenuLatch = '[HTBF]NamedMenuOpen'
local namedMenuToken = '[HTBF]NamedMenuToken'

local function releaseNamedMenu(player)
    player:setLocalVar(namedMenuLatch, 0)
end

local function showTierMenu(player, npc, fightKey)
    local fight = catalog.fights[fightKey]
    local choices = getRegisteredChoices(player, npc, fightKey)
    if #choices == 0 then
        releaseNamedMenu(player)
        player:printToPlayer(
            '[HTBF] No Legendary tiers are currently available for this fight.',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local options = {}
    for _, content in ipairs(choices) do
        local selected = content
        options[#options + 1] =
        {
            selected.customEntryLabel,
            function(p)
                releaseNamedMenu(p)
                if not selected:directEntry(p, npc) then
                    p:printToPlayer(
                        '[HTBF] Entry failed; your gem was not intentionally consumed.',
                        xi.msg.channel.SYSTEM_3)
                end
            end,
        }
    end
    options[#options + 1] = { 'Cancel', releaseNamedMenu }

    local label = fight and fight.label or fightKey
    player:customMenu({
        title = 'Legendary: ' .. label,
        options = options,
    })
end

local function showFightMenu(player, npc, fightKeys)
    if #fightKeys == 1 then
        showTierMenu(player, npc, fightKeys[1])
        return
    end

    local options = {}
    for _, fightKey in ipairs(fightKeys) do
        local key = fightKey
        local fight = catalog.fights[key]
        options[#options + 1] =
        {
            fight.label,
            function(p)
                -- HandleCustomMenu clears the old context after this callback.
                -- Do not install the next context until that teardown has
                -- completed, otherwise the client's next choice is sent as an
                -- ordinary tell to _CUSTOM_MENU.
                p:timer(500, function(pp) showTierMenu(pp, npc, key) end)
            end,
        }
    end
    options[#options + 1] = { 'Cancel', releaseNamedMenu }
    player:customMenu({ title = 'Choose Legendary fight', options = options })
end

-- Dynamic hook: Battlefield.onEntryTrigger consults this at interaction time,
-- so shared retail NPC handlers do not need to be replaced or load-order aware.
if xi.battlefield and not xi.battlefield._htbfNamedEntryPatched then
    xi.battlefield._htbfNamedEntryPatched = true
    local previousCustomEntry = xi.battlefield.customEntryTrigger
    xi.battlefield.customEntryTrigger = function(player, npc)
        local fightKeys = htbf.getMatchingFightKeys(player, npc)
        if #fightKeys == 0 then
            return previousCustomEntry and
                previousCustomEntry(player, npc) or false
        end

        -- Shared battlefield NPC sections can dispatch the same trigger more
        -- than once. Multiple customMenu packets stack client prompts, but only
        -- one server context survives; the remaining selections become failed
        -- tells to _CUSTOM_MENU. Debounce centrally for every HTBF entrance.
        if player:getLocalVar(namedMenuLatch) == 1 then
            return true
        end
        player:setLocalVar(namedMenuLatch, 1)
        local token = player:getLocalVar(namedMenuToken) + 1
        player:setLocalVar(namedMenuToken, token)
        player:timer(30000, function(p)
            -- Recover if the client closes the menu without invoking Cancel,
            -- but never let an old timeout unlock a newer menu.
            if p:getLocalVar(namedMenuToken) == token then
                releaseNamedMenu(p)
            end
        end)

        local canEnter, missing = htbf.accessCheck(player)
        if not canEnter then
            releaseNamedMenu(player)
            player:printToPlayer(
                '[HTBF] Legendary entry requirements are incomplete:',
                xi.msg.channel.SYSTEM_3)
            for _, requirement in ipairs(missing) do
                player:printToPlayer(
                    '[HTBF]   - ' .. requirement, xi.msg.channel.SYSTEM_3)
            end
            return true
        end

        showFightMenu(player, npc, fightKeys)
        return true
    end
end

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
    local _origCheck = xi.trust.checkBattlefieldTrustCount
    xi.trust.checkBattlefieldTrustCount = function(caster)
        local bf = caster:getBattlefield()
        if bf and bf:getLocalVar('HTBF') == 1 then
            local cap = catalog.trustCap[bf:getLocalVar('HTBFTier')] or catalog.trustCap[1]
            local numTrusts = 0
            for _, entity in ipairs(bf:getPlayersAndTrusts()) do
                -- The custom Adventuring Fellow is implemented as a specially
                -- flagged trust, but is a free extra and never consumes a slot.
                if entity:getObjType() == xi.objType.TRUST
                    and entity:getLocalVar('fellowApplied') ~= 1
                then
                    numTrusts = numTrusts + 1
                end
            end
            return numTrusts < cap
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
                rows[#rows + 1] =
                {
                    idx   = f.baseIndex,
                    label = f.label,
                    gem   = catalog.gemName[f.gem] or 'Phantom Gem',
                }
            end
        end
    end

    if #rows == 0 then return end

    -- Holding the gem isn't enough: HTBF is gated on mastering the entering job
    -- and holding every NM affinity (see accessCheck at top). If they fall short,
    -- the entryRequirement override has already hidden these tiers from the menu,
    -- so tell them exactly what's missing rather than print a legend for rows the
    -- menu (correctly) won't offer.
    local canEnter, missing = htbf.accessCheck(player)
    if not canEnter then
        player:printToPlayer('[HTBF] You hold a Phantom Gem, but High-Tier Battlefields have entry requirements you have not met:', xi.msg.channel.SYSTEM_3)
        for _, req in ipairs(missing) do
            player:printToPlayer('[HTBF]   - ' .. req, xi.msg.channel.SYSTEM_3)
        end
        return
    end

    table.sort(rows, function(a, b) return a.idx < b.idx end)

    player:printToPlayer('[HTBF] Some entries below show no name (client limit). High-Tier Battlefields:', xi.msg.channel.SYSTEM_3)
    if #rows > 1 then
        player:printToPlayer(
            '[HTBF] You hold gems for multiple fights at this entrance. Choose the correct tier group.',
            xi.msg.channel.SYSTEM_3)
    end

    local hasTier3 = tier3Unlocked(player)
    for _, r in ipairs(rows) do
        player:printToPlayer(string.format(
            '[HTBF]   Rows %d/%d/%d: %s (%s) -- Tier I/II/%s.',
            r.idx, r.idx + 1, r.idx + 2, r.label, r.gem,
            hasTier3 and 'III' or 'III locked'),
            xi.msg.channel.SYSTEM_3)
    end

    local final = catalog.finalTest
    local finalFight = catalog.fights[final.fightKey]
    local finalEntrance =
        finalFight.zone == zoneId and
        finalFight.entryNpc == npcName
    if finalEntrance and finalTestReady(player) then
        player:printToPlayer(
            '[HTBF]   Final row: Final Proving -- one-time Garuda test; unlocks all Tier III fights and Ambuscade T3 credit.',
            xi.msg.channel.SYSTEM_3)
    elseif not hasTier3 then
        player:printToPlayer(
            '[HTBF] Clear Tier I and Tier II, then take Final Proving from the Phantom Gems NPC.',
            xi.msg.channel.SYSTEM_3)
    end
end

-- Wrap the menu-options builder (dynamically dispatched inside onEntryTrigger).
if xi.battlefield and xi.battlefield.getBattlefieldOptions and not xi.battlefield._htbfLegendPatched then
    xi.battlefield._htbfLegendPatched = true
    local _origOptions = xi.battlefield.getBattlefieldOptions
    xi.battlefield.getBattlefieldOptions = function(player, npc, trade)
        local options = _origOptions(player, npc, trade)
        if not trade then
            -- A Phantom Gem is an explicit HTBF intent. Remove the retail rows
            -- on this same entrance so a client DAT label can never route that
            -- gem holder into a mission battlefield with a coincident index.
            local matchedBaseIds = {}
            local broadFallback = false
            for _, fight in pairs(catalog.fights) do
                if
                    fightMatchesEntrance(
                        fight, player:getZoneID(), npc:getName()) and
                    player:hasKeyItem(fight.gem)
                then
                    if fight.reuseBaseId then
                        matchedBaseIds[fight.reuseBaseId] = true
                    else
                        broadFallback = true
                    end
                end
            end
            if broadFallback or next(matchedBaseIds) then
                for _, content in ipairs(xi.battlefield.contentsByZone[player:getZoneID()] or {}) do
                    if
                        not content.partyKeyItem and
                        content:isValidEntry(player, npc) and
                        (broadFallback or matchedBaseIds[content.battlefieldId])
                    then
                        options = utils.mask.setBit(options, content.index, false)
                    end
                end
            end
        end
        -- Only for gem entry (no trade); printEntranceLegend no-ops on any
        -- entrance without HTBF tiers the player qualifies for.
        if not trade then
            pcall(htbf.printEntranceLegend, player, npc)
        end
        return options
    end
end

function htbf.register(fightKey, tier, variant)
    local f           = catalog.fights[fightKey]
    local isFinalTest = variant == 'finalTest'
    local final       = catalog.finalTest
    local scale       = isFinalTest and final.scale or
        (f and f.tierScaleOverride and f.tierScaleOverride[tier]) or
        (f and catalog.tierScale[f.difficulty or 'standard'][tier])
    local rew         = isFinalTest and final.reward or
        (f and catalog.tierReward[f.rewardClass or 'standard'][tier])
    if not f or not scale then
        print(string.format('[HTBF] register: bad args (%s, %s)', tostring(fightKey), tostring(tier)))
        return nil
    end

    local battlefieldId = isFinalTest and final.battlefieldId or (f.baseBattlefieldId + (tier - 1))
    local menuIndex      = isFinalTest and final.index or (f.baseIndex + (tier - 1))

    local content = Battlefield:new({
        zoneId           = f.zone,
        battlefieldId    = battlefieldId,
        index            = menuIndex,
        entryNpc         = f.entryNpc,
        entryNpcs        = f.entryNpcs,
        exitNpc          = f.exitNpc,
        exitNpcs         = f.exitNpcs,
        allowedAreas     = f.allowedAreas,
        maxPlayers       = f.maxPlayers or 6,
        timeLimit        = f.timeLimit or utils.minutes(30),
        canLoseExp       = false,
        requiredKeyItems = { f.gem },   -- consumed on entry (no keep); HTBF is gem-gated
        -- Battlefield:onEntryEventUpdate enforces and consumes this for every
        -- actual entrant. The engine's requiredKeyItems consumption only covers
        -- the registrant.
        partyKeyItem     = f.gem,
    })
    content.customEntryFight = fightKey
    content.customEntryLabel = isFinalTest and 'Final Proving' or
        string.format('Tier %s', scale.name)
    content.customEntryOrder = isFinalTest and 4 or tier

    -- ACCESS GATE (see top): only a master of the entering job who holds every
    -- NM affinity may enter. checkRequirements calls entryRequirement LAST, so
    -- overriding it hides the fight from the burning-circle menu for anyone who
    -- falls short; printEntranceLegend prints the specific reason. Parens force
    -- the single bool return (the missing-list is dropped).
    function content:entryRequirement(player, npc, isRegistrant, trade)
        local canEnter = htbf.accessCheck(player)
        if not canEnter then
            return false
        end

        if isFinalTest then
            return finalTestReady(player)
        end

        -- Real Tier III rows stay hidden until Final Proving is complete.
        -- HTBF_Cleared_T3 is accepted as a legacy unlock so veterans who had
        -- already cleared a T3 before this gate was introduced are not relocked.
        if tier == 3 then
            return tier3Unlocked(player)
        end

        return true
    end

    -- Groups. Simple single-boss fights name the boss (f.mobs). Complex fights
    -- (multi-group, per-arena mobIds, skillchain AI, phase sections) instead
    -- REUSE the base battlefield's full definition via f.reuseBaseId (the base's
    -- xi.battlefield.id) -- we copy its groups + tick/section logic so the fight
    -- runs identically; we only re-gate it (gem) + scale it. The base script
    -- loads alphabetically before <key>_ht*.lua, so it is registered by now.
    local baseSetup = nil
    if f.groupsForTier then
        content.groups = f.groupsForTier(tier)
    elseif f.reuseBaseId then
        local base = xi.battlefield.contents[f.reuseBaseId]
        if base then
            content.groups = base.groups
            -- Carry the base fight's custom hooks so multi-phase / skillchain-AI /
            -- event-driven fights run identically. We keep our OWN onEventFinishWin
            -- (the reward) and chain setupBattlefield (below) for the tier scaling.
            for _, hook in ipairs({
                -- Retail exit/loss handlers frequently calculate from their
                -- retail battlefield IDs or mission variables. HTBF keeps the
                -- stock exit path instead of inheriting those closures.
                'onBattlefieldTick', 'sections', 'onEventUpdate', 'onBattlefieldRegister', 'paths',
                'onBattlefieldEnter',
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

    -- Per-instance tier scaling of the reused base boss(es). The local-var latch
    -- makes this safe to call again after event-driven phase spawns.
    local function applyTierScale(mob)
        if mob:getLocalVar('HTBFScaled') == 1 then
            return
        end

        if scale.lvl and scale.lvl > 1.0 then
            mob:setMobLevel(math.min(math.floor(mob:getMainLvl() * scale.lvl), 150))
        end
        if (scale.hp and scale.hp > 1.0) or (scale.minHp and scale.minHp > 0) then
            local hp = math.floor(mob:getMaxHP() * (scale.hp or 1.0))
            hp = math.max(hp, scale.minHp or 0)
            mob:setMaxHP(hp)
            mob:setHP(hp)
        end
        if scale.att  and scale.att  > 0 then mob:addMod(xi.mod.ATT,  scale.att)  end
        if scale.def  and scale.def  > 0 then mob:addMod(xi.mod.DEF,  scale.def)  end
        if scale.macc and scale.macc > 0 then mob:addMod(xi.mod.MACC, scale.macc) end
        if scale.meva and scale.meva > 0 then mob:addMod(xi.mod.MEVA, scale.meva) end
        if scale.eva  and scale.eva  > 0 then mob:addMod(xi.mod.EVA,  scale.eva)  end
        mob:setLocalVar('HTBFScaled', 1)
    end

    local function scaleBattlefieldMobs(battlefield)
        for _, mob in ipairs(battlefield:getMobs(true, true)) do
            pcall(function() applyTierScale(mob) end)
        end
    end

    function content:setupBattlefield(battlefield)
        -- Tag as an HTBF battlefield so the trust-count patch above lets players
        -- summon Trusts here (the engine's default cap would reject them).
        battlefield:setLocalVar('HTBF', 1)
        battlefield:setLocalVar('HTBFTier', tier)
        -- Run the base fight's own setup first (spawns/positions/etc.), then scale.
        if baseSetup then pcall(function() baseSetup(self, battlefield) end) end
        scaleBattlefieldMobs(battlefield)
    end

    -- Shadow Lord, Dawn, and Celestial Nexus spawn later phases from this event.
    -- Scale those new mobs immediately; the latch leaves existing phases alone.
    local baseEventFinishBattlefield = rawget(content, 'onEventFinishBattlefield')
    if baseEventFinishBattlefield then
        function content:onEventFinishBattlefield(player, csid, option, npc)
            baseEventFinishBattlefield(self, player, csid, option, npc)
            local battlefield = player:getBattlefield()
            if battlefield then
                scaleBattlefieldMobs(battlefield)
            end
        end
    end

    -- Reward on win: gil + Hunt Marks per tier (catalog.tierReward). Hunt Marks
    -- are the relaunch's HL_Points currency -- the very same marks the Hunting
    -- League pays -- so HTBF clears feed the live progression economy and the
    -- "Marks Earned (Lifetime)" leaderboard. The real retail per-fight item LOOT
    -- still goes in catalog.fights[key].loot[tier] (armoury-crate) as it is
    -- sourced from bg-wiki; this is the guaranteed completion reward on top.
    local function grantWinRewards(player)
        if not rew then return end
        -- Idempotency latch. On 2026-07-13 the Ark Angel HM T3 clear paid the
        -- reward FOUR times to the same player (400k gil * 4, 600 marks * 4,
        -- Copy of Rem's Tale ch6 * 4). Root cause is engine-side: the LSB win
        -- path fires per player via CBattlefield::Cleanup -> OnBattlefieldLeave
        -- -> onBattlefieldWin -> startEvent(32001) -> here, and something in
        -- that chain re-invokes it per-player when it shouldn't. Latch on a
        -- battlefield-instance-scoped var (localVars die with the instance,
        -- so a legit next run isn't affected) so a replay is a hard no-op --
        -- covers every current caller AND anything the engine gains later.
        local bf = player:getBattlefield()
        if bf then
            local latch = 'htbfPaid_' .. player:getID()
            if bf:getLocalVar(latch) == 1 then
                return
            end
            bf:setLocalVar(latch, 1)
        end
        local firstClearCv = 'HTBF_FC_' .. battlefieldId
        local firstClear   = (player:getCharVar(firstClearCv) or 0) == 0
        local multiplier   = firstClear and catalog.firstClearMultiplier or 1
        local gilReward    = (rew.gil or 0) * multiplier
        local markReward   = (rew.marks or 0) * multiplier

        if gilReward > 0 then
            pcall(function() player:addGil(gilReward) end)
        end
        if markReward > 0 then
            pcall(function()
                player:setCharVar('HL_Points',
                    (player:getCharVar('HL_Points') or 0) + markReward)
                player:setCharVar('HL_Points_Lifetime',
                    (player:getCharVar('HL_Points_Lifetime') or 0) + markReward)
            end)
        end
        if firstClear then
            player:setCharVar(firstClearCv, 1)
        end
        catalog.progress.recordClear(player, tier, isFinalTest)
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
            if isFinalTest then
                player:printToPlayer(
                    'Final Proving complete! All Tier III HTBFs are now unlocked, and your Ambuscade T3 requirement is satisfied.',
                    xi.msg.channel.SYSTEM_3)
            end
            player:printToPlayer(string.format(
                    'High-Tier Battlefield cleared! Reward: %d gil and %d Hunt Marks%s%s.',
                    gilReward, markReward,
                    firstClear and ' (first clear x2)' or '',
                    looted > 0 and (' + ' .. looted .. ' item(s)') or ''),
                xi.msg.channel.SYSTEM_3)
        end)
    end

    -- Custom HTBF battlefield IDs have no client win-cutscene entry. Sending
    -- event 32001 can therefore leave the player frozen after a clear. Award
    -- first, then leave the instance and return to the hub after a short win
    -- window instead of starting the unavailable client event.
    function content:onBattlefieldWin(player, battlefield)
        grantWinRewards(player)
        player:timer(2500, function(p)
            if p:getBattlefield() then
                p:leaveBattlefield(1)
            end
            p:timer(100, function(q)
                q:setPos(
                    571.5259, -3.3592, 508.8601, 65,
                    xi.zone.ABDHALJS_ISLE_PURGONORGO)
            end)
        end)
    end

    -- Defensive fallback for an engine path that still reaches the standard
    -- finish callback. The battlefield-scoped latch in grantWinRewards keeps
    -- a reward from being paid twice.
    function content:onEventFinishWin(player, csid, option, npc)
        grantWinRewards(player)
    end

    -- Armoury-crate loot. Priority: a fight's per-tier override (f.loot[tier]),
    -- then its flat retail pool (catalog.fightLoot[fightKey], same pool across
    -- tiers -- retail loot is per-fight, the tiers differ in difficulty + marks),
    -- then the modest tier-scaled default so every fight always drops a crate.
    local loot
    if isFinalTest then
        loot = catalog.tierLoot[3]
    else
        loot = (f.loot and f.loot[tier])
            or (catalog.fightLoot and catalog.fightLoot[fightKey])
            or catalog.tierLoot[tier]
    end
    if loot then
        content.loot = loot
    end

    -- Client-side arena warp fix (2026-07-13). The base battlefield's DAT knows
    -- arena coords keyed on battlefieldId, so entering a base fight teleports
    -- the client into the arena. Custom HTBF battlefieldIds (4000+) are NOT in
    -- the DAT, so the client receives no warp packet and the player is left at
    -- the entry NPC (shimmering circle) with the countdown ticking -- the exact
    -- symptom reported for Ark Angels + Divine Might. When the fight defines
    -- f.entryPosByArea, do the warp ourselves right after the player is inserted.
    -- Chain any base onBattlefieldEnter so multi-phase fights keep their setup.
    if f.entryPosByArea then
        local function warpToStagingPosition(player, battlefield)
            if not battlefield then
                return
            end

            local area = battlefield:getArea()
            local entryPos = f.entryPosByArea[area]
            if entryPos then
                local ok, err = pcall(function()
                    player:setPos(entryPos[1], entryPos[2], entryPos[3], entryPos[4] or 0)
                end)
                if not ok then
                    print(string.format('[HTBF] %s tier %d: staging warp failed for area %d (%s)',
                        tostring(fightKey), tier, area, tostring(err)))
                end
            else
                print(string.format('[HTBF] %s tier %d: no staging position for area %d',
                    tostring(fightKey), tier, area))
            end
        end

        local baseEnter = rawget(content, 'onBattlefieldEnter')
        function content:onBattlefieldEnter(player, battlefield)
            Battlefield.onBattlefieldEnter(self, player, battlefield)
            if baseEnter then pcall(function() baseEnter(self, player, battlefield) end) end
            warpToStagingPosition(player, battlefield)
        end

        -- Reassert after either the retail event finishes or direct named-menu
        -- entry completes. Custom battlefield IDs have no client DAT position.
        function content:onEntryComplete(player, npc)
            Battlefield.onEntryComplete(self, player, npc)
            warpToStagingPosition(player, player:getBattlefield())
        end
    end

    return content:register()
end

function htbf.registerFinalTest()
    return htbf.register(catalog.finalTest.fightKey, 3, 'finalTest')
end

return htbf
