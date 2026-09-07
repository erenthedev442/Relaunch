-----------------------------------
-- Capacity camps (Bibiki Bay, King Ranperre's Tomb) are a CP channel.
-- Alts were standing in party with Conflict / Vanquish RoE accepted and
-- collecting ROE_EXP_RATE payouts off the main's kills. Kill-triggered
-- records do not progress in these two zones. Claims already completed
-- elsewhere still pay.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/roe')

local m = Module:new('roe_capacity_farm')

local blockedZones =
{
    [xi.zone.BIBIKI_BAY]          = true,
    [xi.zone.KING_RANPERRES_TOMB] = true,
}

function xi.roe.blocksCapacityFarmKill(player, recordID, params)
    if params and params.claim then
        return false
    end

    if not player or not blockedZones[player:getZoneID()] then
        return false
    end

    local entry = xi.roe.records and xi.roe.records[recordID]
    return entry ~= nil and entry.trigger == xi.roeTrigger.DEFEAT_MOB
end

m:addOverride('xi.roe.onRecordTrigger', function(player, recordID, params)
    if xi.roe.blocksCapacityFarmKill(player, recordID, params) then
        return
    end

    super(player, recordID, params)
end)

return m
