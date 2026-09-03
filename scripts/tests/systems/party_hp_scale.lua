local scale = require('modules/custom/lua/party_hp_scale')

describe('Party HP scale', function()
    local function makeMob(maxHp)
        local vars = {}
        local hp = maxHp
        local listeners = {}
        return
        {
            _hp = function()
                return hp
            end,
            isAlive = function()
                return hp > 0
            end,
            isMob = function()
                return true
            end,
            isPet = function()
                return false
            end,
            getMaster = function()
                return nil
            end,
            getMaxHP = function()
                return maxHp
            end,
            getHP = function()
                return hp
            end,
            setMaxHP = function(_, value)
                maxHp = value
            end,
            setHP = function(_, value)
                hp = value
            end,
            getLocalVar = function(_, name)
                return vars[name] or 0
            end,
            setLocalVar = function(_, name, value)
                vars[name] = value
            end,
            addListener = function(_, event, id, fn)
                listeners[id] = { event = event, fn = fn }
            end,
            getTarget = function()
                return nil
            end,
        }
    end

    local function makePC(zoneId, alliance)
        local pc =
        {
            getObjType = function()
                return xi.objType.PC
            end,
            getZoneID = function()
                return zoneId or 1
            end,
        }
        pc.getAlliance = function()
            return alliance or { pc }
        end
        return pc
    end

    it('uses the 1 / 1.7 / 2.4 / 3.2 / 4.1 / 5.0 curve and clamps', function()
        assert(scale.multiplier(1) == 1.0)
        assert(scale.multiplier(2) == 1.7)
        assert(scale.multiplier(3) == 2.4)
        assert(scale.multiplier(4) == 3.2)
        assert(scale.multiplier(5) == 4.1)
        assert(scale.multiplier(6) == 5.0)
        assert(scale.multiplier(0) == 1.0)
        assert(scale.multiplier(99) == 5.0)
    end)

    it('leaves unmarked mobs and player pets alone', function()
        local mob = makeMob(10000)
        assert(scale.apply(mob, 6) == false)
        assert(mob:getMaxHP() == 10000)

        local pet = makeMob(10000)
        pet.isPet = function()
            return true
        end
        scale.prepare(pet)
        assert(scale.apply(pet, 6) == false)
    end)

    it('applies once from catalog HP and grows without shrinking', function()
        local mob = makeMob(10000)
        scale.prepare(mob)
        assert(scale.apply(mob, 1) == true)
        assert(mob:getMaxHP() == 10000)

        assert(scale.apply(mob, 3) == true)
        assert(mob:getMaxHP() == 24000)
        mob:setHP(12000)

        assert(scale.apply(mob, 6) == true)
        assert(mob:getMaxHP() == 50000)
        assert(mob:getHP() == 25000)

        assert(scale.apply(mob, 2) == false)
        assert(mob:getMaxHP() == 50000)
    end)

    it('counts alliance PCs in zone and ignores trusts', function()
        local p1 = makePC(44)
        local p2 = makePC(44)
        local trust =
        {
            getObjType = function()
                return xi.objType.TRUST
            end,
            getZoneID = function()
                return 44
            end,
        }
        local otherZone = makePC(50)
        p1.getAlliance = function()
            return { p1, p2, trust, otherZone }
        end

        assert(scale.countFromPlayer(p1) == 2)
    end)

    it('counts instance characters and caps at 6', function()
        local chars = {}
        for i = 1, 8 do
            chars[i] =
            {
                getObjType = function()
                    return xi.objType.PC
                end,
            }
        end
        chars[9] =
        {
            getObjType = function()
                return xi.objType.TRUST
            end,
        }

        local instance =
        {
            getChars = function()
                return chars
            end,
        }

        assert(scale.countInstancePCs(instance) == 6)
    end)

    it('re-snapshots after a later setMaxHP and reports catalog-relative current HP', function()
        local p1 = makePC(1)
        local p2 = makePC(1)
        local p3 = makePC(1)
        p1.getAlliance = function()
            return { p1, p2, p3 }
        end

        local mob = makeMob(10000)
        scale.afterCustomHp(mob, p1)
        assert(mob:getMaxHP() == 24000)
        mob:setHP(12000)
        assert(scale.catalogCurrentHp(mob) == 5000)

        mob:setMaxHP(20000)
        mob:setHP(20000)
        scale.afterCustomHp(mob, p1)
        assert(mob:getMaxHP() == 48000)
        assert(mob:getHP() == 48000)
    end)

    it('reverses species HPP so catalog HP is the displayed bar and spawn is full', function()
        local function makeHppMob(hpp)
            local base = 0
            local current = 0
            local factor = 1 + hpp / 100
            return
            {
                isAlive = function()
                    return current > 0
                end,
                isMob = function()
                    return true
                end,
                isPet = function()
                    return false
                end,
                getMaster = function()
                    return nil
                end,
                getMaxHP = function()
                    return math.floor(base * factor)
                end,
                getHP = function()
                    return current
                end,
                setMaxHP = function(_, value)
                    base = value
                end,
                setHP = function(_, value)
                    local max = math.floor(base * factor)
                    current = math.min(value, max)
                end,
            }
        end

        local manticore = makeHppMob(50)
        scale.setCatalogHp(manticore, 50000)
        assert(math.abs(manticore:getMaxHP() - 50000) <= 1)
        assert(manticore:getHP() == manticore:getMaxHP())

        -- Naive setMaxHP(catalog) + setHP(catalog) is the live spawn bug:
        -- displayed max becomes 1.5x and current stays at two-thirds.
        local naive = makeHppMob(50)
        naive:setMaxHP(50000)
        naive:setHP(50000)
        assert(naive:getMaxHP() == 75000)
        assert(naive:getHP() == 50000)
    end)

    it('does not apply while an instance still has no PCs attached', function()
        local mob = makeMob(10000)
        local instance =
        {
            getChars = function()
                return {}
            end,
        }

        scale.afterCustomHp(mob, instance)
        assert(mob:getMaxHP() == 10000)
        assert(mob:getLocalVar('PartyHpScale') == 1)
        assert(mob:getLocalVar('PartyHpScalePCs') == 0)
    end)
end)
