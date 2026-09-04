local avatarProgression = require('modules/custom/lua/smn_avatar_equalize')
local meteorite = require('scripts/actions/abilities/pets/meteorite')
local holyMist = require('scripts/actions/abilities/pets/holy_mist')
local burningStrike = require('scripts/actions/abilities/pets/burning_strike')
local flamingCrush = require('scripts/actions/abilities/pets/flaming_crush')
local impact = require('scripts/actions/abilities/pets/impact')
local earthenArmor = require('scripts/actions/abilities/pets/earthen_armor')
local pavorNocturnus = require('scripts/actions/abilities/pets/pavor_nocturnus')
local ruinousOmen = require('scripts/actions/abilities/pets/ruinous_omen')

describe('SMN avatar Blood Pact progression', function()
    local function makeMaster(itemId, level, spentJobPoints)
        return
        {
            isPC = function()
                return true
            end,
            getMainJob = function()
                return xi.job.SMN
            end,
            getMainLvl = function()
                return level or 99
            end,
            getSpentJobPoints = function()
                return spentJobPoints or 2100
            end,
            getEquipID = function(_, slot)
                local equippedItemId = type(itemId) == 'table' and itemId.value or itemId
                return slot == xi.slot.MAIN and equippedItemId or 0
            end,
        }
    end

    local function makeAvatar(master)
        local localVars = {}

        return
        {
            isAvatar = function()
                return true
            end,
            getMaster = function()
                return master
            end,
            setLocalVar = function(_, name, value)
                localVars[name] = value
            end,
            getLocalVar = function(_, name)
                return localVars[name] or 0
            end,
        }
    end

    local function makeTarget(level, maxHp)
        return
        {
            getMainLvl = function()
                return level or 155
            end,
            getMaxHP = function()
                return maxHp or 10000000
            end,
            checkDamageCap = function(_, damage)
                return damage
            end,
        }
    end

    local singleTargetSkill =
    {
        isAoE = function()
            return false
        end,
        isConal = function()
            return false
        end,
    }

    it('uses the live standard, Ambuscade, Nirvana and Opashoro tiers', function()
        local target = makeTarget()

        assert(avatarProgression.scaleDamage(
            makeAvatar(makeMaster(1)), target, singleTargetSkill, 100) == 1100)
        assert(avatarProgression.scaleDamage(
            makeAvatar(makeMaster(22086)), target, singleTargetSkill, 100) == 1375)
        assert(avatarProgression.scaleDamage(
            makeAvatar(makeMaster(22063)), target, singleTargetSkill, 100) == 3135)
        assert(avatarProgression.scaleDamage(
            makeAvatar(makeMaster(22106)), target, singleTargetSkill, 100) == 4675)

        assert(avatarProgression.scaleDamage(
            makeAvatar(makeMaster(1)), target, singleTargetSkill, 1000000) == 79999)
        assert(avatarProgression.scaleDamage(
            makeAvatar(makeMaster(22086)), target, singleTargetSkill, 1000000) == 99999)
        assert(avatarProgression.scaleDamage(
            makeAvatar(makeMaster(21141)), target, singleTargetSkill, 1000000) == 99999)
        assert(avatarProgression.scaleDamage(
            makeAvatar(makeMaster(22063)), target, singleTargetSkill, 1000000) == 999999)
        assert(avatarProgression.scaleDamage(
            makeAvatar(makeMaster(22106)), target, singleTargetSkill, 1000000) == 1499999)
    end)

    it('refreshes multiplier and cap immediately after a main-hand swap', function()
        local mainHand = { value = 1 }
        local avatar = makeAvatar(makeMaster(mainHand))
        local target = makeTarget()

        assert(avatarProgression.scaleDamage(avatar, target, singleTargetSkill, 100) == 1100)
        assert(avatar:getLocalVar('CompanionDamageCap') == 79999)

        mainHand.value = 22086
        assert(avatarProgression.scaleDamage(avatar, target, singleTargetSkill, 100) == 1375)
        assert(avatar:getLocalVar('CompanionDamageCap') == 99999)

        mainHand.value = 22063
        assert(avatarProgression.scaleDamage(avatar, target, singleTargetSkill, 100) == 3135)
        assert(avatar:getLocalVar('CompanionDamageCap') == 999999)

        mainHand.value = 22106
        assert(avatarProgression.scaleDamage(avatar, target, singleTargetSkill, 100) == 4675)
        assert(avatar:getLocalVar('CompanionDamageCap') == 1499999)
    end)

    it('caps avatar AoE splash to the player ladder and keeps the aimed-at target at the companion ST cap', function()
        local function makeAoESkill(primaryId)
            return
            {
                isAoE = function()
                    return true
                end,
                isConal = function()
                    return false
                end,
                getPrimaryTargetID = function()
                    return primaryId
                end,
            }
        end

        local function makeIdTarget(id, level, maxHp)
            local target = makeTarget(level, maxHp)
            target.getID = function()
                return id
            end

            return target
        end

        local skill = makeAoESkill(100)
        local primary = makeIdTarget(100)
        local splash = makeIdTarget(200)
        local opashoroAvatar = makeAvatar(makeMaster(22106))
        local levelingAvatar = makeAvatar(makeMaster(1, 50, 0))

        assert(avatarProgression.scaleDamage(opashoroAvatar, primary, skill, 100) == 4675)
        assert(avatarProgression.scaleDamage(opashoroAvatar, splash, skill, 100) == 4675)
        assert(avatarProgression.scaleDamage(
            opashoroAvatar, primary, skill, 1000000) == 1499999)
        assert(avatarProgression.scaleDamage(
            opashoroAvatar, splash, skill, 1000000) == 199999)
        assert(avatarProgression.scaleDamage(
            levelingAvatar, makeTarget(50, 1000), singleTargetSkill, 1000) == 400)
    end)

    it('guards misses, absorbs and non-SMN pets', function()
        local master = makeMaster(22106)
        local avatar = makeAvatar(master)
        local nonAvatar =
        {
            isAvatar = function()
                return false
            end,
        }

        assert(avatarProgression.scaleDamage(avatar, makeTarget(), singleTargetSkill, 0) == 0)
        assert(avatarProgression.scaleDamage(avatar, makeTarget(), singleTargetSkill, -100) == -100)
        assert(avatarProgression.scaleDamage(nonAvatar, makeTarget(), singleTargetSkill, 100) == 100)
    end)

    it('shares one weapon-tier cap across hybrid damage lanes', function()
        local avatar = makeAvatar(makeMaster(22106))
        local physical, magical = avatarProgression.scaleHybridDamage(
            avatar, makeTarget(), singleTargetSkill, 100, 50)

        assert(physical == 4674)
        assert(magical == 2338)
        assert(physical + magical == 7012)

        physical, magical = avatarProgression.scaleHybridDamage(
            avatar, makeTarget(), singleTargetSkill, 100, -20)
        assert(physical == 4675)
        assert(magical == -20)
    end)

    for name, ability in pairs({ Meteorite = meteorite, ['Holy Mist'] = holyMist }) do
        it(string.format('routes %s through magical processing', name), function()
            local processed = false
            local takenDamage = 0
            local target =
            {
                takeDamage = function(_, damage)
                    takenDamage = damage
                end,
            }
            local info =
            {
                damage = 321,
                hitsLanded = 1,
                attackType = xi.attackType.MAGICAL,
                damageType = xi.damageType.LIGHT,
            }

            stub('xi.job_utils.summoner.onUseBloodPact')
            stub('xi.mobskills.mobMagicalMove', function(_, _, _, _, params)
                assert(params.element == xi.element.LIGHT)
                assert(params.dStatMultiplier == 1.5)
                return info
            end)
            stub('xi.mobskills.processDamage', function()
                processed = true
                info.damage = 777
                return true
            end)

            local pet =
            {
                getTP = function()
                    return 0
                end,
            }

            assert(ability.onPetAbility(target, pet, {}, {}, {}) == 777)
            assert(processed)
            assert(takenDamage == 777)
        end)
    end

    for name, ability in pairs({ ['Burning Strike'] = burningStrike, ['Flaming Crush'] = flamingCrush }) do
        it(string.format('scales %s physical and magical lanes only once', name), function()
            local pet = makeAvatar(makeMaster(22106))
            local target = makeTarget()
            local damageTaken = 0

            target.takeDamage = function(_, damage)
                damageTaken = damageTaken + damage
            end
            target.updateEnmityFromDamage = function()
            end

            stub('xi.job_utils.summoner.onUseBloodPact')
            stub('xi.summon.avatarPhysicalMove', { damage = 100, hitslanded = 1 })
            stub('xi.summon.avatarFinalAdjustments', 100)
            stub('xi.mobskills.handleHybridDamage', 50)
            stub('xi.summon.reportPetOverCap')

            local total = ability.onPetAbility(
                target, pet, singleTargetSkill, makeMaster(22106), {})

            assert(total == 7012)
            assert(damageTaken == 7012)
        end)
    end

    it('executes a newly restored magical Rage pact with damage and its debuffs', function()
        local damageTaken = 0
        local effects = 0
        local target =
        {
            takeDamage = function(_, damage)
                damageTaken = damage
            end,
        }
        local pet =
        {
            getMainLvl = function()
                return 99
            end,
        }
        local summoner =
        {
            getSkillLevel = function()
                return 500
            end,
        }
        local info =
        {
            damage = 123,
            hitsLanded = 1,
            attackType = xi.attackType.MAGICAL,
            damageType = xi.damageType.DARK,
        }

        stub('xi.job_utils.summoner.onUseBloodPact')
        stub('xi.mobskills.mobMagicalMove', function(_, _, _, _, params)
            assert(params.attackType == xi.attackType.MAGICAL)
            assert(params.damageType == xi.damageType.DARK)
            return info
        end)
        stub('xi.mobskills.processDamage', true)
        stub('xi.mobskills.mobStatusEffectMove', function()
            effects = effects + 1
        end)

        assert(impact.onPetAbility(target, pet, {}, summoner, {}) == 123)
        assert(damageTaken == 123)
        assert(effects == 7)
    end)

    it('applies a representative Ward to its allied target', function()
        local appliedEffect
        local message
        local target =
        {
            delStatusEffect = function()
            end,
            addStatusEffect = function(_, effect, params)
                appliedEffect = { effect = effect, params = params }
                return true
            end,
        }
        local petskill =
        {
            setMsg = function(_, value)
                message = value
            end,
        }
        local summoner =
        {
            getSkillLevel = function()
                return 500
            end,
        }

        stub('xi.job_utils.summoner.onUseBloodPact')

        assert(
            earthenArmor.onPetAbility(target, {}, petskill, summoner, {}) ==
            xi.effect.EARTHEN_ARMOR)
        assert(appliedEffect.effect == xi.effect.EARTHEN_ARMOR)
        assert(appliedEffect.params.power == 45)
        assert(appliedEffect.params.duration == 260)
        assert(message == xi.msg.basic.JA_GAIN_EFFECT)
    end)

    it('preserves the intentional no-effect path for Pavor immunity', function()
        local message
        local target =
        {
            hasStatusEffect = function()
                return false
            end,
            isNM = function()
                return true
            end,
            getAnimation = function()
                return 0
            end,
            dispelStatusEffect = function()
                return xi.effect.NONE
            end,
        }
        local pet =
        {
            getMainLvl = function()
                return 99
            end,
        }
        local petskill =
        {
            setMsg = function(_, value)
                message = value
            end,
        }

        stub('xi.job_utils.summoner.onUseBloodPact')

        assert(pavorNocturnus.onPetAbility(target, pet, petskill, {}, {}) == xi.effect.NONE)
        assert(message == xi.msg.basic.JA_NO_EFFECT_2)
    end)

    it('reapplies Ruinous Omen special caps after shared progression', function()
        local damageTaken
        local remainingMP = 100
        local target =
        {
            getHP = function()
                return 10000
            end,
            isNM = function()
                return true
            end,
            getID = function()
                return 7
            end,
            takeDamage = function(_, damage)
                damageTaken = damage
            end,
        }
        local action =
        {
            getPrimaryTargetID = function()
                return 7
            end,
        }
        local summoner =
        {
            setMP = function(_, value)
                remainingMP = value
            end,
        }
        local info =
        {
            damage = 1000,
            hitsLanded = 1,
            attackType = xi.attackType.MAGICAL,
            damageType = xi.damageType.DARK,
        }

        stub('xi.job_utils.summoner.onUseBloodPact')
        stub('xi.mobskills.mobMagicalMove', info)
        stub('xi.summon.avatarProgression.scaleDamage', 5000)
        stub('xi.mobskills.processDamage', function(_, _, _, _, processedInfo)
            assert(processedInfo.damage == 1000)
            return true
        end)

        assert(ruinousOmen.onPetAbility(target, {}, {}, summoner, action) == 1000)
        assert(damageTaken == 1000)
        assert(remainingMP == 0)
    end)
end)
