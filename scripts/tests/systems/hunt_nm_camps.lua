describe('Hunt Guild 30-minute camp conversions', function()
    local function readFile(path)
        local file = assert(io.open(path, 'r'))
        local text = file:read('*a')
        file:close()
        return text
    end

    local function assertContains(text, needle, label)
        assert(text:find(needle, 1, true), label .. ' is missing ' .. needle)
    end

    local function assertAbsent(text, needle, label)
        assert(not text:find(needle, 1, true), label .. ' still contains ' .. needle)
    end

    it('keeps Despot as a stationary 30-minute camp', function()
        local despot = readFile('scripts/zones/RuAun_Gardens/mobs/Despot.lua')
        local groundskeeper = readFile('scripts/zones/RuAun_Gardens/mobs/Groundskeeper.lua')

        assertContains(despot, 'x = -0.100', 'Despot')
        assertContains(despot, 'z = -291.000', 'Despot')
        assertAbsent(despot, 'phList', 'Despot')
        assertAbsent(despot, 'IDLE_DESPAWN', 'Despot')
        assertAbsent(groundskeeper, 'phOnDespawn', 'Groundskeeper')
    end)

    it('keeps Steam Cleaner as a stationary 30-minute camp', function()
        local steam = readFile('scripts/zones/VeLugannon_Palace/mobs/Steam_Cleaner.lua')
        local detector = readFile('scripts/zones/VeLugannon_Palace/mobs/Detector.lua')
        local zone = readFile('scripts/zones/VeLugannon_Palace/Zone.lua')

        assertContains(steam, 'x = 317.000', 'Steam Cleaner')
        assertContains(steam, 'z = 361.000', 'Steam Cleaner')
        assertAbsent(steam, '[POP]SteamCleaner', 'Steam Cleaner')
        assertAbsent(detector, 'return steamCleaner', 'Detector')
        assertAbsent(zone, '[POP]SteamCleaner', 'VeLugannon Zone')
    end)

    it('keeps Brigandish Blade as a stationary 30-minute camp', function()
        local blade = readFile('scripts/zones/VeLugannon_Palace/mobs/Brigandish_Blade.lua')
        local qm2 = readFile('scripts/zones/VeLugannon_Palace/npcs/qm2.lua')

        assertContains(blade, 'x = -1.000', 'Brigandish Blade')
        assertContains(blade, 'z = -283.000', 'Brigandish Blade')
        assertAbsent(blade, 'IDLE_DESPAWN', 'Brigandish Blade')
        assertAbsent(qm2, 'popFromQM', 'qm2')
        assertAbsent(qm2, 'confirmTrade', 'qm2')
    end)

    it('makes Jugner Capricornus a visible Hunt camp at the warp', function()
        local capricornus = readFile('scripts/zones/Jugner_Forest/mobs/Capricornus.lua')
        local ids = readFile('scripts/zones/Jugner_Forest/IDs.lua')
        local other = readFile('scripts/zones/East_Ronfaure/mobs/Capricornus.lua')
        local warp = readFile('modules/custom/lua/huntnm_warp_table.lua')

        assertContains(capricornus, 'x = 240.000', 'Jugner Capricornus')
        assertContains(capricornus, 'z = 40.000', 'Jugner Capricornus')
        assertAbsent(capricornus, 'voidwalker.onMobSpawn', 'Jugner Capricornus')
        assertAbsent(capricornus, 'voidwalker.onMobDisengage', 'Jugner Capricornus')
        assertContains(ids, 'CAPRICORNUS', 'Jugner IDs')
        assertAbsent(ids, '17203687, -- Capricornus', 'Jugner VOIDWALKER')
        assertContains(other, 'voidwalker.onMobSpawn', 'East Ronfaure Capricornus')
        assertContains(warp, "key = 'capricornus'", 'hunt warp table')
        assertContains(warp, 'x =  240.000', 'hunt warp table')
    end)
end)
