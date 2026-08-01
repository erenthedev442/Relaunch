-----------------------------------
-- progression_dungeon_rewards.lua
--
-- Currency payouts for the three non-augmentation dungeons (Challenge +
-- Progression categories in dungeon_catalog.lua). Augmentation Dungeons use
-- augment_dungeon_drops.lua instead; these keys return early there.
--
--   * Trash (slots 1-12): TRASH_RATE% roll on the killing blow; pays the killer.
--   * Boss (slot 13): flat payout to every alliance member in the instance.
--   * First lifetime clear: FIRST_CLEAR bonus stacked on the boss payout.
--
-- HOT-RELOADABLE: same in-place table pattern as augment_dungeon_drops.lua.
-----------------------------------
local M = package.loaded['modules/custom/lua/progression_dungeon_rewards']
if type(M) ~= 'table' then M = {} end

local TRASH_RATE = 15 -- % chance trash pays its configured currency

-- Currency display names for player messages.
local LABEL =
{
    escha_silt       = 'Escha Silt',
    unity_accolades  = 'Unity Accolades',
}

local REWARDS =
{
    -- Challenge band: general progression currency (Aeonic checklist, no silt).
    crawlersNest =
    {
        trash = { currency = 'unity_accolades', amount = 50 },
        boss  = { unity_accolades = 600, gil = 40000 },
        firstClear = { unity_accolades = 400 },
    },

    -- Progression band: Aeonic-era silt + accolades (repeatable farm, below Geas T4).
    xarcabard =
    {
        trash = { currency = 'escha_silt', amount = 75 },
        boss  = { escha_silt = 1000, unity_accolades = 400 },
        firstClear = { escha_silt = 500 },
    },

    boyahdaTree =
    {
        trash = { currency = 'escha_silt', amount = 75 },
        boss  = { escha_silt = 1000, unity_accolades = 400 },
        firstClear = { escha_silt = 500 },
    },
}

local function awardCurrency(player, currency, amount, firstClear)
    if amount <= 0 then
        return
    end

    player:addCurrency(currency, amount)
    local label = LABEL[currency] or currency
    local suffix = firstClear and ' (first clear bonus!)' or ''
    player:printToPlayer(
        string.format('[Dungeon] You receive %d %s.%s', amount, label, suffix),
        xi.msg.channel.SYSTEM_3)
end

local function awardGil(player, amount)
    if amount <= 0 then
        return
    end

    player:addGil(amount)
    player:printToPlayer(
        string.format('[Dungeon] You receive %d gil.', amount),
        xi.msg.channel.SYSTEM_3)
end

local function payBoss(member, dungeonKey, cfg)
    for currency, amount in pairs(cfg.boss) do
        if currency == 'gil' then
            awardGil(member, amount)
        else
            awardCurrency(member, currency, amount, false)
        end
    end

    local clearKey = 'Dungeon_Clear_' .. dungeonKey
    if cfg.firstClear and (member:getCharVar(clearKey) or 0) == 0 then
        for currency, amount in pairs(cfg.firstClear) do
            awardCurrency(member, currency, amount, true)
        end
    end
end

M.onDungeonMobDeath = function(dungeonKey, instance, deadMob, player, optParams, slotArg, isBossArg)
    if player == nil or type(optParams) ~= 'table' or not optParams.isKiller then
        return
    end

    local cfg = REWARDS[dungeonKey]
    if not cfg then
        return
    end

    local slot = slotArg or deadMob:getLocalVar('DungeonMobIndex')
    if not slot or slot == 0 then
        return
    end

    if deadMob:getLocalVar('DungeonProgRolled') ~= 0 then
        return
    end
    deadMob:setLocalVar('DungeonProgRolled', 1)

    local isBoss = isBossArg
    if isBoss == nil then
        isBoss = (deadMob:getLocalVar('DungeonBossMob') == 1)
    end

    if isBoss then
        for _, member in ipairs(instance:getChars()) do
            payBoss(member, dungeonKey, cfg)
        end
        return
    end

    local trash = cfg.trash
    if trash and math.random(100) <= TRASH_RATE then
        awardCurrency(player, trash.currency, trash.amount, false)
    end
end

return M
