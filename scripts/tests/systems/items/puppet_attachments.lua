describe('Puppet attachments', function()
    ---@type CClientEntityPair
    local player

    local attachment =
    {
        POWER_COOLER      = 8488,
        AMPLIFIER         = 8491,
        AMPLIFIER_II      = 8494,
        RESISTER          = 8619,
        RESISTER_II       = 8620,
        MANA_CHANNELER_II = 8622,
        DAMAGE_GAUGE_II   = 8655,
    }

    before_each(function()
        player = xi.test.world:spawnPlayer(
            {
                job   = xi.job.PUP,
                level = 75,
                zone  = xi.zone.SOUTHERN_SAN_DORIA,
            })

        player:unlockAttachment(xi.item.HARLEQUIN_FRAME)
        player:unlockAttachment(xi.item.HARLEQUIN_HEAD)
        player:unlockAttachment(xi.item.STROBE_ATTACHMENT)
    end)

    it('equipped attachment is visible on the spawned automaton', function()
        player:setAttachment(xi.item.STROBE_ATTACHMENT, 0)
        player:spawnPet(xi.petId.AUTOMATON)

        local pet = player:getPet()
        assert(pet)

        local attachments = pet:getAttachments()
        assert(attachments)

        local item = attachments[0]
        assert(item)
        assert(item:getName() == 'strobe',
            string.format('expected strobe, got %s', item:getName()))
    end)

    local function spawnWithAttachment(attachmentId)
        player:unlockAttachment(attachmentId)
        player:setAttachment(attachmentId, 0)
        player:spawnPet(xi.petId.AUTOMATON)

        local pet = player:getPet()
        assert(pet)
        return pet
    end

    it('applies Power Cooler idempotently', function()
        local pet = spawnWithAttachment(attachment.POWER_COOLER)
        assert(pet:getMod(xi.mod.BLACK_MAGIC_COST) == -10)
        assert(pet:getMod(xi.mod.WHITE_MAGIC_COST) == -10)

        player:updateAttachments()
        player:updateAttachments()

        assert(pet:getMod(xi.mod.BLACK_MAGIC_COST) == -10)
        assert(pet:getMod(xi.mod.WHITE_MAGIC_COST) == -10)
    end)

    it('applies Amplifier idempotently', function()
        local pet = spawnWithAttachment(attachment.AMPLIFIER)
        assert(pet:getMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED) == 10)

        player:updateAttachments()
        player:updateAttachments()

        assert(pet:getMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED) == 10)
    end)

    it('applies Amplifier II idempotently', function()
        local pet = spawnWithAttachment(attachment.AMPLIFIER_II)
        assert(pet:getMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED) == 20)

        player:updateAttachments()
        player:updateAttachments()

        assert(pet:getMod(xi.mod.MAGIC_BURST_BONUS_UNCAPPED) == 20)
    end)

    it('applies Resister idempotently', function()
        local pet = spawnWithAttachment(attachment.RESISTER)
        assert(pet:getMod(xi.mod.STATUSRES) == 5)

        player:updateAttachments()
        player:updateAttachments()

        assert(pet:getMod(xi.mod.STATUSRES) == 5)
    end)

    it('applies Resister II idempotently', function()
        local pet = spawnWithAttachment(attachment.RESISTER_II)
        assert(pet:getMod(xi.mod.STATUSRES) == 10)

        player:updateAttachments()
        player:updateAttachments()

        assert(pet:getMod(xi.mod.STATUSRES) == 10)
    end)

    it('applies Mana Channeler II idempotently', function()
        local pet = spawnWithAttachment(attachment.MANA_CHANNELER_II)
        assert(pet:getMod(xi.mod.MATT) == 20)
        assert(pet:getMod(xi.mod.AUTO_MAGIC_DELAY) == -6)

        player:updateAttachments()
        player:updateAttachments()

        assert(pet:getMod(xi.mod.MATT) == 20)
        assert(pet:getMod(xi.mod.AUTO_MAGIC_DELAY) == -6)
    end)

    it('applies Damage Gauge II idempotently', function()
        local pet = spawnWithAttachment(attachment.DAMAGE_GAUGE_II)
        -- The controller's native no-maneuver threshold is 30%; this +30
        -- modifier produces Damage Gauge II's final 60% trigger.
        assert(pet:getMod(xi.mod.AUTO_HEALING_THRESHOLD) == 30)
        assert(pet:getMod(xi.mod.AUTO_HEALING_DELAY) == 3)

        player:updateAttachments()
        player:updateAttachments()

        assert(pet:getMod(xi.mod.AUTO_HEALING_THRESHOLD) == 30)
        assert(pet:getMod(xi.mod.AUTO_HEALING_DELAY) == 3)
    end)
end)
