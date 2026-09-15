-----------------------------------
-- relic_voucher_catalog.lua
--
-- Hades weekend Steel stalls. Two wares, the same names and prices for every
-- player that UTC week.
--
-- Rare band (same weight as today's Relic weeks): Relic vouchers and
-- Odyssey vouchers. Common band (same weight as today's Ambuscade weeks):
-- finished Ambuscade finals and Geas Fete named 119s.
-- Relic and Odyssey papers trade to the Weapon Forger after WF_Relic_Final
-- on any job. If you already hold that ware you miss the stall -- no reroll.
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

C.odysseySuccessLine =
    'Very well, adventurer. Here is your Odyssey weapon.'

C.tooWeakLine =
    'I\'m afraid you are not powerful enough yet to wield such a weapon. Come back to me at a later date.'

-- Pool pick uses WEEK_SALT so Relic-tier weeks stay ~16/30. Item pick inside
-- a pool uses a second salt so the ware is not locked to the pool roll.
C.WEEK_SALT   = 17
C.RARE_SALT   = 23 -- must not be a multiple of the rare pool size (29)
C.COMMON_SALT = 31 -- coprime with the common pool size (81)
C.PRICE_SALT  = 41
C.POOL_WEIGHT =
{
    rare   = 16,
    common = 14,
}
C.PRICE =
{
    relic     = { lo = 1901, hi = 2099 },
    odyssey   = { lo = 1400, hi = 1500 },
    ambuscade = { lo =  901, hi = 1099 },
    geas      = { lo =  499, hi =  599 },
}

C.VOUCHER_KINDS = { relic = true, odyssey = true }
C.RARE_KINDS    = { relic = true, odyssey = true }
C.COMMON_KINDS  = { ambuscade = true, geas = true }

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

    { voucherId = 24276, weaponId = 21527, name = 'Sakpata\'s Fists',   kind = 'odyssey' },
    { voucherId = 24277, weaponId = 21567, name = 'Gleti\'s Knife',     kind = 'odyssey' },
    { voucherId = 24278, weaponId = 21637, name = 'Sakpata\'s Sword',   kind = 'odyssey' },
    { voucherId = 24279, weaponId = 21675, name = 'Agwu\'s Claymore',   kind = 'odyssey' },
    { voucherId = 24280, weaponId = 21723, name = 'Ikenga\'s Axe',      kind = 'odyssey' },
    { voucherId = 24281, weaponId = 21724, name = 'Agwu\'s Axe',        kind = 'odyssey' },
    { voucherId = 24282, weaponId = 21780, name = 'Bunzi\'s Chopper',   kind = 'odyssey' },
    { voucherId = 24290, weaponId = 21832, name = 'Agwu\'s Scythe',     kind = 'odyssey' },
    { voucherId = 24291, weaponId = 21884, name = 'Ikenga\'s Lance',    kind = 'odyssey' },
    { voucherId = 24292, weaponId = 22041, name = 'Bunzi\'s Rod',       kind = 'odyssey' },
    { voucherId = 24293, weaponId = 22100, name = 'Mpaca\'s Staff',     kind = 'odyssey' },
    { voucherId = 24294, weaponId = 22150, name = 'Gleti\'s Crossbow',  kind = 'odyssey' },
    { voucherId = 24295, weaponId = 22151, name = 'Mpaca\'s Bow',       kind = 'odyssey' },

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

    { weaponId = 19209, name = 'Molybdosis',       kind = 'geas' },
    { weaponId = 20505, name = 'Condemners',       kind = 'geas' },
    { weaponId = 20506, name = 'Suwaiyas',         kind = 'geas' },
    { weaponId = 20518, name = 'Eshus',            kind = 'geas' },
    { weaponId = 20519, name = 'Hammerfists',      kind = 'geas' },
    { weaponId = 20520, name = 'Midnights',        kind = 'geas' },
    { weaponId = 20523, name = 'Chastisers',       kind = 'geas' },
    { weaponId = 20579, name = 'Skinflayer',       kind = 'geas' },
    { weaponId = 20592, name = 'Sangoma',          kind = 'geas' },
    { weaponId = 20597, name = 'Enchufla',         kind = 'geas' },
    { weaponId = 20598, name = 'Shijo',            kind = 'geas' },
    { weaponId = 20599, name = 'Kali',             kind = 'geas' },
    { weaponId = 20677, name = 'Colada',           kind = 'geas' },
    { weaponId = 20678, name = 'Firangi',          kind = 'geas' },
    { weaponId = 20690, name = 'Reikiko',          kind = 'geas' },
    { weaponId = 20699, name = 'Koboto',           kind = 'geas' },
    { weaponId = 20700, name = 'Nixxer',           kind = 'geas' },
    { weaponId = 20701, name = 'Iris',             kind = 'geas' },
    { weaponId = 20702, name = 'Emissary',         kind = 'geas' },
    { weaponId = 20797, name = 'Skullrender',      kind = 'geas' },
    { weaponId = 20842, name = 'Reikiono',         kind = 'geas' },
    { weaponId = 20845, name = 'Instigator',       kind = 'geas' },
    { weaponId = 20846, name = 'Jokushuono',       kind = 'geas' },
    { weaponId = 20847, name = 'Router',           kind = 'geas' },
    { weaponId = 20887, name = 'Dacnomania',       kind = 'geas' },
    { weaponId = 20889, name = 'Misanthropy',      kind = 'geas' },
    { weaponId = 20892, name = 'Deathbane',        kind = 'geas' },
    { weaponId = 20893, name = 'Shukuyu\'s Scythe', kind = 'geas' },
    { weaponId = 20932, name = 'Habile Mazrak',    kind = 'geas' },
    { weaponId = 20937, name = 'Rhomphaia',        kind = 'geas' },
    { weaponId = 20938, name = 'Annealed Lance',   kind = 'geas' },
    { weaponId = 20979, name = 'Aizushintogo',     kind = 'geas' },
    { weaponId = 20983, name = 'Mijin',            kind = 'geas' },
    { weaponId = 21021, name = 'Umaru',            kind = 'geas' },
    { weaponId = 21022, name = 'Shishio',          kind = 'geas' },
    { weaponId = 21027, name = 'Ichigohitofuri',   kind = 'geas' },
    { weaponId = 21031, name = 'Sensui',           kind = 'geas' },
    { weaponId = 21072, name = 'Gada',             kind = 'geas' },
    { weaponId = 21073, name = 'Izcalli',          kind = 'geas' },
    { weaponId = 21083, name = 'Sucellus',         kind = 'geas' },
    { weaponId = 21084, name = 'Queller Rod',      kind = 'geas' },
    { weaponId = 21085, name = 'Solstice',         kind = 'geas' },
    { weaponId = 21149, name = 'Espiritus',        kind = 'geas' },
    { weaponId = 21150, name = 'Akademos',         kind = 'geas' },
    { weaponId = 21151, name = 'Lathi',            kind = 'geas' },
    { weaponId = 21152, name = 'Reikikon',         kind = 'geas' },
    { weaponId = 21215, name = 'Vijaya Bow',       kind = 'geas' },
    { weaponId = 21390, name = 'Albin Bane',       kind = 'geas' },
    { weaponId = 21482, name = 'Compensator',      kind = 'geas' },
    { weaponId = 21686, name = 'Zulfiqar',         kind = 'geas' },
    { weaponId = 21687, name = 'Takoba',           kind = 'geas' },
    { weaponId = 21698, name = 'Bidenhander',      kind = 'geas' },
    { weaponId = 21746, name = 'Digirbalag',       kind = 'geas' },
    { weaponId = 21747, name = 'Freydis',          kind = 'geas' },
    { weaponId = 21754, name = 'Aganoshe',         kind = 'geas' },
    { weaponId = 21755, name = 'Hodadenon',        kind = 'geas' },
    { weaponId = 21804, name = 'Obschine',         kind = 'geas' },
    { weaponId = 21854, name = 'Reienkyo',         kind = 'geas' },
    { weaponId = 21855, name = 'Lembing',          kind = 'geas' },
    { weaponId = 21904, name = 'Kanaria',          kind = 'geas' },
    { weaponId = 21905, name = 'Taka',             kind = 'geas' },
    { weaponId = 22054, name = 'Grioavolr',        kind = 'geas' },
    { weaponId = 22055, name = 'Oranyan',          kind = 'geas' },
    { weaponId = 22056, name = 'Gozuki Mezuki',    kind = 'geas' },
    { weaponId = 22113, name = 'Teller',           kind = 'geas' },
    { weaponId = 22114, name = 'Steinthor',        kind = 'geas' },
    { weaponId = 22119, name = 'Wochowsen',        kind = 'geas' },
}

C.byVoucherId = {}
C.byWeaponId  = {}
C.rareItems   = {}
C.commonItems = {}
for _, row in ipairs(C.weapons) do
    if C.VOUCHER_KINDS[row.kind] then
        row.voucherName = row.name .. ' Voucher'
    end
    if row.voucherId then
        C.byVoucherId[row.voucherId] = row
    end
    C.byWeaponId[row.weaponId] = row
    if C.RARE_KINDS[row.kind] then
        C.rareItems[#C.rareItems + 1] = row
    else
        C.commonItems[#C.commonItems + 1] = row
    end
end

function C.isVoucherKind(kind)
    return C.VOUCHER_KINDS[kind] == true
end

function C.isOdysseyWeapon(itemId)
    local row = C.byWeaponId[itemId]
    return row ~= nil and row.kind == 'odyssey'
end

function C.voucherName(row)
    return row.voucherName or (row.name .. ' Voucher')
end

function C.shopName(row)
    if not row then
        return 'a Relic'
    end
    if C.isVoucherKind(row.kind) then
        return C.voucherName(row)
    end
    return row.name
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

function C.weeklyRelic(weekId, slot)
    weekId = weekId or C.weekId()
    slot   = slot or 1
    local rareW   = C.POOL_WEIGHT.rare
    local commonW = C.POOL_WEIGHT.common
    local total   = rareW + commonW
    if total < 1 then
        return nil
    end

    local poolRoll = ((weekId or 0) * ((C.WEEK_SALT or 17) + (slot - 1) * 11)) % total
    local pool, itemSalt
    if poolRoll < rareW then
        pool     = C.rareItems
        itemSalt = C.RARE_SALT or 29
    else
        pool     = C.commonItems
        itemSalt = C.COMMON_SALT or 31
    end
    if not pool or #pool == 0 then
        return nil
    end
    local idx = (((weekId or 0) * itemSalt + (slot - 1) * 13) % #pool) + 1
    local row = pool[idx]
    if slot > 1 then
        local first = C.weeklyRelic(weekId, 1)
        if first and row and first.weaponId == row.weaponId then
            row = pool[(idx % #pool) + 1]
        end
    end
    return row
end

C.weeklyWare  = C.weeklyRelic
C.weeklyWares = nil
C.POOLS       = C.POOL_WEIGHT
C.poolItems   = nil

function C.weeklyPrice(weekId, row, slot)
    weekId = weekId or C.weekId()
    slot   = slot or 1
    row    = row or C.weeklyRelic(weekId, slot)
    local band = row and C.PRICE[row.kind] or C.PRICE.relic
    local span = (band.hi - band.lo) + 1
    return band.lo + (((weekId or 0) * ((C.PRICE_SALT or 41) + (slot - 1) * 7)) % span)
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
    local prefix = (tag and tag ~= '') and string.format('[%s] ', tag) or ''
    if player:getFreeSlotsCount() < 1 then
        player:printToPlayer(prefix .. 'Free an inventory slot first.', C.SYS)
        return false
    end

    local itemId = C.isVoucherKind(row.kind) and row.voucherId or row.weaponId
    if not itemId then
        return false
    end
    if hasItem(player, itemId) then
        player:printToPlayer(prefix .. string.format('You already hold %s.', C.shopName(row)), C.SYS)
        return false
    end
    if not player:addItem({ id = itemId, quantity = 1 }) then
        player:printToPlayer(prefix .. 'The ware slipped back into the dark. Try again.', C.SYS)
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
    local slotNeed = 1
    if row.kind == 'relic' then
        slotNeed = relicCatalog.grantSlotNeed(player, row.weaponId, false)
    end
    if player:getFreeSlotsCount() < slotNeed then
        sayForger(player, 'Free an inventory slot, then trade me the voucher again.')
        return true
    end

    player:confirmTrade()
    if not player:addItem({ id = row.weaponId, quantity = 1 }) then
        player:printToPlayer(
            '[Weapon Forge] ERROR: the voucher was taken but the weapon could not be granted -- contact a GM.',
            C.SYS)
        return true
    end

    if row.kind == 'odyssey' then
        sayForger(player, C.successLines[1])
        sayForger(player, C.odysseySuccessLine)
    else
        for _, line in ipairs(C.successLines) do
            sayForger(player, line)
        end
    end
    player:printToPlayer(
        string.format('[Weapon Forge] Received: %s.', row.name),
        C.SYS)
    if row.kind == 'relic' then
        relicCatalog.grantCompanions(player, row.weaponId, 'Weapon Forge')
    end
    return true
end

return C
