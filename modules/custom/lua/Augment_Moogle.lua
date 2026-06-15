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
-- Zone: GM Home (zone 210)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
local catalog  = require('modules/custom/lua/augment_catalog')
local sage     = require('modules/custom/lua/augment_sage_catalog')
local affinity = require('modules/custom/lua/augment_affinity_catalog')
local wh       = require('modules/custom/lua/weekly_hunts')
-----------------------------------
local m = Module:new('augment_moogle')

local MAX_CATALYST_COUNT = 5       -- max catalyst items per trade = the engine's 5 augment slots (each catalyst writes one line; mix types or stack one)
local GIL_COST           = 10000   -- flat per trade

-- Augment formula recap (from src/map/items/item_equipment.cpp:479):
--   final_mod = (base + exdata) * (multiplier > 1 ? multiplier : 1)   -- positive base
--   final_mod = (base - exdata) * ...                                 -- negative base
-- For multiplier <= 1 (vast majority), passing exdata = |base| * (N-1)
-- multiplies the resulting stat by N. So 4 darkness spheres giving MP+97
-- as a 1-catalyst trade now give MP+388 with exdata = 97*3 = 291.
--
-- BOOST FORMULA (Augment Sage side-quest):
--   mastery   = sage.masteryMult[Augment_Mastery + 1]    -- 1.0 .. 2.0
--   affinity  = hasAffinity(cat) ? affinity.affinityMult : 1.0  -- 1.0 or 1.5
--   crit      = math.random() < sage.critChance[mastery_rank+1] ? 2.0 : 1.0
--   totalMult = mastery * affinity * crit
--   exdata    = base * (count * totalMult - 1)
-- The crit is rolled once per trade and applies to all selections that
-- trade (so the player sees one big "Critical augment!" message rather
-- than per-augment surprises). Affinity is per-augment, since each
-- selection may have a different `cat`.

-----------------------------------
-- Per-player state
-- playerState[charName] = {
--   itemId        = gear item ID held by the moogle
--   exAugsBySlot  = { {id, value, cat}, ... }   (one entry per slot;
--                   passed straight to addItem.exdata.augments)
--   labelSummary  = { 'Accuracy +33 x4', ... }   (one string per unique
--                   catalyst type; used for player-facing messaging)
--   catalystsHeld = { {id, qty}, ... }   (for return on cancel)
--   isCrit        = bool                  (whether this trade rolled a crit)
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

-----------------------------------
-- Forward declaration
-----------------------------------
local showConfirmMenu

local menu = { title = '', options = {} }

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
                    returnAll(playerArg)
                    playerArg:printToPlayer('Augmentation failed - gear and catalysts returned, no gil charged, kupo!', xi.msg.channel.SYSTEM_3)
                    return
                end

                playerArg:delGil(GIL_COST)

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
                clearState(playerArg)
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
    menu.title = 'Apply this augment, kupo?'
    menu.options = options
    local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
    player:timer(30, function(p) p:customMenu(snapshot) end)
end

-----------------------------------
-- Module override
-----------------------------------
m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local AugmentMoogle = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Augment_Moogle',
        packetName = string.format('%sAugment Moogle', xi.icon.STAR_LARGE),
        look       = 2401,
        -- GM Home Progression cluster (z=-7): Gear / Augment Moogle / Augment Sage.
        x          =  -4.500,
        y          =  0.000,
        z          = -5.000,
        rotation   =  128,
        widescan   =  1,

        onTrigger = function(player, npc)
            local st = getState(player)
            if st.itemId ~= 0 then
                player:printToPlayer('You have an item awaiting augmentation, kupo!', xi.msg.channel.SYSTEM_3)
                showConfirmMenu(player)
                return
            end
            player:printToPlayer(string.format('[ Augment Moogle ] Trade me 1 piece of gear + up to %d catalyst items (incl. stacks), kupo!', MAX_CATALYST_COUNT), xi.msg.channel.SYSTEM_3)
            player:printToPlayer('  Each catalyst = 1 augment line, up to 5 per item -- stack one type (5 of one = 5x) or mix several. Cost: 10,000 gil.', xi.msg.channel.SYSTEM_3)
            player:printToPlayer('  See modules/custom/lua/augment_catalog.lua for the full item -> augment list.', xi.msg.channel.SYSTEM_3)
        end,

        onTrade = function(player, npc, trade)
            local gearId         = nil
            local catalystCounts = {}    -- itemId -> total count (sums across slots + stack qty)
            local catalystOrder  = {}    -- first-seen order so the menu reads naturally
            local totalCatalysts = 0     -- sum of all catalyst counts

            -- Scan slots. Multiple slots of the same catalyst stack into one
            -- selection; a slot containing a stack of N counts as N catalysts.
            for slot = 0, 7 do
                local tradeItem = trade:getItem(slot)
                if tradeItem then
                    local itemId = tradeItem:getID()
                    local qty    = trade:getSlotQty(slot)
                    if qty == nil or qty < 1 then qty = 1 end
                    local def    = catalog[itemId]

                    if def then
                        if not catalystCounts[itemId] then
                            catalystCounts[itemId] = 0
                            table.insert(catalystOrder, itemId)
                        end
                        catalystCounts[itemId] = catalystCounts[itemId] + qty
                        totalCatalysts         = totalCatalysts + qty

                    elseif gearId == nil then
                        gearId = itemId

                    else
                        player:printToPlayer('Trade 1 equipment piece + catalyst items only, kupo! (one of those items is not a catalyst)', xi.msg.channel.SYSTEM_3)
                        return
                    end
                end
            end

            if gearId == nil then
                player:printToPlayer('Include 1 equipment piece in the trade, kupo!', xi.msg.channel.SYSTEM_3)
                return
            end

            if totalCatalysts == 0 then
                player:printToPlayer('Include at least 1 catalyst item, kupo!', xi.msg.channel.SYSTEM_3)
                return
            end

            if totalCatalysts > MAX_CATALYST_COUNT then
                player:printToPlayer(string.format('Max %d catalysts per trade (you traded %d), kupo!', MAX_CATALYST_COUNT, totalCatalysts), xi.msg.channel.SYSTEM_3)
                return
            end

            if player:getGil() < GIL_COST then
                player:printToPlayer(string.format('You need %d gil to augment, kupo!', GIL_COST), xi.msg.channel.SYSTEM_3)
                return
            end

            -- Read the player's Sage-quest state ONCE for the trade. The
            -- mastery rank dictates the global multiplier + the crit roll;
            -- the affinity bitfield is consulted per-augment because each
            -- selection may belong to a different category.
            local rank        = player:getCharVar('Augment_Mastery') or 0
            local masteryMult = sage.masteryMult[rank + 1] or 1.0
            local critPct     = sage.critChance[rank + 1]  or 0.0
            local isCrit      = math.random() < critPct
            local critMult    = isCrit and 2.0 or 1.0

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
            local exAugsBySlot     = {}    -- one entry per slot, ready for addItem
            local labelSummary     = {}    -- one human-readable string per catalyst type
            local catalystsHeld    = {}
            local capWarnings      = {}    -- de-duped engine-cap warnings to show after the trade summary

            -- Engine-mod cap lookup: augId -> human-readable warning string.
            -- Populated from a manual cross-reference of sql/augments.sql
            -- with the clamps in src/map/utils/battleutils.cpp and
            -- src/map/entities/battleentity.cpp (see the audit notes
            -- in the project memory for the file:line citations). When a
            -- player trades for one of these augIds, we surface the cap
            -- once so they can see whether their stack will be partly
            -- wasted against existing gear that already approaches the
            -- limit. The cap is per-character TOTAL across all gear, not
            -- per-augment, so the warning is purely informational.
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
            }

            for _, itemId in ipairs(catalystOrder) do
                local def    = catalog[itemId]
                local count  = catalystCounts[itemId]
                local base   = def.base or 0
                local mult   = (def.mult and def.mult > 1) and def.mult or 1
                local disp   = (def.disp and def.disp > 1) and def.disp or 1

                local affMult = (def.cat and affinity.hasAffinity(player, def.cat))
                    and affinity.affinityMult or 1.0
                local totalMult = masteryMult * affMult * critMult

                -- Per-slot exdata = the ACHIEVEMENT boost only (Sage mastery x
                -- affinity x crit), mapped linearly across the full 5-bit range
                -- (0..EXDATA_VALUE_MAX). It NO LONGER scales off the augment's
                -- base: a high base (e.g. HP 97) used to blow past 31 the instant
                -- totalMult rose above ~1.3, pinning the boost and silently
                -- wasting your rank / affinity / crit. Now the boost is pure
                -- achievement progress, and each augment's floor + cap come from
                -- its value+multiplier in sql/augments.sql:
                --     final/slot = (value + boost) * multiplier
                --     floor = value*mult  (no achievements)
                --     cap   = (value+31)*mult  (rank5 + affinity + crit)
                local maxTotalMult  = (sage.masteryMult[#sage.masteryMult] or 2.0)
                                        * (affinity.affinityMult or 1.5) * 2.0  -- rank5 x affinity x crit
                local progress      = (maxTotalMult > 1) and ((totalMult - 1) / (maxTotalMult - 1)) or 0
                local rawExdata     = math.floor(progress * EXDATA_VALUE_MAX + 0.5)
                local perSlotExdata = math.min(math.max(rawExdata, 0), EXDATA_VALUE_MAX)

                -- Emit ONE augment slot PER CATALYST: 4 catalysts of one type
                -- write 4 slots of the same augId. The engine sums each slot's
                -- modValue, so N catalysts deliver N x (base + boost) * mult --
                -- the "4-slot piece" the docs + !augstats assume (e.g. HP base 1
                -- mult 4 at rank-5: 4 x (1+31) x 4 = 512). Equipment has 5 augment
                -- slots; MAX_CATALYST_COUNT keeps us within that budget.
                --
                -- NOTE: writing the same augId across multiple slots was suspected
                -- of making the client reject the item, but that was never proven
                -- (the confirm-menu byte overflow, now fixed, was the real cause of
                -- the "lost gear"). Re-testing the 4-slot path per owner request.
                for _ = 1, count do
                    table.insert(exAugsBySlot, {
                        id    = def.augId,
                        value = perSlotExdata,
                        cat   = def.cat,
                    })
                end

                -- Build the label so the player sees what actually lands.
                --
                -- Old behavior (pre-2026-05-29 audit):
                --   "Attack +33 x4 (6.0x)" - implied 4 * 33 * 6 = 792 ATT.
                -- Actual delivery:
                --   the exdata Value field is 5 bits wide (uint16_t Value : 5
                --   in src/map/items/exdata/augment_standard.h:34), max 31.
                --   For base=33 at 6.0x, rawExdata=165 clips to 31, so each
                --   slot writes only (33 + 31) = 64. The "6.0x" claim is a
                --   ~1.94x reality.
                --
                -- New labeling rule:
                --   * No boost (totalMult ~ 1) -> simple "Label xN" line.
                --   * Boost fits within the 5-bit cap -> keep "(Mx)" so the
                --     veteran-eye intuition holds.
                --   * Boost CLIPPED by the 5-bit cap -> drop the (Mx) lie
                --     and show the per-slot magnitude that will actually
                --     be written, plus the total. Player can decide
                --     whether to commit knowing the real return.
                -- Honest mastery-charge meter: how much of the 0..EXDATA_VALUE_MAX
                -- achievement boost (rank x affinity x crit) THIS trade landed.
                -- Replaces the old "(6.0x)" multiplier claim -- the boost is an
                -- ADDITIVE 0..31, not a multiplier; each augment's value +
                -- multiplier (sql/augments.sql) set the real floor and cap.
                -- Real per-slot value the engine will apply (matches !augstats):
                --   (base + boost) * mult / disp, with base/mult/disp the EFFECTIVE
                --   live values from augment_catalog.lua (disp divides stored-xN mods
                --   like damage-taken /100 back to a meaningful number). Show it so
                --   the trade message matches reality, not the old flat label number.
                local perSlotVal = math.floor((base + perSlotExdata) * mult / disp + 0.5)
                local valStr     = (count > 1)
                    and string.format('  ->  %d/slot x%d = %d total', perSlotVal, count, perSlotVal * count)
                    or  string.format('  ->  %d', perSlotVal)
                local boostStr   = string.format('  [boost %d/%d]', perSlotExdata, EXDATA_VALUE_MAX)

                local label = string.format('%s%s%s', def.label, valStr, boostStr)
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

            -- Surface the crit and any boosts to the player BEFORE they
            -- confirm, so they know what they're committing to.
            if isCrit then
                player:printToPlayer('** Critical augment! ** Catalyst potency doubled for this trade.',
                    xi.msg.channel.SYSTEM_3)
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
                exAugsBySlot  = exAugsBySlot,    -- {id,value,cat} per slot
                labelSummary  = labelSummary,    -- one string per catalyst type
                catalystsHeld = catalystsHeld,
                isCrit        = isCrit,  -- for the confirm screen
            }

            player:printToPlayer(
                string.format('Catalysts accepted! Will apply: [%s], kupo!', table.concat(labelSummary, '] [')),
                xi.msg.channel.SYSTEM_3
            )

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
