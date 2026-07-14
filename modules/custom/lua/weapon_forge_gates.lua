-----------------------------------
-- weapon_forge_gates.lua
--
-- SINGLE SOURCE OF TRUTH for the 11 stage gates the Weapon Forge enforces.
-- WeaponForge_NPC.lua (in-forge preflight + recipe preview) and the
-- !forgegates player command both `require` this file so their gate labels,
-- check functions, and target counts can never drift apart.
--
-- Every entry is { label = <widget-verbatim string>, check = function(p) ... }.
-- Missing (category, fromStage) tuples fall through as "no new gate" (the
-- pre-existing HL_Tier / divergenceWins / etc. checks in WeaponForge_NPC.lua
-- still apply).
--
-- Widget stage indexing (matches docs/progression/weapon-forge/):
--   fromStage 0 = "Base -> Stage I"      (about to enter Stage I)
--   fromStage 1 = "Stage I -> Stage II"  (about to enter Stage II)
--   fromStage 2 = "Stage II -> Stage III" (about to enter Stage III)
-----------------------------------
local M = {}

-- ── Reusable check closures (per-job scans, all-trials, any-forge-final) ────

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

local function anyForgeFinal()
    return function(p)
        return (p:getCharVar('WF_Relic_Final')    or 0) == 1
            or (p:getCharVar('WF_Mythic_Final')   or 0) == 1
            or (p:getCharVar('WF_Empyrean_Final') or 0) == 1
            or (p:getCharVar('WF_Aeonic_Final')   or 0) == 1
    end
end

-- ── STAGE_GATES table ──────────────────────────────────────────────────────

M.STAGE_GATES =
{
    empyrean =
    {
        [0] =
        {
            label = 'All Geas Fete bosses killed at least once',
            check = function(p)
                local need = (xi.geasFete and xi.geasFete.uniqueNmCount) or math.huge
                return (p:getCharVar('GF_Unique_Kills') or 0) >= need
            end,
        },
        [1] =
        {
            label = 'Voidspire Floor 100 reached',
            check = function(p) return (p:getCharVar('Voidspire_Best_Floor') or 0) >= 100 end,
        },
        [2] =
        {
            label = 'Fellow Mastery achieved',
            check = function(p) return (p:getCharVar('Fellow_Mastered') or 0) == 1 end,
        },
    },
    mythic =
    {
        [0] =
        {
            label = 'Nyzul Isle Floor 100 cleared',
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
            label = '1 successful win of The Gauntlet',
            check = function(p) return (p:getCharVar('Gauntlet_Clears') or 0) >= 1 end,
        },
    },
    aeonic =
    {
        [0] =
        {
            label = '50 rebirths on a single job (not combined)',
            check = anyRebirthCap50(),
        },
        [1] =
        {
            label = '100 Ascensions on a single job (not combined)',
            check = anyAscension100(),
        },
        [2] =
        {
            label = "All Dungeons cleared + 10 wins against Maat's Echo",
            check = function(p)
                local need = (xi.dungeonInstances and xi.dungeonInstances.uniqueDungeonCount) or math.huge
                return (p:getCharVar('Dungeon_Unique_Clears') or 0) >= need
                   and (p:getCharVar('Maat_Kills') or 0) >= 10
            end,
        },
    },
    prime =
    {
        [0] =
        {
            label = 'Built a Relic, Mythic, Empyrean, or Aeonic final weapon',
            check = anyForgeFinal(),
        },
        [1] =
        {
            label = "All 5 Prime Armory Trials complete + Apex Hunter in the Hunter's Guild",
            check = allPrimeTrialsAndApexHunter(),
        },
        -- Stage III intentionally unset -- existing HL_Tier + all-trials + gil
        -- checks in doUpgrade cover it. Fill in here to add a new Stage III gate.
    },
    -- Relic and Ergon: existing checks in WeaponForge_NPC.lua stay authoritative.
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
function M.checkGate(player, category, fromStage)
    local cat = M.STAGE_GATES[category]
    if not cat then return true, nil end
    local gate = cat[fromStage]
    if not gate then return true, nil end
    return gate.check(player), gate
end

return M
