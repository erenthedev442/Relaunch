-----------------------------------
-- func: fellowaudit
-- desc: Audit the summoned Fellow -- for each mod the build should add, shows
--       EXPECTED (from your allocations + level) vs the LIVE getMod on the pet,
--       flagging anything that didn't land. Answers "does boosting STR actually
--       reach the Fellow?". Fellow must be summoned.
--
-- SELF-CONTAINED on purpose: it hot-loads with NO server restart. The full
-- xi.fellow.audit (which also folds in role/survival mods) lives in
-- fellow_companion.lua, an addOverride module that only reloads on restart -- so
-- until then this command runs its own embedded audit; after a restart it defers
-- to xi.fellow.audit automatically. Keep STATMODS/PERLEVEL in sync with CONFIG.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

-- Mirror of fellow_companion CONFIG.statMods + CONFIG.perLevel (allocatable only).
local STATMODS =
{
    STR       = { { xi.mod.STR, 6 }, { xi.mod.ATT, 12 } },
    DEX       = { { xi.mod.DEX, 6 }, { xi.mod.ACC, 10 } },
    VIT       = { { xi.mod.VIT, 6 }, { xi.mod.DEF, 10 } },
    AGI       = { { xi.mod.AGI, 6 }, { xi.mod.EVA, 10 } },
    INT       = { { xi.mod.INT, 6 }, { xi.mod.MATT, 10 } },
    MND       = { { xi.mod.MND, 6 }, { xi.mod.MDEF, 10 } },
    Ferocity  = { { xi.mod.ATTP, 1 } },
    Frenzy    = { { xi.mod.DOUBLE_ATTACK, 1 } },
    Onslaught = { { xi.mod.TRIPLE_ATTACK, 1 }, { xi.mod.STORETP, 3 } },
    Sorcery   = { { xi.mod.MATT, 12 }, { xi.mod.MACC, 6 } },
    Warding   = { { xi.mod.DMGPHYS, -20 }, { xi.mod.DMGMAGIC, -20 } },
}
local PERLEVEL = { { xi.mod.ATT, 80 }, { xi.mod.ACC, 40 }, { xi.mod.DEF, 15 } }

local function embeddedAudit(player)
    local SYS = xi.msg.channel.SYSTEM_3
    if not player:hasPet() then
        player:printToPlayer('[Fellow] Summon your Fellow first -- the audit reads mods off the live pet.', SYS)
        return
    end
    local pet = player:getPet()
    local lvl = math.max(1, player:getCharVar('Fellow_Level') or 0)

    local MODNAME = {}
    for k, v in pairs(xi.mod) do if type(v) == 'number' then MODNAME[v] = MODNAME[v] or k end end

    local expected, source = {}, {}
    local function add(mod, val, src)
        if not mod or val == 0 then return end
        expected[mod] = (expected[mod] or 0) + val
        source[mod]   = source[mod] and (source[mod] .. '+' .. src) or src
    end
    for _, mv in ipairs(PERLEVEL) do add(mv[1], mv[2] * lvl, 'lvl') end
    for stat, mods in pairs(STATMODS) do
        local pts = player:getCharVar('Fellow_' .. stat) or 0
        if pts > 0 then
            for _, mv in ipairs(mods) do add(mv[1], mv[2] * pts, stat .. 'x' .. pts) end
        end
    end

    local rows = {}
    for mod in pairs(expected) do rows[#rows + 1] = mod end
    table.sort(rows)

    player:printToPlayer(string.format('=== Fellow audit (Lv%d) -- expected (alloc+lvl) vs LIVE ===', lvl), SYS)
    player:printToPlayer('  role mods add MORE on top, so derived stats reading HIGHER is fine', SYS)
    local low = 0
    for _, mod in ipairs(rows) do
        local exp = expected[mod]
        local act = pet:getMod(mod)
        -- allocation must be present in the total: >= for boosts, <= for reductions (Warding)
        local ok = (exp >= 0 and act >= exp) or (exp < 0 and act <= exp)
        if not ok then low = low + 1 end
        player:printToPlayer(string.format('  %-14s exp %5d  live %5d  %s (%s)',
            MODNAME[mod] or ('mod' .. mod), exp, act, ok and 'OK' or '**LOW**', source[mod]), SYS)
    end
    player:printToPlayer(low == 0
        and '  All allocated stats are present on the pet. Spend a point + re-run to watch a row move.'
        or  string.format('  ** %d stat mod(s) LOW -- not reaching the entity (bug). **', low), SYS)
end

commandObj.onTrigger = function(player)
    if xi.fellow and xi.fellow.audit then
        xi.fellow.audit(player)   -- richer version after a restart (also folds in role/survival mods)
    else
        embeddedAudit(player)     -- hot-load fallback: works with NO restart
    end
end

return commandObj
