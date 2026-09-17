-----------------------------------
-- dynamis_currency_drops.lua
--
-- Original Dynamis singles: no proc required. Four TH-agnostic slots
-- (100% / 50% / 20% / 5%, EV ~1.75) so TH14 AoE wipes do not print
-- 4-5 coins per corpse. Flat 5% 100-piece follows the pack/family
-- single. White proc still guarantees one extra 100-piece.
--
-- FileWatcher-safe. Mixins / live rebind call onDeath by require(),
-- so rate edits land without restamping living mobs.
-----------------------------------
local KEY = 'modules/custom/lua/dynamis_currency_drops'
local M = package.loaded[KEY]
if type(M) ~= 'table' then
    M = {}
end
package.loaded[KEY] = M

local hundred = require('modules/custom/lua/dynamis_hundred_piece')

-- Percent chances, rolled in Lua so Treasure Hunter cannot inflate them.
M.SINGLE_RATES = { 100, 50, 20, 5 }

M.FAMILY_CURRENCY =
{
    [xi.mobSuperFamily.ORC   ] = xi.item.ORDELLE_BRONZEPIECE,
    [xi.mobSuperFamily.QUADAV] = xi.item.ONE_BYNE_BILL,
    [xi.mobSuperFamily.YAGUDO] = xi.item.TUKUKU_WHITESHELL,
}

M.ORIGINAL_ZONES =
{
    xi.zone.DYNAMIS_SAN_DORIA,
    xi.zone.DYNAMIS_BASTOK,
    xi.zone.DYNAMIS_WINDURST,
    xi.zone.DYNAMIS_JEUNO,
    xi.zone.DYNAMIS_BEAUCEDINE,
    xi.zone.DYNAMIS_XARCABARD,
    xi.zone.DYNAMIS_VALKURM,
    xi.zone.DYNAMIS_BUBURIMU,
    xi.zone.DYNAMIS_QUFIM,
    xi.zone.DYNAMIS_TAVNAZIA,
}

function M.expectedSingles()
    local total = 0
    for i = 1, #M.SINGLE_RATES do
        total = total + (M.SINGLE_RATES[i] / 100)
    end

    return total
end

function M.packSingle(mob)
    if not mob or not mob.getLocalVar then
        return nil
    end

    local tagged = mob:getLocalVar('dynamis_currency') or 0
    if tagged ~= 0 then
        return tagged
    end

    if VanadielHour then
        return hundred.dreamlandSingle(VanadielHour())
    end

    return xi.item.TUKUKU_WHITESHELL
end

function M.mobSingle(mob)
    if not mob then
        return nil
    end

    local tagged = 0
    if mob.getLocalVar then
        tagged = mob:getLocalVar('dynamis_currency') or 0
    end
    if tagged ~= 0 then
        return tagged
    end

    local fam
    if mob.getSuperFamily then
        fam = mob:getSuperFamily()
    end
    if fam and M.FAMILY_CURRENCY[fam] then
        return M.FAMILY_CURRENCY[fam]
    end

    -- Jeuno goblins / Kindred / Hydra: same three-coin pool as the old mixin.
    return xi.item.TUKUKU_WHITESHELL + math.random(0, 2) * 3
end

function M.isCurrencyMob(mob)
    if not mob then
        return false
    end

    local name = ''
    if mob.getName then
        name = mob:getName() or ''
    end

    if
        name:find('Tombstone', 1, true) or
        name:find('Effigy', 1, true) or
        name:find('Icon', 1, true) or
        name:find('Prototype', 1, true) or
        name:find('Idol', 1, true) or
        name:find('Replica', 1, true) or
        name:find('Animated', 1, true)
    then
        return false
    end

    local tagged = 0
    if mob.getLocalVar then
        tagged = mob:getLocalVar('dynamis_currency') or 0
    end
    if tagged ~= 0 then
        return true
    end

    local fam
    if mob.getSuperFamily then
        fam = mob:getSuperFamily()
    end
    if
        fam and
        (
            M.FAMILY_CURRENCY[fam] or
            fam == xi.mobSuperFamily.GOBLIN or
            fam == xi.mobSuperFamily.DEMON
        )
    then
        return true
    end

    return
        name:find('Vanguard', 1, true) ~= nil or
        name:find('Nightmare', 1, true) ~= nil or
        name:find('Kindred', 1, true) ~= nil or
        name:find('Hydra', 1, true) ~= nil
end

function M.dropSingles(mob, killer, currency)
    if not mob or not killer or not currency or currency == 0 then
        return 0
    end

    local paid = 0
    for i = 1, #M.SINGLE_RATES do
        if math.random(1, 100) <= M.SINGLE_RATES[i] then
            -- Won the Lua roll already. Default addTreasure is 100% and
            -- TH cannot clone a guaranteed drop.
            killer:addTreasure(currency, mob)
            paid = paid + 1
        end
    end

    return paid
end

function M.onDeath(mob, killer, currency)
    if not killer then
        return false
    end

    currency = currency or M.mobSingle(mob)
    if not currency or currency == 0 then
        return false
    end

    M.dropSingles(mob, killer, currency)
    hundred.tryDrop(mob, killer, currency)

    local proc = 0
    if mob.getLocalVar then
        proc = mob:getLocalVar('dynamis_proc') or 0
    end
    if proc >= 4 then
        local itemId = hundred.hundredItem(mob.getZoneID and mob:getZoneID(), currency)
        if itemId then
            killer:addTreasure(itemId, mob)
        end
    end

    return true
end

function M.rebindMob(mob)
    if not mob or not mob.addListener then
        return false
    end

    if not M.isCurrencyMob(mob) then
        return false
    end

    -- Same identifier replaces the old proc-gated DEATH handler.
    mob:addListener('DEATH', 'DYNAMIS_ITEM_DISTRIBUTION', function(deadMob, killer)
        require('modules/custom/lua/dynamis_currency_drops').onDeath(deadMob, killer)
    end)

    return true
end

function M.rebindZone(zoneId)
    if not GetZone then
        return 0
    end

    local zone = GetZone(zoneId)
    if not zone or not zone.getMobs then
        return 0
    end

    local mobs = zone:getMobs()
    if not mobs then
        return 0
    end

    local rebound = 0
    local function handle(mob)
        local ok, paid = pcall(M.rebindMob, mob)
        if ok and paid then
            rebound = rebound + 1
        end
    end

    if mobs[1] then
        for i = 1, #mobs do
            handle(mobs[i])
        end
    else
        for _, mob in pairs(mobs) do
            handle(mob)
        end
    end

    return rebound
end

function M.rebindLive()
    local total = 0
    for i = 1, #M.ORIGINAL_ZONES do
        local ok, n = pcall(M.rebindZone, M.ORIGINAL_ZONES[i])
        if ok and n then
            total = total + n
        end
    end

    print(string.format('[dynamis_currency_drops] rebound %d living original-Dynamis mobs (TH slots, no proc)', total))
    return total
end

return M
