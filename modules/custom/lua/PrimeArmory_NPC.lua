-----------------------------------
-- PrimeArmory_NPC.lua
-- "Prime Armory" -- a GM Home NPC where players can SEE the seven Prime
-- weapons, but can only claim one by trading a Prime Voucher (item 29699),
-- which a GM grants at their discretion (!additem 29699).
--
-- Each Prime weapon's ADDS_WEAPONSKILL mod unlocks its Prime weapon skill the
-- moment it is equipped (wired in modules/custom/sql/prime_weapons_gear.sql):
--   Prime Fists      -> Dragon Blow        Mpu Gandring -> Merciless Strike
--   Varga Purnikawa  -> Maru Kala          Naegling     -> Fast Blade II
--   Prime Sword      -> Imperator          Prime Maul   -> Dagda
--   Prime Staff      -> Oshala
--
-- Flow: talk -> pick a weapon -> see its details -> confirm (spends 1 voucher).
-- Zone: GM Home (zone 210).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
-----------------------------------
local m = Module:new('prime_armory')

local VOUCHER = 29699

-- The grantable Prime weapons. `info` lines are shown when a player inspects
-- the weapon so they know what they are claiming before spending a voucher.
local WEAPONS =
{
    { id = 21531, name = 'Prime Fists',     ws = 'Dragon Blow',      info = 'Hand-to-Hand. STR/DEX, Acc, Att, Store TP, Double Attack.' },
    { id = 21534, name = 'Varga Purnikawa', ws = 'Maru Kala',        info = 'Hand-to-Hand. STR/DEX, Acc, Att, Store TP, Double Attack.' },
    { id = 21589, name = 'Mpu Gandring',    ws = 'Merciless Strike', info = 'Dagger. DEX/AGI, Acc, Att, Store TP, Double Attack.' },
    { id = 21621, name = 'Naegling',        ws = 'Fast Blade II',    info = 'Sword. STR/DEX, Acc, Att, Store TP, Double Attack.' },
    { id = 21642, name = 'Prime Sword',     ws = 'Imperator',        info = 'Sword. STR/DEX/MND, Acc, Att, Store TP, Double Attack.' },
    { id = 21999, name = 'Prime Maul',      ws = 'Dagda',            info = 'Club. STR/MND, Acc, Att, Store TP, Double Attack.' },
    { id = 22102, name = 'Prime Staff',     ws = 'Oshala',           info = 'Staff. INT/MND, Magic Acc/Att, Magic Dmg, Acc, Att.' },
    { id = 21781, name = 'Prime Great Axe', ws = 'Disaster',         info = 'Great Axe. STR/VIT, Acc, Att, Store TP, Double Attack.' },
    { id = 21833, name = 'Prime Scythe',    ws = 'Origin',           info = 'Scythe. STR/INT, Acc, Att, Store TP, Double Attack. WS drains HP/MP.' },
    { id = 21887, name = 'Prime Lance',     ws = 'Diarmuid',         info = 'Polearm. STR/VIT, Acc, Att, Store TP, Double Attack.' },
    { id = 22155, name = 'Prime Bow',       ws = 'Sarv',             info = 'Archery. AGI/STR, Ranged Acc/Att, Store TP, Rapid Shot. Needs arrows.' },
    { id = 22159, name = 'Prime Gun',       ws = 'Terminus',         info = 'Marksmanship. AGI/DEX, Ranged Acc/Att, Store TP, Rapid Shot. Needs bullets.' },
}

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local NAME = 'Prime Armory'

    -- Deferred customMenu send: snapshot first so a second player interacting
    -- in the 30ms window can't swap the shared table mid-flight.
    local function sendMenu(player, menu)
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local showMain  -- forward declaration (the confirm menu's "Back" calls it)

    local PAGE_SIZE = 7  -- 7 weapons + 1 nav button stays within the 8-option client limit

    -----------------------------------
    -- Spend a voucher and hand over the weapon.
    -----------------------------------
    local function claim(player, weapon)
        if player:getItemCount(VOUCHER) < 1 then
            player:printToPlayer('You need a Prime Voucher to claim this. Ask a GM for one, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer('Your inventory is full -- free a slot first, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        -- Take the voucher BEFORE giving the weapon, and verify by count rather
        -- than trusting delItem's return (which isn't reliable across builds --
        -- see the currency-consumption gotcha). Only hand the weapon over if a
        -- voucher was actually removed.
        local before = player:getItemCount(VOUCHER)
        player:delItem(VOUCHER, 1)
        if player:getItemCount(VOUCHER) >= before then
            player:printToPlayer('Could not take your Prime Voucher -- move it into your main inventory and retry, kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        player:addItem({ id = weapon.id, quantity = 1 })
        player:printToPlayer(string.format('Claimed %s! Equip it to wield the weapon skill %s, kupo!', weapon.name, weapon.ws), xi.msg.channel.SYSTEM_3)
    end

    -----------------------------------
    -- Per-weapon detail + confirm menu.
    -----------------------------------
    local function showWeapon(player, weapon, page)
        player:printToPlayer(string.format('%s -- weapon skill: %s', weapon.name, weapon.ws), xi.msg.channel.SYSTEM_3)
        player:printToPlayer('  ' .. weapon.info, xi.msg.channel.SYSTEM_3)
        player:printToPlayer(string.format('  You hold %d Prime Voucher(s).', player:getItemCount(VOUCHER)), xi.msg.channel.SYSTEM_3)

        sendMenu(player, {
            title   = weapon.name,
            options =
            {
                { 'Claim (trade 1 Prime Voucher)', function(p) claim(p, weapon) end },
                { '<< Back',                        function(p) showMain(p, page) end },
            },
        })
    end

    -----------------------------------
    -- Main browse menu: paginated (PAGE_SIZE per page) to stay within the
    -- 8-option client-side render limit.
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
            table.insert(options, { 'More weapons >>', function(p) showMain(p, page + 1) end })
        end
        if page > 1 then
            table.insert(options, { '<< Previous page', function(p) showMain(p, page - 1) end })
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
        look       = 3000,
        -- GM Home corridor, just south of the Unlocker cluster (adjust freely).
        x          = -3.000,
        y          =  0.000,
        z          = -20.000,
        rotation   =  128,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('Talk to me to choose a Prime weapon, kupo! Bring a Prime Voucher.', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            showMain(player)
        end,
    })
end)

return m
