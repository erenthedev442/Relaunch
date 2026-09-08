-----------------------------------
-- thief_mug_catalog.lua
--
-- Main-job THF Mug HP drain. FileWatcher-safe (mutate package.loaded).
-- /THF keeps the SQL 5:00 recast and gets no drain.
--
-- Three bands. DEX+AGI only fill the band you are in.
--   Fresh 99:     500 base, cap 900
--   Mastered:     900 base, cap 2000   (2100 JP, no REMA)
--   REMA:        1600 base, cap 3000   (Relic / Mythic / Empy / Aeonic)
-- bonus = max(0, DEX+AGI-160) * 8
-----------------------------------
local CATALOG_KEY = 'modules/custom/lua/thief_mug_catalog'
local C = package.loaded[CATALOG_KEY]
if type(C) ~= 'table' then
    C = {}
end
package.loaded[CATALOG_KEY] = C

C.MAIN_RECAST = 90
C.SUB_RECAST  = 300
C.MASTER_JP   = 2100
C.STAT_FLOOR  = 160
C.STAT_PER    = 8

C.BANDS =
{
    fresh  = { base = 500,  cap = 900  },
    master = { base = 900,  cap = 2000 },
    rema   = { base = 1600, cap = 3000 },
}

function C.statBonus(dex, agi)
    return math.max(0, (dex or 0) + (agi or 0) - C.STAT_FLOOR) * C.STAT_PER
end

function C.bandFor(hasRema, mastered)
    if hasRema then
        return 'rema'
    end

    if mastered then
        return 'master'
    end

    return 'fresh'
end

function C.healAmount(dex, agi, bandKey)
    local band = C.BANDS[bandKey] or C.BANDS.fresh
    return math.min(band.cap, band.base + C.statBonus(dex, agi))
end

function C.recastFor(isMainThf)
    if isMainThf then
        return C.MAIN_RECAST
    end

    return C.SUB_RECAST
end

function C.isRemaItem(itemId)
    if not itemId or itemId == 0 then
        return false
    end

    local ok, rema = pcall(require, 'modules/custom/lua/rema_ws_tier_catalog')
    return ok and rema and rema.BY_ITEM_ID and rema.BY_ITEM_ID[itemId] ~= nil
end

function C.equippedRema(player)
    if not player or not player.getEquipID then
        return false
    end

    local slots = { xi.slot.MAIN, xi.slot.SUB, xi.slot.RANGED }
    for i = 1, #slots do
        if C.isRemaItem(player:getEquipID(slots[i])) then
            return true
        end
    end

    return false
end

function C.playerHeal(player)
    if not player then
        return 0
    end

    local dex = player:getStat(xi.mod.DEX)
    local agi = player:getStat(xi.mod.AGI)
    local spent = 0
    if player.getSpentJobPoints then
        spent = player:getSpentJobPoints() or 0
    end

    return C.healAmount(dex, agi, C.bandFor(C.equippedRema(player), spent >= C.MASTER_JP))
end

return C
