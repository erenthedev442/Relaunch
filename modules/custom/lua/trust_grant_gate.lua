-----------------------------------
-- trust_grant_gate.lua
-- Single gate for learning trust spells. Retail quests, ROE cipher items,
-- Unity UC auto-grants, and NPC cipher trades are blocked; only these paths
-- may teach trusts:
--   * four starters (Character Upgrader)
--   * using a Trust Cipher item from inventory (NM drops / future content)
--   * Void Keeper purchases (trust_skoll.lua)
--   * GM !givetrust
--   * any caller of xi.trustGrant.grantSpell()
-----------------------------------
require('modules/module_utils')
require('scripts/globals/trust')
require('scripts/globals/npc_util')
require('scripts/globals/player')

local m = Module:new('trust_grant_gate')

local catalog = require('modules/custom/lua/trust_grant_catalog')

local TRUST_SPELL_MIN     = catalog.TRUST_SPELL_MIN
local TRUST_SPELL_MAX     = catalog.TRUST_SPELL_MAX
local STARTER_TRUSTS      = catalog.STARTER_TRUSTS
local STARTER_TRUST_SET   = catalog.STARTER_TRUST_SET
local VOID_KEEPER_SET     = catalog.VOID_KEEPER_SPELL_SET
local UNITY_TRUST_ID      = catalog.UNITY_TRUST_ID
local EARNED_PREFIX       = catalog.EARNED_CHARVAR_PREFIX

local STRIP_INTERVAL_S    = 60
local BLOCKED_CIPHER_MSG  = 'Trust ciphers are earned in content — use them from your inventory, not through NPC trades or Records of Eminence.'

xi.trustGrant = xi.trustGrant or {}

function xi.trustGrant.isTrustSpell(spellId)
    return spellId >= TRUST_SPELL_MIN and spellId <= TRUST_SPELL_MAX
end

function xi.trustGrant.isStarter(spellId)
    return STARTER_TRUST_SET[spellId] == true
end

function xi.trustGrant.isEarned(player, spellId)
    if STARTER_TRUST_SET[spellId] then
        return true
    end

    return player:getCharVar(EARNED_PREFIX .. spellId) == 1
end

function xi.trustGrant.markEarned(player, spellId)
    if xi.trustGrant.isTrustSpell(spellId) then
        player:setCharVar(EARNED_PREFIX .. spellId, 1)
    end
end

local function isDisabledTrust(spellId)
    local disabled = xi.trust and xi.trust.DISABLED_SPELL
    if not disabled then
        return false
    end

    return spellId == disabled.ALDO or spellId == disabled.ALDO_UC
end

function xi.trustGrant.grantSpell(player, spellId, params)
    if not xi.trustGrant.isTrustSpell(spellId) then
        player:addSpell(spellId, params)
        return true
    end

    if isDisabledTrust(spellId) then
        return false
    end

    xi.trustGrant.markEarned(player, spellId)
    player:addSpell(spellId, params)
    return true
end

local function stripUnityTrusts(player)
    for _, trustId in pairs(UNITY_TRUST_ID) do
        if player:hasSpell(trustId) and not xi.trustGrant.isEarned(player, trustId) then
            pcall(function()
                player:delSpell(trustId, { silentLog = true, saveToDB = true, sendUpdate = false })
            end)
        end
    end
end

local function stripDisabledTrusts(player)
    local disabled = xi.trust and xi.trust.DISABLED_SPELL
    if not disabled then
        return
    end

    for _, spellId in pairs(disabled) do
        if player:hasSpell(spellId) then
            pcall(function()
                player:delSpell(spellId, { silentLog = true, saveToDB = true, sendUpdate = false })
            end)
            player:setCharVar(EARNED_PREFIX .. spellId, 0)
        end
    end
end

function xi.trustGrant.stripUnauthorized(player)
    stripDisabledTrusts(player)

    for spellId = TRUST_SPELL_MIN, TRUST_SPELL_MAX do
        if player:hasSpell(spellId) and not xi.trustGrant.isEarned(player, spellId) then
            pcall(function()
                player:delSpell(spellId, { silentLog = true, saveToDB = true, sendUpdate = false })
            end)
        end
    end

    stripUnityTrusts(player)
end

local function migrate(player)
    if (player:getCharVar('TrustGateMigrated') or 0) == 1 then
        return
    end

    player:setCharVar('TrustGateMigrated', 1)

    for _, spellId in ipairs(STARTER_TRUSTS) do
        if player:hasSpell(spellId) then
            xi.trustGrant.markEarned(player, spellId)
        end
    end

    for spellId in pairs(VOID_KEEPER_SET) do
        if player:hasSpell(spellId) then
            xi.trustGrant.markEarned(player, spellId)
        end
    end

    xi.trustGrant.stripUnauthorized(player)
end

local function scheduleStripLoop(player)
    player:timer(STRIP_INTERVAL_S * 1000, function(p)
        if p and p:isPC() then
            xi.trustGrant.stripUnauthorized(p)
            scheduleStripLoop(p)
        end
    end)
end

local function filterCipherItems(items)
    if items == nil then
        return nil
    end

    if type(items) == 'number' then
        if xi.trust.isCipherItem(items) then
            return nil
        end

        return items
    end

    if type(items) ~= 'table' then
        return items
    end

    local filtered = {}
    for _, v in pairs(items) do
        local itemId = nil
        if type(v) == 'number' then
            itemId = v
        elseif type(v) == 'table' and type(v[1]) == 'number' then
            itemId = v[1]
        end

        if itemId and not xi.trust.isCipherItem(itemId) then
            filtered[#filtered + 1] = v
        end
    end

    if #filtered == 0 then
        return nil
    end

    return filtered
end

xi.trustGrant.STARTER_TRUSTS = STARTER_TRUSTS

-- Block NPC cipher trades (Clarion Star, Gondebaud, Wetata, …).
m:addOverride('xi.trust.onTradeCipher', function(player, trade, csid, rovCs, arkAngelCs)
    if xi.trust.hasPermit(player) then
        player:printToPlayer(BLOCKED_CIPHER_MSG, xi.msg.channel.SYSTEM_3)
    end
end)

-- Cipher items used from inventory — intended earn path once ciphers drop in content.
m:addOverride('xi.trust.onItemUseCipher', function(target, item)
    if target == nil or item == nil then
        return
    end

    local spellId = xi.trust.getCipherSpellId(item:getID(), item:getSubID())
    if spellId == nil then
        return
    end

    xi.trustGrant.grantSpell(target, spellId)
end)

-- Strip Trust Cipher items from npcUtil.giveItem (ROE, missions, quests, regimes, …).
m:addOverride('npcUtil.giveItem', function(player, items, params)
    local filtered = filterCipherItems(items)
    if filtered == nil then
        return false
    end

    return super(player, filtered, params)
end)

-- C++ UpdateUnityTrust() may grant the Unity UC trust after pledging; revoke unless earned.
m:addOverride('xi.unity.onEventFinish', function(player, csid, option, npc)
    super(player, csid, option, npc)
    player:timer(500, function(p)
        if p then
            xi.trustGrant.stripUnauthorized(p)
        end
    end)
end)

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    local isLogin = player:getLocalVar('gameLogin') == 1
    super(player, firstLogin, zoning)

    if not isLogin then
        return
    end

    migrate(player)
    player:timer(2000, function(p)
        if p then
            xi.trustGrant.stripUnauthorized(p)
            scheduleStripLoop(p)
        end
    end)
end)

return m
