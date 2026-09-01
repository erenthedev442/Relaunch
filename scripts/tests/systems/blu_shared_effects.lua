local sharedEffects = require('modules/custom/lua/blu_shared_effects')

describe('BLU shared effect helpers', function()
    local function makeCaster(isPlayer, mainJob, subJob)
        return
        {
            isPC = function()
                return isPlayer ~= false
            end,
            getMainJob = function()
                return mainJob or xi.job.BLU
            end,
            getSubJob = function()
                return subJob or (mainJob and mainJob ~= xi.job.BLU and xi.job.BLU or xi.job.WAR)
            end,
            getHP = function()
                return 3000
            end,
            getMainLvl = function()
                return 99
            end,
            getSkillLevel = function()
                return 500
            end,
            getStat = function(_, stat)
                assert(stat == xi.mod.VIT)
                return 200
            end,
        }
    end

    local function makeTarget(options)
        options = type(options) == 'table' and options or { isNm = options == true }
        local localVars = {}
        return
        {
            isNM = function()
                return options.isNm == true
            end,
            isMobType = function(_, mobType)
                return mobType == xi.mobType.BATTLEFIELD and options.isBattlefield == true
            end,
            getMobMod = function(_, mobMod)
                if mobMod == xi.mobMod.CHECK_AS_NM and options.checkAsNm then
                    return 1
                end

                return 0
            end,
            getName = function()
                return options.name or 'Leaping_Lizzy'
            end,
            getLocalVar = function(_, name)
                return localVars[name] or 0
            end,
            setLocalVar = function(_, name, value)
                localVars[name] = value
            end,
        }
    end

    local function makeSpell(id)
        return
        {
            getID = function()
                return id
            end,
        }
    end

    it('converts Diffusion merit values into duration bonuses', function()
        assert(sharedEffects.calculateDiffusionDuration(100, 5) == 100)
        assert(sharedEffects.calculateDiffusionDuration(100, 25) == 120)
    end)

    it('uses the stat-focused breath base and explicit identity scaling', function()
        local caster = makeCaster()
        local expected = 3000 / 3 + 4 * 500 + 6 * 200

        assert(sharedEffects.calculateBreathBase(caster, {}) == expected)
        assert(sharedEffects.calculateBreathBase(caster, { breathMultiplier = 0.5 }) == expected * 0.5)

        local subjobCaster = makeCaster(true, xi.job.WAR)
        assert(sharedEffects.calculateBreathBase(
            subjobCaster, { hpMod = 10, lvlMod = 1.25 }) == 3000 / 10 + 99 / 1.25)
    end)

    it('honors coefficient-provided drain bases without changing their path', function()
        local caster = makeCaster()
        local intendedBase = 900 + 2.5 * 500 + 3 * 200
        local skillBase = math.floor(500 * 0.11)

        assert(sharedEffects.calculateDrainBase(caster,
        {
            dmgMultiplier = intendedBase / skillBase,
        }) == intendedBase)
    end)

    it('restores every retuned subjob-level parameter contract only for /BLU', function()
        local distinguishingValues =
        {
            [513] = { 'power', 6 },       [519] = { 'duppercap', 27 },
            [521] = { 'dmgMultiplier', 3.5 }, [522] = { 'multiplier', 1.625 },
            [524] = { 'int_wsc', 0.2 },   [527] = { 'azuretp', 2.53125 },
            [529] = { 'chr_wsc', 0.3 },   [532] = { 'multiplier', 1.5625 },
            [534] = { 'chr_wsc', 0.3 },   [536] = { 'hpMod', 10 },
            [537] = { 'duration', 60 },   [539] = { 'duppercap', 41 },
            [541] = { 'dmgMultiplier', 3.5 }, [542] = { 'dmgMultiplier', 5 },
            [543] = { 'duppercap', 45 },  [544] = { 'multiplier', 1.5 },
            [545] = { 'dex_wsc', 0.5 },   [551] = { 'multiplier', 1.125 },
            [555] = { 'hpMod', 6 },       [567] = { 'tp300', 2 },
            [569] = { 'multiplier', 1.125 }, [570] = { 'dmgMultiplier', 3 },
            [572] = { 'power', 9 },       [575] = { 'duration', 3 },
            [577] = { 'duppercap', 9 },   [582] = { 'power', 1 },
            [584] = { 'duration', 60 },   [587] = { 'multiplier', 1.4375 },
            [594] = { 'str_wsc', 0.35 },  [596] = { 'duppercap', 37 },
            [597] = { 'duppercap', 11 },  [599] = { 'multiplier', 1.75 },
            [603] = { 'multiplier', 1.84 }, [606] = { 'duration', 30 },
            [618] = { 'multiplier', 1.375 }, [620] = { 'str_wsc', 0.3 },
            [622] = { 'duppercap', 33 },  [623] = { 'azuretp', 2.375 },
            [626] = { 'multiplier', 1.625 }, [638] = { 'agi_wsc', 0.3 },
        }

        local subjobCaster = makeCaster(true, xi.job.WAR)
        for id, expected in pairs(distinguishingValues) do
            local params = { [expected[1]] = -1 }
            sharedEffects.applyStockSubjobParams(subjobCaster, makeSpell(id), params)
            assert(params[expected[1]] == expected[2], string.format('stock mismatch for spell %u', id))
        end

        local mainParams = { multiplier = 4.5 }
        sharedEffects.applyStockSubjobParams(makeCaster(), makeSpell(519), mainParams)
        assert(mainParams.multiplier == 4.5)

        local mobParams = { multiplier = 4.5 }
        sharedEffects.applyStockSubjobParams(makeCaster(false, xi.job.WAR), makeSpell(519), mobParams)
        assert(mobParams.multiplier == 4.5)

        local nonBlueParams = { multiplier = 4.5 }
        sharedEffects.applyStockSubjobParams(
            makeCaster(true, xi.job.WAR, xi.job.RDM), makeSpell(519), nonBlueParams)
        assert(nonBlueParams.multiplier == 4.5)
    end)

    it('restores stock drain caps only for /BLU', function()
        local subjobCaster = makeCaster(true, xi.job.WAR)
        assert(sharedEffects.getDrainCap(subjobCaster, makeSpell(521), 2000) == 165)
        assert(sharedEffects.getDrainCap(subjobCaster, makeSpell(541), 2500) == 0)
        assert(sharedEffects.getDrainCap(makeCaster(), makeSpell(521), 2000) == 2000)
    end)

    it('keeps subjob-only branches on low-level heals, buffs, and dispels', function()
        local function readSpell(name)
            local file = assert(io.open('scripts/actions/spells/blue/' .. name .. '.lua', 'r'))
            local source = file:read('*a')
            file:close()
            return source
        end

        for _, name in ipairs({ 'pollen', 'wild_carrot', 'healing_breeze' }) do
            local source = readSpell(name)
            assert(source:find('usesStockSubjobBehavior', 1, true))
            assert(source:find('useCuringSpell', 1, true))
        end

        for _, name in ipairs({ 'metallic_body', 'cocoon', 'refueling' }) do
            assert(readSpell(name):find('usesStockSubjobBehavior', 1, true))
        end

        for _, name in ipairs({ 'blank_gaze', 'geist_wall' }) do
            assert(readSpell(name):find('usesStockSubjobBehavior', 1, true))
        end

        local headButt = readSpell('head_butt')
        assert(headButt:find('applyBlueAdditionalEffect', 1, true))
        assert(not headButt:find('if damage <= 0', 1, true))
    end)

    it('gives Head Butt stun a guaranteed 5-second window with no lockout', function()
        local caster = makeCaster()
        local target = makeTarget()
        local allowed, duration, lockout, _, fixedDuration =
            sharedEffects.preparePlayerControl(caster, target, xi.effect.STUN, 30, 100)

        assert(allowed and duration == 5 and lockout == nil and fixedDuration)
        sharedEffects.commitPlayerControl(target, xi.effect.STUN, duration, lockout, 100)

        allowed = sharedEffects.preparePlayerControl(caster, target, xi.effect.STUN, 30, 114)
        assert(allowed)
    end)

    it('gives terror and petrify a full 25 seconds on trash, Apex, and NMs', function()
        local caster = makeCaster()
        for _, target in ipairs(
        {
            makeTarget(),
            makeTarget({ name = 'Apex_Poxhound' }),
            makeTarget({ isNm = true }),
            makeTarget({ isBattlefield = true }),
            makeTarget({ checkAsNm = true }),
        })
        do
            local allowed, duration, lockout, _, fixedDuration =
                sharedEffects.preparePlayerControl(caster, target, xi.effect.TERROR, 1, 100)
            assert(allowed and duration == 25 and lockout == nil and fixedDuration)

            allowed, duration, lockout, _, fixedDuration =
                sharedEffects.preparePlayerControl(caster, target, xi.effect.PETRIFICATION, 60, 100)
            assert(allowed and duration == 25 and lockout == nil and fixedDuration)

            allowed, duration, lockout, _, fixedDuration =
                sharedEffects.preparePlayerControl(caster, target, xi.effect.STUN, 30, 100)
            assert(allowed and duration == 5 and lockout == nil and fixedDuration)
        end

        assert(sharedEffects.isApexMob(makeTarget({ name = 'Apex_Poxhound' })))
        assert(not sharedEffects.isApexMob(makeTarget({ name = 'Leaping_Lizzy' })))
    end)

    it('does not lock out a second terror or petrify after the first lands', function()
        local caster = makeCaster()
        local target = makeTarget({ isNm = true })
        sharedEffects.commitPlayerControl(target, xi.effect.TERROR, 25, nil, 100)

        local allowed = sharedEffects.preparePlayerControl(caster, target, xi.effect.TERROR, 1, 101)
        assert(allowed)
        allowed = sharedEffects.preparePlayerControl(caster, target, xi.effect.PETRIFICATION, 60, 101)
        assert(allowed)
    end)

    it('clamps main-job BLU magic resist to a full hit', function()
        assert(sharedEffects.clampMagicResist(makeCaster(), 0.125) == 1)
        assert(sharedEffects.clampMagicResist(makeCaster(true, xi.job.WAR), 0.125) == 0.125)
        assert(sharedEffects.clampMagicResist(makeCaster(false), 0.125) == 0.125)
    end)

    it('leaves sleep, subjob BLU, and mob-cast BLU durations unchanged', function()
        local caster = makeCaster()
        local target = makeTarget()
        local allowed, duration, lockout, _, fixedDuration =
            sharedEffects.preparePlayerControl(caster, target, xi.effect.SLEEP_I, 60, 100)
        assert(allowed and duration == 60 and lockout == nil and not fixedDuration)

        allowed, duration, lockout, _, fixedDuration =
            sharedEffects.preparePlayerControl(
                makeCaster(true, xi.job.WAR), target, xi.effect.STUN, 5, 100)
        assert(allowed and duration == 5 and lockout == nil and not fixedDuration)

        allowed, duration, lockout, _, fixedDuration =
            sharedEffects.preparePlayerControl(makeCaster(false), target, xi.effect.STUN, 17, 100)
        assert(allowed and duration == 17 and lockout == nil and not fixedDuration)
    end)

    it('makes player BLU Doom ineffective against NMs', function()
        local allowed, _, _, reason =
            sharedEffects.preparePlayerControl(makeCaster(), makeTarget(true), xi.effect.DOOM, 60, 100)
        assert(not allowed and reason == 'nm_doom')

        allowed = sharedEffects.preparePlayerControl(makeCaster(false), makeTarget(true), xi.effect.DOOM, 60, 100)
        assert(allowed)
    end)

    it('bands elemental matchup to resist / neutral / weak', function()
        assert(sharedEffects.getElementMatchupFromSDT(0.5) == sharedEffects.ELEMENT_RESIST)
        assert(sharedEffects.getElementMatchupFromSDT(1) == sharedEffects.ELEMENT_NEUTRAL)
        assert(sharedEffects.getElementMatchupFromSDT(1.5) == sharedEffects.ELEMENT_WEAK)
        assert(sharedEffects.getElementMatchupFromSDT(nil) == sharedEffects.ELEMENT_NEUTRAL)
    end)

    it('scales investment heals with skill, MND, and cure potency', function()
        local function makeHealCaster(skill, mnd, potency, maxHP)
            return
            {
                getSkillLevel = function()
                    return skill
                end,
                getStat = function(_, stat)
                    return stat == xi.mod.MND and mnd or 0
                end,
                getMod = function(_, mod)
                    if mod == xi.mod.CURE_POTENCY then
                        return potency
                    end

                    return 0
                end,
                getMaxHP = function()
                    return maxHP or 1500
                end,
            }
        end

        local fresh = makeHealCaster(320, 90, 0, 1500)
        local geared = makeHealCaster(500, 280, 40, 7000)
        local missing = { getMod = function() return 0 end }

        local pollenFresh  = sharedEffects.calculateBlueCure(fresh, missing, { base = 0, scale = 1.0 })
        local pollenGeared = sharedEffects.calculateBlueCure(geared, missing, { base = 0, scale = 1.0 })
        assert(pollenFresh >= 150 and pollenFresh <= 250)
        assert(pollenGeared >= 750 and pollenGeared <= 950)

        local windFresh = sharedEffects.calculateBlueCure(fresh, missing, { base = 60, scale = 1.55, hp = 0.05 })
        local windGeared = sharedEffects.calculateBlueCure(geared, missing, { base = 60, scale = 1.55, hp = 0.05 })
        assert(windFresh >= 350 and windFresh <= 550)
        assert(windGeared >= 1400 and windGeared <= 2000)
        assert(windGeared < 4500)
    end)
end)
