describe('Global HP damage cap', function()
    ---@type CClientEntityPair
    local player

    ---@type CTestEntity
    local target

    local damageCap = 999999
    local maxHP     = 10000000

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

    it('allows only an active Prime WS window to use its higher job cap', function()
        local primeCap = 1749999
        player:setLocalVar('PrimeWsDamageCap', primeCap)

        target:takeDamage(primeCap + 1, player, xi.attackType.PHYSICAL, xi.damageType.SLASHING)

        assert(target:getHP() == maxHP - primeCap,
            string.format('Expected Prime damage cap %d, got %d damage',
                primeCap, maxHP - target:getHP()))
    end)

    it('never permits a Prime WS cap above 1,999,999', function()
        local primeAbsoluteCap = 1999999
        player:setLocalVar('PrimeWsDamageCap', 9999999)

        target:takeDamage(primeAbsoluteCap + 1, player, xi.attackType.PHYSICAL, xi.damageType.SLASHING)

        assert(target:getHP() == maxHP - primeAbsoluteCap,
            string.format('Expected absolute Prime cap %d, got %d damage',
                primeAbsoluteCap, maxHP - target:getHP()))
    end)

    it('allows only an active BLU spell window to reach the Prime BLU cap', function()
        local blueSpellCap = 1749999
        player:setLocalVar('BlueSpellDamageCap', blueSpellCap)

        target:takeDamage(blueSpellCap + 1, player, xi.attackType.MAGICAL, xi.damageType.FIRE)

        assert(target:getHP() == maxHP - blueSpellCap,
            string.format('Expected BLU spell cap %d, got %d damage',
                blueSpellCap, maxHP - target:getHP()))
    end)

    it('enforces lower BLU weapon-tier caps and rejects oversized values', function()
        player:setLocalVar('BlueSpellDamageCap', 40000)
        target:takeDamage(damageCap, player, xi.attackType.MAGICAL, xi.damageType.FIRE)
        assert(target:getHP() == maxHP - 40000, 'Expected the pre-119 BLU cap')

        target:setHP(maxHP)
        player:setLocalVar('BlueSpellDamageCap', 9999999)
        target:takeDamage(1749999, player, xi.attackType.MAGICAL, xi.damageType.FIRE)
        assert(target:getHP() == maxHP - damageCap,
            'An invalid BLU local cap must not raise the global ceiling')
    end)

    it('returns to the global cap after the BLU spell window is cleared', function()
        player:setLocalVar('BlueSpellDamageCap', 1749999)
        player:setLocalVar('BlueSpellDamageCap', 0)

        target:takeDamage(1749999, player, xi.attackType.MAGICAL, xi.damageType.FIRE)

        assert(target:getHP() == maxHP - damageCap,
            string.format('Expected restored global cap %d, got %d damage',
                damageCap, maxHP - target:getHP()))
    end)

    it('uses the lower AoE WS cap even during a Prime window', function()
        local wsCap = 99999
        player:setLocalVar('PrimeWsDamageCap', 1999999)
        player:setLocalVar('AoEWsDamageCap', wsCap)

        target:takeDamage(damageCap, player, xi.attackType.PHYSICAL, xi.damageType.SLASHING)

        assert(target:getHP() == maxHP - wsCap,
            string.format('Expected AoE WS cap %d, got %d damage',
                wsCap, maxHP - target:getHP()))
    end)

    it('uses the lower final-Ambuscade WS cap', function()
        local wsCap = 99999
        player:setLocalVar('AmbuscadeWsDamageCap', wsCap)

        target:takeDamage(damageCap, player, xi.attackType.PHYSICAL, xi.damageType.SLASHING)

        assert(target:getHP() == maxHP - wsCap,
            string.format('Expected Ambuscade WS cap %d, got %d damage',
                wsCap, maxHP - target:getHP()))
    end)

    it('enforces the active standard weapon progression cap', function()
        local wsCap = 40000
        player:setLocalVar('StandardWsDamageCap', wsCap)

        target:takeDamage(damageCap, player, xi.attackType.PHYSICAL, xi.damageType.SLASHING)

        assert(target:getHP() == maxHP - wsCap,
            string.format('Expected standard WS damage cap %d, got %d damage',
                wsCap, maxHP - target:getHP()))
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
