local mastery = require('modules/custom/lua/weapon_mastery_catalog')
local forge = require('modules/custom/lua/weapon_forge_catalog')

describe('Weapon Mastery integrity', function()
    it('defines one deterministic Guardian for every forged Prime family', function()
        assert(#mastery.order == 14)
        assert(#forge.chains == 14)

        local keys = {}
        local types = {}
        local signatures = {}
        for index, key in ipairs(mastery.order) do
            local guardian = mastery.guardians[key]
            local chain = forge.chains[index]
            assert(guardian ~= nil)
            assert(guardian.key == key)
            assert(not keys[key] and not types[guardian.type])
            assert(not signatures[guardian.signature])
            assert(guardian.type == chain.type)
            assert(guardian.primeName == chain.s3.name)
            keys[key] = true
            types[guardian.type] = true
            signatures[guardian.signature] = true
        end
        assert(keys.handtohand and keys.marksmanship)
    end)

    it('keeps deterministic solo tuning inside the approved bounds', function()
        assert(mastery.softEnrageSec == 420)
        assert(mastery.hardTimeoutSec == 600)
        for _, key in ipairs(mastery.order) do
            local guardian = mastery.guardians[key]
            assert(guardian.hp >= 12000000 and guardian.hp <= 18000000)
            assert(guardian.level >= 140 and guardian.level <= 150)
            assert(guardian.damageCap >= 4000 and guardian.damageCap <= 4500)
            assert(guardian.mechanics.enrage.sec == mastery.softEnrageSec)
            assert(guardian.signature ~= '')
            assert(guardian.mods[xi.mod.ATT] >= 6000)
            assert(guardian.mods[xi.mod.ACC] >= 1800)
            assert(guardian.mods[xi.mod.DEF] >= 1500)
        end
    end)

    it('uses survivable mechanics without scripted solo-ending effects', function()
        local forbiddenActions = { doom = true, terror = true }
        local forbiddenEffects =
        {
            [xi.effect.PETRIFICATION] = true,
            [xi.effect.TERROR] = true,
            [xi.effect.DOOM] = true,
            [xi.effect.CHARM_I] = true,
            [xi.effect.SLEEP_I] = true,
            [xi.effect.SLEEP_II] = true,
        }

        for _, key in ipairs(mastery.order) do
            local cfg = mastery.guardians[key].mechanics
            assert(cfg.doom == nil)
            if cfg.aoe then
                assert(cfg.aoe.dmgPct <= 12)
                assert(cfg.aoe.periodSec >= 18)
            end
            if cfg.drain then
                assert(cfg.drain.healPct <= 0.20)
                assert(cfg.drain.periodSec >= 20)
            end
            if cfg.cc then
                assert(not forbiddenEffects[cfg.cc.effect])
                assert(cfg.cc.dur <= 12)
            end
            for _, phase in ipairs(cfg.phases or {}) do
                assert(not forbiddenActions[phase.action])
                if phase.action == 'nuke' then assert(phase.dmgPct <= 16) end
                if phase.action == 'dispel' then assert(phase.count <= 2) end
            end
            for _, stance in ipairs((cfg.stance and cfg.stance.stances) or {}) do
                assert((stance.mods[xi.mod.DMGPHYS] or 0) >= -1500)
                assert((stance.mods[xi.mod.DMGMAGIC] or 0) >= -1500)
            end
        end
    end)

    it('clears every native status that can unfairly end a solo run', function()
        local protected = {}
        for _, effect in ipairs(mastery.soloFailEffects) do protected[effect] = true end
        assert(protected[xi.effect.PETRIFICATION])
        assert(protected[xi.effect.GRADUAL_PETRIFICATION])
        assert(protected[xi.effect.TERROR])
        assert(protected[xi.effect.DOOM])
        assert(protected[xi.effect.CHARM_I])
        assert(protected[xi.effect.SLEEP_I])
        assert(protected[xi.effect.SLEEP_II])
    end)

    it('maps melee and ranged families to the correct equipment slots', function()
        for _, key in ipairs(mastery.order) do
            local guardian = mastery.guardians[key]
            if key == 'archery' or key == 'marksmanship' then
                assert(guardian.slot == xi.slot.RANGED)
            else
                assert(guardian.slot == xi.slot.MAIN)
            end
            assert(guardian.skill ~= nil)
        end
        assert(mastery.guardians.handtohand.skill == xi.skill.HAND_TO_HAND)
        assert(mastery.guardians.greatkatana.skill == xi.skill.GREAT_KATANA)
        assert(mastery.guardians.marksmanship.skill == xi.skill.MARKSMANSHIP)
    end)

    it('requires progression, true solo status, and a matching item-level weapon', function()
        local vars =
        {
            PW_Trial1_Done = 1,
            PW_Trial2_Done = 1,
            PW_Trial3_Done = 1,
            WF_Aeonic_Final = 1,
        }
        local level = 99
        local grouped = false
        local itemLevel = 119
        local skill = xi.skill.GREAT_KATANA
        local selfMember = { isPC = function() return true end, getID = function() return 1 end }
        local otherMember = { isPC = function() return true end, getID = function() return 2 end }
        local weapon =
        {
            getILvl = function() return itemLevel end,
            getSkillType = function() return skill end,
        }
        local player = {}
        function player:getID() return 1 end
        function player:getMainLvl() return level end
        function player:getCharVar(name) return vars[name] or 0 end
        function player:getParty() return grouped and { selfMember, otherMember } or { selfMember } end
        function player:getAlliance() return {} end
        function player:getEquippedItem(slot) return slot == xi.slot.MAIN and weapon or nil end

        local guardian = mastery.guardians.greatkatana
        assert(mastery.entryCheck(player, guardian))

        skill = xi.skill.KATANA
        local ok, reason = mastery.entryCheck(player, guardian)
        assert(not ok and reason == 'weapon')
        skill = xi.skill.GREAT_KATANA
        itemLevel = 118
        ok, reason = mastery.entryCheck(player, guardian)
        assert(not ok and reason == 'weapon')
        itemLevel = 119
        grouped = true
        ok, reason = mastery.entryCheck(player, guardian)
        assert(not ok and reason == 'grouped')
        grouped = false
        vars.PW_Trial2_Done = 0
        ok, reason = mastery.entryCheck(player, guardian)
        assert(not ok and reason == 'prior_trials')
    end)

    it('authorizes forged Primes by family while support Primes accept any clear', function()
        local vars = { PW_Trial4_Done = 1, PW_T4_greatkatana_Done = 1 }
        local player = {}
        function player:getCharVar(name) return vars[name] or 0 end

        assert(mastery.supportAuthorized(player))
        assert(mastery.primeAuthorized(player, 'Great Katana'))
        assert(not mastery.primeAuthorized(player, 'Katana'))
        assert(not mastery.primeAuthorized(player, 'Not a weapon family'))
    end)
end)
