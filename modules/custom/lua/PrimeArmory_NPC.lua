-----------------------------------
-- PrimeArmory_NPC.lua
-- "Prime Armory" -- a GM Home NPC where players forge a Prime Weapon by
-- completing the five Prime Weapon Trials:
--
--   Trial 1 (PW_Trial1_Done)  Turn in 12 each of the 20 Abyssea collectibles
--   Trial 2 (PW_Trial2_Done)  Clear floor 50 of the Endless Tower
--   Trial 3 (PW_Trial3_Done)  Turn in a Prime Voucher (rare Hunting League drop)
--   Trial 4 (PW_Trial4_Done)  Defeat any Weapon Guardian (Job Mastery)
--   Trial 5 (PW_Trial5_Done)  Turn in 99 each of three Aht Urhgan currencies
--
-- Once all five are complete the player may claim ONE Prime weapon of their
-- choice. Claiming sets PW_WeaponClaimed = item_id (0 = none yet).
--
-- The claim list is the 16 retail Stage-5 Primes (Level 119 III -- the final
-- form of each type, owner-corrected 2026-07-13; the old list mixed Stage-1
-- placeholders, a Stage-4 Varga/Mpu, and Naegling, which is not a Prime).
-- Each weapon's ADDS_WEAPONSKILL mod (modules/custom/sql/prime_weapons_gear.sql,
-- Stage-5 block) unlocks its weapon skill on equip; types whose true Prime WS
-- is not in the engine substitute the type's flagship WS (see that file).
--
-- Zone: GM Home (zone 210).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local m = Module:new('prime_armory')

local TRIALS =
{
    { var = 'PW_Trial1_Done', label = 'Trial 1', desc = '12 each of all 20 Abyssea collectibles (turn in here)' },
    { var = 'PW_Trial2_Done', label = 'Trial 2', desc = 'Endless Tower floor 50' },
    { var = 'PW_Trial3_Done', label = 'Trial 3', desc = 'Prime Voucher (Maze Monger Crown) - rare Hunting League NM drop (turn in here)' },
    { var = 'PW_Trial4_Done', label = 'Trial 4', desc = 'Weapon Guardian defeated (Job Mastery)' },
    { var = 'PW_Trial5_Done', label = 'Trial 5', desc = '99 each of Jadeshell, Silverpiece & 100 Byne Bill (turn in here)' },
}

local WEAPONS =
{
    -- The 16 retail Stage-5 Primes (Level 119 III), one per weapon type.
    -- ids = the final stage of each name run in item_basic; stats + WS links
    -- live in prime_weapons_gear.sql (Stage-5 block).
    { id = 21535, name = 'Varga Purnikawa', ws = 'Maru Kala',        info = 'Hand-to-Hand. STR/DEX, Acc, Att, Store TP, Double Attack.' },
    { id = 21590, name = 'Mpu Gandring',    ws = 'Merciless Strike', info = 'Dagger. DEX/AGI, Acc, Att, Store TP, Double Attack.' },
    { id = 21646, name = 'Caliburnus',      ws = 'Imperator',        info = 'Sword. STR/DEX, Acc, Att, Store TP, Double Attack.' },
    { id = 21653, name = 'Helheim',         ws = 'Resolution',       info = 'Great Sword. STR/VIT, Acc, Att, Store TP, Double Attack.' },
    { id = 21730, name = 'Spalirisos',      ws = 'Decimation',       info = 'Axe. STR/DEX, Acc, Att, Store TP, Double Attack.' },
    { id = 21785, name = 'Laphria',         ws = 'Disaster',         info = 'Great Axe. STR/VIT, Acc, Att, Store TP, Double Attack.' },
    { id = 21837, name = 'Foenaria',        ws = 'Origin',           info = 'Scythe. STR/INT, Acc, Att, Store TP, Double Attack.' },
    { id = 21891, name = 'Gae Buide',       ws = 'Diarmuid',         info = 'Polearm. STR/VIT, Acc, Att, Store TP, Double Attack.' },
    { id = 21932, name = 'Dokoku',          ws = '(native katana WS)'  , info = 'Katana. DEX/AGI, Acc, Att, Store TP, Double Attack.' },
    { id = 21986, name = 'Kusanagi',        ws = 'Tachi: Mumei',     info = 'Great Katana. STR/DEX, Acc, Att, Store TP, Double Attack.' },
    { id = 22002, name = 'Lorg Mor',        ws = 'Dagda',            info = 'Club. STR/MND, Acc, Att, Store TP, Double Attack.' },
    { id = 22106, name = 'Opashoro',        ws = 'Oshala',           info = 'Staff. INT/MND, Magic Acc/Att, Magic Dmg, Acc, Att.' },
    { id = 22163, name = 'Pinaka',          ws = 'Sarv',             info = 'Archery. AGI/STR, Ranged Acc/Att, Store TP, Rapid Shot. Needs arrows.' },
    { id = 22164, name = 'Earp',            ws = 'Terminus',         info = 'Marksmanship. AGI/DEX, Ranged Acc/Att, Store TP, Rapid Shot. Needs bullets.' },
    { id = 26495, name = 'Duban',           ws = '(shield -- no WS)', info = 'Shield. DEF+150, HP+300, VIT, Magic Evasion. Sub slot.' },
    { id = 22307, name = 'Loughnashade',    ws = '(harp -- no WS)',  info = 'Harp. CHR, Magic Acc, HP/MP. BRD song support. Range slot.' },
}

-----------------------------------
-- Trial 1: collect 12 EACH of the 20 Abyssea "five elements" collectibles
-- (Stone/Coin/Jewel/Card of Vision/Ardor/Wieldance/Balance/Voyage -- they drop
-- from Abyssea NMs). Turned in at this NPC, which CONSUMES all 240 and stamps
-- PW_Trial1_Done. itemIds are contiguous 3210..3229, grouped by element below.
-----------------------------------
local T1_REQUIRED = 12
local T1_SETS =
{
    { name = 'Vision',    types = { { id = 3210, t = 'Stone' }, { id = 3211, t = 'Coin' }, { id = 3212, t = 'Jewel' }, { id = 3213, t = 'Card' } } },
    { name = 'Ardor',     types = { { id = 3214, t = 'Stone' }, { id = 3215, t = 'Coin' }, { id = 3216, t = 'Jewel' }, { id = 3217, t = 'Card' } } },
    { name = 'Wieldance', types = { { id = 3218, t = 'Stone' }, { id = 3219, t = 'Coin' }, { id = 3220, t = 'Jewel' }, { id = 3221, t = 'Card' } } },
    { name = 'Balance',   types = { { id = 3222, t = 'Stone' }, { id = 3223, t = 'Coin' }, { id = 3224, t = 'Jewel' }, { id = 3225, t = 'Card' } } },
    { name = 'Voyage',    types = { { id = 3226, t = 'Stone' }, { id = 3227, t = 'Coin' }, { id = 3228, t = 'Jewel' }, { id = 3229, t = 'Card' } } },
}

-- Trial 3: turn in ONE Prime Voucher -- now the Maze Monger Crown (item 3038, a real
-- Rare/Ex item with proper client art; the old custom 29699 rendered as a blank item).
-- A ~1% drop from Hunting League NMs (HuntingLeague.lua onMobDeath), also grantable via
-- the !primevoucher command. The legacy 29699 voucher is still accepted at turn-in below
-- so anyone who already earned one isn't stranded.
local T3_ITEM        = 3038    -- Maze Monger Crown (Rare/Ex) -- the Prime Voucher
local T3_ITEM_LEGACY = 29699   -- old blank custom voucher, still accepted at turn-in

-- Trial 5: collect 99 EACH of three Aht Urhgan Assault currencies (stack to 99).
-- Turned in here, which CONSUMES all 297 (99 x 3) and stamps PW_Trial5_Done.
local T5_REQUIRED = 99

local GIL_COST = 750000000
local T5_ITEMS =
{
    { id = 1450, name = 'Lungo-Nango Jadeshell' },
    { id = 1453, name = 'Montiont Silverpiece'  },
    { id = 1456, name = '100 Byne Bill'         },
}

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local function sendMenu(player, menu)
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local showMain

    -- customMenu cap ~150 bytes across title + ALL labels. 4 items/page keeps
    -- every page under the cap (worst case: 18 title + 107 labels = 125 bytes).
    local PAGE_SIZE = 4

    -----------------------------------
    -- Returns true if all trials are complete.
    -----------------------------------
    local function trialsComplete(player)
        for _, t in ipairs(TRIALS) do
            if (player:getCharVar(t.var) or 0) == 0 then return false end
        end
        return true
    end

    -----------------------------------
    -- Print trial status to the player (used on first talk when incomplete).
    -----------------------------------
    local function printTrialStatus(player)
        player:printToPlayer(string.format('[Prime Armory] Complete all %d trials and pay 750,000,000 gil to forge a Prime Weapon:', #TRIALS), xi.msg.channel.SYSTEM_3)
        for _, t in ipairs(TRIALS) do
            local done  = (player:getCharVar(t.var) or 0) == 1
            local icon  = done and '[+]' or '[ ]'
            player:printToPlayer(string.format('  %s %s - %s', icon, t.label, t.desc), xi.msg.channel.SYSTEM_3)
        end
    end

    -----------------------------------
    -- Trial 1: per-element collectible progress (chat, not menu -- 20 lines
    -- would blow the customMenu byte cap).
    -----------------------------------
    local function printTrial1Progress(player)
        player:printToPlayer(string.format(
            '[Prime Armory] Trial 1 - bring %d of EACH (Stone/Coin/Jewel/Card) for all five elements:', T1_REQUIRED),
            xi.msg.channel.SYSTEM_3)
        for _, set in ipairs(T1_SETS) do
            local parts = {}
            for _, ty in ipairs(set.types) do
                local have = player:getItemCount(ty.id)
                table.insert(parts, string.format('%s %s', ty.t, have >= T1_REQUIRED and '[+]' or tostring(have)))
            end
            player:printToPlayer(string.format('  %-10s %s', set.name .. ':', table.concat(parts, '  ')), xi.msg.channel.SYSTEM_3)
        end
    end

    -----------------------------------
    -- Trial 1 turn-in. Verifies 12 of every collectible, then consumes all 240.
    -- delItem only debits the FIRST main-inventory stack, and getItemCount spans
    -- ALL containers, so a split stack (some in satchel) could otherwise pass the
    -- check but under-consume -> a partly-free trial. We measure the ACTUAL
    -- removal via the count delta and REFUND on any shortfall (all-or-nothing).
    -----------------------------------
    local function turnInTrial1(player)
        if (player:getCharVar('PW_Trial1_Done') or 0) == 1 then
            player:printToPlayer('[Prime Armory] Trial 1 is already complete, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end

        -- Pass 1: every one of the 20 collectibles present in the required count.
        for _, set in ipairs(T1_SETS) do
            for _, ty in ipairs(set.types) do
                if player:getItemCount(ty.id) < T1_REQUIRED then
                    player:printToPlayer('[Prime Armory] Not yet - you still need more. Here is your tally:', xi.msg.channel.SYSTEM_3)
                    printTrial1Progress(player)
                    return
                end
            end
        end

        -- Pass 2: consume, measuring the real delta; refund all if any shortfall.
        local removed = {}
        local shortfall = false
        for _, set in ipairs(T1_SETS) do
            for _, ty in ipairs(set.types) do
                local before = player:getItemCount(ty.id)
                player:delItem(ty.id, T1_REQUIRED)
                local got = before - player:getItemCount(ty.id)
                removed[ty.id] = got
                if got < T1_REQUIRED then shortfall = true end
            end
        end

        if shortfall then
            for id, qty in pairs(removed) do
                if qty > 0 then player:addItem({ id = id, quantity = qty }) end
            end
            player:printToPlayer('[Prime Armory] I could not gather all of them - keep every collectible in your MAIN inventory (not satchel/case) and try again, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end

        player:setCharVar('PW_Trial1_Done', 1)
        player:printToPlayer('[Prime Armory] The offering of all five elements is accepted! Trial 1 complete, kupo!', xi.msg.channel.SYSTEM_3)
    end

    -----------------------------------
    -- Trial 3 turn-in: one Prime Voucher. Consume-and-verify so a split
    -- stack can't credit the trial without actually handing the item over.
    -----------------------------------
    local function turnInTrial3(player)
        if (player:getCharVar('PW_Trial3_Done') or 0) == 1 then
            player:printToPlayer('[Prime Armory] Trial 3 is already complete, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        -- Accept the new Maze Monger Crown (T3_ITEM) OR the legacy blank voucher
        -- (T3_ITEM_LEGACY), so anyone holding an old voucher isn't stranded.
        local voucherId
        if player:getItemCount(T3_ITEM) >= 1 then
            voucherId = T3_ITEM
        elseif player:getItemCount(T3_ITEM_LEGACY) >= 1 then
            voucherId = T3_ITEM_LEGACY
        end
        if not voucherId then
            player:printToPlayer('[Prime Armory] You need a Prime Voucher (a Maze Monger Crown) - a rare drop from Hunting League NMs - for Trial 3, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        local before = player:getItemCount(voucherId)
        player:delItem(voucherId, 1)
        if player:getItemCount(voucherId) >= before then
            player:printToPlayer('[Prime Armory] Keep the Prime Voucher in your MAIN inventory and try again, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        player:setCharVar('PW_Trial3_Done', 1)
        player:printToPlayer('[Prime Armory] The Prime Voucher is accepted! Trial 3 complete, kupo!', xi.msg.channel.SYSTEM_3)
    end

    -----------------------------------
    -- Trial 5: per-currency progress (chat).
    -----------------------------------
    local function printTrial5Progress(player)
        player:printToPlayer(string.format(
            '[Prime Armory] Trial 5 - bring %d of EACH currency:', T5_REQUIRED),
            xi.msg.channel.SYSTEM_3)
        for _, it in ipairs(T5_ITEMS) do
            local have = player:getItemCount(it.id)
            player:printToPlayer(string.format('  %-22s %s', it.name .. ':',
                have >= T5_REQUIRED and '[+]' or tostring(have)), xi.msg.channel.SYSTEM_3)
        end
    end

    -----------------------------------
    -- Trial 5 turn-in: 99 of each currency. Same consume-and-verify-with-refund
    -- guard as Trial 1 -- delItem only debits the first MAIN-inventory stack while
    -- getItemCount spans all containers, so a split/satchel stack can't credit the
    -- trial without actually handing the currency over. All-or-nothing.
    -----------------------------------
    local function turnInTrial5(player)
        if (player:getCharVar('PW_Trial5_Done') or 0) == 1 then
            player:printToPlayer('[Prime Armory] Trial 5 is already complete, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end

        -- Pass 1: all three currencies present in the required count.
        for _, it in ipairs(T5_ITEMS) do
            if player:getItemCount(it.id) < T5_REQUIRED then
                player:printToPlayer('[Prime Armory] Not yet - you still need more. Here is your tally:', xi.msg.channel.SYSTEM_3)
                printTrial5Progress(player)
                return
            end
        end

        -- Pass 2: consume, measuring the real delta; refund all on any shortfall.
        local removed = {}
        local shortfall = false
        for _, it in ipairs(T5_ITEMS) do
            local before = player:getItemCount(it.id)
            player:delItem(it.id, T5_REQUIRED)
            local got = before - player:getItemCount(it.id)
            removed[it.id] = got
            if got < T5_REQUIRED then shortfall = true end
        end

        if shortfall then
            for id, qty in pairs(removed) do
                if qty > 0 then player:addItem({ id = id, quantity = qty }) end
            end
            player:printToPlayer('[Prime Armory] I could not gather all of them - keep each currency as a single 99 stack in your MAIN inventory (not satchel/case) and try again, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end

        player:setCharVar('PW_Trial5_Done', 1)
        player:printToPlayer('[Prime Armory] The currency offering is accepted! Trial 5 complete, kupo!', xi.msg.channel.SYSTEM_3)
    end

    -----------------------------------
    -- Forge the selected weapon (one per player, ever).
    -----------------------------------
    local function claim(player, weapon)
        -- Guard: all trials must still be complete (in case a GM cleared them).
        if not trialsComplete(player) then
            player:printToPlayer('[Prime Armory] Trial requirement no longer met. Cannot forge.', xi.msg.channel.SYSTEM_3)
            return
        end
        -- Guard: one prime weapon per player.
        local alreadyClaimed = player:getCharVar('PW_WeaponClaimed') or 0
        if alreadyClaimed ~= 0 then
            -- Find the weapon name for the message.
            for _, w in ipairs(WEAPONS) do
                if w.id == alreadyClaimed then
                    player:printToPlayer(string.format(
                        '[Prime Armory] You already forged %s. Each hero may forge one Prime Weapon. Kupo!', w.name),
                        xi.msg.channel.SYSTEM_3)
                    return
                end
            end
            player:printToPlayer('[Prime Armory] You have already forged a Prime Weapon. Kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        -- Inventory check.
        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer('[Prime Armory] Your inventory is full - free a slot first! Kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        -- Gil cost.
        if player:getGil() < GIL_COST then
            player:printToPlayer(string.format(
                '[Prime Armory] Forging requires 750,000,000 gil. You have %d gil. Kupo!',
                player:getGil()), xi.msg.channel.SYSTEM_3)
            return
        end
        -- Forge!
        player:delGil(GIL_COST)
        player:setCharVar('PW_WeaponClaimed', weapon.id)
        player:addItem({ id = weapon.id, quantity = 1 })
        if weapon.ws then
            player:printToPlayer(string.format(
                '[Prime Armory] %s has been forged! Equip it to unlock the weapon skill %s. Kupo!',
                weapon.name, weapon.ws), xi.msg.channel.SYSTEM_3)
        else
            player:printToPlayer(string.format(
                '[Prime Armory] %s has been forged! Kupo!', weapon.name), xi.msg.channel.SYSTEM_3)
        end
    end

    -----------------------------------
    -- Per-weapon detail + confirm menu.
    -----------------------------------
    local function showWeapon(player, weapon, page)
        if weapon.ws then
            player:printToPlayer(string.format('[Prime Armory] %s - Weapon Skill: %s', weapon.name, weapon.ws), xi.msg.channel.SYSTEM_3)
        else
            player:printToPlayer(string.format('[Prime Armory] %s (Stage-5 Relic)', weapon.name), xi.msg.channel.SYSTEM_3)
        end
        player:printToPlayer('  ' .. weapon.info, xi.msg.channel.SYSTEM_3)
        local claimed = player:getCharVar('PW_WeaponClaimed') or 0
        if claimed ~= 0 then
            player:printToPlayer('[Prime Armory] You have already forged a Prime Weapon. Each hero gets one.', xi.msg.channel.SYSTEM_3)
        else
            player:printToPlayer(string.format(
                '[Prime Armory] Cost to forge: 750,000,000 gil  (you have %d)', player:getGil()),
                xi.msg.channel.SYSTEM_3)
        end

        sendMenu(player, {
            title   = weapon.name,
            options =
            {
                { 'Forge this weapon', function(p) claim(p, weapon) end },
                { '<< Back',           function(p) showMain(p, page) end },
            },
        })
    end

    -----------------------------------
    -- Paginated weapon browse menu.
    -----------------------------------
    showMain = function(player, page)
        page = page or 1
        local totalPages = math.ceil(#WEAPONS / PAGE_SIZE)
        local startIdx   = (page - 1) * PAGE_SIZE + 1
        local endIdx     = math.min(startIdx + PAGE_SIZE - 1, #WEAPONS)

        local options = {}
        for i = startIdx, endIdx do
            local weapon = WEAPONS[i]
            table.insert(options, {
                string.format('%s [%s]', weapon.name, weapon.ws),
                function(p) showWeapon(p, weapon, page) end,
            })
        end

        if page < totalPages then
            table.insert(options, { 'Next >>',  function(p) showMain(p, page + 1) end })
        end
        if page > 1 then
            table.insert(options, { '<< Prev',  function(p) showMain(p, page - 1) end })
        end

        local title = totalPages > 1
            and string.format('Prime Armory (%d/%d)', page, totalPages)
            or  'Prime Armory'
        sendMenu(player, { title = title, options = options })
    end

    -----------------------------------
    -- NPC entity.
    -----------------------------------
    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Prime_Armory',
        packetName = string.format('%sPrime Armory', xi.icon.STAR_LARGE),
        look       = 216,
        x          =  584.971,
        y          =   -3.360,
        z          =  526.586,
        rotation   =  192,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('[Prime Armory] Talk to me to forge your Prime Weapon, kupo!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            local claimed = player:getCharVar('PW_WeaponClaimed') or 0
            if claimed ~= 0 then
                for _, w in ipairs(WEAPONS) do
                    if w.id == claimed then
                        player:printToPlayer(string.format(
                            '[Prime Armory] You have forged %s. Each hero may forge one Prime Weapon. Kupo!', w.name),
                            xi.msg.channel.SYSTEM_3)
                        return
                    end
                end
            end

            if not trialsComplete(player) then
                printTrialStatus(player)
                -- Trials 1, 3 and 5 are turned in HERE; Trials 2 and 4 are earned
                -- out in the world (Endless Tower / Weapon Guardian).
                local opts = {}
                if (player:getCharVar('PW_Trial1_Done') or 0) == 0 then
                    table.insert(opts, { string.format('Trial 1: turn in (%d each x20)', T1_REQUIRED), function(p) turnInTrial1(p) end })
                    table.insert(opts, { 'Trial 1: what do I still need?',                             function(p) printTrial1Progress(p) end })
                end
                if (player:getCharVar('PW_Trial3_Done') or 0) == 0 then
                    table.insert(opts, { 'Trial 3: turn in Voucher', function(p) turnInTrial3(p) end })
                end
                if (player:getCharVar('PW_Trial5_Done') or 0) == 0 then
                    table.insert(opts, { 'Trial 5: turn in (x3)', function(p) turnInTrial5(p) end })
                end
                table.insert(opts, { 'Close', function(p) end })
                if #opts > 1 then
                    -- Short title so title + all labels stay under the ~150-byte
                    -- customMenu cap even with every trial still pending.
                    sendMenu(player, { title = 'Prime Trials', options = opts })
                end
                return
            end

            -- All trials done and no weapon claimed yet - show the forge menu.
            player:printToPlayer(string.format('[Prime Armory] All %d trials complete! Choose your Prime Weapon (costs 750,000,000 gil). Kupo!', #TRIALS), xi.msg.channel.SYSTEM_3)
            showMain(player)
        end,
    })
end)

return m
