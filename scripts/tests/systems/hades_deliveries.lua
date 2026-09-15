local catalog = require('modules/custom/lua/hades_catalog')

describe('Hades parcel destinations', function()
    it('pins every delivery NPC to a live id and a real display name', function()
        local seen = {}
        assert(#catalog.deliveries == 16)

        for _, dest in ipairs(catalog.deliveries) do
            assert(dest.npc and dest.npc ~= '', dest.zone)
            assert(dest.npcId and dest.npcId > 0, dest.npc)
            assert(dest.speaker and dest.speaker ~= '' and dest.speaker ~= 'NPC', dest.npc)
            assert(not seen[dest.npcId], dest.npc)
            seen[dest.npcId] = true

            local zoneFromId = bit.rshift(bit.band(dest.npcId, 0xFFF000), 12)
            assert(zoneFromId == dest.zoneId, dest.npc)
        end

        assert(seen[16974290], 'Al Zahbi Chayaya')
        assert(seen[16982088], 'Whitegate Gavrie')
        assert(seen[16994377], 'Nashmau Nanaroon')
        assert(seen[17105519], 'Southern San d\'Oria [S] Miliart')
        assert(seen[17826052], 'Western Adoulin Flapano')
        assert(seen[17830004], 'Eastern Adoulin Octavien')
    end)
end)
