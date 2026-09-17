-----------------------------------
-- Dynamis Dreamland (Nightmare) mixin
-----------------------------------
require('scripts/globals/mixins')
require('scripts/globals/dynamis')
-----------------------------------
g_mixins = g_mixins or {}

g_mixins.dynamis_dreamland = function(dynamisDreamlandMob)
    dynamisDreamlandMob:addListener('SPAWN', 'PARTY_HP_SCALE_PREPARE', function(mob)
        require('modules/custom/lua/party_hp_scale').prepare(mob)
    end)

    local procTimes =
    {
        weaponskill =
        {
            [xi.item.TUKUKU_WHITESHELL  ] = {  0,  8 },
            [xi.item.ORDELLE_BRONZEPIECE] = { 16, 24 },
            [xi.item.ONE_BYNE_BILL      ] = {  8, 16 },
        },
        magic =
        {
            [xi.item.TUKUKU_WHITESHELL  ] = {  8, 16 },
            [xi.item.ORDELLE_BRONZEPIECE] = {  0,  8 },
            [xi.item.ONE_BYNE_BILL      ] = { 16, 24 },
        },
        jobAbility =
        {
            [xi.item.TUKUKU_WHITESHELL  ] = { 16, 24 },
            [xi.item.ORDELLE_BRONZEPIECE] = {  8, 16 },
            [xi.item.ONE_BYNE_BILL      ] = {  0,  8 },
        },
    }

    -- Proc is visual + white guaranteed 100-piece only. Singles always pay
    -- 100/50/20/5 with no proc required.
    dynamisDreamlandMob:addListener('MAGIC_TAKE', 'DYNAMIS_MAGIC_PROC_CHECK', function(target, caster, spell, action)
        local isPrimary = action and target:getID() == action:getPrimaryTargetID()
        local chance = isPrimary and 8 or 1
        if math.random(1, 100) > chance or target:getLocalVar('dynamis_proc') ~= 0 then
            return
        end

        local currency = target:getLocalVar('dynamis_currency')
        local vanaHour = VanadielHour()
        if
            currency == 0 or
            (vanaHour >= procTimes.magic[currency][1] and vanaHour < procTimes.magic[currency][2])
        then
            xi.dynamis.procMonster(target, caster)
        end
    end)

    dynamisDreamlandMob:addListener('WEAPONSKILL_TAKE', 'DYNAMIS_WS_PROC_CHECK', function(user, target, skill, tp, action)
        local isPrimary = action and target:getID() == action:getPrimaryTargetID()
        local chance = isPrimary and 25 or 2
        if math.random(1, 100) > chance or target:getLocalVar('dynamis_proc') ~= 0 then
            return
        end

        local currency = target:getLocalVar('dynamis_currency')
        local vanaHour = VanadielHour()
        if
            currency == 0 or
            (vanaHour >= procTimes.weaponskill[currency][1] and vanaHour < procTimes.weaponskill[currency][2])
        then
            xi.dynamis.procMonster(target, user)
        end
    end)

    dynamisDreamlandMob:addListener('ABILITY_TAKE', 'DYNAMIS_ABILITY_PROC_CHECK', function(user, target, skill, action)
        local isPrimary = action and target:getID() == action:getPrimaryTargetID()
        local chance = isPrimary and 20 or 2
        if math.random(1, 100) > chance or target:getLocalVar('dynamis_proc') ~= 0 then
            return
        end

        local currency = target:getLocalVar('dynamis_currency')
        local vanaHour = VanadielHour()
        if
            currency == 0 or
            (vanaHour >= procTimes.jobAbility[currency][1] and vanaHour < procTimes.jobAbility[currency][2])
        then
            xi.dynamis.procMonster(target, user)
        end
    end)

    dynamisDreamlandMob:addListener('DEATH', 'DYNAMIS_ITEM_DISTRIBUTION', function(mob, killer)
        -- Pack tag picks the single. 100/50/20/5 slots, no proc required.
        require('modules/custom/lua/dynamis_currency_drops').onDeath(mob, killer)
    end)
end

return g_mixins.dynamis_dreamland
