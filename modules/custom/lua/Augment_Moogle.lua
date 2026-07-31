-----------------------------------
-- Augment_Moogle.lua
-- Trade 1 equipment piece + 1-5 catalyst items.
-- Each catalyst maps 1:1 to a specific augmentId via augment_catalog.lua.
-- Costs 10,000 gil per successful augmentation (flat, regardless of how many
-- augments are applied in the trade).
--
-- See modules/custom/lua/augment_catalog.lua for the full catalyst -> augment
-- mapping (2047 entries, one per augmentId in sql/augments.sql).
--
-- CRYSTALIZED AUGMENTS (2026-07-06 -- "lock your best rolls"):
--   Re-augmenting an item now REBUILDS only its non-crystalized slots -- any
--   slot that has crystalized is preserved verbatim and its catalyst is not
--   required again. When a freshly rolled slot lands on its MAXIMUM value
--   (a perfect roll -- crit or lucky), it gets a second roll, by Augment Sage
--   rank (Augment_Mastery), to CRYSTALIZE. A crystalized slot can no longer be
--   changed or removed by normal augmenting -- only a full SCOUR (trade the
--   gear alone, or the configured scour item) strips everything and starts anew.
--
--   Crystalize chance by Augment Sage rank (Augment_Mastery 0..5):
--     0% / 5% / 15% / 30% / 45% / 50%
--
--   Storage: the per-slot lock bitmask lives ON THE ITEM, in exdata byte 13
--   (the second signature byte). Byte 12 (the first signature byte) is kept
--   zero, so the item's signature decodes to an empty string and renders blank
--   on the client (DecodeStringSignature terminates on the leading null char).
--   The full 24-byte `extra` blob round-trips through char_inventory, so the
--   mask survives relog/zone/restart for normal gear. Items with the
--   Inscribable flag (0x20) get their signature bytes re-encoded from the
--   `signature` DB column on load (charutils.cpp LoadInventory), which would
--   wipe the mask -- so crystalize is DISABLED on Inscribable gear and the
--   player is told.
--
-- Zone: GM Home (zone 210)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')
local catalog  = require('modules/custom/lua/augment_catalog')
local sage     = require('modules/custom/lua/augment_sage_catalog')
local affinity = require('modules/custom/lua/augment_affinity_catalog')
local waveProgress = require('modules/custom/lua/game_master_progress')
local wh       = require('modules/custom/lua/weekly_hunts')
local bank     = require('modules/custom/lua/augment_catalyst_bank')
local itemNames = require('modules/custom/lua/augment_item_names')
-----------------------------------
local m = Module:new('augment_moogle')

local MAX_CATALYST_COUNT = 5       -- max catalyst items per trade = the engine's 5 augment slots (each catalyst writes one line; mix types or stack one)
local GIL_COST           = 10000   -- flat per trade
local SCOUR_GIL_COST     = 25000   -- flat to scour (strip ALL augments incl. crystalized)
local CRIT_TOKEN_ID      = 15194   -- Maat's Cap: guarantees a crit when held (consumed on success). Retail Rare/EX, so it renders on the client (the old custom 29000 had no client DAT).
local CRIT_TOKEN_LEGACY  = 29000   -- old custom 'Maat's Blessing'; still honored so pre-swap drops aren't stranded
local LAST_RECIPE_VAR    = 'Augment_LastRecipe'   -- persisted catalyst recipe for "repeat last catalyst set"

-----------------------------------
-- CRYSTALIZED AUGMENTS config
-----------------------------------
-- Lock bitmask storage: exdata byte 13 (signature[1]). Byte 12 stays 0 so the
-- signature decodes blank. Bit (slot-1) set => that FINAL augment slot is
-- crystalized (locked).
local LOCK_MASK_BYTE = 13
local SIG_HEAD_BYTE  = 12          -- must stay 0 for a blank-decoding signature
local INSCRIBABLE    = 0x20        -- ItemFlag::INSCRIBABLE (scripts/enum/item_flag.lua)

-- Crystalize chance indexed by Augment Sage rank (Augment_Mastery, 0..5).
-- Mirrors the design post: T0 0% / T1 5% / T2 15% / T3 30% / T4 45% / T5 50%.
local CRYSTAL_CHANCE = { [0] = 0.00, [1] = 0.05, [2] = 0.15, [3] = 0.30, [4] = 0.45, [5] = 0.50 }

-- Optional dedicated scour item. When set to a real itemId, trading it with a
-- piece of gear strips ALL augments (including crystalized) and starts anew.
-- Leave nil to use only the always-available "trade the gear alone" scour path.
local SCOUR_ITEM_ID = nil

-- Augment formula recap (from src/map/items/item_equipment.cpp:479):
--   final_mod = (base + exdata) * (multiplier > 1 ? multiplier : 1)   -- positive base
--   final_mod = (base - exdata) * ...                                 -- negative base
-- For multiplier <= 1 (vast majority), passing exdata = |base| * (N-1)
-- multiplies the resulting stat by N. So 4 darkness spheres giving MP+97
-- as a 1-catalyst trade now give MP+388 with exdata = 97*3 = 291.
--
-- ROLL FORMULA (2026-06-30 TIER REVAMP -- rolled bands, content-gated):
--   tier   = augmentTier(player)        -- 1..5, gated by CUSTOM CONTENT (TIER_GATES)
--   slice  = TIER_SLICES[tier]          -- that tier's band of the 5-bit exdata space
--   floor  = slice.min + sageRank       -- Sage mastery rank (0-5) raises the floor
--   roll   = random(floor .. slice.max) -- rolled PER SLOT (each catalyst = own roll)
--   affinity match (Sage)               -- roll twice, keep the better
--   crit (sage.critChance by rank; Maat's Cap guarantees) -- slice.max: PERFECT roll
--   final/slot = (value + roll) * multiplier      (engine math unchanged)
-- Tier bands never overlap, and T5's ceiling (roll 31) == the old
-- rank5 x affinity x crit cap -- no power creep vs the previous system.
-- The crit is rolled once per trade and applies to all slots that trade
-- (one big "Critical augment!" message). Affinity is per-augment, since
-- each selection may have a different `cat`.

-----------------------------------
-- AUGMENT TIER (content progression). Your tier picks the roll band; EVERY
-- tier -- including T1 -- is a piece of custom content. LADDERED: tier =
-- highest N with every gate 1..N passed (so you can't skip ahead). A fresh
-- character is TIER 0: the Moogle refuses to augment until one job reaches 99.
-- The catalog's per-catalyst `tier` field is the minimum Augment Tier needed
-- to TRADE that catalyst.
-----------------------------------
local TIER_SLICES =
{
    { min =  0, max =  5 },   -- T1
    { min =  6, max = 11 },   -- T2
    { min = 12, max = 17 },   -- T3
    { min = 18, max = 24 },   -- T4
    { min = 25, max = 31 },   -- T5
}

-- Hunting League boss completion uses the permanent first-kill stamps written
-- by HuntingLeague.lua. Requiring every boss prevents marks earned elsewhere
-- (boards, events, or repeatedly farming one target) from skipping Hunt content.
local HL_TIER_NMS =
{
    [2] = { 11358, 11359, 11360 }, -- Roc, Bomb Queen, Aquarius
    [3] = { 11361, 11362, 11363 }, -- Serket, Vrtra, Simurgh
    [4] = { 11364, 11365, 11366 }, -- Nidhogg, King Behemoth, Kirin
}

local function clearedHuntTier(player, tier)
    for _, groupId in ipairs(HL_TIER_NMS[tier] or {}) do
        if (player:getCharVar('NMKilled_' .. groupId) or 0) < 1 then
            return false
        end
    end

    return true
end

local TIER_GATES =
{
    { tier = 1, unlock = 'reach level 99 on any job',
      check = function(p)
          for jobId = 1, 22 do
              if (p:getJobLevel(jobId) or 0) >= 99 then return true end
          end
          return false
      end },
    { tier = 2, unlock = 'defeat all 3 Rank 2 Hunt NMs + promote to Hunting League Rank 3',
      check = function(p)
          return (p:getCharVar('HL_Tier') or 1) >= 3
              and clearedHuntTier(p, 2)
      end },
    -- T3 is the first three Wave Master stages; later stages remain relevant
    -- through T4 and the weapon progression ladder.
    { tier = 3, unlock = 'defeat all 3 Rank 3 Hunt NMs + clear Voidspire floor 10 + Wave Master Easy/Normal/Hard',
      check = function(p)
          return clearedHuntTier(p, 3)
              and (p:getCharVar('Voidspire_Best_Floor') or 0) >= 10
              and waveProgress.hasThrough(p, 3)
      end },
    { tier = 4, unlock = 'defeat all 3 Rank 4 Hunt NMs + one full Dynamis - Divergence city + Wave Master Insane',
      check = function(p)
          -- DivergenceSlots is stamped only after the Disjoined capstone dies
          -- and the city instance completes; Mega-Boss credit alone is not enough.
          return clearedHuntTier(p, 4)
              and (p:getCharVar('DivergenceSlots') or 0) >= 1
              and waveProgress.hasThrough(p, 4)
      end },
    { tier = 5, unlock = "defeat Maat's Echo (Ru'Lude Gardens, !maat)",
      check = function(p) return (p:getCharVar('Maat_Kills') or 0) >= 1 end },
}

local function augmentTier(player)
    local tier = 0
    for _, g in ipairs(TIER_GATES) do
        if g.check(player) then
            tier = g.tier
        else
            break
        end
    end
    -- The 2026-07 Wave Master realignment added Insane to T4. Preserve the
    -- strength previously earned by T4/T5 players; this does not fabricate
    -- Wave Master clears and therefore cannot satisfy weapon gates.
    return math.max(tier, player:getCharVar('Augment_Tier_Grandfather') or 0)
end

-- Evaluate the pre-realignment ladder once, before the new Insane requirement
-- can lower an established character's live roll band.
local function legacyAugmentTier(player)
    if not TIER_GATES[1].check(player) then return 0 end
    if not TIER_GATES[2].check(player) then return 1 end

    local oldT3 = clearedHuntTier(player, 3)
        and (player:getCharVar('Voidspire_Best_Floor') or 0) >= 10
        and waveProgress.hasThrough(player, 5)
    if not oldT3 then return 2 end

    local oldT4 = clearedHuntTier(player, 4)
        and (player:getCharVar('DivergenceSlots') or 0) >= 1
    if not oldT4 then return 3 end
    if (player:getCharVar('Maat_Kills') or 0) < 1 then return 4 end
    return 5
end

-- What unlocks the player's NEXT tier (nil at T5). For gate messages + !augstats.
local function nextUnlock(tier)
    for _, g in ipairs(TIER_GATES) do
        if g.tier == tier + 1 then
            return g.unlock
        end
    end
    return nil
end

-- Shared with !augstats (same Lua state; module loads at boot).
xi.augmentTiers =
{
    tierOf     = augmentTier,
    slices     = TIER_SLICES,
    gates      = TIER_GATES,
    nextUnlock = nextUnlock,
    crystalChance = CRYSTAL_CHANCE,
}

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    if player:getCharVar('Augment_Tier_Migrated') ~= 0 then return end

    local oldTier = legacyAugmentTier(player)
    if oldTier >= 4 then
        player:setCharVar('Augment_Tier_Grandfather', oldTier)
    end
    player:setCharVar('Augment_Tier_Migrated', 1)
end)

-----------------------------------
-- Crystalize helpers
-----------------------------------
-- Read the crystalize state off a piece of gear held in the trade window.
-- Returns:
--   mask   : 5-bit lock bitmask (bit s-1 => slot s crystalized), 0 if none
--   augs   : { {id=, value=}, ... } for all 5 slots (id 0 == empty slot)
--   locked : ordered list of the currently-crystalized {id, value} pairs
--   canCrystalize : false for Inscribable gear (mask can't persist there)
local function readCrystalState(gearItem)
    local canCrystalize = true
    if gearItem.getFlag then
        local ok, flags = pcall(function() return gearItem:getFlag() end)
        if ok and flags and bit.band(flags, INSCRIBABLE) ~= 0 then
            canCrystalize = false
        end
    end

    local augs = {}
    for i = 1, 5 do
        augs[i] = { id = 0, value = 0 }
    end

    local ex = nil
    if gearItem.getExData then
        local ok, res = pcall(function() return gearItem:getExData() end)
        if ok then ex = res end
    end
    if ex and ex.augments then
        for i = 1, 5 do
            local a = ex.augments[i]
            if a then
                augs[i] = { id = a.id or 0, value = a.value or 0 }
            end
        end
    end

    local mask = 0
    if canCrystalize and gearItem.getExDataRaw then
        local raw = gearItem:getExDataRaw()
        mask = (raw and raw[LOCK_MASK_BYTE]) or 0
    end

    local locked = {}
    for i = 1, 5 do
        if bit.band(mask, bit.lshift(1, i - 1)) ~= 0 and augs[i].id ~= 0 then
            table.insert(locked, { id = augs[i].id, value = augs[i].value })
        end
    end

    return mask, augs, locked, canCrystalize
end

-----------------------------------
-- Per-player state
-- playerState[charName] = {
--   itemId        = gear item ID held by the moogle
--   exAugsBySlot  = { {id, value, cat}, ... }   (one entry per FINAL slot;
--                   passed straight to addItem.exdata.augments -- locked slots
--                   first, then freshly rolled slots)
--   labelSummary  = { 'Accuracy +33 x4', ... }
--   catalystsHeld = { {id, qty}, ... }   (for return on cancel)
--   isCrit        = bool
--   newMask       = int   (lock bitmask to stamp onto the rebuilt item)
--   crystalNews   = { 'Accuracy +33', ... }  (labels that crystalized this trade)
--   scour         = bool  (this pending action strips ALL augments)
--   bankCatalysts = { {id, qty}, ... } (deducted atomically only on confirm)
--   bankConsumed  = bool
-- }
-----------------------------------
local playerState = {}

local function getState(player)
    local key = player:getName()
    if not playerState[key] then
        playerState[key] = {
            itemId        = 0,
            exAugsBySlot  = {},
            labelSummary  = {},
            catalystsHeld = {},
        }
    end
    return playerState[key]
end

local function clearState(player)
    playerState[player:getName()] = nil
end

local function returnAll(player)
    local st = getState(player)
    if st.itemId ~= 0 then
        player:addItem({ id = st.itemId, quantity = 1 })
    end
    for _, cat in ipairs(st.catalystsHeld) do
        player:addItem({ id = cat.id, quantity = cat.qty })
    end
    clearState(player)
end

local function refundBankCatalysts(player, st)
    if st.bankConsumed and st.bankCatalysts then
        bank.refund(player, st.bankCatalysts)
        st.bankConsumed = false
    end
end

-----------------------------------
-- Weapons that CANNOT take a standard augment: the trade would otherwise read as
-- "success" (the item re-adds fine, passing the weak `if not augmented` check) but the
-- augment never applies, so the player loses the gil + catalysts for nothing. These
-- have fixed per-stage stats + aftermath and reject standard augments. Death Penalty
-- (Mythic gun) -- all upgrade-stage ids. Rejected up front in onTrade. Extend this set
-- as more REMA (Relic/Mythic/Empyrean/Aeonic) weapons turn up.
-----------------------------------
local NON_AUGMENTABLE =
{
    [18987] = true, [19007] = true, [19076] = true, [19096] = true,  -- Death Penalty: base / 75 / 80 / 85
    [19628] = true, [19726] = true, [19835] = true, [19964] = true,  -- Death Penalty: 90 / 95 / 99 / 99 II
    [21262] = true, [21263] = true, [21268] = true, [22141] = true,  -- Death Penalty: 119 / 119 II / 119 III / Aeonic
}

-----------------------------------
-- Forward declaration
-----------------------------------
local showConfirmMenu
local showScourMenu
local showBankMain
local showPostAugmentMenu

-----------------------------------
-- Persistent catalyst-bank menus
-----------------------------------
local BANK_CATEGORY_NAMES =
{
    [1] = 'Base Stats',
    [2] = 'Melee',
    [3] = 'Magic',
    [4] = 'Defense',
    [5] = 'Delays',
    [6] = 'Duration',
    [7] = 'Pets',
    [8] = 'Potency',
    [9] = 'Skills',
    [10] = 'EXP / Capacity',
    [11] = 'Job Utilities',
}

local bankCategories = {}
for categoryId = 1, #BANK_CATEGORY_NAMES do
    bankCategories[categoryId] = {}
end
for itemId, def in pairs(catalog) do
    if bankCategories[def.cat] then
        table.insert(bankCategories[def.cat],
        {
            itemId = itemId,
            label  = def.label,
        })
    end
end
for _, entries in ipairs(bankCategories) do
    table.sort(entries, function(left, right)
        if left.label == right.label then
            return left.itemId < right.itemId
        end
        return left.label < right.label
    end)
end

local bankSelections = {}

local function readableItemName(itemId)
    local name = itemNames[itemId] or string.format('catalyst_%d', itemId)
    name = name:gsub('_', ' ')
    return name:gsub("(%a[%w']*)", function(word)
        return word:sub(1, 1):upper() .. word:sub(2)
    end)
end

local function sendBankMenu(player, menu)
    player:timer(30, function(p)
        p:customMenu(menu)
    end)
end

local function getBankSelection(player)
    local key = player:getName()
    if not bankSelections[key] then
        bankSelections[key] =
        {
            counts = {},
            order  = {},
            total  = 0,
        }
    end
    return bankSelections[key]
end

local function clearBankSelection(player)
    bankSelections[player:getName()] = nil
end

local function selectionRequests(selection)
    local requests = {}
    for _, itemId in ipairs(selection.order or {}) do
        local qty = selection.counts[itemId] or 0
        if qty > 0 then
            table.insert(requests, { id = itemId, qty = qty })
        end
    end
    return requests
end

local function encodeRecipe(requests)
    local parts = {}
    for _, req in ipairs(requests or {}) do
        if req.id and req.qty and req.qty > 0 then
            table.insert(parts, string.format('%d:%d', req.id, req.qty))
        end
    end
    return table.concat(parts, ',')
end

local function decodeRecipe(raw)
    if not raw or raw == '' then return nil end
    local requests = {}
    for part in string.gmatch(raw, '[^,]+') do
        local itemId, qty = part:match('^(%d+):(%d+)$')
        if itemId and qty then
            table.insert(requests, { id = tonumber(itemId), qty = tonumber(qty) })
        end
    end
    return (#requests > 0) and requests or nil
end

local function recipeFromState(st)
    if st.bankCatalysts and #st.bankCatalysts > 0 then
        return st.bankCatalysts
    end
    if st.catalystsHeld and #st.catalystsHeld > 0 then
        local requests = {}
        for _, cat in ipairs(st.catalystsHeld) do
            table.insert(requests, { id = cat.id, qty = cat.qty })
        end
        return requests
    end
    return nil
end

local function saveLastRecipe(player, requests)
    local encoded = encodeRecipe(requests)
    if encoded ~= '' then
        player:setCharVar(LAST_RECIPE_VAR, encoded)
    end
end

local function loadLastRecipe(player)
    return decodeRecipe(player:getCharVar(LAST_RECIPE_VAR) or '')
end

local function recipeSummary(requests)
    local parts = {}
    local total = 0
    for _, req in ipairs(requests or {}) do
        total = total + req.qty
        local def = catalog[req.id]
        table.insert(parts, string.format('%s x%d',
            def and def.label or readableItemName(req.id), req.qty))
    end
    return table.concat(parts, ', '), total
end

local function validateRecipeForRepeat(player, requests)
    if not requests or #requests == 0 then
        return false, 'You have not augmented anything yet, kupo!'
    end

    local total = 0
    for _, req in ipairs(requests) do
        total = total + req.qty
        if not catalog[req.id] then
            return false, 'Your saved catalyst set is no longer valid, kupo!'
        end
    end

    if total < 1 or total > MAX_CATALYST_COUNT then
        return false, 'Your saved catalyst set is no longer valid, kupo!'
    end

    if player:getGil() < GIL_COST then
        return false, string.format('You need %d gil to augment, kupo!', GIL_COST)
    end

    local playerTier = augmentTier(player)
    if playerTier < 1 then
        return false, string.format(
            'Augmenting is locked until you prove yourself, kupo! Unlock Tier 1: %s.',
            nextUnlock(0) or '???')
    end

    for _, req in ipairs(requests) do
        local def = catalog[req.id]
        local need = def and (def.tier or 0) or 0
        if need > playerTier then
            return false, string.format(
                '[%s] requires Augment Tier %d -- yours is %d, kupo!',
                def.label, need, playerTier)
        end
    end

    local balances = bank.balances(player)
    local missing = {}
    for _, req in ipairs(requests) do
        local have = balances[req.id] or 0
        if have < req.qty then
            local def = catalog[req.id]
            table.insert(missing, string.format('%s (need %d, have %d)',
                def and def.label or readableItemName(req.id), req.qty, have))
        end
    end

    if #missing > 0 then
        return false, string.format(
            'Not enough stored catalysts to repeat, kupo! Missing: %s.',
            table.concat(missing, '; '))
    end

    return true
end

local function applyRecipeToSelection(player, requests)
    clearBankSelection(player)
    local selection = getBankSelection(player)
    for _, req in ipairs(requests) do
        if not selection.counts[req.id] then
            table.insert(selection.order, req.id)
            selection.counts[req.id] = 0
        end
        selection.counts[req.id] = selection.counts[req.id] + req.qty
        selection.total = selection.total + req.qty
    end
end

local function tryRepeatLastRecipe(player, opts)
    opts = opts or {}
    local requests = loadLastRecipe(player)
    local ok, err = validateRecipeForRepeat(player, requests)
    if not ok then
        player:printToPlayer('[Arcane Augmenter] ' .. err, xi.msg.channel.SYSTEM_3)
        if opts.onFail then
            opts.onFail(player)
        end
        return false
    end

    applyRecipeToSelection(player, requests)
    local summary, total = recipeSummary(requests)
    player:printToPlayer(string.format(
        '[Arcane Augmenter] Last catalyst set loaded (%d slot%s): %s.',
        total, total == 1 and '' or 's', summary),
        xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        '[Arcane Augmenter] Trade any equipment piece to roll the same augments again, kupo!',
        xi.msg.channel.SYSTEM_3)
    if opts.onSuccess then
        opts.onSuccess(player)
    end
    return true
end

local function printBankHelp(player)
    player:printToPlayer(
        '[ Arcane Augmenter ] Catalyst drops are stored here automatically and never take inventory slots.',
        xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        '  Choose "Build an augment", select up to 5 stored catalysts, then trade one equipment item.',
        xi.msg.channel.SYSTEM_3)
    player:printToPlayer(string.format(
        '  Catalysts are consumed only when you confirm. Augmentation cost: %d gil.',
        GIL_COST), xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        '  Use "Withdraw catalysts" to pull items back to inventory (Dynamis currency, etc.).',
        xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        '  Physical catalysts from before this update can be traded here without gear to deposit them.',
        xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        '  "Repeat last catalyst set" reloads your previous catalysts -- trade any gear piece to roll again.',
        xi.msg.channel.SYSTEM_3)
end

-- mode: 'browse' | 'build' | 'withdraw'
local showBankCategories
local showBankItems
local showBankQuantity
local showWithdrawQuantity

showBankItems = function(player, categoryId, page, mode)
    mode = mode or 'browse'
    local balances  = bank.balances(player)
    local selection = getBankSelection(player)
    local available = {}
    for _, entry in ipairs(bankCategories[categoryId] or {}) do
        local balance = balances[entry.itemId] or 0
        local selected = selection.counts[entry.itemId] or 0
        local shown = (mode == 'build') and (balance - selected) or balance
        if shown > 0 then
            table.insert(available, entry)
        end
    end

    local pageSize = 2
    local maxPage  = math.max(1, math.ceil(#available / pageSize))
    page = math.max(1, math.min(page or 1, maxPage))
    local options = {}
    local first = (page - 1) * pageSize + 1
    for index = first, math.min(first + pageSize - 1, #available) do
        local entry = available[index]
        local balance = balances[entry.itemId] or 0
        local selected = selection.counts[entry.itemId] or 0
        local shown = (mode == 'build') and (balance - selected) or balance
        table.insert(options,
        {
            string.format('%s [%d]', entry.label:sub(1, 22), shown),
            function(p)
                if mode == 'build' then
                    showBankQuantity(p, entry, categoryId, page)
                elseif mode == 'withdraw' then
                    showWithdrawQuantity(p, entry, categoryId, page)
                else
                    p:printToPlayer(string.format(
                        '[Arcane Bank] %s -- %s. Stored: %d.',
                        readableItemName(entry.itemId), entry.label, balance),
                        xi.msg.channel.SYSTEM_3)
                    showBankItems(p, categoryId, page, 'browse')
                end
            end,
        })
    end

    if page < maxPage then
        table.insert(options, { 'Next page', function(p) showBankItems(p, categoryId, page + 1, mode) end })
    end
    if page > 1 then
        table.insert(options, { 'Previous page', function(p) showBankItems(p, categoryId, page - 1, mode) end })
    end
    table.insert(options, { 'Back', function(p) showBankCategories(p, 1, mode) end })

    sendBankMenu(player,
    {
        title = string.format('%s (%d/%d)', BANK_CATEGORY_NAMES[categoryId], page, maxPage),
        options = options,
        onCancelled = function(p) showBankMain(p) end,
    })
end

showWithdrawQuantity = function(player, entry, categoryId, page)
    local balance = bank.balances(player)[entry.itemId] or 0
    if balance < 1 then
        showBankItems(player, categoryId, page, 'withdraw')
        return
    end

    local freeSlots = player:getFreeSlotsCount()
    if freeSlots < 1 then
        player:printToPlayer(
            '[Arcane Bank] Inventory full — free a slot before withdrawing.',
            xi.msg.channel.SYSTEM_3)
        showBankItems(player, categoryId, page, 'withdraw')
        return
    end

    local maxQty = math.min(balance, freeSlots * 99)
    local presets = { 1, 5, 12, 24, 48, 99 }
    local options = {}
    local seen = {}
    for _, qty in ipairs(presets) do
        if qty <= maxQty and not seen[qty] then
            seen[qty] = true
            local withdrawQty = qty
            table.insert(options,
            {
                string.format('Withdraw %d', withdrawQty),
                function(p)
                    bank.withdraw(p, entry.itemId, withdrawQty, false)
                    showBankItems(p, categoryId, page, 'withdraw')
                end,
            })
        end
    end
    if maxQty > 0 and not seen[maxQty] then
        table.insert(options,
        {
            string.format('Withdraw all (%d)', maxQty),
            function(p)
                bank.withdraw(p, entry.itemId, maxQty, false)
                showBankItems(p, categoryId, page, 'withdraw')
            end,
        })
    end
    table.insert(options, { 'Back', function(p) showBankItems(p, categoryId, page, 'withdraw') end })

    sendBankMenu(player,
    {
        title = string.format('Withdraw %s', entry.label:sub(1, 18)),
        options = options,
        onCancelled = function(p) showBankCategories(p, 1, 'withdraw') end,
    })
end

showBankQuantity = function(player, entry, categoryId, page)
    local balances  = bank.balances(player)
    local selection = getBankSelection(player)
    local remaining = math.min(
        (balances[entry.itemId] or 0) - (selection.counts[entry.itemId] or 0),
        MAX_CATALYST_COUNT - selection.total)
    if remaining < 1 then
        showBankItems(player, categoryId, page, 'build')
        return
    end

    local options = {}
    for qty = 1, remaining do
        local addQty = qty
        table.insert(options,
        {
            string.format('Add %d', addQty),
            function(p)
                local current = getBankSelection(p)
                if not current.counts[entry.itemId] then
                    table.insert(current.order, entry.itemId)
                    current.counts[entry.itemId] = 0
                end
                current.counts[entry.itemId] = current.counts[entry.itemId] + addQty
                current.total = current.total + addQty
                p:printToPlayer(string.format(
                    '[Arcane Bank] Added %s x%d to the augment (%d/%d slots).',
                    entry.label, addQty, current.total, MAX_CATALYST_COUNT),
                    xi.msg.channel.SYSTEM_3)
                if current.total >= MAX_CATALYST_COUNT then
                    p:printToPlayer(
                        '[Arcane Bank] Selection full. Trade one equipment item to the Arcane Augmenter.',
                        xi.msg.channel.SYSTEM_3)
                else
                    showBankCategories(p, 1, 'build')
                end
            end,
        })
    end
    table.insert(options, { 'Back', function(p) showBankItems(p, categoryId, page, 'build') end })

    sendBankMenu(player,
    {
        title = string.format('%s: choose amount', entry.label:sub(1, 20)),
        options = options,
        onCancelled = function(p) showBankCategories(p, 1, 'build') end,
    })
end

showBankCategories = function(player, page, mode)
    mode = mode or 'browse'
    -- Legacy callers passed a boolean selecting flag.
    if mode == true then
        mode = 'build'
    elseif mode == false then
        mode = 'browse'
    end

    local balances  = bank.balances(player)
    local selection = getBankSelection(player)
    local categories = {}
    for categoryId, entries in ipairs(bankCategories) do
        local total, types = 0, 0
        for _, entry in ipairs(entries) do
            local amount = balances[entry.itemId] or 0
            if mode == 'build' then
                amount = amount - (selection.counts[entry.itemId] or 0)
            end
            if amount > 0 then
                total = total + amount
                types = types + 1
            end
        end
        if types > 0 then
            table.insert(categories, { id = categoryId, total = total, types = types })
        end
    end

    local pageSize = 2
    local maxPage  = math.max(1, math.ceil(#categories / pageSize))
    page = math.max(1, math.min(page or 1, maxPage))
    local options = {}
    local first = (page - 1) * pageSize + 1
    for index = first, math.min(first + pageSize - 1, #categories) do
        local category = categories[index]
        table.insert(options,
        {
            string.format('%s [%d]', BANK_CATEGORY_NAMES[category.id], category.total),
            function(p) showBankItems(p, category.id, 1, mode) end,
        })
    end

    if page < maxPage then
        table.insert(options, { 'Next page', function(p) showBankCategories(p, page + 1, mode) end })
    end
    if page > 1 then
        table.insert(options, { 'Previous page', function(p) showBankCategories(p, page - 1, mode) end })
    end
    if mode == 'build' and selection.total > 0 then
        table.insert(options,
        {
            string.format('Ready - trade gear (%d)', selection.total),
            function(p)
                p:printToPlayer(string.format(
                    '[Arcane Bank] %d catalyst%s selected. Trade one equipment item to continue.',
                    selection.total, selection.total == 1 and '' or 's'),
                    xi.msg.channel.SYSTEM_3)
            end,
        })
    else
        table.insert(options, { 'Back', function(p) showBankMain(p) end })
    end

    local title
    if mode == 'build' then
        title = string.format('Build augment (%d/5)', selection.total)
    elseif mode == 'withdraw' then
        title = string.format('Withdraw (%d/%d)', page, maxPage)
    else
        title = string.format('Stored catalysts (%d/%d)', page, maxPage)
    end

    sendBankMenu(player,
    {
        title = title,
        options = options,
        onCancelled = function(p) showBankMain(p) end,
    })
end

showBankMain = function(player)
    local balances = bank.balances(player)
    local total = 0
    for _, quantity in pairs(balances) do
        if quantity > 0 then
            total = total + quantity
        end
    end
    local selection = getBankSelection(player)
    local lastRecipe = loadLastRecipe(player)
    local lastTotal = 0
    if lastRecipe then
        _, lastTotal = recipeSummary(lastRecipe)
    end

    local options = {}
    if lastRecipe then
        table.insert(options,
        {
            string.format('Repeat last catalyst set (%d)', lastTotal),
            function(p)
                tryRepeatLastRecipe(p, { onFail = function(pp) showBankMain(pp) end })
            end,
        })
    end
    table.insert(options,
    {
        string.format('Browse bank (%d)', total),
        function(p) showBankCategories(p, 1, 'browse') end,
    })
    table.insert(options,
    {
        string.format('Withdraw catalysts (%d)', total),
        function(p) showBankCategories(p, 1, 'withdraw') end,
    })
    table.insert(options,
    {
        string.format('Build an augment (%d/5)', selection.total),
        function(p) showBankCategories(p, 1, 'build') end,
    })
    table.insert(options,
    {
        'How this works',
        function(p)
            printBankHelp(p)
            showBankMain(p)
        end,
    })
    if selection.total > 0 then
        table.insert(options,
        {
            'Clear selection',
            function(p)
                clearBankSelection(p)
                p:printToPlayer('[Arcane Bank] Augment selection cleared.', xi.msg.channel.SYSTEM_3)
                showBankMain(p)
            end,
        })
    end

    sendBankMenu(player,
    {
        title = string.format('Arcane Bank: %d catalysts', total),
        options = options,
    })
end

showPostAugmentMenu = function(player)
    local lastRecipe = loadLastRecipe(player)
    if not lastRecipe then
        showBankMain(player)
        return
    end

    local _, total = recipeSummary(lastRecipe)
    sendBankMenu(player,
    {
        title = 'Augment another piece?',
        options =
        {
            {
                string.format('Same catalysts again (%d)', total),
                function(p)
                    tryRepeatLastRecipe(p,
                    {
                        onFail = function(pp) showPostAugmentMenu(pp) end,
                    })
                end,
            },
            {
                'Back to Arcane Bank',
                function(p) showBankMain(p) end,
            },
        },
    })
end


-----------------------------------
-- Confirm menu
-----------------------------------
showConfirmMenu = function(player)
    local st       = getState(player)
    local nameList = st.labelSummary or {}

    local options =
    {
        {
            string.format('Yes - apply (%d gil)', GIL_COST),
            function(playerArg)
                if playerArg:getFreeSlotsCount() == 0 then
                    playerArg:printToPlayer('Inventory full! Free a slot first, kupo!', xi.msg.channel.SYSTEM_3)
                    showConfirmMenu(playerArg)
                    return
                end

                if playerArg:getGil() < GIL_COST then
                    playerArg:printToPlayer(string.format('Need %d gil, kupo! Trade cancelled - returning items.', GIL_COST), xi.msg.channel.SYSTEM_3)
                    returnAll(playerArg)
                    return
                end

                local st2 = getState(playerArg)
                -- Bank-backed catalysts are consumed atomically only after the
                -- player confirms. The roll was staged privately and nothing
                -- below reveals crit/values until this deduction succeeds.
                if st2.bankCatalysts and #st2.bankCatalysts > 0 then
                    if not bank.consume(playerArg, st2.bankCatalysts) then
                        returnAll(playerArg)
                        playerArg:printToPlayer(
                            'Your stored catalyst balance changed. Gear returned; no augmentation was applied, kupo!',
                            xi.msg.channel.SYSTEM_3)
                        return
                    end
                    st2.bankConsumed = true
                    playerArg:printToPlayer(
                        'Stored catalysts consumed. Resolving your augmentation now, kupo!',
                        xi.msg.channel.SYSTEM_3)
                end

                -- exAugsBySlot is already in {id, value, cat} format -
                -- pass straight through to addItem. The `cat` field is
                -- ignored by addItem; it's only used by the Sage affinity
                -- check during selection building.
                local exAugs = {}
                for _, sel in ipairs(st2.exAugsBySlot) do
                    table.insert(exAugs, { id = sel.id, value = sel.value })
                end

                local augmented = playerArg:addItem({
                    id     = st2.itemId,
                    exdata =
                    {
                        augmentKind    = xi.augment.kind.HAS_AUGMENTS,
                        augmentSubKind = xi.augment.subKind.STANDARD,
                        augments       = exAugs,
                    },
                })

                -- Never eat the player's gear: if the engine refused the
                -- augmented item, hand everything back and charge no gil.
                if not augmented then
                    refundBankCatalysts(playerArg, st2)
                    returnAll(playerArg)
                    playerArg:printToPlayer('Augmentation failed - gear and catalysts returned, no gil charged, kupo!', xi.msg.channel.SYSTEM_3)
                    return
                end

                -- Stamp the crystalize lock bitmask onto the rebuilt item.
                -- Written AFTER addItem so the augment bytes (0-11) are already
                -- in place; we only touch byte 13 (mask) and keep byte 12 (the
                -- first signature byte) at 0 so the signature renders blank.
                if (st2.newMask or 0) ~= 0 and augmented.setExDataRaw then
                    augmented:setExDataRaw({ [SIG_HEAD_BYTE] = 0, [LOCK_MASK_BYTE] = st2.newMask })
                end

                -- The rebuilt gear now exists. Clear the retryable held-item
                -- state before optional achievement/message callbacks so a
                -- later script error can never duplicate the equipment.
                saveLastRecipe(playerArg, recipeFromState(st2))
                clearState(playerArg)
                playerArg:delGil(GIL_COST)

                -- Consume the crit token (Maat's Cap, or a legacy Maat's Blessing) if it guaranteed this crit.
                if st2.usedCritToken then
                    local token = playerArg:getItemCount(CRIT_TOKEN_ID) > 0 and CRIT_TOKEN_ID or CRIT_TOKEN_LEGACY
                    playerArg:delItem(token, 1)
                    playerArg:printToPlayer("Maat's Cap consumed by the augment's power.", xi.msg.channel.SYSTEM_3)
                end

                -- Bump the lifetime augment counter - feeds Sage rank-ups.
                local prev = playerArg:getCharVar('Augment_Count') or 0
                playerArg:setCharVar('Augment_Count', prev + 1)

                -- Fire achievement checks now that Augment_Count is updated.
                local ach = require('modules/custom/lua/achievements')
                ach.onAugmentTrade(playerArg)

                -- Weekly Hunt Board: notify "Sage's Hand" / similar
                -- objectives that the player just augmented an item.
                wh.fire(playerArg, 'augment_done', { isCrit = st2.isCrit })

                playerArg:printToPlayer(
                    string.format('Augmentation complete! Applied: [%s], kupo!', table.concat(st2.labelSummary, '] [')),
                    xi.msg.channel.SYSTEM_3
                )
                if st2.isCrit then
                    playerArg:printToPlayer('Critical augment locked in - your catalysts hit twice as hard!',
                        xi.msg.channel.SYSTEM_3)
                end
                -- Crystalize results.
                for _, lbl in ipairs(st2.crystalNews or {}) do
                    playerArg:printToPlayer(string.format('%s CRYSTALIZED: [%s] is now locked at max -- re-rolls can no longer touch it, kupo!', xi.icon.STAR_LARGE, lbl),
                        xi.msg.channel.SYSTEM_3)
                end
                showPostAugmentMenu(playerArg)
            end,
        },
        {
            'Cancel - return items',
            function(playerArg)
                returnAll(playerArg)
                playerArg:printToPlayer('Item and catalysts returned, kupo!', xi.msg.channel.SYSTEM_3)
            end,
        },
    }

    -- Keep the confirm title SHORT and fixed-length. The full per-catalyst
    -- breakdown is already printed to chat ("Catalysts accepted! Will apply:
    -- ..."), so the menu doesn't need it -- and embedding it here is exactly
    -- what broke STACKED trades: a long label like
    -- "Weapon skill damage -> +16 (stacked x4) [boost 12/31]" pushed
    -- title+options past the client's ~128-byte customMenu ceiling, so the
    -- entire menu silently no-op'd (no Yes button) and the trade hung with the
    -- item held in limbo. A fixed title fits no matter how many or how big the
    -- catalysts are.
    utils.unused(nameList)
    local menu = {
        title   = 'Apply this augment, kupo?',
        options = options,
        onCancelled = function(p)
            returnAll(p)
            p:printToPlayer('Augmentation cancelled - items returned, kupo!', xi.msg.channel.SYSTEM_3)
        end,
    }
    player:timer(30, function(p) p:customMenu(menu) end)
end

-----------------------------------
-- Scour menu (strip ALL augments, including crystalized, and start anew)
-----------------------------------
showScourMenu = function(player)
    local options =
    {
        {
            string.format('Yes - scour (%d gil)', SCOUR_GIL_COST),
            function(playerArg)
                if playerArg:getFreeSlotsCount() == 0 then
                    playerArg:printToPlayer('Inventory full! Free a slot first, kupo!', xi.msg.channel.SYSTEM_3)
                    showScourMenu(playerArg)
                    return
                end
                if playerArg:getGil() < SCOUR_GIL_COST then
                    playerArg:printToPlayer(string.format('Need %d gil to scour, kupo! Returning your gear.', SCOUR_GIL_COST), xi.msg.channel.SYSTEM_3)
                    returnAll(playerArg)
                    return
                end

                local st2 = getState(playerArg)
                -- Re-add the gear with NO exdata: a blank, un-augmented item.
                local stripped = playerArg:addItem({ id = st2.itemId })
                if not stripped then
                    returnAll(playerArg)
                    playerArg:printToPlayer('Scour failed - gear returned, no gil charged, kupo!', xi.msg.channel.SYSTEM_3)
                    return
                end
                -- Belt-and-suspenders: zero the lock mask byte too.
                if stripped.setExDataRaw then
                    stripped:setExDataRaw({ [SIG_HEAD_BYTE] = 0, [LOCK_MASK_BYTE] = 0 })
                end

                playerArg:delGil(SCOUR_GIL_COST)
                playerArg:printToPlayer('Scoured! All augments -- crystalized or not -- are gone. Start anew, kupo!', xi.msg.channel.SYSTEM_3)
                clearState(playerArg)
            end,
        },
        {
            'Cancel - return gear',
            function(playerArg)
                returnAll(playerArg)
                playerArg:printToPlayer('Gear returned, nothing scoured, kupo!', xi.msg.channel.SYSTEM_3)
            end,
        },
    }

    local menu = {
        title   = 'Scour ALL augments, kupo?',
        options = options,
        onCancelled = function(p)
            returnAll(p)
            p:printToPlayer('Scour cancelled - gear returned, kupo!', xi.msg.channel.SYSTEM_3)
        end,
    }
    player:timer(30, function(p) p:customMenu(menu) end)
end

-----------------------------------
-- Module override
-----------------------------------
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local AugmentMoogle = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Augment_Moogle',
        packetName = string.format('%sArcane Augmenter', xi.icon.STAR_LARGE),
        look       = 1834,   -- Alexander model: divine mechanical deity, colossal scale
        -- GM Home Augment Sanctum (z=-45): centered, standalone, far from the main NPC cluster.
        x          = 571.6949,
        y          =  -0.5056,
        z          = 544.0399,
        rotation   =  67,
        widescan   =  1,

        onTrigger = function(player, npc)
            local st = getState(player)
            if st.itemId ~= 0 then
                player:printToPlayer('You have an item awaiting augmentation, kupo!', xi.msg.channel.SYSTEM_3)
                if st.scour then
                    showScourMenu(player)
                else
                    showConfirmMenu(player)
                end
                return
            end
            showBankMain(player)
        end,

        onTrade = function(player, npc, trade)
            local gearId         = nil
            local gearItemObj    = nil   -- CLuaItem for the gear (for crystalize state)
            local catalystCounts = {}    -- itemId -> total count (sums across slots + stack qty)
            local catalystOrder  = {}    -- first-seen order so the menu reads naturally
            local totalCatalysts = 0     -- sum of all catalyst counts
            local hasScourItem   = false -- dedicated scour item present in the trade

            -- Scan slots. Multiple slots of the same catalyst stack into one
            -- selection; a slot containing a stack of N counts as N catalysts.
            for slot = 0, 7 do
                local tradeItem = trade:getItem(slot)
                if tradeItem then
                    local itemId = tradeItem:getID()
                    local qty    = trade:getSlotQty(slot)
                    if qty == nil or qty < 1 then qty = 1 end
                    local def    = catalog[itemId]

                    if SCOUR_ITEM_ID and itemId == SCOUR_ITEM_ID then
                        hasScourItem = true

                    elseif def then
                        if not catalystCounts[itemId] then
                            catalystCounts[itemId] = 0
                            table.insert(catalystOrder, itemId)
                        end
                        catalystCounts[itemId] = catalystCounts[itemId] + qty
                        totalCatalysts         = totalCatalysts + qty

                    elseif gearId == nil then
                        gearId      = itemId
                        gearItemObj = tradeItem

                    else
                        player:printToPlayer('Trade 1 equipment piece + catalyst items only, kupo! (one of those items is not a catalyst)', xi.msg.channel.SYSTEM_3)
                        return
                    end
                end
            end

            if gearId == nil then
                -- Migration/convenience path for physical catalysts already
                -- owned before automatic banking was introduced.
                if totalCatalysts > 0 then
                    local requests = {}
                    for _, itemId in ipairs(catalystOrder) do
                        table.insert(requests, { id = itemId, qty = catalystCounts[itemId] or 0 })
                    end
                    player:tradeComplete()
                    if not bank.depositBatch(player, requests, false) then
                        for _, request in ipairs(requests) do
                            player:addItem({ id = request.id, quantity = request.qty })
                        end
                        player:printToPlayer(
                            '[Arcane Bank] Deposit failed; all catalyst items were returned.',
                            xi.msg.channel.SYSTEM_3)
                        return
                    end
                    player:printToPlayer(string.format(
                        '[Arcane Bank] Deposit complete: %d catalyst%s stored.',
                        totalCatalysts, totalCatalysts == 1 and '' or 's'), xi.msg.channel.SYSTEM_3)
                    return
                end
                player:printToPlayer('Trade catalyst materials to deposit them, or select a bank augment first, kupo!', xi.msg.channel.SYSTEM_3)
                return
            end

            -- A bank selection is made before the gear trade. Inject it into
            -- the existing validation/roll pipeline so bank and legacy
            -- physical catalysts produce identical augments.
            local bankMode = false
            local selectedBankCatalysts = {}
            if totalCatalysts == 0 then
                local selection = getBankSelection(player)
                if selection.total > 0 then
                    bankMode = true
                    selectedBankCatalysts = selectionRequests(selection)
                    for _, request in ipairs(selectedBankCatalysts) do
                        catalystCounts[request.id] = request.qty
                        table.insert(catalystOrder, request.id)
                        totalCatalysts = totalCatalysts + request.qty
                    end
                else
                    local lastRecipe = loadLastRecipe(player)
                    if lastRecipe then
                        local ok, err = validateRecipeForRepeat(player, lastRecipe)
                        if ok then
                            applyRecipeToSelection(player, lastRecipe)
                            selection = getBankSelection(player)
                            bankMode = true
                            selectedBankCatalysts = selectionRequests(selection)
                            for _, request in ipairs(selectedBankCatalysts) do
                                catalystCounts[request.id] = request.qty
                                table.insert(catalystOrder, request.id)
                                totalCatalysts = totalCatalysts + request.qty
                            end
                            player:printToPlayer(
                                '[Arcane Augmenter] Using your last catalyst set again, kupo!',
                                xi.msg.channel.SYSTEM_3)
                        else
                            player:printToPlayer('[Arcane Augmenter] ' .. err, xi.msg.channel.SYSTEM_3)
                            return
                        end
                    end
                end
            end

            -- Reject weapons that can't actually take a standard augment (Death Penalty
            -- etc.). The trade would otherwise read as success -- the item re-adds fine so
            -- the weak `if not augmented` check passes -- but the augment never applies and
            -- the player loses the gil + catalysts. Bail here, before anything is taken.
            if NON_AUGMENTABLE[gearId] then
                player:printToPlayer('That weapon cannot be augmented, kupo! Mythic/Relic weapons (like Death Penalty) have fixed stats and reject augments.', xi.msg.channel.SYSTEM_3)
                return
            end

            -- Read the gear's current crystalize state up front (needed for both
            -- the scour path and the free-slot budget).
            local _, _, lockedAugs, canCrystalize = readCrystalState(gearItemObj)
            local lockedCount = #lockedAugs

            -- SCOUR: either the dedicated scour item was traded, or the gear was
            -- traded ALONE and it carries crystalized augments the player wants to
            -- clear. Strip everything and start anew.
            if hasScourItem or (totalCatalysts == 0 and lockedCount > 0) then
                -- Clear any previous pending session first.
                local existing = getState(player)
                if existing.itemId ~= 0 then
                    returnAll(player)
                    player:printToPlayer('Returning your previous item and catalysts first, kupo!', xi.msg.channel.SYSTEM_3)
                end

                player:tradeComplete()
                playerState[player:getName()] =
                {
                    itemId        = gearId,
                    exAugsBySlot  = {},
                    labelSummary  = {},
                    catalystsHeld = {},
                    scour         = true,
                }
                player:printToPlayer(string.format('This will STRIP all augments (including %d crystalized), kupo! Confirm below.', lockedCount), xi.msg.channel.SYSTEM_3)
                showScourMenu(player)
                return
            end

            if totalCatalysts == 0 then
                player:printToPlayer(
                    'Select stored catalysts from my menu, use "Repeat last catalyst set", or trade gear after a prior augment to reuse your last catalysts, kupo!',
                    xi.msg.channel.SYSTEM_3)
                return
            end

            if totalCatalysts > MAX_CATALYST_COUNT then
                player:printToPlayer(string.format('Max %d catalysts per trade (you traded %d), kupo!', MAX_CATALYST_COUNT, totalCatalysts), xi.msg.channel.SYSTEM_3)
                return
            end

            -- Crystalized slots are preserved for free; new catalysts fill the
            -- remaining slots. Reject if there isn't room.
            local freeSlots = MAX_CATALYST_COUNT - lockedCount
            if totalCatalysts > freeSlots then
                player:printToPlayer(string.format(
                    'This item has %d crystalized slot%s -- only %d free. You traded %d catalyst%s. Scour it (trade alone) to free crystalized slots, kupo!',
                    lockedCount, lockedCount == 1 and '' or 's', freeSlots,
                    totalCatalysts, totalCatalysts == 1 and '' or 's'),
                    xi.msg.channel.SYSTEM_3)
                return
            end

            if player:getGil() < GIL_COST then
                player:printToPlayer(string.format('You need %d gil to augment, kupo!', GIL_COST), xi.msg.channel.SYSTEM_3)
                return
            end

            -- Read sage rank early (raises the roll floor + drives crit chance).
            local rank = player:getCharVar('Augment_Mastery') or 0

            -- AUGMENT TIER gate (content progression, not Sage rank): your tier
            -- sets the roll band for every line in this trade, AND each catalyst's
            -- catalog `tier` is the minimum Augment Tier required to trade it
            -- (tier 0 = open; the old Maat's-Echo T5 gate is now the T5 ladder step).
            local playerTier = augmentTier(player)
            if playerTier < 1 then
                player:printToPlayer(string.format(
                    'Augmenting is locked until you prove yourself, kupo! Unlock Tier 1: %s.',
                    nextUnlock(0) or '???'),
                    xi.msg.channel.SYSTEM_3)
                return
            end
            for _, itemId in ipairs(catalystOrder) do
                local def2 = catalog[itemId]
                local need = def2 and (def2.tier or 0) or 0
                if need > playerTier then
                    player:printToPlayer(string.format(
                        '[%s] requires Augment Tier %d -- yours is %d. Next unlock: %s, kupo!',
                        def2.label, need, playerTier,
                        nextUnlock(playerTier) or '???'),
                        xi.msg.channel.SYSTEM_3)
                    return
                end
                -- Tier-fixed augments (Treasure Hunter, All songs, ...): the line's
                -- value is either your Augment Tier (tierValue) or a hard flat
                -- number (flatValue). Extra catalysts add nothing but stacked
                -- slots would multiply it -> one catalyst per trade, one line
                -- per item. flatValue augments (currently just Treasure Hunter)
                -- deliberately do NOT scale with player tier: they cap out at
                -- their written value on every gear piece.
                if def2 and (def2.tierValue or def2.flatValue) then
                    if (catalystCounts[itemId] or 0) > 1 then
                        local shownVal = def2.flatValue or (def2.tierValue * playerTier)
                        local suffix   = def2.flatValue and '' or ' at your Augment Tier'
                        player:printToPlayer(string.format(
                            '[%s] is single-line (+%d%s) -- trade a SINGLE catalyst, kupo!',
                            def2.label, shownVal, suffix),
                            xi.msg.channel.SYSTEM_3)
                        return
                    end
                    for _, la in ipairs(lockedAugs) do
                        if la.id == def2.augId then
                            player:printToPlayer(string.format(
                                'This item already carries a crystalized %s line -- it cannot stack. Scour the item first, kupo!',
                                def2.label),
                                xi.msg.channel.SYSTEM_3)
                            return
                        end
                    end
                end
            end

            -- Read the player's Sage-quest state ONCE for the trade. The
            -- mastery rank raises the roll floor + drives the crit chance;
            -- the affinity bitfield is consulted per-augment because each
            -- selection may belong to a different category.
            local critPct     = sage.critChance[rank + 1]  or 0.0
            -- Maat's Cap (or a legacy Maat's Blessing) guarantees a crit; consumed after delGil on success.
            local usedCritToken = player:getItemCount(CRIT_TOKEN_ID) > 0 or player:getItemCount(CRIT_TOKEN_LEGACY) > 0
            local isCrit        = usedCritToken or (math.random() < critPct)

            -- Crystalize chance for THIS trade, by Augment Sage rank.
            local crystalPct = canCrystalize and (CRYSTAL_CHANCE[rank] or 0.0) or 0.0

            -- IMPORTANT: the exdata Value field is 5 bits wide (max 31),
            -- defined in src/map/items/exdata/augment_standard.h. Stuffing
            -- a stacked value > 31 into one slot causes silent overflow:
            --   `Accuracy+33 x4` was emitting exdata=99 which the engine
            --   stored as `99 & 0x1F = 3`, giving Accuracy+36 instead of
            --   the +132 the website promised.
            --
            -- Fix: emit ONE augment slot per catalyst instead of stuffing
            -- the stack into a single slot. Equipment supports 5 augment
            -- slots; MAX_CATALYST_COUNT=5 fills them exactly. The
            -- engine sums each slot's contribution to the mod independently
            -- so 4 slots of Accuracy+33 (exdata=0 each) cleanly delivers
            -- +132.
            --
            -- Boost (mastery * affinity * crit) is applied as per-slot
            -- exdata, also capped at 31. For high-base augments (e.g.
            -- base=33) the boost can't fully express via exdata; we use
            -- the maximum the cap allows. Sign polarity is handled by the
            -- engine (item_equipment.cpp:479): for positive base it adds,
            -- for negative base it subtracts. We always pass a positive
            -- exdata magnitude.
            local EXDATA_VALUE_MAX = 31
            -- FINAL augment layout: crystalized (locked) slots first, then the
            -- freshly rolled catalyst slots. The lock bitmask is built to match.
            local exAugsBySlot     = {}    -- one entry per FINAL slot, ready for addItem
            local labelSummary     = {}    -- one human-readable string per catalyst type
            local catalystsHeld    = {}
            local capWarnings      = {}    -- de-duped engine-cap warnings to show after the trade summary
            local crystalNews      = {}    -- labels that crystalized this trade
            local newMask          = 0

            -- Preserve crystalized slots verbatim; their mask bits carry forward.
            for _, la in ipairs(lockedAugs) do
                table.insert(exAugsBySlot, { id = la.id, value = la.value, cat = nil })
                newMask = bit.bor(newMask, bit.lshift(1, #exAugsBySlot - 1))
            end

            -- Engine-mod cap lookup: augId -> human-readable warning string.
            -- Populated from a manual cross-reference of sql/augments.sql
            -- with the clamps in src/map/utils/battleutils.cpp and
            -- src/map/entities/battleentity.cpp (see the audit notes
            -- in the project memory for the file:line citations). When a
            -- player trades for one of these augIds, we surface the cap
            -- once so they can see whether their stack will be partly
            -- wasted against existing gear that already approaches the
            -- limit. The cap is the per-character equipment total, not
            -- per-augment; traits, merits, effects, and progression bonuses
            -- remain separate, so the warning is purely informational.
            local CAPPED_MOD_AUGS =
            {
                -- HASTE_GEAR (mod 384) clamped to ±25% (2500/10000)
                -- in battleentity.cpp:534 and battleutils.cpp:5991.
                [ 49] = 'HASTE_GEAR is capped at +25% total across all gear.',
                [ 50] = 'HASTE_GEAR is capped at +25% total across all gear.',
                -- PDT (mod 161 DMGPHYS) floored at -50% in
                -- battleutils.cpp:4707.
                [ 54] = 'Physical Dmg. Taken floors at -50% total. (PDT-II only goes lower.)',
                [ 71] = 'Damage Taken floors at -50% total across gear.',
                [1155] = 'Physical Dmg. Taken floors at -50% total. (PDT-II only goes lower.)',
                -- MDT (mod 163 DMGMAGIC) floored at -50% in
                -- battleutils.cpp:4664.
                [ 55] = 'Magic Dmg. Taken floors at -50% total. (MDT-II only goes lower.)',
                [1156] = 'Magic Dmg. Taken floors at -50% total. (MDT-II only goes lower.)',
                -- Breath Dmg Taken (mod 162) shares the same clamp path.
                [ 56] = 'Breath Dmg. Taken floors at -50% total.',
                -- Magic Burst Bonus (mod 487 MAGIC_BURST_BONUS_CAPPED).
                -- Cap enforced at scripts/globals/spells/damage_spell.lua:988
                -- via utils.clamp(cappedBonus, 0, 0.4) - confirmed 40%.
                [334] = 'Magic Burst Bonus caps at +40% total across gear / atmas / merits.',
                -- CRIT_DMG_INCREASE (mod 421). Cap enforced at
                -- scripts/globals/combat/physical_utilities.lua:696 via
                -- utils.clamp(actor:getMod(CRIT_DMG_INCREASE) - target's
                -- CRIT_DEF_BONUS, 0, 100). Augment is functional (not
                -- dead code as a first pass suggested); cap is +100%
                -- (i.e. a doubling of crit damage), which a deep stack
                -- can hit.
                [328] = 'Crit. Hit Damage caps at +100% total (per-swing clamp).',
                -- CRIT_HIT_RATE (mod 165), DOUBLE_ATTACK (mod 288) and
                -- their kin each clamp [0, 100] per swing in
                -- battleutils.cpp:2710 / 3035-3037 - only matters at
                -- extreme stacks but worth surfacing.
                [ 41] = 'Crit Hit Rate caps at 100% per swing.',
                [132] = 'Double Attack caps at 100% per swing.',
                [143] = 'Double Attack caps at 100% per swing.',
                [144] = 'Triple Attack caps at 100% per swing.',
                [354] = 'Quad. Attack caps at 100% per swing.',
                -- ENMITY (mod 27) - hate calc clamps each event to
                -- [-50, +100] in src/map/enmity_container.cpp:150.
                [ 39] = 'Enmity contribution clamped to [-50, +100] per hate event.',
                -- FASTCAST (mod 170) - cast-time cap +50%, then
                -- recast-side re-clamp caps combined at +80% (40%
                -- recast reduction) in battleutils.cpp:5935/6085.
                [140] = 'Fast Cast caps at +80% total (recast reduction capped at 40%).',
                -- SUBTLE_BLOW (mod 289) - Lua clamp 50% in
                -- scripts/globals/combat/tp.lua:204; SB + SB_II combined
                -- floors at 75% (same file:207).
                [195] = 'Subtle Blow caps at 50% total. (SB + SB II combined floors at 75%.)',
                -- ZANSHIN (mod 306) - per-round clamp 100% in
                -- src/map/entities/battleentity.cpp:3785 (after merits).
                [198] = 'Zanshin caps at 100% per round.',
                -- SNAPSHOT (mod 253) - delay-reduction cap 70% in
                -- src/map/utils/battleutils.cpp:5610.
                [211] = 'Snapshot caps at 70% total across gear.',
                -- CURE_POTENCY (mod 374) - Lua clamp 50% in
                -- scripts/globals/magic.lua:42 (mod header modifier.h:890
                -- also documents "capped at 50").
                [329] = 'Cure Potency caps at +50% total.',
                -- TP_BONUS (mod 345) - hard ceiling 3000 TP applied at
                -- weaponskill time in battleutils.cpp:6298.
                [353] = 'TP Bonus caps at +3000 total at weaponskill time.',
                -- COUNTER (mod 291) - 80% cap (with merits) in
                -- src/map/attack.cpp:482.
                [640] = 'Counter caps at 80% per swing (with merits).',
                -- Relaunch aggregate augment ceilings. Raw equipment totals
                -- remain intact so removing over-cap gear reveals the correct
                -- remainder; CBattleEntity::getMod applies these effective
                -- limits to PCs (and the separate Pet Regen limit to pets).
                [  67] = 'All Songs gear ceiling is +50.',
                [ 148] = 'Gilfinder gear ceiling is +300.',
                [ 338] = 'Barrage gear ceiling is +320.',
                [ 147] = 'Treasure Hunter gear ceiling is +15.',
                [2046] = 'Phantom Roll Effect gear ceiling is +150.',
                [ 137] = 'Regen gear ceiling is +600 HP per tick.',
                [2100] = 'Beast Affinity gear ceiling is +900.',
                [ 110] = 'Pet Regen gear ceiling is +1280 HP per tick.',
                [1264] = 'Meditate Duration gear ceiling is +320 seconds.',
                [1153] = 'Evasion gear ceiling is +850.',
                [1472] = 'Parrying Rate gear ceiling is +50%.',
                [ 363] = 'Chance of Successful Block gear ceiling is +50%.',
                [ 134] = 'Magic Defense Bonus gear ceiling is +480.',
                [1152] = 'Defense gear ceiling is +3200.',
                [1157] = 'Spell Interruption Rate Down gear ceiling is +80%.',
                [  57] = 'Magic Critical Hit Rate gear ceiling is +100%.',
            }

            for _, itemId in ipairs(catalystOrder) do
                local def    = catalog[itemId]
                local count  = catalystCounts[itemId]
                local base   = def.base or 0
                local mult   = (def.mult and def.mult > 1) and def.mult or 1
                local disp   = (def.disp and def.disp > 1) and def.disp or 1

                local hasAff = def.cat and affinity.hasAffinity(player, def.cat) or false

                -- TIER ROLL (per slot). Your Augment Tier's slice of the 5-bit
                -- space is the band; every catalyst rolls its own number in it:
                --   floor    = slice.min + Sage mastery rank (0-5)
                --   affinity = roll twice, keep the better
                --   crit     = slice.max (a PERFECT roll, all slots this trade)
                -- Tier bands never overlap, so a T3 line always beats any T2 line.
                -- maxBoost-capped stats (fixed augments like Treasure Hunter,
                -- All songs) clamp the roll as before.
                local slice     = TIER_SLICES[playerTier] or TIER_SLICES[1]
                local rollFloor = math.min(slice.min + rank, slice.max)
                -- Boost ceiling. Rather than HARD-capping the 0-31 roll at maxBoost
                -- (which saturated every tier band above the cap, so low-ceiling
                -- stats -- Quad Attack, Triple Attack, Refresh, ... -- landed the
                -- SAME value at T2..T5), SCALE the roll into the augment's
                -- [0, maxBoost] range. Each Augment Tier then lands a DISTINCT step
                -- of that ceiling instead of all piling on the max. Uncapped
                -- augments (maxBoost == EXDATA_VALUE_MAX = 31) scale 1:1 -> unchanged.
                local boostCap  = def.maxBoost and math.min(EXDATA_VALUE_MAX, def.maxBoost) or EXDATA_VALUE_MAX
                local function scaleRoll(raw)
                    return math.floor(raw * boostCap / EXDATA_VALUE_MAX + 0.5)
                end
                local slotMax   = scaleRoll(slice.max)   -- the achievable "perfect" (crystalize) value this tier
                local rolls     = {}
                if def.tierValue or def.flatValue then
                    -- Single-line augments (Treasure Hunter, All songs, ...):
                    --   tierValue -> value = tierValue * playerTier
                    --                (Treasure Hunter used this pre-2026-07-19;
                    --                 All songs still does; grows with tier)
                    --   flatValue -> value = flatValue (constant across tiers)
                    -- Both encode the written boost as (target - base) so the
                    -- engine's (base + boost) renders exactly `target`.
                    -- Deterministic: no roll, affinity, or crit. Both are
                    -- always crystalize-eligible (a flatValue line is
                    -- already at its cap; a tierValue line becomes eligible
                    -- when it matches its final T5 form).
                    local target = def.flatValue or (def.tierValue * playerTier)
                    slotMax = (def.flatValue or (def.tierValue * #TIER_SLICES)) - base
                    for _ = 1, count do
                        table.insert(rolls, target - base)
                    end
                else
                    for _ = 1, count do
                        local r = math.random(rollFloor, slice.max)
                        if hasAff then
                            r = math.max(r, math.random(rollFloor, slice.max))
                        end
                        if isCrit then
                            r = slice.max
                        end
                        table.insert(rolls, scaleRoll(r))
                    end
                end

                -- Emit ONE augment slot PER CATALYST into the FINAL layout (after
                -- the preserved crystalized slots). The engine sums each slot's
                -- modValue, so N catalysts deliver N x (base + boost) * mult.
                --
                -- CRYSTALIZE (two-part, per the design post):
                --   (1) the slot must roll its MAXIMUM value (slotMax, > 0), then
                --   (2) a second roll at the Sage-rank crystalize chance locks it.
                -- A crystalized slot's bit is set in newMask so it's preserved on
                -- future re-rolls until scoured.
                for _, r in ipairs(rolls) do
                    table.insert(exAugsBySlot, {
                        id    = def.augId,
                        value = r,
                        cat   = def.cat,
                    })
                    local slotIndex0 = #exAugsBySlot - 1
                    if slotMax > 0 and r == slotMax and math.random() < crystalPct then
                        newMask = bit.bor(newMask, bit.lshift(1, slotIndex0))
                        table.insert(crystalNews, def.label)
                    end
                end

                -- Build the label so the player sees what actually lands.
                -- Real per-slot value the engine will apply (matches !augstats):
                --   (base + boost) * mult / disp, with base/mult/disp the EFFECTIVE
                --   live values from augment_catalog.lua (disp divides stored-xN mods
                --   like damage-taken /100 back to a meaningful number).
                local vals, total = {}, 0
                for _, r in ipairs(rolls) do
                    local v = math.floor((base + r) * mult / disp + 0.5)
                    table.insert(vals, tostring(v))
                    total = total + v
                end
                local valStr = (count > 1)
                    and string.format('  ->  %s = %d total', table.concat(vals, '+'), total)
                    or  string.format('  ->  %s', vals[1])
                local rollStr = (boostCap > 0)
                    and string.format('  [T%d roll%s %s/%d%s]',
                        playerTier,
                        count > 1 and 's' or '',
                        table.concat(rolls, ','),
                        math.min(slice.max, boostCap),
                        hasAff and ' +affinity' or '')
                    or  ''

                local label = string.format('%s%s%s', def.label, valStr, rollStr)
                table.insert(labelSummary, label)
                table.insert(catalystsHeld, { id = itemId, qty = count })

                -- Surface any engine-cap warning for this augId, once
                -- per trade regardless of how many catalysts of the
                -- same type were used.
                local capMsg = CAPPED_MOD_AUGS[def.augId]
                if capMsg then capWarnings[capMsg] = true end
            end

            -- Clear any previous pending session
            local existing = getState(player)
            if existing.itemId ~= 0 then
                returnAll(player)
                player:printToPlayer('Returning your previous item and catalysts first, kupo!', xi.msg.channel.SYSTEM_3)
            end

            -- Consume all items in the trade window. Using tradeComplete
            -- instead of confirmSlot+confirmTrade because tradeComplete
            -- explicitly setReserve(0) on every slot - the confirm pattern
            -- only subtracts confirmed quantity, so any slot that misses a
            -- confirmSlot call leaks its reserve forever after Clean wipes
            -- the container (see src/map/lua/lua_baseentity.cpp:5072 vs
            -- :5117). We always consume everything traded, so there's no
            -- reason to use the partial-acceptance pattern.
            player:tradeComplete()

            playerState[player:getName()] =
            {
                itemId        = gearId,
                exAugsBySlot  = exAugsBySlot,    -- {id,value,cat} per FINAL slot (locked first)
                labelSummary  = labelSummary,    -- one string per catalyst type
                catalystsHeld = bankMode and {} or catalystsHeld,
                bankCatalysts = bankMode and selectedBankCatalysts or nil,
                bankConsumed  = false,
                isCrit        = isCrit,          -- for the confirm screen
                usedCritToken = usedCritToken,   -- consume Maat's Blessing on success
                newMask       = newMask,         -- lock bitmask to stamp on the rebuilt item
                crystalNews   = crystalNews,     -- crystalized labels to announce
            }
            if bankMode then
                clearBankSelection(player)
            end

            if lockedCount > 0 then
                player:printToPlayer(string.format('%d crystalized slot%s preserved. New rolls fill the rest -- results revealed on confirm, kupo!',
                    lockedCount, lockedCount == 1 and '' or 's'), xi.msg.channel.SYSTEM_3)
            else
                player:printToPlayer('Catalysts accepted! Confirm below to apply the augmentation -- results revealed on confirm, kupo!',
                    xi.msg.channel.SYSTEM_3)
            end
            if not canCrystalize then
                player:printToPlayer('  (This piece is inscribable, so its augments cannot crystalize/lock, kupo.)', xi.msg.channel.SYSTEM_3)
            end

            -- Engine-cap warnings - printed once per distinct warning,
            -- after the trade summary so the player can see them in
            -- the confirmation flow. These are informational only
            -- (we don't refuse the trade); the player decides whether
            -- the cap risk is worth it. Sorted for stable presentation
            -- across trades.
            local capLines = {}
            for msg, _ in pairs(capWarnings) do
                table.insert(capLines, msg)
            end
            table.sort(capLines)
            for _, msg in ipairs(capLines) do
                player:printToPlayer('  Note: ' .. msg, xi.msg.channel.SYSTEM_3)
            end

            showConfirmMenu(player)
        end,
    })
    utils.unused(AugmentMoogle)
end)

return m
