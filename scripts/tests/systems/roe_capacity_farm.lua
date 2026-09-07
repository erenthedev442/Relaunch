require('modules/custom/lua/roe_capacity_farm')

describe('RoE blocks at capacity farms', function()
    local previousRecords
    local previousTrigger

    before_each(function()
        previousRecords = xi.roe.records
        previousTrigger = xi.roeTrigger
        xi.roeTrigger = { DEFEAT_MOB = 1, MAGIC_BURST = 2 }
        xi.roe.records =
        {
            [2]   = { trigger = 1 },
            [225] = { trigger = 1 },
            [468] = { trigger = 1 },
            [3]   = {},
        }
    end)

    after_each(function()
        xi.roe.records = previousRecords
        xi.roeTrigger = previousTrigger
    end)

    local function playerIn(zoneId)
        return
        {
            getZoneID = function()
                return zoneId
            end,
        }
    end

    it('blocks Conflict and generic kill records in Bibiki and Ranperre', function()
        local bibiki   = playerIn(xi.zone.BIBIKI_BAY)
        local ranperre = playerIn(xi.zone.KING_RANPERRES_TOMB)

        assert(xi.roe.blocksCapacityFarmKill(bibiki, 468))
        assert(xi.roe.blocksCapacityFarmKill(bibiki, 2))
        assert(xi.roe.blocksCapacityFarmKill(ranperre, 225))
        assert(xi.roe.blocksCapacityFarmKill(ranperre, 2))
    end)

    it('does not block other zones or non-kill records', function()
        local jeuno = playerIn(xi.zone.LOWER_JEUNO)
        assert(not xi.roe.blocksCapacityFarmKill(jeuno, 468))
        assert(not xi.roe.blocksCapacityFarmKill(playerIn(xi.zone.BIBIKI_BAY), 3))
    end)

    it('still allows claiming a finished record while standing in camp', function()
        assert(not xi.roe.blocksCapacityFarmKill(playerIn(xi.zone.BIBIKI_BAY), 468, { claim = true }))
    end)
end)
