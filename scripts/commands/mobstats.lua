-----------------------------------
-- !mobstats
-- Dump all combat-relevant stats for the cursor-targeted entity in one
-- shot. Works on mobs, trusts, PCs, and automatons -- anything that is
-- not a plain NPC.
--
-- Usage:  !mobstats
--
-- Output example (mob):
--   [MobStats] Test_Dummy_Standard  Lv.99  WAR/MNK
--   [MobStats] HP: 10000000/10000000  MP: 0/0
--   [MobStats] STR:220 DEX:200 VIT:195 AGI:180 INT:120 MND:110 CHR:100
--   [MobStats] DEF:420 EVA:310 MEVA:0 | ATT:380 ACC:340 MATT:0 MACC:0
--   [MobStats] Phys SDT — Slash:100% Pierce:100% Impact:100% H2H:100%
--   [MobStats] Elem SDT — Fire:100% Ice:100% Wind:100% Earth:100%
--                          Thunder:100% Water:100% Light:100% Dark:100%
--   [MobStats] Weapon dmg:22  Immunities: None
--
-- SDT percentages: 100% = neutral, <100% = resistant, >100% = weak
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = '',
}

-- Build id->name map from xi.job once.
local function buildJobNames()
    local t = {}
    for name, id in pairs(xi.job) do
        t[id] = name
    end
    return t
end

-- Convert a raw SDT mod value (stored as delta from neutral in /10000 units)
-- to an integer percentage. 0 -> 100%, -5000 -> 50%, 2500 -> 125%.
local function sdtPct(modVal)
    return math.floor((1 + modVal / 10000) * 100 + 0.5)
end

local ELEM_ORDER = {
    xi.element.FIRE,
    xi.element.ICE,
    xi.element.WIND,
    xi.element.EARTH,
    xi.element.THUNDER,
    xi.element.WATER,
    xi.element.LIGHT,
    xi.element.DARK,
}

local ELEM_ABBR = {
    [xi.element.FIRE]     = 'Fire',
    [xi.element.ICE]      = 'Ice',
    [xi.element.WIND]     = 'Wind',
    [xi.element.EARTH]    = 'Earth',
    [xi.element.THUNDER]  = 'Thunder',
    [xi.element.WATER]    = 'Water',
    [xi.element.LIGHT]    = 'Light',
    [xi.element.DARK]     = 'Dark',
}

commandObj.onTrigger = function(player)
    local target = player:getCursorTarget()
    if target == nil then
        player:printToPlayer('[MobStats] Target something first.', xi.msg.channel.SYSTEM_3)
        return
    end

    local objType = target:getObjType()
    if objType == xi.objType.NPC then
        player:printToPlayer('[MobStats] NPCs have no combat stats.', xi.msg.channel.SYSTEM_3)
        return
    end

    local function p(msg)
        player:printToPlayer('[MobStats] ' .. msg, xi.msg.channel.SYSTEM_3)
    end

    local jobNames = buildJobNames()
    local mJobId   = target:getMainJob()
    local sJobId   = target:getSubJob()
    local mJobName = jobNames[mJobId] or ('?'..mJobId)
    local sJobName = jobNames[sJobId] or ('?'..sJobId)

    -- ── Line 1: identity ──────────────────────────────────────────────
    p(string.format('%s  Lv.%d  %s/%s',
        target:getName(),
        target:getMainLvl(),
        mJobName, sJobName))

    -- ── Line 2: HP / MP ───────────────────────────────────────────────
    p(string.format('HP: %d/%d  MP: %d/%d',
        target:getHP(), target:getMaxHP(),
        target:getMP(), target:getMaxMP()))

    -- ── Line 3: primary stats ─────────────────────────────────────────
    p(string.format('STR:%d DEX:%d VIT:%d AGI:%d INT:%d MND:%d CHR:%d',
        target:getStat(xi.mod.STR),
        target:getStat(xi.mod.DEX),
        target:getStat(xi.mod.VIT),
        target:getStat(xi.mod.AGI),
        target:getStat(xi.mod.INT),
        target:getStat(xi.mod.MND),
        target:getStat(xi.mod.CHR)))

    -- ── Line 4: defensive / offensive totals ──────────────────────────
    p(string.format('DEF:%d EVA:%d MEVA:%d | ATT:%d ACC:%d MATT:%d MACC:%d',
        target:getStat(xi.mod.DEF),
        target:getStat(xi.mod.EVA),
        target:getMod(xi.mod.MEVA),
        target:getStat(xi.mod.ATT),
        target:getStat(xi.mod.ACC),
        target:getMod(xi.mod.MATT),
        target:getMod(xi.mod.MACC)))

    -- ── Line 5: physical SDTs ─────────────────────────────────────────
    p(string.format('Phys SDT — Slash:%d%% Pierce:%d%% Impact:%d%% H2H:%d%%',
        sdtPct(target:getMod(xi.mod.SLASH_SDT)),
        sdtPct(target:getMod(xi.mod.PIERCE_SDT)),
        sdtPct(target:getMod(xi.mod.IMPACT_SDT)),
        sdtPct(target:getMod(xi.mod.HTH_SDT))))

    -- ── Line 6: elemental SDTs ────────────────────────────────────────
    local elemParts = {}
    for _, elem in ipairs(ELEM_ORDER) do
        local pct = sdtPct(target:getMod(xi.data.element.getElementalSDTModifier(elem)))
        elemParts[#elemParts + 1] = string.format('%s:%d%%', ELEM_ABBR[elem], pct)
    end
    p('Elem SDT — ' .. table.concat(elemParts, ' '))

    -- ── Line 7: weapon dmg + immunities (mobs only) ───────────────────
    local extras = string.format('Weapon dmg:%d', target:getWeaponDmg())
    if objType == xi.objType.MOB then
        local immuneStr = 'None'
        local parts     = {}
        for name, flag in pairs(xi.immunity) do
            if flag > 0 and target:hasImmunity(flag) then
                parts[#parts + 1] = name
            end
        end
        if #parts > 0 then
            table.sort(parts)
            immuneStr = table.concat(parts, ' ')
        end
        extras = extras .. '  Immunities: ' .. immuneStr
    end
    p(extras)
end

return commandObj
