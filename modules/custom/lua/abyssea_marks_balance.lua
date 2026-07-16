-----------------------------------
-- Abyssea marks balance contract
--
-- DPS values are sustained encounter throughput (auto-attacks, TP generation,
-- mechanic downtime, and earned vulnerability windows included), not a claim
-- that every individual WS deals this amount.
-----------------------------------

local B = {}

B.tiers =
{
    [1] =
    {
        hp = 4000000,
        targetSoloMinutes = { 5, 7 },
        relicDpsPerMinute = { 600000, 800000 },
        preRelicDpsPerMinute = 300000,
        pressureMinutes = 12,
    },
    [2] =
    {
        hp = 8000000,
        targetSoloMinutes = { 7, 10 },
        relicDpsPerMinute = { 800000, 1142857 },
        pressureMinutes = 14,
    },
    [3] =
    {
        hp = 14000000,
        targetSoloMinutes = { 10, 14 },
        relicDpsPerMinute = { 1000000, 1400000 },
        targetGroupMinutes = { 6, 9 },
        pressureMinutes = 16,
    },
}

function B.hpScale(realPlayers)
    if realPlayers >= 3 then return 2.10 end
    if realPlayers == 2 then return 1.55 end
    return 1.00
end

function B.expectedMinutes(tier, realPlayers, perPlayerDpsPerMinute)
    local cfg = B.tiers[tier]
    if not cfg or not perPlayerDpsPerMinute or perPlayerDpsPerMinute <= 0 then
        return nil
    end

    local players = math.max(1, realPlayers or 1)
    return (cfg.hp * B.hpScale(players)) / (perPlayerDpsPerMinute * players)
end

return B
