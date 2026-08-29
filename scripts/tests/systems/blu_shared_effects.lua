local sharedEffects = require('modules/custom/lua/blu_shared_effects')

describe('BLU shared effect helpers', function()
    local function makeCaster(isPlayer)
        return
        {
            isPC = function()
                return isPlayer ~= false
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

    local function makeTarget(isNm)
        local localVars = {}
        return
        {
            isNM = function()
                return isNm == true
            end,
            getLocalVar = function(_, name)
                return localVars[name] or 0
            end,
            setLocalVar = function(_, name, value)
                localVars[name] = value
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

    it('caps player hard control and starts lockout after the applied effect', function()
        local caster = makeCaster()
        local target = makeTarget()
        local allowed, duration, lockout =
            sharedEffects.preparePlayerControl(caster, target, xi.effect.STUN, 30, 100)

        assert(allowed and duration == 3 and lockout == 12)
        sharedEffects.commitPlayerControl(target, xi.effect.STUN, duration, lockout, 100)

        allowed = sharedEffects.preparePlayerControl(caster, target, xi.effect.STUN, 30, 114)
        assert(not allowed)
        allowed = sharedEffects.preparePlayerControl(caster, target, xi.effect.STUN, 30, 115)
        assert(allowed)
    end)

    it('applies each control profile and exempts mob-cast BLU', function()
        local caster = makeCaster()
        local target = makeTarget()
        local allowed, duration, lockout =
            sharedEffects.preparePlayerControl(caster, target, xi.effect.TERROR, 1, 100)
        assert(allowed and duration == 5 and lockout == 20)

        allowed, duration, lockout =
            sharedEffects.preparePlayerControl(caster, target, xi.effect.PETRIFICATION, 60, 100)
        assert(allowed and duration == 8 and lockout == 30)

        allowed, duration, lockout =
            sharedEffects.preparePlayerControl(makeCaster(false), target, xi.effect.STUN, 17, 100)
        assert(allowed and duration == 17 and lockout == nil)
    end)

    it('makes player BLU Doom ineffective against NMs', function()
        local allowed, _, _, reason =
            sharedEffects.preparePlayerControl(makeCaster(), makeTarget(true), xi.effect.DOOM, 60, 100)
        assert(not allowed and reason == 'nm_doom')

        allowed = sharedEffects.preparePlayerControl(makeCaster(false), makeTarget(true), xi.effect.DOOM, 60, 100)
        assert(allowed)
    end)
end)
