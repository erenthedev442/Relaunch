-----------------------------------
-- Abyssea marks balance contract
--
-- DPS values are sustained encounter throughput (auto-attacks, TP generation,
-- mechanic downtime, and earned vulnerability windows included), not a claim
-- that every individual WS deals this amount.
-----------------------------------

local B = {}

-- Representative sheet available before Abyssea progression. Encounter
-- offense is calibrated against this defensive baseline; Aeonic ownership is
-- intentionally irrelevant here because it does not change incoming damage.
B.targetPlayer =
{
    accuracy       = 3000,
    evasion        = 1000,
    defense        = 3400,
    damageTakenPct = -35,
    regen          = 700,
}

B.tiers =
{
    [1] =
    {
        hp = 4000000,
        targetSoloMinutes = { 5, 7 },
        relicDpsPerMinute = { 600000, 800000 },
        preRelicDpsPerMinute = 300000,
        pressureMinutes = 4,
    },
    [2] =
    {
        hp = 8000000,
        targetSoloMinutes = { 7, 10 },
        relicDpsPerMinute = { 800000, 1142857 },
        pressureMinutes = 6,
    },
    [3] =
    {
        hp = 14000000,
        targetSoloMinutes = { 10, 14 },
        relicDpsPerMinute = { 1000000, 1400000 },
        targetGroupMinutes = { 6, 9 },
        pressureMinutes = 8,
    },
}

function B.hpScale(realPlayers)
    return require('modules/custom/lua/party_hp_scale').multiplier(realPlayers)
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
