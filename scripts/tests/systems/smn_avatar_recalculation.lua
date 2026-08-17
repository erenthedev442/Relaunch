describe('SMN avatar stat recalculation', function()
    it('preserves live pools and rebuilds modifier layers on weapon swaps', function()
        local player = xi.test.world:spawnPlayer(
        {
            job   = xi.job.SMN,
            level = 99,
            zone  = xi.zone.SOUTHERN_SAN_DORIA,
        })

        player:setPetMod(xi.mod.HP, 123)
        player:setPetMod(xi.mod.ATT, 37)
        player:addItem(xi.item.FIRE_STAFF)
        player:addItem(xi.item.DARK_STAFF)
        player:spawnPet(xi.petId.GARUDA)

        local pet = player:getPet()
        assert(pet)
        assert(pet:getHP() == pet:getMaxHP(), 'first spawn should have full HP')
        assert(pet:getMP() == pet:getMaxMP(), 'first spawn should have full MP')
        assert(
            pet:getMod(xi.mod.HP) >= 5123,
            'stable SMN boost and master HP layers should both apply')

        -- Simulate an independent spawn/status layer that recalculation must
        -- preserve rather than replacing or tracking as an intrinsic stat.
        pet:addMod(xi.mod.ATT, 41)

        local expectedMaxHP = pet:getMaxHP()
        local expectedMaxMP = pet:getMaxMP()
        local expectedHPMod = pet:getMod(xi.mod.HP)
        local expectedAtt   = pet:getMod(xi.mod.ATT)
        local expectedMacc  = pet:getMod(xi.mod.MACC)

        local expectedHP = math.floor(expectedMaxHP / 3)
        local expectedMP = math.floor(expectedMaxMP / 4)
        local expectedTP = 1750
        pet:setHP(expectedHP)
        pet:setMP(expectedMP)
        pet:setTP(expectedTP)

        for _, staff in ipairs({ xi.item.FIRE_STAFF, xi.item.DARK_STAFF, xi.item.FIRE_STAFF }) do
            player:equipItem(staff, nil, xi.slot.MAIN)

            assert(pet:getMaxHP() == expectedMaxHP, 'maximum HP must not collapse or stack')
            assert(pet:getMaxMP() == expectedMaxMP, 'maximum MP must not collapse or stack')
            assert(pet:getHP() == expectedHP, 'weapon swaps must not heal or damage the avatar')
            assert(pet:getMP() == expectedMP, 'weapon swaps must preserve avatar MP percentage')
            assert(pet:getTP() == expectedTP, 'weapon swaps must not reset avatar TP')
            assert(pet:getMod(xi.mod.HP) == expectedHPMod, 'HP modifier layers must remain idempotent')
            assert(
                pet:getMod(xi.mod.ATT) == expectedAtt,
                'intrinsic, master, and raw ATT must not stack or disappear')
            assert(pet:getMod(xi.mod.MACC) == expectedMacc, 'SMN boost MACC must survive recalculation')
        end
    end)
end)
