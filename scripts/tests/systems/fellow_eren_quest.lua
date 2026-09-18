local catalog = require('modules/custom/lua/eren_quest_catalog')
local names = require('modules/custom/lua/fellow_name')
local runtime = require('modules/custom/lua/eren_quest_instance')

local STATS =
{
    'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND',
    'Ferocity', 'Critical', 'Frenzy', 'Onslaught',
    'Sorcery', 'Celerity', 'Warding', 'Vigor',
}

local function mockPlayer(options)
    options = options or {}
    local vars = options.vars or {}
    local fellow = options.fellow == false and nil or {
        getHP = function() return 1000 end,
    }
    local player =
    {
        vars = vars,
        messages = {},
        getCharVar = function(_, key) return vars[key] or 0 end,
        setCharVar = function(_, key, value) vars[key] = value end,
        getGMLevel = function() return options.gm or 0 end,
        getName = function() return options.name or 'QuestTester' end,
        getInstance = function() return options.instance end,
        getPartySize = function() return options.partySize or 1 end,
        getAlliance = function(self) return options.alliance or { self } end,
        getPartyWithTrusts = function() return options.party or {} end,
        getLocalVar = function(_, key) return vars['local:' .. key] or 0 end,
        setLocalVar = function(_, key, value) vars['local:' .. key] = value end,
        createInstance = function(self, id) self.createdInstance = id end,
        timer = function(self, _, callback) self.lastTimer = callback end,
        printToPlayer = function(self, text) self.messages[#self.messages + 1] = text end,
    }
    return player, fellow
end

local function master(player)
    for _, stat in ipairs(STATS) do
        player:setCharVar('Fellow_' .. stat, 100)
    end
end

describe('The Name Beyond the Ferry progression', function()
    local previousFellow
    local activeFellow

    before_each(function()
        previousFellow = xi.fellow
        xi.fellow =
        {
            isMastered = function(player)
                for _, stat in ipairs(STATS) do
                    if player:getCharVar('Fellow_' .. stat) < 100 then
                        return false
                    end
                end
                return true
            end,
            getTrust = function()
                return activeFellow
            end,
        }
    end)

    after_each(function()
        xi.fellow = previousFellow
        activeFellow = nil
    end)

    it('is invisible without GM or tester access and never bypasses mastery', function()
        local player, fellow = mockPlayer()
        activeFellow = fellow
        master(player)

        assert(catalog.hasAccess(player) == false)
        assert(catalog.shouldShowOfficer(player) == false)
        local ok, reason = catalog.canAccept(player)
        assert(ok == false)
        assert(reason == 'access')

        player:setCharVar(catalog.vars.access, 1)
        player:setCharVar('Fellow_Vigor', 99)
        ok, reason = catalog.canAccept(player)
        assert(ok == false)
        assert(reason == 'mastery')
    end)

    it('allows acceptance from a trust-restricted hub once the bond is mastered', function()
        local player = mockPlayer({ fellow = false })
        master(player)
        player:setCharVar(catalog.vars.access, 1)
        activeFellow = nil

        local ok = catalog.canAccept(player)
        assert(ok == true)
    end)

    it('banks all four pilgrimage sites idempotently before opening the trials', function()
        local player, fellow = mockPlayer()
        activeFellow = fellow
        master(player)
        player:setCharVar(catalog.vars.access, 1)

        assert(catalog.accept(player))
        assert(catalog.getStage(player) == catalog.stage.SECOND_SHADOW)
        assert(catalog.beginPilgrimage(player))
        assert(catalog.getStage(player) == catalog.stage.PILGRIMAGE)
        assert(catalog.encounterAvailable(player, 5))
        assert(catalog.creditEncounter(player, 5) == false)
        assert(catalog.siteComplete(player, 'gusgen') == false)

        assert(catalog.creditSite(player, 'gusgen'))
        assert(catalog.creditSite(player, 'gusgen') == false)
        assert(catalog.creditSite(player, 'feiyin'))
        assert(catalog.creditSite(player, 'xarcabard'))
        assert(catalog.getStage(player) == catalog.stage.PILGRIMAGE)
        assert(catalog.creditSite(player, 'echoes'))
        assert(catalog.getStage(player) == catalog.stage.REMEMBRANCES)
        assert(player:getCharVar(catalog.vars.sites) == 0x0F)
    end)

    it('banks each remembrance and advances only after all six', function()
        local player = mockPlayer({ vars = {
            [catalog.vars.access] = 1,
            [catalog.vars.stage] = catalog.stage.REMEMBRANCES,
        } })
        master(player)

        for index, key in ipairs(catalog.memoryOrder) do
            assert(catalog.encounterAvailable(player, catalog.memories[key].encounter))
            assert(catalog.creditMemory(player, key))
            assert(catalog.creditMemory(player, key) == false)
            if index < #catalog.memoryOrder then
                assert(catalog.getStage(player) == catalog.stage.REMEMBRANCES)
            end
        end
        assert(catalog.getStage(player) == catalog.stage.BOND)
        assert(player:getCharVar(catalog.vars.memories) == 0x3F)
    end)

    it('enforces ordered finale transitions', function()
        local player = mockPlayer({ vars = {
            [catalog.vars.access] = 1,
            [catalog.vars.stage] = catalog.stage.BOND,
        } })
        master(player)

        assert(catalog.creditEncounter(player, 30) == false)
        assert(catalog.creditEncounter(player, 20))
        assert(catalog.getStage(player) == catalog.stage.EREN)
        assert(catalog.creditEncounter(player, 30))
        assert(catalog.getStage(player) == catalog.stage.CROSSING)
        assert(catalog.creditEncounter(player, 40))
        assert(catalog.getStage(player) == catalog.stage.DECISION)
    end)

    it('repairs interrupted site and remembrance checkpoint writes', function()
        local player = mockPlayer({ vars = {
            [catalog.vars.access] = 1,
            [catalog.vars.stage] = catalog.stage.PILGRIMAGE,
            [catalog.vars.sites] = 0x0F,
            [catalog.vars.memories] = 0x3F,
        } })
        master(player)

        assert(catalog.reconcile(player) == catalog.stage.BOND)
        assert(catalog.getStage(player) == catalog.stage.BOND)
        assert(catalog.encounterAvailable(player, 20))
    end)

    it('archives the former identity and preserves the mastered build on transformation', function()
        local player, fellow = mockPlayer({ vars = {
            [catalog.vars.access] = 1,
            [catalog.vars.stage] = catalog.stage.DECISION,
            Fellow_Level = 120,
            Fellow_Role = 6,
        } })
        activeFellow = fellow
        master(player)
        names.pack(player, 'Beatrice')

        assert(catalog.transform(player))
        assert(catalog.isUnlocked(player))
        assert(catalog.getStage(player) == catalog.stage.COMPLETE)
        assert(names.read(player) == 'Eren')
        assert(catalog.formerName(player) == 'Beatrice')
        assert(player:getCharVar('Fellow_Level') == 120)
        assert(player:getCharVar('Fellow_Role') == 6)
        for _, stat in ipairs(STATS) do
            assert(player:getCharVar('Fellow_' .. stat) == 100)
        end
        assert(catalog.transform(player) == false)
    end)

    it('archives preset names through the shared live-name resolver', function()
        local player = mockPlayer({ vars = {
            [catalog.vars.access] = 1,
            [catalog.vars.stage] = catalog.stage.DECISION,
        } })
        master(player)
        xi.fellow.resolveName = function() return 'Nanako' end

        assert(catalog.transform(player))
        assert(catalog.formerName(player) == 'Nanako')
    end)

    it('finishes an interrupted transformation monotonically', function()
        local player = mockPlayer({ vars = {
            [catalog.vars.access] = 1,
            [catalog.vars.stage] = catalog.stage.DECISION,
            [catalog.vars.unlocked] = 1,
        } })
        master(player)
        names.pack(player, 'Beatrice')

        assert(catalog.reconcile(player) == catalog.stage.COMPLETE)
        assert(catalog.isUnlocked(player))
        assert(names.read(player) == 'Eren')
        assert(catalog.formerName(player) == 'Beatrice')
    end)

    it('marks a legacy name without granting the unlock', function()
        local player = mockPlayer()
        names.pack(player, 'Eren')

        assert(catalog.migrateLegacy(player, true))
        assert(player:getCharVar(catalog.vars.legacy) == 1)
        assert(player:getCharVar(catalog.vars.legacyNotice) == 1)
        assert(catalog.isUnlocked(player) == false)
    end)

    it('opens an encounter from a trust-restricted source zone and restores a forced role on abort', function()
        local player = mockPlayer({ vars = {
            [catalog.vars.access] = 1,
            [catalog.vars.stage] = catalog.stage.REMEMBRANCES,
            Fellow_Role = 6,
        } })
        master(player)
        activeFellow = nil

        local ok = runtime.start(player, 10)
        assert(ok)
        assert(player.createdInstance == catalog.instanceId)
        assert(player:getCharVar(catalog.vars.pending) == catalog.instanceId)
        assert(player:getCharVar(catalog.vars.savedRole) == 7)
        assert(player:getCharVar('Fellow_Role') == catalog.roleIndex.vanguard)

        assert(runtime.abort(player))
        assert(player:getCharVar(catalog.vars.pending) == 0)
        assert(player:getCharVar(catalog.vars.encounter) == 0)
        assert(player:getCharVar('Fellow_Role') == 6)
    end)
end)
