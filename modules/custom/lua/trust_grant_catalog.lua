-----------------------------------
-- trust_grant_catalog.lua
-- Shared trust-economy constants (starters, spell id range, Unity UC ids).
-- Required by trust_grant_gate.lua and Character_Upgrader.lua.
-----------------------------------
local catalog = {}

catalog.TRUST_SPELL_MIN = 896
catalog.TRUST_SPELL_MAX = 1021

-- Starter trusts (see exports/trust_cipher_drop_proposal.csv).
catalog.STARTER_TRUSTS = { 896, 898, 905, 908 } -- Shantotto, Kupipi, Trion, Tenzen

catalog.STARTER_TRUST_SET = {}
for _, spellId in ipairs(catalog.STARTER_TRUSTS) do
    catalog.STARTER_TRUST_SET[spellId] = true
end

-- Void Keeper capstones / paid custom trusts — grandfather on migration if owned.
catalog.VOID_KEEPER_SPELL_SET =
{
    [899]  = true, -- Meat / Excenmille
    [901]  = true, -- Gemma / Nanaa Mihgo
    [902]  = true, -- Corvus / Curilla
    [1002] = true, -- Cornelia (client spell id)
    [1003] = true, -- Matsui-P (client spell id)
}

-- Mirror of ROE_TRUST_ID[11] from src/map/roe.h (C++ UpdateUnityTrust grants these).
catalog.UNITY_TRUST_ID =
{
    [1]  = 953,  -- Pieuje
    [2]  = 1005, -- Ayame
    [3]  = 954,  -- Invincible Shield
    [4]  = 955,  -- Apururu
    [5]  = 1006, -- Maat
    [6]  = 1007, -- Aldo
    [7]  = 956,  -- Jakoh
    [8]  = 1008, -- Naja
    [9]  = 957,  -- Flaviria
    [10] = 980,  -- Yoran-Oran
    [11] = 981,  -- Sylvie
}

catalog.EARNED_CHARVAR_PREFIX = 'TrustEarned_'

return catalog
