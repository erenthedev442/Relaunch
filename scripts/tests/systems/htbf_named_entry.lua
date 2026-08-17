local htbf = require('modules/custom/lua/htbf')

describe('Legendary HTBF named entry routing', function()
    local function makeNpc(name)
        return
        {
            getName = function()
                return name
            end,
        }
    end

    local function makeRoutingPlayer(zoneId, heldGems)
        return
        {
            getZoneID = function()
                return zoneId
            end,
            hasKeyItem = function(_, keyItem)
                return heldGems[keyItem] == true
            end,
            battlefieldAtCapacity = function()
                return false
            end,
        }
    end

    it('resolves only the matching gem at the exact entrance', function()
        local player = makeRoutingPlayer(
            xi.zone.LALOFF_AMPHITHEATER,
            { [xi.ki.PHANTOM_GEM_OF_COWARDICE] = true })

        local matches = htbf.getMatchingFightKeys(player, makeNpc('qm1_2'))
        assert(#matches == 1)
        assert(matches[1] == 'ark_angels_2')
        assert(#htbf.getMatchingFightKeys(player, makeNpc('qm1_1')) == 0)
    end)

    it('leaves retail entry untouched when no matching gem is held', function()
        local player = makeRoutingPlayer(
            xi.zone.LALOFF_AMPHITHEATER, {})
        local npc = makeNpc('qm1_2')

        assert(#htbf.getMatchingFightKeys(player, npc) == 0)
        assert(not xi.battlefield.customEntryTrigger(player, npc))
    end)

    it('sorts and exposes only currently eligible named choices', function()
        local zoneId = xi.zone.LALOFF_AMPHITHEATER
        local previous = xi.battlefield.contentsByZone[zoneId]
        local player = makeRoutingPlayer(zoneId, {})
        local npc = makeNpc('qm1_1')
        local function choice(order, eligible)
            return
            {
                customEntryFight = 'ark_angels_1',
                customEntryOrder = order,
                isValidEntry = function()
                    return true
                end,
                checkRequirements = function()
                    return eligible
                end,
                battlefieldId = 4160 + order - 1,
            }
        end
        xi.battlefield.contentsByZone[zoneId] =
        {
            choice(3, false),
            choice(2, true),
            choice(1, true),
        }

        local choices = htbf.getRegisteredChoices(
            player, npc, 'ark_angels_1')
        assert(#choices == 2)
        assert(choices[1].customEntryOrder == 1)
        assert(choices[2].customEntryOrder == 2)

        xi.battlefield.contentsByZone[zoneId] = previous
    end)

    it('directly registers and completes entry without event 32000', function()
        local zoneId = xi.zone.LALOFF_AMPHITHEATER
        local battlefield = {}
        local effect = {}
        local completed = 0
        local player = {}
        player.getID = function()
            return 1
        end
        player.getName = function()
            return 'Leader'
        end
        player.getZoneID = function()
            return zoneId
        end
        player.getAlliance = function()
            return { player }
        end
        player.getStatus = function()
            return xi.status.NORMAL
        end
        player.hasStatusEffect = function()
            return false
        end
        player.getBattlefield = function()
            return player.battlefield
        end
        player.battlefieldAtCapacity = function()
            return false
        end
        player.registerBattlefield = function()
            player.effect = effect
            player.battlefield = battlefield
            return xi.battlefield.returnCode.CUTSCENE
        end
        player.getStatusEffect = function()
            return player.effect
        end
        player.delStatusEffect = function()
        end
        player.enterBattlefield = function()
        end
        player.printToPlayer = function()
        end
        player.messageSpecial = function()
        end

        local content =
        {
            zoneId = zoneId,
            battlefieldId = 4160,
            maxPlayers = 6,
            isValidEntry = function()
                return true
            end,
            checkRequirements = function()
                return true
            end,
            onEntryComplete = function()
                completed = completed + 1
            end,
        }

        assert(Battlefield.directEntry(
            content, player, makeNpc('qm1_1')))
        assert(completed == 1)
        assert(player:getBattlefield() == battlefield)
    end)

    it('preflights every party members gem before registration', function()
        local zoneId = xi.zone.LALOFF_AMPHITHEATER
        local leader = {}
        local member =
        {
            getID = function()
                return 2
            end,
            getName = function()
                return 'MissingGem'
            end,
            getZoneID = function()
                return zoneId
            end,
            getStatus = function()
                return xi.status.NORMAL
            end,
            hasStatusEffect = function()
                return false
            end,
            getBattlefield = function()
                return nil
            end,
        }
        leader.getID = function()
            return 1
        end
        leader.getName = function()
            return 'Leader'
        end
        leader.getZoneID = function()
            return zoneId
        end
        leader.getAlliance = function()
            return { leader, member }
        end
        leader.getStatus = function()
            return xi.status.NORMAL
        end
        leader.hasStatusEffect = function()
            return false
        end
        leader.getBattlefield = function()
            return nil
        end
        leader.battlefieldAtCapacity = function()
            return false
        end
        leader.printToPlayer = function()
        end
        leader.messageSpecial = function()
        end
        leader.registerBattlefield = function()
            error('registration must not run before party preflight passes')
        end

        local content =
        {
            zoneId = zoneId,
            battlefieldId = 4160,
            maxPlayers = 6,
            isValidEntry = function()
                return true
            end,
            checkRequirements = function(_, candidate)
                return candidate:getID() == 1
            end,
        }

        assert(not Battlefield.directEntry(
            content, leader, makeNpc('qm1_1')))
    end)

    it('rolls back and refunds entry if a party registration fails', function()
        local zoneId = xi.zone.LALOFF_AMPHITHEATER
        local battlefield = {}
        local effect = {}
        local leader = { refunded = false, left = false }
        local member = { hasGem = true }

        leader.getID = function() return 1 end
        leader.getName = function() return 'Leader' end
        leader.getZoneID = function() return zoneId end
        leader.getAlliance = function() return { leader, member } end
        leader.getStatus = function() return xi.status.NORMAL end
        leader.hasStatusEffect = function() return false end
        leader.getBattlefield = function() return leader.battlefield end
        leader.battlefieldAtCapacity = function() return false end
        leader.registerBattlefield = function()
            leader.battlefield = battlefield
            leader.effect = effect
            return xi.battlefield.returnCode.CUTSCENE
        end
        leader.getStatusEffect = function() return leader.effect end
        leader.delStatusEffect = function() end
        leader.hasKeyItem = function() return false end
        leader.addKeyItem = function()
            leader.refunded = true
        end
        leader.leaveBattlefield = function()
            leader.left = true
            leader.battlefield = nil
        end
        leader.printToPlayer = function() end
        leader.messageSpecial = function() end

        member.getID = function() return 2 end
        member.getName = function() return 'Member' end
        member.getZoneID = function() return zoneId end
        member.getStatus = function() return xi.status.NORMAL end
        member.hasStatusEffect = function() return false end
        member.getBattlefield = function() return nil end
        member.copyStatusEffect = function() end
        member.registerBattlefield = function()
            return xi.battlefield.returnCode.REQS_NOT_MET
        end
        member.delStatusEffect = function() end
        member.hasKeyItem = function() return member.hasGem end
        member.addKeyItem = function() member.hasGem = true end

        local content =
        {
            zoneId = zoneId,
            battlefieldId = 4160,
            maxPlayers = 6,
            partyKeyItem = xi.ki.PHANTOM_GEM_OF_APATHY,
            isValidEntry = function() return true end,
            checkRequirements = function() return true end,
        }

        assert(not Battlefield.directEntry(
            content, leader, makeNpc('qm1_1')))
        assert(leader.left)
        assert(leader.refunded)
        assert(member.hasGem)
    end)
end)
