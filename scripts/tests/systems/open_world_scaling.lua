local catalog = require('modules/custom/lua/open_world_scaling_catalog')
require('modules/custom/lua/OpenWorldScaling')

describe('Legendary open world scaling', function()
    local function makeMob(options)
        options = options or {}

        local mods      = options.mods or {}
        local mobMods   = options.mobMods or {}
        local localVars = options.localVars or {}
        local mobTypes  = options.mobTypes or {}
        local maxHP     = options.maxHP or 10000
        local hp        = maxHP

        local mob =
        {
            getObjType = function()
                return options.objType or xi.objType.MOB
            end,

            getMainLvl = function()
                return options.level or 132
            end,

            getZoneID = function()
                return options.zoneId or xi.zone.RAKAZNAR_INNER_COURT
            end,

            getID = function()
                return options.mobId or 0x110
            end,

            getSpecies = function()
                return options.speciesId or 409
            end,

            getPool = function()
                return options.poolId or 4828
            end,

            getName = function()
                return options.name or 'Apex_Poxhound'
            end,

            isNM = function()
                return options.isNM == true
            end,

            isMobType = function(_, mobType)
                return mobTypes[mobType] == true
            end,

            getInstance = function()
                return options.instance
            end,

            getBattlefield = function()
                return options.battlefield
            end,

            getMaster = function()
                return options.master
            end,

            isInDynamis = function()
                return options.inDynamis == true
            end,

            getMobMod = function(_, mobMod)
                return mobMods[mobMod] or 0
            end,

            getLocalVar = function(_, key)
                return localVars[key] or 0
            end,

            getMaxHP = function()
                return maxHP
            end,

            setMaxHP = function(_, value)
                maxHP = value
            end,

            setHP = function(_, value)
                hp = value
            end,

            getHP = function()
                return hp
            end,

            getMod = function(_, modId)
                return mods[modId] or 0
            end,

            setMod = function(_, modId, value)
                mods[modId] = value
            end,
        }

        return mob
    end

    it('resolves every configured level band', function()
        local expected =
        {
            [91]  = 60000,
            [100] = 100000,
            [110] = 180000,
            [120] = 320000,
            [130] = 450000,
            [135] = 600000,
        }

        for level, hpFloor in pairs(expected) do
            local profile = xi.openWorldScaling.getLevelProfile(level)
            assert(profile and profile.hpFloor == hpFloor,
                string.format('Expected level %d HP floor %d', level, hpFloor))
        end
    end)

    it('applies the Inner RaKaznar Apex Poxhound override', function()
        local mob     = makeMob()
        local profile = xi.openWorldScaling.resolveProfile(mob)

        assert(profile.hpFloor == 600000,
            string.format('Expected Apex Poxhound HP floor 600000, got %d', profile.hpFloor))
    end)

    it('raises weak mobs to profile floors without lowering stronger values', function()
        local weakMob = makeMob({ poolId = 1, maxHP = 10000 })
        local applied = xi.openWorldScaling.apply(weakMob)

        assert(applied)
        assert(weakMob:getMaxHP() == 450000)
        assert(weakMob:getHP() == 450000)
        assert(weakMob:getMod(xi.mod.ATT) == 1800)
        assert(weakMob:getMod(xi.mod.DEF) == 1300)

        local strongMob = makeMob({
            poolId = 1,
            maxHP  = 900000,
            mods   =
            {
                [xi.mod.ATT] = 3000,
                [xi.mod.DEF] = 2500,
            },
        })

        xi.openWorldScaling.apply(strongMob)
        assert(strongMob:getMaxHP() == 900000)
        assert(strongMob:getMod(xi.mod.ATT) == 3000)
        assert(strongMob:getMod(xi.mod.DEF) == 2500)
    end)

    it('is idempotent when the hook is called more than once', function()
        local mob = makeMob({ poolId = 1 })

        xi.openWorldScaling.apply(mob)
        local firstHP  = mob:getMaxHP()
        local firstAtt = mob:getMod(xi.mod.ATT)
        xi.openWorldScaling.apply(mob)

        assert(mob:getMaxHP() == firstHP)
        assert(mob:getMod(xi.mod.ATT) == firstAtt)
    end)

    it('rejects mobs below level 91 and outside allowlisted zones', function()
        local eligible, reason = xi.openWorldScaling.checkEligibility(makeMob({ level = 90 }))
        assert(not eligible and reason == 'below-min-level')

        eligible, reason = xi.openWorldScaling.checkEligibility(makeMob({ zoneId = xi.zone.WEST_RONFAURE }))
        assert(not eligible and reason == 'zone-not-allowlisted')
    end)

    it('rejects NMs, special mob types, encounters, ownership and dynamic entities', function()
        local cases =
        {
            makeMob({ isNM = true }),
            makeMob({ mobTypes = { [xi.mobType.EVENT] = true } }),
            makeMob({ mobTypes = { [xi.mobType.BATTLEFIELD] = true } }),
            makeMob({ instance = {} }),
            makeMob({ battlefield = {} }),
            makeMob({ master = {} }),
            makeMob({ inDynamis = true }),
            makeMob({ mobId = 0x700 }),
        }

        for _, mob in ipairs(cases) do
            local eligible = xi.openWorldScaling.checkEligibility(mob)
            assert(not eligible, 'Expected special or encounter mob to be excluded')
        end
    end)

    it('honors runtime exclusion markers used by custom content', function()
        local cases =
        {
            makeMob({ mobMods = { [xi.mobMod.CHECK_AS_NM] = 1 } }),
            makeMob({ mobMods = { [xi.mobMod.NO_CAPACITY_POINTS] = 1 } }),
            makeMob({ mobMods = { [xi.mobMod.NO_DROPS] = 1 } }),
            makeMob({ localVars = { OWS_EXCLUDE = 1 } }),
        }

        for _, mob in ipairs(cases) do
            local eligible = xi.openWorldScaling.checkEligibility(mob)
            assert(not eligible, 'Expected custom-content marker to exclude mob')
        end
    end)

    it('uses one replaceable global hook without stacking listeners', function()
        local previousHook = xi.mob.openWorldScalingHook
        package.loaded['modules/custom/lua/OpenWorldScaling'] = nil
        require('modules/custom/lua/OpenWorldScaling')

        assert(type(xi.mob.openWorldScalingHook) == 'function')
        assert(xi.mob.openWorldScalingHook ~= previousHook)
        assert(catalog.enabled)
    end)
end)
