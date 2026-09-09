-----------------------------------
-- relic_voucher_catalog.lua
--
-- Hades weekend Steel stall. One Relic voucher or finished Ambuscade
-- weapon, the same name and price for every player that UTC week.
-- Relics trade to the Weapon Forger after WF_Relic_Final. If you already
-- hold that weapon you miss the stall -- there is no reroll.
-----------------------------------
local CATALOG_KEY = 'modules/custom/lua/relic_voucher_catalog'
local C = package.loaded[CATALOG_KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[CATALOG_KEY] = C

C.FIRST_VOUCHER_ID = 23879
C.FORGE_VAR        = 'WF_Relic_Final'
C.SYS              = xi.msg.channel.SYSTEM_3

C.successLines =
{
    '-gasp- I don\'t know where you got this... These are a very ancient form of currency...',
    'Very well, adventurer. Here is your relic.',
}

C.tooWeakLine =
    'I\'m afraid you are not powerful enough yet to wield such a weapon. Come back to me at a later date.'

C.WEEK_SALT  = 17
C.PRICE_SALT = 41
C.PRICE =
{
    relic     = { lo = 1901, hi = 2099 },
    ambuscade = { lo =  901, hi = 1099 },
}

C.weapons =
{
    { voucherId = 23879, weaponId = 20509, name = 'Spharai',       kind = 'relic' },
    { voucherId = 23880, weaponId = 20583, name = 'Mandau',        kind = 'relic' },
    { voucherId = 23881, weaponId = 20685, name = 'Excalibur',     kind = 'relic' },
    { voucherId = 23882, weaponId = 21683, name = 'Ragnarok',      kind = 'relic' },
    { voucherId = 23883, weaponId = 21750, name = 'Guttler',       kind = 'relic' },
    { voucherId = 23884, weaponId = 21756, name = 'Bravura',       kind = 'relic' },
    { voucherId = 23885, weaponId = 21808, name = 'Apocalypse',    kind = 'relic' },
    { voucherId = 23886, weaponId = 21857, name = 'Gungnir',       kind = 'relic' },
    { voucherId = 23887, weaponId = 21906, name = 'Kikoku',        kind = 'relic' },
    { voucherId = 23888, weaponId = 21954, name = 'Amanomurakumo', kind = 'relic' },
    { voucherId = 23889, weaponId = 21077, name = 'Mjollnir',      kind = 'relic' },
    { voucherId = 23890, weaponId = 22060, name = 'Claustrum',     kind = 'relic' },
    { voucherId = 23891, weaponId = 22129, name = 'Yoichinoyumi',  kind = 'relic' },
    { voucherId = 23892, weaponId = 22140, name = 'Annihilator',   kind = 'relic' },
    { voucherId = 23867, weaponId = 11927, name = 'Aegis',         kind = 'relic' },
    { voucherId = 23868, weaponId = 18840, name = 'Gjallarhorn',   kind = 'relic' },
    { weaponId = 21519, name = 'Karambit',    kind = 'ambuscade' },
    { weaponId = 21565, name = 'Tauret',      kind = 'ambuscade' },
    { weaponId = 21621, name = 'Naegling',    kind = 'ambuscade' },
    { weaponId = 21674, name = 'Nandaka',     kind = 'ambuscade' },
    { weaponId = 21722, name = 'Dolichenus',  kind = 'ambuscade' },
    { weaponId = 21779, name = 'Lycurgos',    kind = 'ambuscade' },
    { weaponId = 21830, name = 'Drepanum',    kind = 'ambuscade' },
    { weaponId = 21883, name = 'Shining One', kind = 'ambuscade' },
    { weaponId = 21922, name = 'Gokotai',     kind = 'ambuscade' },
    { weaponId = 21975, name = 'Hachimonji',  kind = 'ambuscade' },
    { weaponId = 22031, name = 'Maxentius',   kind = 'ambuscade' },
    { weaponId = 22086, name = 'Xoanon',      kind = 'ambuscade' },
    { weaponId = 22107, name = 'Ullr',        kind = 'ambuscade' },
    { weaponId = 22218, name = 'Khonsu',      kind = 'ambuscade' },
}

C.byVoucherId = {}
C.byWeaponId  = {}
for _, row in ipairs(C.weapons) do
    if row.kind == 'relic' then
        row.voucherName = row.name .. ' Voucher'
    end
    if row.voucherId then
        C.byVoucherId[row.voucherId] = row
    end
    C.byWeaponId[row.weaponId] = row
end

function C.voucherName(row)
    return row.voucherName or (row.name .. ' Voucher')
end

function C.shopName(row)
    if not row then
        return 'a Relic'
    end
    if row.kind == 'ambuscade' then
        return row.name
    end
    return C.voucherName(row)
end

function C.hasForgedRelic(player)
    return player and (player:getCharVar(C.FORGE_VAR) or 0) == 1
end

function C.isVoucherId(itemId)
    return C.byVoucherId[itemId] ~= nil
end

local function hasItem(player, itemId)
    if not player or not itemId then
        return false
    end
    local ok, count = pcall(function()
        return player:getItemCount(itemId)
    end)
    return ok and (count or 0) > 0
end

-- UTC week so Saturday and Sunday of the same weekend share one ware.
function C.weekId(timestamp)
    return tonumber(os.date('!%Y%W', timestamp or os.time()))
end

function C.weeklyRelic(weekId)
    local n = #C.weapons
    if n == 0 then
        return nil
    end
    weekId = weekId or C.weekId()
    return C.weapons[(((weekId or 0) * (C.WEEK_SALT or 17)) % n) + 1]
end

C.weeklyWare  = nil
C.weeklyWares = nil
C.POOLS       = nil
C.poolItems   = nil

function C.weeklyPrice(weekId, row)
    weekId = weekId or C.weekId()
    row = row or C.weeklyRelic(weekId)
    local band = row and C.PRICE[row.kind] or C.PRICE.relic
    local span = (band.hi - band.lo) + 1
    return band.lo + (((weekId or 0) * (C.PRICE_SALT or 41)) % span)
end

function C.ownsRelic(player, row)
    return row ~= nil and hasItem(player, row.weaponId)
end

function C.ownsVoucher(player, row)
    return row ~= nil and row.voucherId ~= nil and hasItem(player, row.voucherId)
end

function C.award(player, row, tag)
    if not player or not row then
        return false
    end
    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer(
            string.format('[%s] Free an inventory slot first.', tag or 'Hades'),
            C.SYS)
        return false
    end

    local itemId = row.kind == 'ambuscade' and row.weaponId or row.voucherId
    if not itemId then
        return false
    end
    if hasItem(player, itemId) then
        player:printToPlayer(
            string.format('[%s] You already hold %s.', tag or 'Hades', C.shopName(row)),
            C.SYS)
        return false
    end
    if not player:addItem({ id = itemId, quantity = 1 }) then
        player:printToPlayer(
            string.format('[%s] The ware slipped back into the dark. Try again.', tag or 'Hades'),
            C.SYS)
        return false
    end
    return true
end

local function sayForger(player, line)
    player:printToPlayer('Weapon Forger : ' .. line, C.SYS)
end

local function tradeVoucher(trade)
    if not trade then
        return nil
    end

    local gil = 0
    pcall(function() gil = trade:getGil() or 0 end)
    if gil > 0 then
        return nil, 'extra'
    end

    local found
    for _, row in ipairs(C.weapons) do
        if row.voucherId then
            local qty = 0
            pcall(function() qty = trade:getItemQty(row.voucherId) or 0 end)
            if qty > 1 then
                return nil, 'extra'
            end
            if qty == 1 then
                if found then
                    return nil, 'extra'
                end
                found = row
            end
        end
    end

    local count = 0
    pcall(function() count = trade:getItemCount() or 0 end)
    if not found then
        return nil
    end
    if count ~= 1 then
        return nil, 'extra'
    end
    return found
end

function C.tryRedeem(player, trade)
    local row, why = tradeVoucher(trade)
    if not row then
        if why == 'extra' then
            sayForger(player, 'Bring me only the voucher. Nothing else.')
            return true
        end
        return false
    end

    if not C.hasForgedRelic(player) then
        sayForger(player, C.tooWeakLine)
        return true
    end

    if hasItem(player, row.weaponId) then
        sayForger(player, string.format('You already wield %s. I will not mint a second.', row.name))
        return true
    end

    local relicCatalog = require('modules/custom/lua/relic_forge_catalog')
    if player:getFreeSlotsCount() < relicCatalog.grantSlotNeed(player, row.weaponId, false) then
        sayForger(player, 'Free an inventory slot, then trade me the voucher again.')
        return true
    end

    player:confirmTrade()
    if not player:addItem({ id = row.weaponId, quantity = 1 }) then
        player:printToPlayer(
            '[Weapon Forge] ERROR: the voucher was taken but the relic could not be granted -- contact a GM.',
            C.SYS)
        return true
    end

    for _, line in ipairs(C.successLines) do
        sayForger(player, line)
    end
    player:printToPlayer(
        string.format('[Weapon Forge] Received: %s.', row.name),
        C.SYS)
    relicCatalog.grantCompanions(player, row.weaponId, 'Weapon Forge')
    return true
end

return C
