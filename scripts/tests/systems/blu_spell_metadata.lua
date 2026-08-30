describe('BLU spell metadata integrity', function()
    local function readFile(path)
        local file = assert(io.open(path, 'r'))
        local text = file:read('*a')
        file:close()
        return text
    end

    local function parseMagicIds(text)
        local ids = {}
        for name, id in text:gmatch('%s+([A-Z0-9_]+)%s*=%s*(%d+),') do
            ids[name] = tonumber(id)
        end

        return ids
    end

    local function parseSpellRows(text)
        local constants = {}
        for name, value in text:gmatch('SET%s+@([A-Z0-9_]+)%s*=%s*(%d+)%s*;') do
            constants[name] = tonumber(value)
        end

        local function sqlNumber(value)
            local numeric = tonumber(value)
            if numeric then
                return numeric
            end

            local name = value:match('@([A-Z0-9_]+)')
            return name and constants[name] or nil
        end

        local rows = {}
        for row in text:gmatch("INSERT INTO `spell_list` VALUES %((.-)%);") do
            local fields = {}
            for field in row:gmatch('[^,]+') do
                fields[#fields + 1] = field
            end

            rows[tonumber(fields[1])] =
            {
                element      = sqlNumber(fields[6]),
                mpCost       = tonumber(fields[10]),
                castTime     = tonumber(fields[11]),
                recastTime   = tonumber(fields[12]),
                animation    = tonumber(fields[15]),
                requirements = tonumber(fields[22]),
            }
        end

        return rows
    end

    local function parseBlueRows(text)
        local rows = {}
        for id, mobSkillId, setPoints, category, weight in
            text:gmatch("INSERT INTO `blue_spell_list` VALUES %((%d+),(%d+),(%d+),(%d+),(%d+),")
        do
            id = tonumber(id)
            rows[id] =
            {
                mobSkillId = tonumber(mobSkillId),
                setPoints  = tonumber(setPoints),
                category   = tonumber(category),
                weight     = tonumber(weight),
            }
        end

        -- Account for the canonical normalization statements in the SQL file.
        for id, row in pairs(rows) do
            if id < 700 then
                if row.category == 0 then
                    row.weight = 0
                elseif row.category == 23 or row.category == 27 or row.category == 28 then
                    row.weight = 6
                elseif row.category ~= 14 then
                    row.weight = row.weight * 4
                end
            end
        end

        return rows
    end

    local magicIds = parseMagicIds(readFile('scripts/enum/magic.lua'))
    local progression = readFile('modules/custom/lua/blu_spell_progression.lua')
    local spellRows = parseSpellRows(readFile('sql/spell_list.sql'))
    local blueRows = parseBlueRows(readFile('sql/blue_spell_list.sql'))
    local modSql = readFile('sql/blue_spell_mods.sql')

    it('keeps all 195 progression entries loadable', function()
        local seen = {}
        local count = 0
        for name in progression:gmatch('xi%.magic%.spell%.([A-Z0-9_]+)') do
            local id = magicIds[name]
            assert(id ~= nil, string.format('missing magic enum for %s', name))
            assert(not seen[id], string.format('duplicate progression spell %u', id))
            assert(spellRows[id] ~= nil, string.format('missing spell_list row %u', id))
            assert(blueRows[id] ~= nil, string.format('missing blue_spell_list row %u', id))
            seen[id] = true
            count = count + 1
        end

        assert(count == 195, string.format('expected 195 BLU spells, found %u', count))
    end)

    it('matches the complete retail spell trait roster', function()
        local expected =
        {
            [1]  = '595:4 597:4 603:4 650:4 716:8',
            [2]  = '581:4 584:4 690:4',
            [3]  = '577:4 585:4 587:4 717:8',
            [4]  = '513:4 515:4 536:4 548:4 573:4 588:4 598:4 606:4 621:4 636:4 644:4 651:4',
            [5]  = '549:4 576:4 578:4 593:4 645:4',
            [6]  = '538:4 544:4 557:4 572:4 591:4 613:4 646:4 678:4 708:8 720:8',
            [7]  = '527:4 529:4',
            [8]  = '540:4 554:4 594:4 616:4 620:4 675:4 703:8 719:8',
            [9]  = '569:4 631:4 638:4',
            [10] = '517:4 534:4 563:4 668:4 694:4',
            [11] = '539:4 614:4 617:4 622:4 722:8',
            [12] = '543:4 551:4 652:4',
            [13] = '531:4 555:4 672:4 702:8 726:8',
            [14] = '533:2 535:1 537:1 561:2 579:3 612:4 615:4 634:2 681:4',
            [15] = '564:4 628:4 629:4 685:4 695:4 706:4 711:8',
            [16] = '560:4 589:4 611:4 667:4 700:8 721:8',
            [17] = '582:4 608:4 637:4 647:4 687:4 707:8',
            [18] = '519:4 641:4 679:4 701:8 727:8',
            [19] = '574:4 648:4',
            [20] = '545:4 640:4 674:4 692:4 713:8',
            [21] = '633:4 653:4 689:4 696:4',
            [22] = '604:4 654:4 671:4 698:4 710:8',
            [23] = '666:6 670:6 693:6 704:8',
            [24] = '656:4 659:4 677:4 688:4 709:8',
            [25] = '657:4 661:4 673:4 682:4 686:4 699:4 715:8',
            [26] = '665:4 669:4',
            [27] = '660:6 663:6 684:6 712:8',
            [28] = '680:6 683:6 697:6',
            [29] = '705:8',
            [30] = '728:8',
            [31] = '725:8',
            [32] = '714:8',
            [33] = '723:8',
            [34] = '724:8',
        }

        local expectedIds = {}
        for category, roster in pairs(expected) do
            for id, weight in roster:gmatch('(%d+):(%d+)') do
                id = tonumber(id)
                weight = tonumber(weight)
                expectedIds[id] = true
                assert(blueRows[id] ~= nil, string.format('missing trait spell %u', id))
                assert(blueRows[id].category == category,
                    string.format('spell %u category: expected %u, got %u', id, category, blueRows[id].category))
                assert(blueRows[id].weight == weight,
                    string.format('spell %u weight: expected %u, got %u', id, weight, blueRows[id].weight))
            end
        end

        for id, row in pairs(blueRows) do
            assert(
                (row.category == 0 and row.weight == 0) or expectedIds[id],
                string.format('unexpected trait mapping on spell %u: category %u, weight %u',
                    id, row.category, row.weight))
        end
    end)

    it('keeps every trait category reachable at the retail 8-point floor', function()
        local traitSql = readFile('sql/blue_traits.sql')
        for category = 1, 34 do
            assert(
                traitSql:match(string.format('VALUES %(%u,8,%%d+,%%d+,%%-?%%d+,%%d+,0%%)', category)),
                string.format('trait category %u has no non-JP 8-point entry', category))
        end
    end)

    it('keeps every Unbridled spell non-settable and modifier-free', function()
        local unbridled = {}
        for id = 736, 753 do
            if blueRows[id] then
                unbridled[#unbridled + 1] = id
            end
        end

        for _, id in ipairs(unbridled) do
            assert(spellRows[id].requirements == 16, string.format('spell %u must require Unbridled Learning', id))
            assert(blueRows[id].setPoints == 0, string.format('spell %u must not consume set points', id))
            assert(blueRows[id].category == 0 and blueRows[id].weight == 0,
                string.format('spell %u must not grant a set trait', id))
            assert(not modSql:match(string.format('VALUES %(%u,[^0]', id)),
                string.format('spell %u must not grant equip modifiers', id))
        end
    end)

    it('keeps premium spell costs and safe SOA animations intact', function()
        local premiumAnimations =
        {
            [719] = 673, -- Self-Destruct
            [720] = 721, -- Ice Break
            [721] = 697, -- Blitzstrahl
            [722] = 631, -- Sandspin
            [725] = 741, -- Actinic Burst
            [726] = 690, -- Maelstrom
            [727] = 695, -- Mysterious Light
            [728] = 661, -- Blood Saber
        }

        for id, animation in pairs(premiumAnimations) do
            assert(blueRows[id].setPoints == 8, string.format('spell %u must cost 8 points', id))
            assert(spellRows[id].animation == animation, string.format('spell %u has unsafe animation', id))
        end

        assert(spellRows[749].animation == 688, 'Polar Roar must use Frost Breath, not Warp')
        assert(spellRows[724].animation == 704, 'Palling Salvo must use Eyes On Me')
        assert(spellRows[750].animation == 654, 'Mighty Guard must use Cocoon')
        assert(spellRows[717].animation == 698, 'Sweeping Gouge must use Sickle Slash')
        assert(spellRows[723].animation == 692, 'Saurian Slide must use Uppercut')
    end)

    it('keeps Tenebral Crush on the same INT payload as Spectral Floe', function()
        local floe = readFile('scripts/actions/spells/blue/spectral_floe.lua')
        local tenebral = readFile('scripts/actions/spells/blue/tenebral_crush.lua')

        assert(floe:match('int_wsc%s*=%s*0%.8'), 'Spectral Floe must stay 0.8 INT')
        assert(tenebral:match('int_wsc%s*=%s*0%.8'), 'Tenebral Crush must use 0.8 INT')
        assert(tenebral:match('vit_wsc%s*=%s*0%.0'), 'Tenebral Crush must not split onto VIT')
        assert(tenebral:match('mnd_wsc%s*=%s*0%.0'), 'Tenebral Crush must not split onto MND')
        assert(tenebral:match('multiplier%s*=%s*6%.5'), 'Tenebral Crush multiplier must match the 8-point suite')
    end)

    it('uses real learn skills and passive modifiers for repaired spells', function()
        assert(blueRows[709].mobSkillId == 3974)
        assert(blueRows[711].mobSkillId == 2041)
        assert(blueRows[712].mobSkillId == 2040)

        for id = 708, 714 do
            assert(
                not modSql:find(string.format('VALUES %(%u,0,0%)', id)),
                string.format('spell %u still has placeholder modifiers', id))
        end
    end)

    it('keeps the re-enabled BLU spells castable and bounded', function()
        local fantod = readFile('scripts/actions/spells/blue/fantod.lua')
        local mortalRay = readFile('scripts/actions/spells/blue/mortal_ray.lua')
        local pyricBulwark = readFile('scripts/actions/spells/blue/pyric_bulwark.lua')
        local damageMultipliers = readFile('scripts/globals/combat/damage_multipliers.lua')

        for name, source in pairs(
        {
            fantod        = fantod,
            mortal_ray    = mortalRay,
            pyric_bulwark = pyricBulwark,
        })
        do
            assert(
                source:match('onMagicCastingCheck%s*=%s*function.-return 0'),
                string.format('%s must remain castable', name))
        end

        assert(fantod:match('math%.min%(currentEffect:getPower%(%) %+ 5, 25%)'))
        assert(pyricBulwark:match('subPower%s*=%s*255'))
        assert(damageMultipliers:match('physicalShield:getSubPower%(%) == 255'))
        assert(damageMultipliers:match('delStatusEffectSilent%(xi%.effect%.PHYSICAL_SHIELD%)'))

        assert(spellRows[674].mpCost == 12 and spellRows[674].recastTime == 10000)
        assert(spellRows[686].mpCost == 267 and spellRows[686].castTime == 8000)
        assert(spellRows[686].recastTime == 150000)
        assert(spellRows[741].element == 2 and spellRows[741].requirements == 16)
        assert(blueRows[674].mobSkillId == 580 and blueRows[674].setPoints == 1)
        assert(blueRows[686].mobSkillId == 502 and blueRows[686].setPoints == 4)
        assert(blueRows[741].mobSkillId == 1831 and blueRows[741].setPoints == 0)
    end)
end)
