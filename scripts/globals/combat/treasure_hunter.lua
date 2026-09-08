-----------------------------------
xi = xi or {}
xi.combat = xi.combat or {}
xi.combat.treasureHunter = xi.combat.treasureHunter or {}
-----------------------------------

-- https://forum.square-enix.com/ffxi/threads/56550
xi.combat.treasureHunter.treasureHunterTable =
{
-- TH lvl    VC    C     UC    R     VR    SR   UR
    [ 0] = { 2400, 1500, 1000,  500,  100,  50,  10 },
    [ 1] = { 4800, 3000, 1200,  600,  150,  75,  20 },
    [ 2] = { 5600, 4000, 1500,  700,  200, 100,  30 },
    [ 3] = { 6000, 4250, 1650,  750,  225, 120,  35 },
    [ 4] = { 6400, 4500, 1800,  800,  250, 140,  40 },
    [ 5] = { 6666, 4750, 1900,  850,  300, 160,  45 },
    [ 6] = { 6800, 5000, 2000,  900,  350, 180,  50 },
    [ 7] = { 6900, 5250, 2100,  950,  400, 200,  60 },
    [ 8] = { 7050, 5500, 2250, 1050,  475, 230,  70 },
    [ 9] = { 7200, 5750, 2400, 1150,  550, 260,  80 },
    [10] = { 7350, 6000, 2650, 1250,  650, 300,  90 },
    [11] = { 7400, 6250, 2800, 1350,  750, 350, 100 },
    [12] = { 7600, 6500, 2950, 1550,  825, 400, 115 },
    [13] = { 7800, 6750, 3100, 1750,  900, 450, 130 },
    [14] = { 8000, 7000, 3250, 2000, 1000, 500, 150 },
    -- Main-job THF only (TH I/II/III sit above the shared 14).
    [15] = { 8200, 7250, 3400, 2250, 1100, 550, 170 },
    [16] = { 8400, 7500, 3550, 2500, 1200, 600, 190 },
    [17] = { 8600, 7750, 3700, 2750, 1300, 650, 210 },
}

xi.combat.treasureHunter.dropBracketTable =
{
    [1] = { 2400 },
    [2] = { 1500 },
    [3] = { 1000 },
    [4] = {  500 },
    [5] = {  100 },
    [6] = {   50 },
    [7] = {    0 }, -- Set to 0, for weird cases in DB.
}

xi.combat.treasureHunter.SHARED_CAP   = 14
xi.combat.treasureHunter.THF_MAIN_CAP = 17

-- Shared gear / prestige / augments stop at 14. Main THF keeps TH I/II/III above that.
xi.combat.treasureHunter.playerCap = function(player)
    local cap = xi.combat.treasureHunter.SHARED_CAP
    if not player or player:getMainJob() ~= xi.job.THF then
        return cap
    end

    if player:hasTrait(xi.trait.TREASURE_HUNTER) then
        cap = cap + 1
    end

    if player:hasTrait(xi.trait.TREASURE_HUNTER_II) then
        cap = cap + 1
    end

    if player:hasTrait(xi.trait.TREASURE_HUNTER_III) then
        cap = cap + 1
    end

    return cap
end

xi.combat.treasureHunter.getDropRate = function(thLevel, dropRate)
    -- Sanitize parameters
    local thTier     = utils.defaultIfNil(thLevel, 0)
    local thDropRate = utils.defaultIfNil(dropRate, 0)

    -- Shared sources cap at 14. Main-job THF can apply 15-17.
    thTier     = utils.clamp(math.floor(thTier), 0, 17)
    thDropRate = utils.clamp(thDropRate, 0, 10000)

    -- Early returns: Drop is guaranteed or non-existant.
    if thDropRate == 10000 then
        return 10000
    elseif thDropRate == 0 then
        return 0
    end

    -- Calculate original drop rate bracket.
    local thBracket = 0

    for i = 1, #xi.combat.treasureHunter.dropBracketTable do
        if thDropRate >= xi.combat.treasureHunter.dropBracketTable[i][1] then
            thBracket = i

            break
        end
    end

    -- Calculate TH drop rate
    return xi.combat.treasureHunter.treasureHunterTable[thTier][thBracket]
end
