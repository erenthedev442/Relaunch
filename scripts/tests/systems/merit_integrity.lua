local function readFile(path)
    local file = assert(io.open(path, 'r'))
    local text = file:read('*a')
    file:close()
    return text
end

local function parseSqlTuple(inner)
    local fields = {}
    local current = {}
    local inQuote = false

    for i = 1, #inner do
        local ch = inner:sub(i, i)
        if ch == "'" and not inQuote then
            inQuote = true
        elseif ch == "'" and inQuote then
            inQuote = false
        elseif ch == ',' and not inQuote then
            fields[#fields + 1] = table.concat(current)
            current = {}
        else
            current[#current + 1] = ch
        end
    end

    fields[#fields + 1] = table.concat(current)
    return fields
end

local function parseMeritsSql(text)
    local rows = {}
    for inner in text:gmatch("INSERT INTO `merits` VALUES %((.-)%);") do
        local fields = parseSqlTuple(inner)
        local id     = tonumber(fields[1])
        local name   = fields[2] and fields[2]:match("^'(.-)'$") or fields[2]
        rows[id] =
        {
            name       = name,
            upgrade    = tonumber(fields[3]),
            value      = tonumber(fields[4]),
            jobs       = tonumber(fields[5]),
            upgradeid  = tonumber(fields[6]),
            categoryid = tonumber(fields[7]),
        }
    end

    return rows
end

local function parseAbilityMeritIds(text)
    local rows = {}
    for inner in text:gmatch("INSERT INTO `abilities` VALUES %((.-)%);") do
        local fields = parseSqlTuple(inner)
        local name   = fields[2] and fields[2]:match("^'(.-)'$") or fields[2]
        rows[name] =
        {
            id         = tonumber(fields[1]),
            meritModID = tonumber(fields[19]) or 0,
            addType    = tonumber(fields[20]) or 0,
        }
    end

    return rows
end

local function parseChargeMeritIds(text)
    local rows = {}
    for recastId, job, level, maxCharges, chargeTime, meritModID in
        text:gmatch("INSERT INTO `abilities_charges` VALUES %((%d+),(%d+),(%d+),(%d+),(%d+),(%d+)%)")
    do
        rows[#rows + 1] =
        {
            recastId   = tonumber(recastId),
            job        = tonumber(job),
            meritModID = tonumber(meritModID),
        }
    end

    return rows
end

-- SQL names that do not upper-snake to the Lua enum key.
local sqlNameToLua =
{
    max_merits                  = 'MAX_MERIT',
    guarding_skill              = 'GUARDING',
    evasion_skill               = 'EVASION',
    shield_skill                = 'SHIELD',
    parrying_skill              = 'PARRYING',
    ninjitsu                    = 'NINJITSU',
    geo                         = 'GEOMANCY',
    spell_interuption_rate      = 'SPELL_INTERUPTION_RATE',
    beserk_recast               = 'BERSERK_RECAST',
    zashin_attack_rate          = 'ZASHIN_ATTACK_RATE',
    ecliptic_attrition_recast   = 'ECLIPTIC_ATT_RECAST',
    rune_enchantment_effect     = 'MERIT_RUNE_ENHANCE',
    vallation_effect            = 'MERIT_VALLATION_EFFECT',
    lunge_effect                = 'MERIT_LUNGE_EFFECT',
    pflug_effect                = 'MERIT_PFLUG_EFFECT',
    gambit_recast               = 'MERIT_GAMBIT_EFFECT',
    desperate_blows_effect      = 'DESPERATE_BLOWS',
    anc_magic_attack_bonus      = 'ANCIENT_MAGIC_ATK_BONUS',
    anc_magic_burst_dmg         = 'ANCIENT_MAGIC_BURST_DMG',
    ele_magic_acc               = 'ELEMENTAL_MAGIC_ACCURACY',
    ele_magic_debuff_duration   = 'ELEMENTAL_DEBUFF_DURATION',
    ele_magic_debuff_effect     = 'ELEMENTAL_DEBUFF_EFFECT',
    melee_accuracy              = 'ACCURACY',
    nin_magic_attack            = 'NIN_MAGIC_BONUS',
    enquanimity                 = 'EQUANIMITY',
    battuta                     = 'MERIT_BATTUTA',
    rayke                       = 'MERIT_RAYKE',
    inspiration                 = 'MERIT_INSPIRATION',
    sleight_of_sword            = 'MERIT_SLEIGHT_OF_SWORD',
}

local function luaNameForSql(name)
    return sqlNameToLua[name] or name:upper()
end

-- Effect merits that must have a live consumer (not recast-only, not unlock-only).
local requiredConsumers =
{
    { token = 'xi.merit.STEP_ACCURACY',              path = 'scripts/globals/job_utils/dancer.lua' },
    { token = 'xi.merit.BANISH_EFFECT',              path = 'scripts/globals/spells/damage_spell.lua' },
    { token = 'xi.merit.ANIMUS_MISERY',              path = 'scripts/globals/spells/damage_spell.lua' },
    { token = 'xi.merit.WEAPON_BASH_EFFECT',         path = 'scripts/globals/job_utils/dark_knight.lua' },
    { token = 'xi.merit.LAST_RESORT_EFFECT',         path = 'scripts/effects/last_resort.lua' },
    { token = 'xi.merit.MERIT_LUNGE_EFFECT',         path = 'scripts/globals/job_utils/rune_fencer.lua' },
    { token = 'xi.merit.PRIMEVAL_ZEAL',              path = 'scripts/globals/job_utils/geomancer.lua' },
    { token = 'xi.merit.PROTECTRA_V',                path = 'scripts/globals/spells/enhancing_spell.lua' },
    { token = 'xi.merit.SHELLRA_V',                  path = 'scripts/globals/spells/enhancing_spell.lua' },
    { token = 'xi.merit.CON_ANIMA',                  path = 'scripts/globals/spells/enhancing_song.lua' },
    { token = 'xi.merit.CON_BRIO',                   path = 'scripts/globals/spells/enhancing_song.lua' },
    { token = 'xi.merit.ASPIR_ABSORPTION_AMOUNT',    path = 'scripts/globals/spells/absorb_spell.lua' },
    { token = 'xi.merit.BEAST_HEALER',               path = 'scripts/globals/job_utils/beastmaster.lua' },
    { token = 'MERIT_KILLER_EFFECTS',                path = 'src/map/utils/battleutils.cpp' },
    { token = 'MERIT_SUPER_JUMP_RECAST',             path = 'src/map/merit.h' },
}

describe('Job merit integrity', function()
    local meritRows   = parseMeritsSql(readFile('sql/merits.sql'))
    local abilities   = parseAbilityMeritIds(readFile('sql/abilities.sql'))
    local charges     = parseChargeMeritIds(readFile('sql/abilities_charges.sql'))

    it('keeps Lua merit IDs aligned with merits.sql', function()
        local seenLua = {}
        local missing = {}

        for id, row in pairs(meritRows) do
            local luaName = luaNameForSql(row.name)
            local luaId   = xi.merit[luaName]
            if luaId ~= id then
                missing[#missing + 1] = string.format('%s sql=%s lua=%s (%s)', row.name, id, tostring(luaId), luaName)
            else
                seenLua[luaName] = true
            end
        end

        assert(#missing == 0, 'Lua/SQL merit ID mismatches:\n  ' .. table.concat(missing, '\n  '))

        local extra = {}
        for luaName, luaId in pairs(xi.merit) do
            if type(luaName) == 'string' and type(luaId) == 'number' and not seenLua[luaName] then
                extra[#extra + 1] = string.format('%s=%s', luaName, luaId)
            end
        end

        table.sort(extra)
        assert(#extra == 0, 'Lua merits missing from merits.sql:\n  ' .. table.concat(extra, '\n  '))
    end)

    it('wires Super Jump recast to merit 1222 on both sides', function()
        assert(xi.merit.SUPER_JUMP_RECAST == 1222)
        assert(meritRows[1222] ~= nil)
        assert(meritRows[1222].name == 'super_jump_recast')
        assert(abilities.super_jump ~= nil)
        assert(abilities.super_jump.meritModID == 1222)
        assert(abilities.super_jump.meritModID ~= 1221)
    end)

    it('does not treat Lunge Effect as a recast merit', function()
        assert(xi.merit.MERIT_LUNGE_EFFECT == 1796)
        assert(meritRows[1796] ~= nil)
        assert(meritRows[1796].name == 'lunge_effect')
        assert(abilities.lunge ~= nil)
        assert(abilities.lunge.meritModID == 0)
    end)

    it('points every ability meritModID at a real merit', function()
        local bad = {}
        for name, row in pairs(abilities) do
            if row.meritModID > 0 and meritRows[row.meritModID] == nil then
                bad[#bad + 1] = string.format('%s meritModID=%s', name, row.meritModID)
            end
        end

        table.sort(bad)
        assert(#bad == 0, 'ability meritModIDs not in merits.sql:\n  ' .. table.concat(bad, '\n  '))
    end)

    it('points every charge meritModID at a real merit', function()
        for _, row in ipairs(charges) do
            if row.meritModID > 0 then
                assert(meritRows[row.meritModID] ~= nil, string.format('charges recast %s uses missing merit %s', row.recastId, row.meritModID))
            end
        end
    end)

    it('keeps previously dead effect merits wired to a consumer', function()
        local missing = {}
        for _, entry in ipairs(requiredConsumers) do
            local text = readFile(entry.path)
            if not text:find(entry.token, 1, true) then
                missing[#missing + 1] = string.format('%s missing from %s', entry.token, entry.path)
            end
        end

        assert(#missing == 0, table.concat(missing, '\n'))
    end)
end)
