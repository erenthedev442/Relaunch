-----------------------------------
-- player_trusts.lua
-- "Player Trust" social mechanic - partner up with someone in-game
-- and you both unlock each other as a personal Trust.
--
-- Mechanic overview:
--   1. While two characters are in the same party AND the same zone,
--      a friendship counter accumulates a minute every minute.
--   2. When the counter hits catalog.unlockMinutes (default 30), BOTH
--      players unlock each other. Persisted in char_vars so it survives
--      logout.
--   3. Each player can talk to the Companion Master NPC at GM Home to
--      list unlocked friends, summon one (grants a stat buff named after
--      the friend), or upgrade a friend's Trust tier (Bronze -> Silver
--      -> Gold -> Platinum -> Mythic; each tier costs gil and boosts
--      the buff).
--
-- CharVar schema (per character):
--   PT_Mins_<otherCharId>    - minutes-partied counter for that pair
--   PT_Unlocked_<otherCharId> - 1 once the threshold has fired
--   PT_Tier_<otherCharId>    - current upgrade tier for that friend (1-5)
--   PT_Name_<otherCharId>    - captured friend name at unlock time, so
--                              the menu can show it even if the friend
--                              is offline / renamed
--   Trusts_Unlocked          - count of unlocked friends (leaderboard)
--
-- v1 explicitly does NOT spawn a follower mob. The "summon" is a buff.
-- v2 work is left for later - see the docs page for the planned arc.
-----------------------------------
require('modules/module_utils')
local catalog = require('modules/custom/lua/player_trusts_catalog')
require(string.format('scripts/zones/%s/Zone', catalog.npcPos.zone))

local m = Module:new('player_trusts')

-- Runtime cache: charid -> display name. Populated whenever we see a
-- player (zone-in, unlock, NPC visit). Lets the Companion Master menu
-- display friend names even when those friends are offline this session.
-- char_vars stores integers only, so we can't persist names there;
-- instead we cache on-demand and fall back to a "Friend #ID" label.
local nameCache = {}

-- Active buff bookkeeping. Tracks the per-player live summon so we can
-- cleanly remove the prior set of mods when a new summon happens (or
-- when the timer expires). Key: charid -> { mods = {{mod, value}, ...} }.
local activeBuffs = {}

-----------------------------------
-- CharVar helpers - every per-friend key embeds the OTHER character's
-- charid, so a single char_vars row covers each direction of the pair.
-----------------------------------
local function cvMins(otherId)     return 'PT_Mins_'     .. tostring(otherId) end
local function cvUnlocked(otherId) return 'PT_Unlocked_' .. tostring(otherId) end
local function cvTier(otherId)     return 'PT_Tier_'     .. tostring(otherId) end
local function cvRace(otherId)     return 'PT_Race_'     .. tostring(otherId) end
local function cvFace(otherId)     return 'PT_Face_'     .. tostring(otherId) end

-- Slot assignments - CharVar per slot holding the charid of the friend
-- assigned to that slot (or 0 for empty). Five slots total; each
-- corresponds to one of the hijacked Trust spells in catalog.trustSlots.
-- The override for spell N reads PT_Slot_N to find whose Trust to summon.
local function cvSlot(slotNum) return 'PT_Slot_' .. tostring(slotNum) end

-- Reverse lookup: given a friend's charid, return the slot they're in
-- (1..maxSlots) or nil if not assigned. Lets us show "Bdr (Slot 1)" in
-- the main menu and warn on swap when assigning a friend who's already
-- in a different slot.
local function findFriendSlot(player, otherId)
    for i = 1, catalog.maxSlots do
        if player:getCharVar(cvSlot(i)) == otherId then
            return i
        end
    end
    return nil
end

-- Given a slot number, return the friend currently in it (charid) or 0.
local function getSlotFriend(player, slotNum)
    return player:getCharVar(cvSlot(slotNum)) or 0
end

local function getTier(player, otherId)
    local t = player:getCharVar(cvTier(otherId))
    if t < 1 then return 1 end
    if t > catalog.maxTier then return catalog.maxTier end
    return t
end

-- Iterate every char_var matching prefix and call cb(otherId, value).
-- Uses getCharVarsWithPrefix (registered globally on player entities).
local function forEachFriend(player, prefix, cb)
    local vars = player:getCharVarsWithPrefix(prefix)
    if not vars then return end
    for name, value in pairs(vars) do
        local idStr = name:sub(#prefix + 1)
        local id = tonumber(idStr)
        if id then cb(id, value) end
    end
end

-----------------------------------
-- Friendship tracking
-----------------------------------
-- Called once per tick interval (default 60s) per online player. Looks
-- at every party member in the same zone, bumps the per-pair minute
-- counter, and fires the unlock when threshold is hit.
local function tickFriendship(player)
    local party = player:getParty()
    if not party or #party < 2 then return end

    local meId   = player:getID()
    local meName = player:getName()
    local myZone = player:getZoneID()

    for _, other in ipairs(party) do
        if other and other:getID() ~= meId then
            -- Same-zone requirement keeps things honest - you have to
            -- actually be hanging out, not just on each other's friend
            -- list in different zones.
            if other:getZoneID() == myZone then
                local otherId   = other:getID()
                local otherName = other:getName()

                -- Cache both characters' names runtime-side so menus
                -- can display them this session. char_vars is int-only
                -- so we can't persist names there.
                nameCache[otherId] = otherName
                nameCache[meId]    = meName

                if player:getCharVar(cvUnlocked(otherId)) == 0 then
                    local mins = player:getCharVar(cvMins(otherId)) + 1
                    player:setCharVar(cvMins(otherId), mins)

                    if mins >= catalog.unlockMinutes then
                        -- Unlock both directions.
                        player:setCharVar(cvUnlocked(otherId), 1)
                        player:setCharVar(cvTier(otherId), 1)
                        -- Capture friend's race/face for the v2 Trust
                        -- spawn's setModelId lookup. Both characters are
                        -- online here so getRace/getFace are reliable.
                        player:setCharVar(cvRace(otherId), other:getRace())
                        player:setCharVar(cvFace(otherId), other:getFace())
                        player:setCharVar('Trusts_Unlocked',
                            (player:getCharVar('Trusts_Unlocked') or 0) + 1)
                        -- Grant ALL hijacked Trust spells so they can fill
                        -- the full 5-slot roster as they unlock more
                        -- friends. addSpell is idempotent - it silently
                        -- skips spells the player already knows.
                        for _, slotDef in ipairs(catalog.trustSlots) do
                            if not player:hasSpell(slotDef.spellId) then
                                player:addSpell(slotDef.spellId)
                            end
                        end

                        other:setCharVar(cvUnlocked(meId), 1)
                        other:setCharVar(cvTier(meId), 1)
                        other:setCharVar(cvRace(meId), player:getRace())
                        other:setCharVar(cvFace(meId), player:getFace())
                        other:setCharVar('Trusts_Unlocked',
                            (other:getCharVar('Trusts_Unlocked') or 0) + 1)
                        for _, slotDef in ipairs(catalog.trustSlots) do
                            if not other:hasSpell(slotDef.spellId) then
                                other:addSpell(slotDef.spellId)
                            end
                        end

                        player:printToPlayer(
                            string.format(
                                '[Companion Master] You have unlocked %s as a Trust, kupo! Visit the Companion Master at GM Home.',
                                otherName),
                            xi.msg.channel.SYSTEM_3)
                        other:printToPlayer(
                            string.format(
                                '[Companion Master] You have unlocked %s as a Trust, kupo! Visit the Companion Master at GM Home.',
                                meName),
                            xi.msg.channel.SYSTEM_3)
                    end
                end
            end
        end
    end
end

-- Re-arming timer kept per player; cancels naturally when they log out.
local function armNextTick(player)
    player:timer(catalog.tickIntervalSec * 1000, function(p)
        if p then
            tickFriendship(p)
            armNextTick(p)
        end
    end)
end

local function displayName(player, otherId)
    return nameCache[otherId] or string.format('Friend #%d', otherId)
end

-----------------------------------
-- Summon buff
-----------------------------------
-- The "summon" doesn't spawn a follower mob (v1 limitation). Instead
-- we apply raw stat mods for the buff duration and remove them on a
-- timer. No visible buff icon, but no status-effect-slot conflicts
-- either - the bonuses just appear in the player's stat sheet.
-- Re-summoning before expiry cleanly replaces the prior mod set.
local function removeActiveBuff(player)
    local id = player:getID()
    local active = activeBuffs[id]
    if not active then return end
    for _, modPair in ipairs(active.mods) do
        pcall(function() player:delMod(modPair[1], modPair[2]) end)
    end
    activeBuffs[id] = nil
end

local function summonTrust(player, otherId)
    if player:getCharVar(cvUnlocked(otherId)) == 0 then
        player:printToPlayer('That friend is not unlocked, kupo!', xi.msg.channel.SYSTEM_3)
        return
    end

    local tier    = getTier(player, otherId)
    local tierDef = catalog.tiers[tier]
    local name    = displayName(player, otherId)
    local durationSec = tierDef.buffDurationMin * 60

    -- Stat mods this summon contributes. Symmetric across all 7 main
    -- stats; HP and MP bonuses are also flat. Bigger tiers = bigger mods.
    local mods = {
        { xi.mod.STR, tierDef.statBonus },
        { xi.mod.DEX, tierDef.statBonus },
        { xi.mod.VIT, tierDef.statBonus },
        { xi.mod.AGI, tierDef.statBonus },
        { xi.mod.INT, tierDef.statBonus },
        { xi.mod.MND, tierDef.statBonus },
        { xi.mod.CHR, tierDef.statBonus },
        { xi.mod.HP,  tierDef.hpBonus  },
        { xi.mod.MP,  tierDef.mpBonus  },
    }

    -- Replace any prior summon-buff cleanly.
    removeActiveBuff(player)

    for _, modPair in ipairs(mods) do
        player:addMod(modPair[1], modPair[2])
    end
    activeBuffs[player:getID()] = { mods = mods, friendName = name, tier = tier }

    player:printToPlayer(
        string.format(
            '[Companion Master] %s\'s %s Trust answers! All stats +%d, HP +%d, MP +%d for %d minutes, kupo!',
            name, tierDef.label,
            tierDef.statBonus, tierDef.hpBonus, tierDef.mpBonus,
            tierDef.buffDurationMin),
        xi.msg.channel.SYSTEM_3)

    -- Schedule removal. If the player logs out before this fires, the
    -- mods come off automatically with the session anyway - addMod is
    -- in-memory only.
    player:timer(durationSec * 1000, function(p)
        if not p then return end
        local stillActive = activeBuffs[p:getID()]
        -- Only remove if THIS summon is still the active one (a later
        -- re-summon may have already taken over).
        if stillActive and stillActive.friendName == name and stillActive.tier == tier then
            removeActiveBuff(p)
            p:printToPlayer(
                string.format('[Companion Master] %s\'s Trust fades, kupo.', name),
                xi.msg.channel.SYSTEM_3)
        end
    end)
end

-----------------------------------
-- Tier upgrade
-----------------------------------
local function upgradeTrust(player, otherId)
    local currentTier = getTier(player, otherId)
    if currentTier >= catalog.maxTier then
        player:printToPlayer('That Trust is already at the maximum tier, kupo!', xi.msg.channel.SYSTEM_3)
        return
    end

    local nextTierDef = catalog.tiers[currentTier + 1]
    local cost        = nextTierDef.gilCost
    local name        = displayName(player, otherId)

    if player:getGil() < cost then
        player:printToPlayer(
            string.format(
                '[Companion Master] You need %d gil to upgrade %s to %s, kupo!',
                cost, name, nextTierDef.label),
            xi.msg.channel.SYSTEM_3)
        return
    end

    player:delGil(cost)
    player:setCharVar(cvTier(otherId), currentTier + 1)
    player:printToPlayer(
        string.format(
            '[Companion Master] %s\'s Trust is now %s tier! (-%d gil)',
            name, nextTierDef.label, cost),
        xi.msg.channel.SYSTEM_3)
end

-----------------------------------
-- NPC menus
-----------------------------------
local menu = { title = 'Companion Master', options = {} }

local function delaySendMenu(player)
    -- Snapshot before the deferred send: `menu` is a shared scratch
    -- table, and another player's interaction inside the 50ms window
    -- would otherwise swap its contents mid-flight.
    local snapshot = { title = menu.title, options = menu.options }
    player:timer(15, function(p) p:customMenu(snapshot) end)
end

-- Convert internal spell name like "kuyin_hathdenna" to a readable
-- title-case label "Kuyin Hathdenna" for display in menus.
function _displayTrustName(internalName)
    return (internalName:gsub('_', ' '):gsub('(%a)([%w]*)', function(first, rest)
        return first:upper() .. rest
    end))
end

local showMainMenu
local buildFriendMenu

-- Friends per page in the Companion Master roster. customMenu caps the
-- packet at 150 bytes (title + every option label + a NUL per row).
--
-- Per-friend label format:  "<name> [<tier>]<slotTag>"
--   name      up to 15 chars (FFXI char limit)
--   tier      up to 7 chars ("Mythic")
--   slotTag   up to 5 chars (" (S5)")
--   brackets/spaces            4 chars
--                              ------
--   worst case label           31 chars + NUL = 32 bytes
--
-- Title + Close + 2 nav rows = roughly 65 bytes of fixed overhead.
-- That leaves ~85 bytes for friend rows = ~2 worst-case 15-char-name
-- friends per page, ~4 with typical (~8-char) names.
--
-- 3 keeps the common case (<=3 friends) on a single page AND survives
-- the worst case (3 x 32 = 96, plus ~50 fixed = 146 bytes). Tighter
-- than ideal, with the upside that very small rosters still feel
-- single-page.
local FRIEND_PAGE_SIZE = 3

showMainMenu = function(player, page)
    page = page or 1

    -- Collect unlocked friend ids (value=1 in PT_Unlocked_*).
    local friends = {}
    forEachFriend(player, 'PT_Unlocked_', function(id, value)
        if value == 1 then
            table.insert(friends, id)
        end
    end)
    table.sort(friends)

    local options = {}
    if #friends == 0 then
        table.insert(options, {
            'No friends unlocked yet.',
            function(p)
                p:printToPlayer('Party up with someone for 30 minutes to unlock them, kupo!',
                    xi.msg.channel.SYSTEM_3)
            end,
        })
        menu.title   = 'Companion Master'
        menu.options = options
        delaySendMenu(player)
        return
    end

    -- Pagination math. Clamp the requested page into range so out-of-bounds
    -- calls (a friend unassigned between renders, etc.) snap to a valid page.
    local nPages = math.max(1, math.ceil(#friends / FRIEND_PAGE_SIZE))
    page = math.max(1, math.min(page, nPages))
    local startIdx = (page - 1) * FRIEND_PAGE_SIZE + 1
    local endIdx   = math.min(startIdx + FRIEND_PAGE_SIZE - 1, #friends)

    -- One menu entry per unlocked friend on this page. Label shows their
    -- tier AND which slot they're currently assigned to (if any) so the
    -- player can see at a glance who's "live" without drilling in.
    for i = startIdx, endIdx do
        local id        = friends[i]
        local tier      = getTier(player, id)
        local tierDef   = catalog.tiers[tier]
        local name      = displayName(player, id)
        local slotNum   = findFriendSlot(player, id)
        local slotTag   = slotNum and string.format(' (S%d)', slotNum) or ''
        local capturedId = id
        table.insert(options, {
            string.format('%s [%s]%s', name, tierDef.label, slotTag),
            function(p) buildFriendMenu(p, capturedId) end,
        })
    end

    -- Nav rows - only shown when there's somewhere to go. Each one costs
    -- ~10 bytes of label budget; we account for both in FRIEND_PAGE_SIZE.
    if page > 1 then
        local prevPage = page - 1
        table.insert(options, {
            string.format('<< Prev (%d/%d)', prevPage, nPages),
            function(p) showMainMenu(p, prevPage) end,
        })
    end
    if page < nPages then
        local nextPage = page + 1
        table.insert(options, {
            string.format('Next >> (%d/%d)', nextPage, nPages),
            function(p) showMainMenu(p, nextPage) end,
        })
    end

    table.insert(options, {
        'Close',
        function(p) p:printToPlayer('Friendship is its own reward, kupo!', xi.msg.channel.SYSTEM_3) end,
    })

    -- Title shows page indicator only when paginated, keeping the
    -- single-page case unchanged for players with <=5 friends.
    if nPages > 1 then
        menu.title = string.format('Companion Master (%d/%d)', page, nPages)
    else
        menu.title = 'Companion Master'
    end
    menu.options = options
    delaySendMenu(player)
end

-- Forward declaration so buildFriendMenu and buildSlotPickerMenu can
-- reference each other.
local buildSlotPickerMenu

buildFriendMenu = function(player, otherId)
    local tier         = getTier(player, otherId)
    local tierDef      = catalog.tiers[tier]
    local name         = displayName(player, otherId)
    local nextTier     = (tier < catalog.maxTier) and catalog.tiers[tier + 1] or nil
    local currentSlot  = findFriendSlot(player, otherId)

    local slotLabel
    if currentSlot then
        local slotDef = catalog.trustSlots[currentSlot]
        slotLabel = string.format('Slot %d (cast Trust: %s)',
            currentSlot, _displayTrustName(slotDef.name))
    else
        slotLabel = 'Unassigned - pick a slot'
    end

    local options = {
        {
            slotLabel,
            function(p) buildSlotPickerMenu(p, otherId) end,
        },
        -- v1 buff kept as the lightweight alternative.
        {
            string.format('Quick Buff (%dmin stat boost)', tierDef.buffDurationMin),
            function(p)
                summonTrust(p, otherId)
            end,
        },
    }

    if nextTier then
        table.insert(options, {
            string.format('Upgrade to %s (%d gil)', nextTier.label, nextTier.gilCost),
            function(p)
                upgradeTrust(p, otherId)
                buildFriendMenu(p, otherId)
            end,
        })
    else
        table.insert(options, {
            'Already at Mythic (max)',
            function(p) buildFriendMenu(p, otherId) end,
        })
    end

    table.insert(options, {
        '<< Back',
        function(p) showMainMenu(p) end,
    })

    menu.title   = string.format('%s [%s]', name, tierDef.label)
    menu.options = options
    delaySendMenu(player)
end

-- Slot picker submenu. Shown when the player picks "Slot N..." in the
-- friend submenu. Lists all 5 slots with their current occupant (if
-- any), letting the player assign the friend to any slot, swap in (if
-- the slot is occupied by someone else), or unassign the friend entirely.
buildSlotPickerMenu = function(player, otherId)
    local name        = displayName(player, otherId)
    local currentSlot = findFriendSlot(player, otherId)

    local options = {}
    for i = 1, catalog.maxSlots do
        local occupantId = getSlotFriend(player, i)
        local slotDef    = catalog.trustSlots[i]
        local label
        if occupantId == otherId then
            label = string.format('Slot %d: %s (current)', i, name)
        elseif occupantId == 0 then
            label = string.format('Slot %d: (empty)', i)
        else
            local occupantName = displayName(player, occupantId)
            label = string.format('Slot %d: %s -> swap', i, occupantName)
        end
        local capturedSlot = i
        table.insert(options, {
            label,
            function(p)
                -- If our friend is already in another slot, clear that
                -- one (move semantics, not duplicate). Then either
                -- evict whoever's in the target slot, or just take it.
                local previous = findFriendSlot(p, otherId)
                if previous and previous ~= capturedSlot then
                    p:setCharVar(cvSlot(previous), 0)
                end
                p:setCharVar(cvSlot(capturedSlot), otherId)
                p:printToPlayer(
                    string.format(
                        '[Companion Master] %s assigned to Slot %d. Cast Trust: %s to summon, kupo!',
                        name, capturedSlot,
                        _displayTrustName(catalog.trustSlots[capturedSlot].name)),
                    xi.msg.channel.SYSTEM_3)
                buildFriendMenu(p, otherId)
            end,
        })
    end

    if currentSlot then
        table.insert(options, {
            string.format('Remove from Slot %d', currentSlot),
            function(p)
                p:setCharVar(cvSlot(currentSlot), 0)
                p:printToPlayer(
                    string.format('[Companion Master] %s removed from slot %d, kupo!', name, currentSlot),
                    xi.msg.channel.SYSTEM_3)
                buildFriendMenu(p, otherId)
            end,
        })
    end

    table.insert(options, {
        '<< Back',
        function(p) buildFriendMenu(p, otherId) end,
    })

    menu.title   = string.format('Assign %s', name)
    menu.options = options
    delaySendMenu(player)
end

-----------------------------------
-- NPC + per-zone hooks
-----------------------------------
m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', catalog.npcPos.zone), function(zone)
    super(zone)

    local CompanionMaster = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Companion_Master',
        packetName = string.format('%sCompanion Master', xi.icon.STAR_LARGE),
        look       = 2308,                      -- standard Moogle
        x          = catalog.npcPos.x,
        y          = catalog.npcPos.y,
        z          = catalog.npcPos.z,
        rotation   = catalog.npcPos.rotation,
        widescan   = 1,

        onTrigger = function(player, npc)
            -- Refresh this player's name in the runtime cache so they
            -- show up correctly in others' menus this session.
            nameCache[player:getID()] = player:getName()
            showMainMenu(player)
        end,
    })
    utils.unused(CompanionMaster)
end)

-- Friendship tick: arm a recurring timer when any player zones into any
-- zone. The tick handler bails harmlessly when the player isn't in a
-- party or party members aren't in zone, so it's safe to run everywhere.
-- We hook a small, popular set of zones rather than every zone to avoid
-- needless work in places nobody parties.
local TICK_ZONES = { 'GM_Home', 'Reisenjima_Henge' }
for _, zoneName in ipairs(TICK_ZONES) do
    require(string.format('scripts/zones/%s/Zone', zoneName))
    m:addOverride(string.format('xi.zones.%s.Zone.onZoneIn', zoneName), function(player, prevZone)
        local result = super(player, prevZone)
        -- Cache our own name so others see us correctly even before we
        -- get unlocked by them.
        nameCache[player:getID()] = player:getName()
        -- Stagger the first tick by a couple seconds so onZoneIn returns
        -- promptly and the player isn't ticking immediately on arrival.
        player:timer(2000, function(p) armNextTick(p) end)
        return result
    end)
end

-----------------------------------
-- Hijacked Trust spell - the "real follower" payload (v2)
--
-- We override the three event hooks of an obscure Trust spell (default
-- kuyin_hathdenna). When a player casts it, instead of summoning the
-- canonical Walk of Echoes Trust, we spawn a Trust that wears the active
-- friend's race/face, displays the friend's name above its head, and
-- has stats scaled by the friend's tier.
--
-- This keeps the entire feature inside modules/custom/ - no upstream
-- file is touched. If LSB ever rebalances the original spell, we get
-- whatever they ship plus our override on top.
-----------------------------------
require('scripts/globals/trust')

local function applyTrustMods(trust, tier)
    local tierDef   = catalog.tiers[tier] or catalog.tiers[1]
    local mult      = tierDef.trustMult or 1.0
    for _, modPair in ipairs(catalog.trustBaseMods) do
        local modId    = modPair[1]
        local baseVal  = modPair[2]
        local scaled   = math.floor(baseVal * mult + 0.5)
        trust:addMod(modId, scaled)
    end
end

-- Register the three event handlers for ALL five hijacked Trust spells.
-- Each spell maps to one slot (by its position in catalog.trustSlots).
-- When a player casts spell X, the override reads PT_Slot_<N> for the
-- slot that maps to X and looks up the assigned friend.
for slotIdx, slotDef in ipairs(catalog.trustSlots) do
    -- Capture loop variables in upvalues so each closure binds correctly.
    local capturedSlot = slotIdx
    local capturedName = slotDef.name

    m:addOverride(
        string.format('xi.actions.spells.trust.%s.onSpellCast', capturedName),
        function(caster, target, spell)
            local friendId = caster:getCharVar(cvSlot(capturedSlot))
            local trust    = caster:spawnTrust(spell:getID())

            -- Records of Eminence: Call Forth an Alter Ego - preserve.
            if caster:getEminenceProgress(932) then
                xi.roe.onRecordTrigger(caster, 932)
            end

            if friendId and friendId > 0 then
                local friendName = nameCache[friendId] or string.format('Friend #%d', friendId)
                local race       = caster:getCharVar(cvRace(friendId))
                local tier       = getTier(caster, friendId)

                trust:renameEntity(friendName)
                trust:setModelId(catalog.raceModels[race] or catalog.defaultModelId)
                applyTrustMods(trust, tier)

                trust:setLocalVar('PT_MASTER_ID', caster:getID())
                trust:setLocalVar('PT_FRIEND_ID', friendId)
            end

            return 0
        end)

    m:addOverride(
        string.format('xi.actions.spells.trust.%s.onMobSpawn', capturedName),
        function(mob)
            super(mob)

            local friendId = mob:getLocalVar('PT_FRIEND_ID')
            if friendId == 0 then return end
            local friendName = nameCache[friendId] or string.format('Friend #%d', friendId)
            local master = mob:getMaster()
            if not master then return end

            for _, member in ipairs(master:getParty()) do
                if member:isPC() then
                    member:printToPlayer(
                        string.format('%s answers the call!', friendName),
                        4,                  -- MESSAGE_PARTY
                        friendName)
                end
            end
        end)

    m:addOverride(
        string.format('xi.actions.spells.trust.%s.onMobDespawn', capturedName),
        function(mob)
            super(mob)

            local friendId = mob:getLocalVar('PT_FRIEND_ID')
            if friendId == 0 then return end
            local friendName = nameCache[friendId] or string.format('Friend #%d', friendId)
            local masterId   = mob:getLocalVar('PT_MASTER_ID')
            local master     = GetPlayerByID(masterId)
            if not master then return end

            for _, member in ipairs(master:getParty()) do
                if member:isPC() then
                    member:printToPlayer(
                        string.format('%s heads off - until next time!', friendName),
                        4,
                        friendName)
                end
            end
        end)
end

return m
