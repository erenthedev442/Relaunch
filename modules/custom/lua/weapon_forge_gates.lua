-----------------------------------
-- weapon_forge_gates.lua
--
-- SINGLE SOURCE OF TRUTH for the stage gates the Weapon Forge enforces.
-- WeaponForge_NPC.lua (in-forge preflight + recipe preview) and the
-- !forgegates player command both `require` this file so their gate labels,
-- check functions, and target counts can never drift apart.
--
-- Every entry is { label = <widget-verbatim string>, check = function(p) ... }.
-- Missing (category, fromStage) tuples fall through as "no new gate" (the
-- pre-existing HL_Tier / divergenceWins / etc. checks in WeaponForge_NPC.lua
-- still apply).
--
-- Player-facing stage indexing:
--   fromStage 0 = "Base -> Stage I"      (about to enter Stage I)
--   fromStage 1 = "Stage I -> Stage II"  (about to enter Stage II)
--   fromStage 2 = "Stage II -> Stage III" (about to enter Stage III)
-----------------------------------
-- FileWatcher dofile discards the return value. Mutate the cached table
-- so path unlocks stay live without a map restart.
local KEY = 'modules/custom/lua/weapon_forge_gates'
local M = package.loaded[KEY]
if type(M) ~= 'table' then
    M = {}
end
package.loaded[KEY] = M

local catalog = require('modules/custom/lua/weapon_forge_catalog')
local abysseaProgress = require('modules/custom/lua/abyssea_marks_progress')
local unityProgress = require('modules/custom/lua/unity_wanted_progress')
local waveProgress = require('modules/custom/lua/game_master_progress')
local aeonicMaat = require('modules/custom/lua/aeonic_maat_catalog')

-- Shown when a player opens a family they have not unlocked yet.
-- Relic is the first path. Empyrean and Mythic both open after Relic.
-- Aeonic opens after Relic plus a finished Empyrean or Mythic. Prime
-- after Aeonic.
M.PATH_LOCKED_MSG = "You've got a long way to go before you're able to start this path!"

local function hasFinal(player, family)
    return (player:getCharVar('WF_' .. family .. '_Final') or 0) == 1
end

local function chainItemIds(chain)
    return { chain.base, chain.s1, chain.s2, chain.s3 }
end

local function familyStarted(player, chains)
    if not player.getItemCount then
        return false
    end
    for _, chain in ipairs(chains) do
        for _, itemId in ipairs(chainItemIds(chain)) do
            if itemId and itemId > 0 and player:getItemCount(itemId) > 0 then
                return true
            end
        end
    end
    return false
end

-- True when this family is already complete or the player is allowed to
-- obtain its starter. Stage gates (Unity, Nyzul, rebirth, …) still apply.
function M.pathUnlocked(player, category)
    if category == 'relic' then
        return true
    end
    if category == 'empyrean' then
        return hasFinal(player, 'Relic')
            or hasFinal(player, 'Empyrean')
            or familyStarted(player, catalog.empyreanChains)
    end
    if category == 'mythic' then
        return hasFinal(player, 'Relic')
            or hasFinal(player, 'Mythic')
            or familyStarted(player, catalog.mythicChains)
    end
    if category == 'aeonic' then
        if hasFinal(player, 'Aeonic') or (player:getCharVar('LWP_AeonicActive') or 0) > 0 then
            return true
        end
        return hasFinal(player, 'Relic')
            and (hasFinal(player, 'Empyrean') or hasFinal(player, 'Mythic'))
    end
    if category == 'prime' then
        return hasFinal(player, 'Aeonic')
    end
    return true
end

-- ── Reusable check closures (per-job scans and all-trials) ─────────────────

local function anyRebirthCap50()
    return function(p)
        for jobId = 1, 22 do
            if (p:getCharVar('Rebirth_Count_' .. jobId) or 0) >= 50 then return true end
        end
        return false
    end
end

local function anyAscension100()
    return function(p)
        for jobId = 1, 22 do
            if (p:getCharVar(('Prestige_Level_%d'):format(jobId)) or 0) >= 100 then return true end
        end
        return false
    end
end

local function allPrimeTrialsAndApexHunter()
    return function(p)
        for i = 1, 5 do
            if (p:getCharVar('PW_Trial' .. i .. '_Done') or 0) ~= 1 then return false end
        end
        return (p:getCharVar('Title_Apex_Hunter') or 0) == 1
    end
end

local function allGeasAeonicOnce()
    return function(p)
        if xi.geasFete and xi.geasFete.aeonicProgress then
            local cleared, need = xi.geasFete.aeonicProgress(p)
            return cleared >= need
        end
        local need = (xi.geasFete and xi.geasFete.aeonicNmCount) or math.huge
        return (p:getCharVar('GF_Aeonic_Kills') or 0) >= need
    end
end

-- ── STAGE_GATES table ──────────────────────────────────────────────────────

M.STAGE_GATES =
{
    relic =
    {
        [0] =
        {
            label = 'All Tier 2 Unity Wanted NMs conquered',
            check = function(p) return unityProgress.tierComplete(p, 2) end,
        },
        [1] =
        {
            label = 'All Tier 3 Unity Wanted NMs conquered',
            check = function(p) return unityProgress.tierComplete(p, 3) end,
        },
        [2] =
        {
            label = 'Wave Master Nightmare cleared',
            check = function(p) return waveProgress.has(p, 'Nightmare') end,
        },
    },
    empyrean =
    {
        [0] =
        {
            -- T1-T2 roster only. T3-T4 are Aeonic-era (silt / Attestations).
            label = 'All Geas Fete T1-T2 NMs killed at least once',
            check = function(p)
                if xi.geasFete and xi.geasFete.empyreanProgress then
                    local cleared, need = xi.geasFete.empyreanProgress(p)
                    return cleared >= need
                end
                local need = (xi.geasFete and xi.geasFete.empyreanNmCount) or math.huge
                return (p:getCharVar('GF_Empyrean_Kills') or 0) >= need
            end,
        },
        [1] =
        {
            label = 'Voidspire Floor 100 reached',
            check = function(p) return (p:getCharVar('Voidspire_Best_Floor') or 0) >= 100 end,
        },
        [2] =
        {
            label = 'First-Empyrean Abyssea roster complete + Wave Master Apocalypse cleared',
            check = function(p)
                return abysseaProgress.firstEmpyreanGatePassed(p)
                    and waveProgress.has(p, 'Apocalypse')
            end,
        },
    },
    mythic =
    {
        [0] =
        {
            label = 'Floor 100 recorded on your Runic Disc',
            check = function(p) return (p:getCharVar('Nyzul_F100_Cleared') or 0) == 1 end,
        },
        [1] =
        {
            label = 'All Voidwatch NMs killed',
            check = function(p)
                local need = (xi.voidwatch and xi.voidwatch.uniqueNmCount) or math.huge
                return (p:getCharVar('VW_Unique_Kills') or 0) >= need
            end,
        },
        [2] =
        {
            label = '1 Gauntlet win + Wave Master Apocalypse cleared',
            check = function(p)
                return (p:getCharVar('Gauntlet_Clears') or 0) >= 1
                    and waveProgress.has(p, 'Apocalypse')
            end,
        },
    },
    aeonic =
    {
        [0] =
        {
            label = 'Final Relic and a final Empyrean or Mythic forged, and 50 rebirths on one job',
            check = function(p)
                return (p:getCharVar('WF_Relic_Final') or 0) == 1
                    and ((p:getCharVar('WF_Empyrean_Final') or 0) == 1
                        or (p:getCharVar('WF_Mythic_Final') or 0) == 1)
                    and anyRebirthCap50()(p)
            end,
        },
        [1] =
        {
            label = '100 Ascensions on a single job + all Geas Fete T3-T4 NMs killed once',
            check = function(p)
                return anyAscension100()(p) and allGeasAeonicOnce()(p)
            end,
        },
        [2] =
        {
            label = "All Dungeons + this weapon's solo Aeonic Maat trial + Wave Master Oblivion cleared",
            check = function(p, chain)
                local need = (xi.dungeonInstances and xi.dungeonInstances.uniqueDungeonCount) or math.huge
                return (p:getCharVar('Dungeon_Unique_Clears') or 0) >= need
                   and chain ~= nil
                   and chain.aeonic ~= nil
                   and aeonicMaat.isComplete(p, chain.aeonic.s3.id)
                   and waveProgress.has(p, 'Oblivion')
            end,
        },
    },
    prime =
    {
        [0] =
        {
            label = 'Built a final Aeonic weapon',
            check = function(p) return (p:getCharVar('WF_Aeonic_Final') or 0) == 1 end,
        },
        [1] =
        {
            label = "All 5 Prime Armory Trials complete + Apex Hunter in the Hunter's Guild",
            check = allPrimeTrialsAndApexHunter(),
        },
        [2] =
        {
            label = 'Wave Master Ragnarok cleared',
            check = function(p) return waveProgress.has(p, 'Ragnarok') end,
        },
    },
    -- Ergon follows the Mythic path; existing material checks remain authoritative.
}

-- ── Display order (Relic -> Empyrean -> Mythic -> Aeonic -> Prime) ─────────
-- Matches the widget's category tab order. The command iterates this list so
-- categories with no gates render as "no new gates on this category".
M.DISPLAY_ORDER = { 'relic', 'empyrean', 'mythic', 'aeonic', 'prime' }

M.CATEGORY_LABELS =
{
    relic    = 'Relic',
    empyrean = 'Empyrean',
    mythic   = 'Mythic',
    aeonic   = 'Aeonic',
    prime    = 'Prime',
}

-- ── Helpers ────────────────────────────────────────────────────────────────

-- Returns (ok, gateOrNil). ok is true if the gate passes (or doesn't exist).
function M.checkGate(player, category, fromStage, chain)
    local cat = M.STAGE_GATES[category]
    if not cat then return true, nil end
    local gate = cat[fromStage]
    if not gate then return true, nil end
    return gate.check(player, chain), gate
end

return M
