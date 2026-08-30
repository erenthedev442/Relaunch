describe('Blue Mage set traits', function()
    ---@type CClientEntityPair
    local player

    local function setSpells(spells)
        for _, spellId in ipairs(spells) do
            player:addSpell(spellId)
        end

        player.actions:setBlueSpells(spells)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ level = 99 })
        player:changeJob(xi.job.BLU)
        player:setLevel(99)
    end)

    it('applies retail thresholds and every modifier on multi-mod traits', function()
        local baseAtt  = player:getMod(xi.mod.ATT)
        local baseRatt = player:getMod(xi.mod.RATT)

        setSpells({ xi.magic.spell.EMBALMING_EARTH })
        assert(player:getMod(xi.mod.ATT) == baseAtt + 10)
        assert(player:getMod(xi.mod.RATT) == baseRatt + 10)

        setSpells({ xi.magic.spell.EMBALMING_EARTH, xi.magic.spell.SEARING_TEMPEST })
        assert(player:getMod(xi.mod.ATT) == baseAtt + 22)
        assert(player:getMod(xi.mod.RATT) == baseRatt + 22)

        setSpells({ xi.magic.spell.PALLING_SALVO })
        for _, modId in ipairs(
        {
            xi.mod.SLEEPRES,
            xi.mod.POISONRES,
            xi.mod.PARALYZERES,
            xi.mod.BLINDRES,
            xi.mod.SILENCERES,
            xi.mod.VIRUSRES,
            xi.mod.PETRIFYRES,
            xi.mod.BINDRES,
            xi.mod.CURSERES,
        })
        do
            assert(player:getMod(modId) == 5, string.format('Tenacity did not apply modifier %u', modId))
        end
    end)

    it('applies the new level-99 trait families', function()
        local baseMacc = player:getMod(xi.mod.MACC)
        local baseMeva = player:getMod(xi.mod.MEVA)

        setSpells({ xi.magic.spell.TENEBRAL_CRUSH })
        assert(player:getMod(xi.mod.MACC) == baseMacc + 10)

        setSpells({ xi.magic.spell.BLINDING_FULGOR })
        assert(player:getMod(xi.mod.MEVA) == baseMeva + 10)

        setSpells({ xi.magic.spell.SINKER_DRILL })
        assert(player:getMod(xi.mod.CRIT_DMG_INCREASE) == 5)

        setSpells({ xi.magic.spell.SAURIAN_SLIDE })
        assert(player:getMod(xi.mod.INQUARTATA) == 5)

        setSpells({ xi.magic.spell.FOUL_WATERS })
        assert(player:getMod(xi.mod.SILENCERES) == 10)
    end)

    it('replaces Double Attack with Triple Attack at 16 trait points', function()
        setSpells(
        {
            xi.magic.spell.THRASHING_ASSAULT,
            xi.magic.spell.ACRID_STREAM,
            xi.magic.spell.HEAVY_STRIKE,
        })

        assert(player:getMod(xi.mod.DOUBLE_ATTACK) == 0)
        assert(player:getMod(xi.mod.TRIPLE_ATTACK) == 5)
    end)

    it('applies Job Trait Bonus tiers but preserves retail exceptions', function()
        player:setMod(xi.mod.BLUE_JOB_TRAIT_BONUS, 1)
        local baseAtt = player:getMod(xi.mod.ATT)

        setSpells({ xi.magic.spell.EMBALMING_EARTH })
        assert(player:getMod(xi.mod.ATT) == baseAtt + 22)

        setSpells({ xi.magic.spell.THRASHING_ASSAULT })
        assert(player:getMod(xi.mod.DOUBLE_ATTACK) == 7)
        assert(player:getMod(xi.mod.TRIPLE_ATTACK) == 0)
    end)

    it('does not stack spell modifiers on repeated set loads', function()
        setSpells({ xi.magic.spell.EMBALMING_EARTH })
        local str = player:getMod(xi.mod.STR)
        local att = player:getMod(xi.mod.ATT)

        player:changeJob(xi.job.WAR)
        player:changeJob(xi.job.BLU)
        assert(player:getMod(xi.mod.STR) == str)
        assert(player:getMod(xi.mod.ATT) == att)

        player:changeJob(xi.job.WAR)
        player:changeJob(xi.job.BLU)
        assert(player:getMod(xi.mod.STR) == str)
        assert(player:getMod(xi.mod.ATT) == att)
    end)

    it('rejects Unbridled spells without disturbing the equipped slot', function()
        setSpells({ xi.magic.spell.SAURIAN_SLIDE })
        assert(player:getMod(xi.mod.INQUARTATA) == 5)

        player:addSpell(xi.magic.spell.DRONING_WHIRLWIND)
        player.actions:setBlueSpells({ xi.magic.spell.DRONING_WHIRLWIND })
        assert(player:getMod(xi.mod.INQUARTATA) == 5)
    end)

    it('preserves the BLU spell set when BLU main changes support job', function()
        setSpells({ xi.magic.spell.SAURIAN_SLIDE })
        assert(player:getMod(xi.mod.INQUARTATA) == 5)

        player:changesJob(xi.job.WAR)
        assert(player:getMod(xi.mod.INQUARTATA) == 5)
    end)

    it('reloads the persisted set when promoting BLU from support to main', function()
        setSpells({ xi.magic.spell.SAURIAN_SLIDE })
        player:changeJob(xi.job.WAR)
        player:changesJob(xi.job.BLU)
        assert(player:getMod(xi.mod.INQUARTATA) == 5)

        player:changeJob(xi.job.BLU)
        assert(player:getMod(xi.mod.INQUARTATA) == 5)
    end)
end)
