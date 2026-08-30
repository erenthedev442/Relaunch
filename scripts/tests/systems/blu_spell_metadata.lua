describe('BLU spell metadata integrity', function()
    local function readFile(path)
        local file = assert(io.open(path, 'r'))
        local text = file:read('*a')
        file:close()
        return text
    end

    local function parseMagicIds(text)
        local ids = {}
        for name, id in text:gmatch('%s+([A-Z0-9_]+)%s*=%s*(%d+),') do
            ids[name] = tonumber(id)
        end

        return ids
    end

    local function parseSpellRows(text)
        local rows = {}
        for row in text:gmatch("INSERT INTO `spell_list` VALUES %((.-)%);") do
            local fields = {}
            for field in row:gmatch('[^,]+') do
                fields[#fields + 1] = field
            end

            rows[tonumber(fields[1])] =
            {
                element      = tonumber(fields[6]),
                mpCost       = tonumber(fields[10]),
                castTime     = tonumber(fields[11]),
                recastTime   = tonumber(fields[12]),
                animation    = tonumber(fields[15]),
                requirements = tonumber(fields[22]),
            }
        end

        return rows
    end

    local function parseBlueRows(text)
        local rows = {}
        for id, mobSkillId, setPoints in
            text:gmatch("INSERT INTO `blue_spell_list` VALUES %((%d+),(%d+),(%d+),")
        do
            rows[tonumber(id)] =
            {
                mobSkillId = tonumber(mobSkillId),
                setPoints  = tonumber(setPoints),
            }
        end

        return rows
    end

    local magicIds = parseMagicIds(readFile('scripts/enum/magic.lua'))
    local progression = readFile('modules/custom/lua/blu_spell_progression.lua')
    local spellRows = parseSpellRows(readFile('sql/spell_list.sql'))
    local blueRows = parseBlueRows(readFile('sql/blue_spell_list.sql'))
    local modSql = readFile('sql/blue_spell_mods.sql')

    it('keeps all 195 progression entries loadable and settable', function()
        local seen = {}
        local count = 0
        for name in progression:gmatch('xi%.magic%.spell%.([A-Z0-9_]+)') do
            local id = magicIds[name]
            assert(id ~= nil, string.format('missing magic enum for %s', name))
            assert(not seen[id], string.format('duplicate progression spell %u', id))
            assert(spellRows[id] ~= nil, string.format('missing spell_list row %u', id))
            assert(blueRows[id] ~= nil, string.format('missing blue_spell_list row %u', id))
            seen[id] = true
            count = count + 1
        end

        assert(count == 195, string.format('expected 195 BLU spells, found %u', count))
    end)

    it('keeps premium spell costs and safe SOA animations intact', function()
        local premiumAnimations =
        {
            [719] = 673, -- Self-Destruct
            [720] = 721, -- Ice Break
            [721] = 697, -- Blitzstrahl
            [722] = 631, -- Sandspin
            [725] = 741, -- Actinic Burst
            [726] = 690, -- Maelstrom
            [727] = 695, -- Mysterious Light
            [728] = 661, -- Blood Saber
        }

        for id, animation in pairs(premiumAnimations) do
            assert(blueRows[id].setPoints == 8, string.format('spell %u must cost 8 points', id))
            assert(spellRows[id].animation == animation, string.format('spell %u has unsafe animation', id))
        end

        assert(spellRows[749].animation == 688, 'Polar Roar must use Frost Breath, not Warp')
        assert(spellRows[724].animation == 704, 'Palling Salvo must use Eyes On Me')
        assert(spellRows[750].animation == 654, 'Mighty Guard must use Cocoon')
        assert(spellRows[717].animation == 698, 'Sweeping Gouge must use Sickle Slash')
        assert(spellRows[723].animation == 692, 'Saurian Slide must use Uppercut')
    end)

    it('keeps Tenebral Crush on the same INT payload as Spectral Floe', function()
        local floe = readFile('scripts/actions/spells/blue/spectral_floe.lua')
        local tenebral = readFile('scripts/actions/spells/blue/tenebral_crush.lua')

        assert(floe:match('int_wsc%s*=%s*0%.8'), 'Spectral Floe must stay 0.8 INT')
        assert(tenebral:match('int_wsc%s*=%s*0%.8'), 'Tenebral Crush must use 0.8 INT')
        assert(tenebral:match('vit_wsc%s*=%s*0%.0'), 'Tenebral Crush must not split onto VIT')
        assert(tenebral:match('mnd_wsc%s*=%s*0%.0'), 'Tenebral Crush must not split onto MND')
        assert(tenebral:match('multiplier%s*=%s*6%.5'), 'Tenebral Crush multiplier must match the 8-point suite')
    end)

    it('uses real learn skills and passive modifiers for repaired spells', function()
        assert(blueRows[709].mobSkillId == 3974)
        assert(blueRows[711].mobSkillId == 2041)
        assert(blueRows[712].mobSkillId == 2040)

        for id = 708, 714 do
            assert(
                not modSql:find(string.format('VALUES %(%u,0,0%)', id)),
                string.format('spell %u still has placeholder modifiers', id))
        end
    end)

    it('keeps the re-enabled BLU spells castable and bounded', function()
        local fantod = readFile('scripts/actions/spells/blue/fantod.lua')
        local mortalRay = readFile('scripts/actions/spells/blue/mortal_ray.lua')
        local pyricBulwark = readFile('scripts/actions/spells/blue/pyric_bulwark.lua')
        local damageMultipliers = readFile('scripts/globals/combat/damage_multipliers.lua')

        for name, source in pairs(
        {
            fantod        = fantod,
            mortal_ray    = mortalRay,
            pyric_bulwark = pyricBulwark,
        })
        do
            assert(
                source:match('onMagicCastingCheck%s*=%s*function.-return 0'),
                string.format('%s must remain castable', name))
        end

        assert(fantod:match('math%.min%(currentEffect:getPower%(%) %+ 5, 25%)'))
        assert(pyricBulwark:match('subPower%s*=%s*255'))
        assert(damageMultipliers:match('physicalShield:getSubPower%(%) == 255'))
        assert(damageMultipliers:match('delStatusEffectSilent%(xi%.effect%.PHYSICAL_SHIELD%)'))

        assert(spellRows[674].mpCost == 12 and spellRows[674].recastTime == 10000)
        assert(spellRows[686].mpCost == 267 and spellRows[686].castTime == 8000)
        assert(spellRows[686].recastTime == 150000)
        assert(spellRows[741].element == 2 and spellRows[741].requirements == 16)
        assert(blueRows[674].mobSkillId == 580 and blueRows[674].setPoints == 1)
        assert(blueRows[686].mobSkillId == 502 and blueRows[686].setPoints == 4)
        assert(blueRows[741].mobSkillId == 1831 and blueRows[741].setPoints == 0)
    end)
end)
