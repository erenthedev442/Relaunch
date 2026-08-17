describe('Puppetmaster role identity', function()
    local function spawnAutomaton(frameItem, headItem, frame, head, attachments)
        local player = xi.test.world:spawnPlayer(
            {
                job   = xi.job.PUP,
                level = 99,
                zone  = xi.zone.SOUTHERN_SAN_DORIA,
            })

        player:unlockAttachment(frameItem)
        player:unlockAttachment(headItem)
        player:setAutomatonFrame(frame)
        player:setAutomatonHead(head)

        for slot, attachmentId in ipairs(attachments or {}) do
            player:unlockAttachment(attachmentId)
            player:setAttachment(attachmentId, slot - 1)
        end

        player:spawnPet(xi.petId.AUTOMATON)

        local pet = player:getPet()
        assert(pet)
        return player, pet
    end

    it('gives each specialized frame a distinct aptitude', function()
        local _, tank = spawnAutomaton(
            8225, 8194, xi.automaton.frame.VALOREDGE, xi.automaton.head.VALOREDGE)
        local _, ranger = spawnAutomaton(
            8226, 8195, xi.automaton.frame.SHARPSHOT, xi.automaton.head.SHARPSHOT)
        local _, mage = spawnAutomaton(
            8227, 8196, xi.automaton.frame.STORMWAKER, xi.automaton.head.STORMWAKER)

        assert(tank:getMaxHP() > ranger:getMaxHP(), 'Valoredge should have the highest HP aptitude')
        assert(tank:getMod(xi.mod.DEF) > mage:getMod(xi.mod.DEF), 'Valoredge should have the highest DEF aptitude')
        assert(ranger:getRATT() > tank:getRATT(), 'Sharpshot should have the highest ranged attack aptitude')
        assert(ranger:getRACC() > tank:getRACC(), 'Sharpshot should have the highest ranged accuracy aptitude')
        assert(mage:getMaxMP() > ranger:getMaxMP(), 'Stormwaker should have the highest MP aptitude')
        assert(mage:getMod(xi.mod.MATT) > tank:getMod(xi.mod.MATT), 'Stormwaker should have the highest magic attack aptitude')
        assert(mage:getMod(xi.mod.MACC) > tank:getMod(xi.mod.MACC), 'Stormwaker should have the highest magic accuracy aptitude')
    end)

    it('rebuilds frame and master modifiers without stacking', function()
        local player, pet = spawnAutomaton(
            8225, 8194, xi.automaton.frame.VALOREDGE, xi.automaton.head.VALOREDGE)

        local expectedHP   = pet:getMaxHP()
        local expectedDef  = pet:getMod(xi.mod.DEF)
        local expectedVit  = pet:getMod(xi.mod.VIT)

        -- A live automaton is recalculated when its master's level changes.
        -- Changing the configured frame/head while it is active does not
        -- exercise CalculateAutomatonStats.
        player:setLevel(98)
        player:setLevel(99)

        assert(pet:getMaxHP() == expectedHP, 'recalculation must not stack maximum HP')
        assert(pet:getMod(xi.mod.DEF) == expectedDef, 'recalculation must not stack DEF')
        assert(pet:getMod(xi.mod.VIT) == expectedVit, 'recalculation must not stack frame stats')
    end)

    it('makes tank attachments materially improve the Valoredge frame', function()
        local _, naked = spawnAutomaton(
            8225, 8194, xi.automaton.frame.VALOREDGE, xi.automaton.head.VALOREDGE)
        local _, pet = spawnAutomaton(
            8225, 8194, xi.automaton.frame.VALOREDGE, xi.automaton.head.VALOREDGE,
            { 8556, 8653, 8457 }) -- Armor Plate IV, Auto-Repair Kit IV, Strobe II

        local nakedHP     = naked:getMaxHP()
        local nakedPDT    = naked:getMod(xi.mod.DMGPHYS)
        local nakedEnmity = naked:getMod(xi.mod.ENMITY)

        assert(pet:getMaxHP() > nakedHP, 'Auto-Repair Kit IV should raise maximum HP')
        assert(pet:getMod(xi.mod.DMGPHYS) < nakedPDT, 'Armor Plate IV should add physical mitigation')
        assert(pet:getMod(xi.mod.ENMITY) > nakedEnmity, 'Strobe II should add enmity')
    end)

    it('makes ranged attachments materially improve the Sharpshot frame', function()
        local _, naked = spawnAutomaton(
            8226, 8195, xi.automaton.frame.SHARPSHOT, xi.automaton.head.SHARPSHOT)
        local _, pet = spawnAutomaton(
            8226, 8195, xi.automaton.frame.SHARPSHOT, xi.automaton.head.SHARPSHOT,
            { 8460, 8527, 8528 }) -- Tension Spring IV, Scope IV, Truesights

        local nakedRatt = naked:getMod(xi.mod.RATTP)
        local nakedRacc = naked:getMod(xi.mod.RACC)

        assert(pet:getMod(xi.mod.RATTP) > nakedRatt, 'Tension Spring IV should raise ranged attack')
        assert(pet:getMod(xi.mod.RACC) > nakedRacc, 'Scope IV should raise ranged accuracy')
        assert(pet:getMod(xi.mod.AUTO_RANGED_DAMAGEP) > 0, 'Truesights should raise ranged damage')
    end)

    it('makes caster attachments materially improve the Stormwaker frame', function()
        local _, naked = spawnAutomaton(
            8227, 8198, xi.automaton.frame.STORMWAKER, xi.automaton.head.SPIRITREAVER)
        local _, pet = spawnAutomaton(
            8227, 8198, xi.automaton.frame.STORMWAKER, xi.automaton.head.SPIRITREAVER,
            { 8484, 8496, 8683 }) -- Loudspeaker II, Tranquilizer IV, Mana Tank IV

        local nakedMab  = naked:getMod(xi.mod.MATT)
        local nakedMacc = naked:getMod(xi.mod.MACC)
        local nakedMp   = naked:getMaxMP()

        assert(pet:getMod(xi.mod.MATT) > nakedMab, 'Loudspeaker II should raise magic attack')
        assert(pet:getMod(xi.mod.MACC) > nakedMacc, 'Tranquilizer IV should raise magic accuracy')
        assert(pet:getMaxMP() > nakedMp, 'Mana Tank IV should raise maximum MP')
    end)

    it('makes healer attachments materially improve the Soulsoother build', function()
        local _, pet = spawnAutomaton(
            8227, 8197, xi.automaton.frame.STORMWAKER, xi.automaton.head.SOULSOOTHER,
            { 8649, 8655, 8681 }) -- Vivi-Valve II, Damage Gauge II, Mana Tank III

        assert(pet:getMod(xi.mod.CURE_POTENCY) > 0, 'Vivi-Valve II should raise cure potency')
        assert(pet:getMod(xi.mod.AUTO_HEALING_THRESHOLD) > 0, 'Damage Gauge II should raise healing threshold')
        assert(pet:getMod(xi.mod.MPP) > 0, 'Mana Tank III should raise maximum MP')
    end)
end)
