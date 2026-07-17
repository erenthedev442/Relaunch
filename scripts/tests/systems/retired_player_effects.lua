local augmentCatalog = require('modules/custom/lua/augment_catalog')
local masteryCatalog = require('modules/custom/lua/spell_skill_mastery_catalog')
local phalanxEffect  = require('scripts/effects/phalanx')

describe('Retired player-wide combat effects', function()
    it('removes custom Phalanx Received acquisition', function()
        assert(augmentCatalog[1449] == nil)
    end)

    it('caps grandfathered Phalanx Received at fifteen', function()
        local appliedMod
        local appliedPower
        local target =
        {
            getMod = function(_, mod)
                assert(mod == xi.mod.PHALANX_RECEIVED)
                return 600
            end,
        }
        local effect =
        {
            getPower = function()
                return 35
            end,
            addMod = function(_, mod, power)
                appliedMod = mod
                appliedPower = power
            end,
        }

        phalanxEffect.onEffectGain(target, effect)
        assert(appliedMod == xi.mod.PHALANX)
        assert(appliedPower == 50)
    end)

    it('keeps only non-sustain weapon-skill effects', function()
        assert(#masteryCatalog.wsEffects == 1)
        for _, effect in ipairs(masteryCatalog.wsEffects) do
            assert(effect.kind ~= 'lifesteal')
            assert(effect.kind ~= 'splash')
            assert(effect.var ~= 'Mastery_WSFx_drain')
            assert(effect.var ~= 'Mastery_WSFx_splash')
        end
    end)
end)
