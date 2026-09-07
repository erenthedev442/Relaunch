-- Spaekona's Coat: refund 25% of elemental MP spent when the nuke lands.
-- Client text still says 2% of damage; Relaunch ignores damage.

local function readFile(path)
    local file = assert(io.open(path, 'r'))
    local text = file:read('*a')
    file:close()
    return text
end

local function makeCaster(opts)
    opts = opts or {}
    local vars = opts.vars or {}
    local added = 0

    return
    {
        added = function()
            return added
        end,
        getMod = function(_, modId)
            if modId == xi.mod.ELEM_DMG_TO_MP then
                return opts.percent or 0
            end

            return 0
        end,
        getEquipID = function(_, slot)
            if slot == xi.slot.BODY then
                return opts.body or 0
            end

            return 0
        end,
        hasStatusEffect = function(_, effect)
            return opts.manafont == true and effect == xi.effect.MANAFONT
        end,
        getLocalVar = function(_, name)
            return vars[name] or 0
        end,
        setLocalVar = function(_, name, value)
            vars[name] = value
        end,
        addMP = function(_, amount)
            added = added + amount
        end,
    }, vars
end

local function makeSpell(skill, mpCost)
    return
    {
        getSkillType = function()
            return skill or xi.skill.ELEMENTAL_MAGIC
        end,
        getMPCost = function()
            return mpCost or 100
        end,
        getID = function()
            return xi.magic.spell.FIRE
        end,
    }
end

describe('Spaekona coat elemental MP refund', function()
    it('assigns ELEM_DMG_TO_MP on every Spaekona coat', function()
        local coats = { 27810, 27831, 23110, 23445, 23943 }
        local sources =
        {
            readFile('sql/item_mods.sql'),
            readFile('sql/zz_derived_tier_mods.sql'),
            readFile('modules/custom/sql/spaekona_coat_elem_to_mp.sql'),
        }
        local blob = table.concat(sources, '\n')

        for _, itemId in ipairs(coats) do
            local found = blob:find(itemId .. ',%s*1202,%s*2', 1, false)
            assert(found, 'missing ELEM_DMG_TO_MP on item ' .. itemId)
        end

        assert(xi.mod.ELEM_DMG_TO_MP == 1202)
        assert(xi.spells.damage.ELEM_DMG_TO_MP_COST_REFUND == 25)
    end)

    it('refunds 25 percent of the spell cost, not a slice of damage', function()
        local caster = makeCaster({ percent = 2 })
        local restored = xi.spells.damage.applyElementalDamageToMP(
            caster, nil, makeSpell(xi.skill.ELEMENTAL_MAGIC, 306), 1000000)
        assert(restored == 76)
        assert(caster.added() == 76)
    end)

    it('uses the coat body id when the item mod is not loaded yet', function()
        local caster = makeCaster({ body = xi.item.SPAEKONAS_COAT_P3 })
        local restored = xi.spells.damage.applyElementalDamageToMP(
            caster, nil, makeSpell(xi.skill.ELEMENTAL_MAGIC, 200), 1)
        assert(restored == 50)
    end)

    it('does not refund divine or dark magic', function()
        local caster = makeCaster({ percent = 2 })
        local restored = xi.spells.damage.applyElementalDamageToMP(
            caster, nil, makeSpell(xi.skill.DIVINE_MAGIC, 200), 1000)
        assert(restored == 0)
        assert(caster.added() == 0)
    end)

    it('refunds nothing under Manafont', function()
        local caster = makeCaster({ percent = 2, manafont = true })
        local restored = xi.spells.damage.applyElementalDamageToMP(
            caster, nil, makeSpell(xi.skill.ELEMENTAL_MAGIC, 200), 1000)
        assert(restored == 0)
    end)

    it('pays the refund once per cast on AoE', function()
        local caster = makeCaster({
            percent = 2,
            vars    = { SpellCastSeq = 7, SpellMPSpent = 80 },
        })
        local spell = makeSpell(xi.skill.ELEMENTAL_MAGIC, 200)

        assert(xi.spells.damage.applyElementalDamageToMP(caster, nil, spell, 1000) == 20)
        assert(xi.spells.damage.applyElementalDamageToMP(caster, nil, spell, 1000) == 0)
        assert(caster.added() == 20)
    end)
end)
