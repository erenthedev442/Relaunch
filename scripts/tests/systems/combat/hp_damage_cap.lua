describe('Global HP damage cap', function()
    ---@type CClientEntityPair
    local player

    ---@type CTestEntity
    local target

    local damageCap = 9999999
    local maxHP     = 30000000

    before_each(function()
        player = xi.test.world:spawnPlayer(
        {
            zone  = xi.zone.WEST_RONFAURE,
            job   = xi.job.WAR,
            level = 99,
        })

        target = player.entities:moveTo('Wild_Rabbit')
        target:setMaxHP(maxHP)
        target:setHP(maxHP)

        assert(xi.settings.map.GLOBAL_HP_DAMAGE_CAP == damageCap,
            'The test expects GLOBAL_HP_DAMAGE_CAP to use its default value')
    end)

    it('caps positive damage before listeners and HP reduction', function()
        local observedDamage = 0
        target:addListener('TAKE_DAMAGE', 'TEST_GLOBAL_HP_DAMAGE_CAP', function(_, amount)
            observedDamage = amount
        end)

        target:takeDamage(damageCap + 1, player, xi.attackType.PHYSICAL, xi.damageType.SLASHING)

        assert(observedDamage == damageCap,
            string.format('Expected listener damage %d, got %d', damageCap, observedDamage))
        assert(target:getHP() == maxHP - damageCap,
            string.format('Expected target HP %d, got %d', maxHP - damageCap, target:getHP()))

        target:removeListener('TEST_GLOBAL_HP_DAMAGE_CAP')
    end)

    it('leaves positive damage at or below the cap unchanged', function()
        local damage = damageCap - 1
        target:takeDamage(damage, player, xi.attackType.PHYSICAL, xi.damageType.SLASHING)

        assert(target:getHP() == maxHP - damage,
            string.format('Expected target HP %d, got %d', maxHP - damage, target:getHP()))
    end)

    it('leaves healing and negative damage unchanged', function()
        target:setHP(maxHP - 1000)
        target:takeDamage(-500, player, xi.attackType.MAGICAL, xi.damageType.LIGHT)

        assert(target:getHP() == maxHP - 500,
            string.format('Expected target HP %d, got %d', maxHP - 500, target:getHP()))
    end)

    it('allows an explicit forced-death bypass', function()
        local lethalDamage = maxHP
        target:takeDamage(lethalDamage, player, xi.attackType.MAGICAL, xi.damageType.DARK,
            { wakeUp = true, breakBind = true, bypassGlobalHpDamageCap = true })

        assert(target:getHP() == 0, 'Expected forced-death bypass to apply the full lethal amount')
    end)

    it('preserves a lower target-specific received-damage cap', function()
        local targetCap = 1234
        target:setMod(xi.mod.RECEIVED_DAMAGE_CAP, targetCap)

        local damage = target:checkDamageCap(damageCap + 1)
        target:takeDamage(damage, player, xi.attackType.PHYSICAL, xi.damageType.SLASHING)

        assert(target:getHP() == maxHP - targetCap,
            string.format('Expected lower target cap %d to win, got %d damage',
                targetCap, maxHP - target:getHP()))
    end)
end)
