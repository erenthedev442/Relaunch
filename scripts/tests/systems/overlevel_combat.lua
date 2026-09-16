local combat = require('modules/custom/lua/overlevel_combat')
local levelingHpCap = require('modules/custom/lua/leveling_hp_cap')

local function player(vars)
    vars = vars or {}
    return
    {
        getCharVar = function(_, key)
            return vars[key] or 0
        end,
        getMainJob = function()
            return vars.job or 1
        end,
        getMainLvl = function()
            return vars.level or 1
        end,
        hasStatusEffect = function(_, effectId)
            local locked = vars.effects or {}
            return locked[effectId] == true
        end,
    }
end

local function mobAt(level)
    return
    {
        isMob = function()
            return true
        end,
        getMainLvl = function()
            return level
        end,
        getMaxHP = function()
            return 30000
        end,
        getHP = function()
            return 30000
        end,
    }
end

describe('Overlevel combat while leveling', function()
    it('lets a fresh character take +15 and not +16', function()
        assert(combat.allowedGap(player()) == 15)
        assert(combat.incomingMult(15, 15) == 1)
        assert(combat.incomingMult(16, 15) > 1)
    end)

    it('stretches the free band to 20 for deep prestige/rebirth/paragon', function()
        local advanced = player(
        {
            job = 1,
            Prestige_Ascensions_Total = 20,
            Prestige_Level_1 = 40,
            Rebirth_Count_1 = 50,
            Paragon_Level = 20,
        })
        assert(combat.allowedGap(advanced) == 20)
        assert(combat.incomingMult(20, 20) == 1)
        assert(combat.incomingMult(21, 20) > 4)
    end)

    it('is lethal at 30 levels regardless of progression', function()
        assert(combat.incomingMult(30, 15) == 100)
        assert(combat.incomingMult(104, 20) == 100)
        assert(combat.outgoingMult(30) == 0.01)
        assert(combat.pulseFraction(30, 20) == 0)
        assert(combat.shouldPierceIncoming(29) == false)
        assert(combat.shouldPierceIncoming(30) == true)
        assert(combat.pierceIncoming(105, 29, 2500, 40) == 2500)
        assert(combat.pierceIncoming(105, 99, 2500, 40) == 40)
        assert(combat.pierceIncoming(44, 29, 2500, 40) == 40)
        assert(combat.pierceIncoming(105, 29, 2500, 0) == 0)
    end)

    it('applies incoming pierce from a mob onto a player or their pet', function()
        local foe = mobAt(105)
        local pc = player({ level = 29 })
        pc.isPC = function()
            return true
        end
        pc.isMob = function()
            return false
        end
        pc.getMaxHP = function()
            return 1800
        end

        assert(combat.applyIncomingPierce(foe, pc, 40) == 1800)

        local pet =
        {
            isPC = function()
                return false
            end,
            isMob = function()
                return false
            end,
            getMaster = function()
                return pc
            end,
            getMaxHP = function()
                return 600
            end,
        }
        assert(combat.applyIncomingPierce(foe, pet, 12) == 600)
        assert(combat.applyIncomingPierce(pc, foe, 40) == 40)
    end)

    it('crushes outgoing past +20 and leaves +20 alone', function()
        local mob = mobAt(105)
        assert(combat.scaleOutgoing(85, mob, 10000) == 10000)
        assert(combat.scaleOutgoing(75, mob, 10000) < 10000)
        assert(combat.scaleOutgoing(1, mob, 10000) == 100)
        assert(combat.scaleOutgoing(99, mob, 10000) == 10000)
    end)

    it('caps any hit at 10-100 against a mob 40+ levels higher', function()
        local mob = mobAt(105)
        assert(combat.scaleOutgoing(65, mob, 50000) == 100)
        assert(combat.scaleOutgoing(65, mob, 3) == 10)
        assert(combat.clampOutgoing(40, 999999) == 100)
        assert(combat.clampOutgoing(39, 50000) == 500)
    end)

    it('ignores prestige stretch while Level Sync is active', function()
        local synced = player(
        {
            job = 1,
            level = 65,
            Prestige_Ascensions_Total = 20,
            Prestige_Level_1 = 40,
            Rebirth_Count_1 = 50,
            Paragon_Level = 20,
            effects = { [269] = true },
        })
        assert(combat.isLevelLocked(synced) == true)
        assert(combat.combatLevel(synced) == 65)
        assert(combat.allowedGap(synced) == 15)
        assert(combat.incomingMult(20, combat.allowedGap(synced)) > 1)
    end)

    it('caps UDMG at the int16 ceiling', function()
        assert(combat.udmgFromMult(1) == 0)
        assert(combat.udmgFromMult(4.276) <= combat.UDMG_CAP)
        assert(combat.udmgFromMult(100) == combat.UDMG_CAP)
    end)

    it('runs through the leveling HP cap so a padded 1 cannot chunk a 105', function()
        assert(levelingHpCap.apply(1, mobAt(105), 20000) == 100)
    end)
end)
