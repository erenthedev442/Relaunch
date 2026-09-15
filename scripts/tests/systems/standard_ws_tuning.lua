local catalog = require('modules/custom/lua/standard_ws_tuning_catalog')
require('modules/custom/lua/StandardWeaponskillTuning')

describe('Level-scaled ordinary weaponskill tuning', function()
    local function makePlayer(equipment, level, spentJobPoints, mainJob)
        local mods      = {}
        local localVars = {}
        local player    = { equipment = equipment or {} }

        player.isPC = function()
            return true
        end

        player.getEquipID = function(self, slot)
            local equipped = self.equipment[slot]
            return type(equipped) == 'table' and equipped.id or equipped or 0
        end

        player.getEquippedItem = function(self, slot)
            local equipped = self.equipment[slot]
            if not equipped then
                return nil
            end

            local details = type(equipped) == 'table' and equipped or
                { id = equipped, ilvl = 119, reqLvl = 99 }
            return
            {
                getILvl = function()
                    return details.ilvl or 0
                end,
                getReqLvl = function()
                    return details.reqLvl or 0
                end,
            }
        end

        player.getMainLvl = function()
            return level or 99
        end

        player.getMainJob = function()
            return mainJob or xi.job.WAR
        end

        player.getSpentJobPoints = function()
            return spentJobPoints or 0
        end

        player.getMod = function(_, modId)
            return mods[modId] or 0
        end

        player.addMod = function(_, modId, amount)
            mods[modId] = (mods[modId] or 0) + amount
        end

        player.setMod = function(_, modId, amount)
            mods[modId] = amount
        end

        player.getLocalVar = function(_, name)
            return localVars[name] or 0
        end

        player.setLocalVar = function(_, name, value)
            localVars[name] = value
        end

        return player
    end

    local function makeTarget(level, maxHp)
        return
        {
            isMob = function()
                return true
            end,
            getMainLvl = function()
                return level
            end,
            getMaxHP = function()
                return maxHp
            end,
        }
    end

    it('scales its additive share with target HP and level gap', function()
        assert(catalog.getDamageBonus(99, 155, 120000) == 36000)
        assert(catalog.getDamageBonus(1, 1, 100) == 30)
        assert(catalog.getDamageBonus(50, 58, 10000) == 2100)
        assert(catalog.getDamageBonus(50, 75, 120000) == 1080)
    end)

    it('uses mastery-scaled multipliers at level 99', function()
        local target = makeTarget(155, 120000)
        local weapon = { [xi.slot.MAIN] = { id = 1, ilvl = 119, reqLvl = 99 } }
        assert(catalog.DAMAGE_CAP == 79999)
        assert(catalog.getWeaponskillMultiplier(makePlayer(weapon, 99, 0), target) == 8)
        assert(catalog.getWeaponskillMultiplier(makePlayer(weapon, 99, 1050), target) == 10.5)
        assert(catalog.getWeaponskillMultiplier(makePlayer(weapon, 99, 2100), target) == 13)
        assert(catalog.getPetDamageMultiplier(makePlayer({}, 99, 0), target) == 7)
        assert(catalog.getPetDamageMultiplier(makePlayer({}, 99, 2100), target) == 11)
        assert(catalog.applyMultiplier(1500, 11, 79999) == 16500)
        assert(catalog.applyMultiplier(8000, 11, 79999) == 79999)
        assert(catalog.applyMultiplier(1500, 13, 79999) == 19500)
        assert(catalog.applyMultiplier(6150, 13, 79999) == 79950)
        assert(catalog.applyMultiplier(10000, 13, 79999) == 79999)
    end)

    it('uses companion-only caps from the master main-hand tier', function()
        assert(catalog.DAMAGE_CAP == 79999)
        assert(catalog.REMA_PRE_III_DAMAGE_CAP == 99999)
        assert(catalog.REMA_PRE_III_NATIVE_WS_CAP == 149999)
        assert(catalog.REMA_OFF_NATIVE_DAMAGE_CAP == 500000)
        assert(catalog.ODYSSEY_FTP_SCALE == 1.35)
        assert(catalog.ODYSSEY_MULTIPLIER_BONUS == 1.15)
        assert(catalog.PET_AMBU_DAMAGE_CAP == 99999)
        assert(catalog.PET_REMA_DAMAGE_CAP == 999999)
        assert(catalog.PET_PRIME_DAMAGE_CAP == 1499999)
        assert(catalog.COMPANION_PLAYER_REMA_CAP == 249999)
        assert(catalog.COMPANION_PLAYER_PRIME_CAP == 499999)
        assert(catalog.PET_REMA_MULTIPLIER_BONUS == 2.85)
        assert(catalog.PET_PRIME_MULTIPLIER_BONUS == 4.25)

        local standard = makePlayer({ [xi.slot.MAIN] = 1 }, 99)
        local ambuscade = makePlayer({ [xi.slot.MAIN] = 21621 }, 99) -- Naegling
        local pupMythic119I = makePlayer({ [xi.slot.MAIN] = 20484 }, 99) -- Kenkonken 119 I
        local pupMythic = makePlayer({ [xi.slot.MAIN] = 20511 }, 99) -- Kenkonken
        local pupPrime = makePlayer(
            { [xi.slot.MAIN] = 21535 }, 99, 2100, xi.job.PUP) -- Varga Purnikawa
        local bstPrime = makePlayer(
            { [xi.slot.MAIN] = 21730 }, 99, 2100, xi.job.BST) -- Spalirisos
        local smnPrime = makePlayer(
            { [xi.slot.MAIN] = 22106 }, 99, 2100, xi.job.SMN) -- Opashoro
        local mismatchedPupPrime = makePlayer(
            { [xi.slot.MAIN] = 22106 }, 99, 2100, xi.job.PUP) -- SMN's Opashoro
        local drgPrime = makePlayer(
            { [xi.slot.MAIN] = 21891 }, 99, 2100, xi.job.DRG) -- Gae Buide

        assert(catalog.getPetDamageCap(standard) == catalog.DAMAGE_CAP)
        assert(catalog.getPetDamageCap(ambuscade) == catalog.PET_AMBU_DAMAGE_CAP)
        assert(catalog.getPetDamageCap(pupMythic119I) == catalog.PET_AMBU_DAMAGE_CAP)
        assert(catalog.getRemaPathInfo(20484).final == false)
        assert(catalog.getRemaPathInfo(20511).final == true)
        assert(catalog.getPetDamageCap(pupMythic) == catalog.PET_REMA_DAMAGE_CAP)
        assert(catalog.getPetDamageCap(pupPrime) == catalog.PET_PRIME_DAMAGE_CAP)
        assert(catalog.getPetDamageCap(bstPrime) == catalog.PET_PRIME_DAMAGE_CAP)
        assert(catalog.getPetDamageCap(smnPrime) == catalog.PET_PRIME_DAMAGE_CAP)
        assert(catalog.getPetDamageMultiplier(pupPrime, makeTarget(155, 120000)) == 46.75)
        assert(catalog.getPetDamageCap(mismatchedPupPrime) == catalog.DAMAGE_CAP)
        assert(catalog.getPetDamageMultiplier(
            mismatchedPupPrime, makeTarget(155, 120000)) == 11)
        assert(catalog.getPetDamageCap(drgPrime) == catalog.PET_REMA_DAMAGE_CAP)
        assert(catalog.getPetDamageMultiplier(drgPrime, makeTarget(155, 120000)) == 31.35)
        assert(catalog.applyMultiplier(200000, 1, catalog.getPetDamageCap(pupMythic)) == 200000)
        assert(catalog.getPetAoEDamageCap(standard) == catalog.DAMAGE_CAP)
        assert(catalog.getPetAoEDamageCap(ambuscade) == catalog.PET_AMBU_DAMAGE_CAP)
        assert(catalog.getPetAoEDamageCap(pupMythic119I) == catalog.PET_AMBU_DAMAGE_CAP)
        assert(catalog.getPetAoEDamageCap(pupMythic) == 149999)
        assert(catalog.getPetAoEDamageCap(pupPrime) == 199999)
        assert(catalog.getPetAoEDamageCap(bstPrime) == 199999)
        assert(catalog.getPetAoEDamageCap(smnPrime) == 199999)
        assert(catalog.getPetAoEDamageCap(mismatchedPupPrime) == catalog.DAMAGE_CAP)
        assert(catalog.getPetAoEDamageCap(drgPrime) == 199999)
        assert(catalog.getPetAoEDamageCap(makePlayer(
            { [xi.slot.MAIN] = { id = 1, ilvl = 1, reqLvl = 1 } }, 99)) ==
            catalog.NON_ITEM_LEVEL_119_CAP)
        assert(catalog.getPlayerSplashDamageCap(makePlayer(
            { [xi.slot.MAIN] = 20695 }, 99)) == 149999) -- Sequence
        assert(catalog.getPlayerSplashDamageCap(makePlayer(
            { [xi.slot.MAIN] = 20509 }, 99)) == 149999) -- Spharai
        assert(catalog.getPlayerSplashDamageCap(makePlayer(
            { [xi.slot.MAIN] = 20515 }, 99)) == 149999) -- Godhands
        assert(catalog.getPlayerSplashDamageCap(makePlayer(
            { [xi.slot.MAIN] = 20512 }, 99)) == 149999) -- Verethragna
        assert(catalog.getPlayerSplashDamageCap(makePlayer(
            { [xi.slot.MAIN] = 20843 }, 99)) == 149999) -- Chango
        assert(catalog.getPlayerSplashDamageCap(makePlayer(
            { [xi.slot.MAIN] = 21637 }, 99)) == 149999) -- Sakpata's Sword
        assert(catalog.getPlayerSplashDamageCap(makePlayer(
            { [xi.slot.MAIN] = 22100 }, 99)) == 149999) -- Mpaca's Staff
        assert(catalog.ODYSSEY_AOE_DAMAGE_CAP == 149999)
    end)

    it('refreshes a live pet cap from the currently equipped main hand', function()
        local player = makePlayer(
            { [xi.slot.MAIN] = 21535 }, 99, 2100, xi.job.PUP)
        local localVars = {}
        local pet =
        {
            setLocalVar = function(_, name, value)
                localVars[name] = value
            end,
        }

        assert(catalog.setPetDamageCap(pet, player) == catalog.PET_PRIME_DAMAGE_CAP)
        assert(localVars[catalog.PET_DAMAGE_CAP_LOCAL_VAR] == catalog.PET_PRIME_DAMAGE_CAP)

        player.equipment[xi.slot.MAIN] = 1
        assert(catalog.setPetDamageCap(pet, player) == catalog.DAMAGE_CAP)
        assert(localVars[catalog.PET_DAMAGE_CAP_LOCAL_VAR] == catalog.DAMAGE_CAP)
    end)

    it('keeps the full level-99 multiplier on low-HP farming targets', function()
        local player = makePlayer(
            { [xi.slot.MAIN] = { id = 1, ilvl = 119, reqLvl = 99 } }, 99, 2100)

        assert(catalog.getWeaponskillMultiplier(
            player, makeTarget(76, 8000), xi.slot.MAIN) == 13)
    end)

    it('scales custom bonuses by weapon level and caps non-item-level weapons', function()
        local onionSword = makePlayer(
            { [xi.slot.MAIN] = { id = 2, ilvl = 0, reqLvl = 1 } }, 99, 0)
        local level99Sword = makePlayer(
            { [xi.slot.MAIN] = { id = 3, ilvl = 0, reqLvl = 99 } }, 99, 0)
        local itemLevel119Sword = makePlayer(
            { [xi.slot.MAIN] = { id = 4, ilvl = 119, reqLvl = 99 } }, 99, 0)
        local target = makeTarget(155, 120000)

        assert(math.abs(catalog.getWeaponskillMultiplier(
            onionSword, target, xi.slot.MAIN) - 1.070707) < 0.000001)
        assert(catalog.getWeaponskillMultiplier(
            level99Sword, target, xi.slot.MAIN) == 8)
        assert(catalog.getWeaponskillCap(onionSword, xi.slot.MAIN) == 40000)
        assert(catalog.getWeaponskillCap(level99Sword, xi.slot.MAIN) == 40000)
        assert(catalog.getWeaponskillCap(itemLevel119Sword, xi.slot.MAIN) == 79999)
        assert(catalog.ODYSSEY_DAMAGE_CAP == 349999)
        local sakpata = makePlayer({ [xi.slot.MAIN] = 21637 }, 99) -- Sakpata's Sword
        local gletiXbow = makePlayer({ [xi.slot.RANGED] = 22150 }, 99)
        assert(catalog.isOdysseyWeapon(21637) == true)
        assert(catalog.getWeaponskillCap(sakpata, xi.slot.MAIN) == 349999)
        assert(catalog.getWeaponskillCap(gletiXbow, xi.slot.RANGED) == 349999)
        assert(catalog.getWeaponskillCap(itemLevel119Sword, xi.slot.MAIN) == 79999)
    end)

    it('adds a progressive accuracy penalty only beyond the grace band', function()
        assert(catalog.getAccuracyPenalty(50, 53) == 0)
        assert(catalog.getAccuracyPenalty(50, 58) == 40)
        assert(catalog.getAccuracyPenalty(50, 75) == 176)
        assert(catalog.getAccuracyPenalty(99, 155) == 0)
    end)

    it('exposes ordinary WS multiplier, cap, and underlevel accuracy synchronously', function()
        local player = makePlayer(
            { [xi.slot.MAIN] = { id = 20819, ilvl = 0, reqLvl = 50 } }, 50)
        local target = makeTarget(58, 10000)

        xi.standardWsTuning.withStandardEffects(
            player, target, xi.weaponskill.RAGING_RUSH, xi.slot.MAIN,
            {}, false,
            function()
                assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 2250)
                assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 40000)
                assert(player:getMod(xi.mod.WSACC) == -40)
            end)

        assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 0)
        assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 0)
        assert(player:getMod(xi.mod.WSACC) == 0)
    end)

    it('raises ordinary AoE caps for final main-hand Ambuscade, REMA, and Prime weapons', function()
        local target = makeTarget(150, 1000000)
        local cases =
        {
            { item = 21621, st =  99999, aoe =  99999, ws = xi.weaponskill.CIRCLE_BLADE }, -- Naegling
            { item = 20695, st = 500000, aoe = 149999, ws = xi.weaponskill.CIRCLE_BLADE }, -- Sequence
            { item = 20509, st = 500000, aoe = 149999, ws = xi.weaponskill.SPINNING_ATTACK }, -- Spharai
            { item = 20515, st = 500000, aoe = 149999, ws = xi.weaponskill.SPINNING_ATTACK }, -- Godhands
            { item = 20512, st = 500000, aoe = 149999, ws = xi.weaponskill.SPINNING_ATTACK }, -- Verethragna
            { item = 20511, st = 500000, aoe = 149999, ws = xi.weaponskill.SPINNING_ATTACK }, -- Kenkonken
            { item = 20843, st = 500000, aoe = 149999, ws = xi.weaponskill.FELL_CLEAVE }, -- Chango
            { item = 21646, st = 199999, aoe = 199999, ws = xi.weaponskill.CIRCLE_BLADE }, -- Caliburnus
            { item = 21637, st = 349999, aoe = 149999, ws = xi.weaponskill.CIRCLE_BLADE }, -- Sakpata's Sword
        }

        for _, case in ipairs(cases) do
            local player = makePlayer({ [xi.slot.MAIN] = case.item }, 99)
            player:setLocalVar('AoEWsDamageCap', 79999)

            xi.standardWsTuning.withStandardEffects(
                player, target, case.ws, xi.slot.MAIN,
                {}, false,
                function()
                    assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == case.st)
                    assert(player:getLocalVar('AoEWsDamageCap') == case.aoe)
                end)

            assert(player:getLocalVar('AoEWsDamageCap') == 79999)
        end
    end)

    it('keeps the ordinary curve on REMA and Prime native WS unless already tuned', function()
        local target = makeTarget(150, 1000000)
        local apoc = makePlayer({ [xi.slot.MAIN] = 21808 }, 99)

        -- 119 III Catastrophe must not fall below Entropy on the same weapon
        -- when the REMA fTP wrapper does not run (live 2026-09-07 report).
        xi.standardWsTuning.withStandardEffects(
            apoc, target, xi.weaponskill.CATASTROPHE, xi.slot.MAIN, {}, false,
            function()
                assert(apoc:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 8000)
                assert(apoc:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 500000)
            end)

        apoc:setLocalVar('RemaWsTuned', 1)
        xi.standardWsTuning.withStandardEffects(
            apoc, target, xi.weaponskill.CATASTROPHE, xi.slot.MAIN, {}, false,
            function()
                assert(apoc:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 0)
                assert(apoc:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 0)
            end)

        local prime = makePlayer({ [xi.slot.MAIN] = 21646 }, 99)
        xi.standardWsTuning.withStandardEffects(
            prime, target, xi.weaponskill.IMPERATOR, xi.slot.MAIN, {}, false,
            function()
                assert(prime:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 8000)
            end)

        prime:setLocalVar('PrimeWsTuned', 1)
        xi.standardWsTuning.withStandardEffects(
            prime, target, xi.weaponskill.IMPERATOR, xi.slot.MAIN, {}, false,
            function()
                assert(prime:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 0)
            end)
    end)

    it('keeps standard progression on final Ambuscade linked WSs with a 99,999 ceiling', function()
        local player = makePlayer({ [xi.slot.MAIN] = 21621 }, 99)
        local target = makeTarget(150, 1000000)

        xi.standardWsTuning.withStandardEffects(
            player, target, xi.weaponskill.SAVAGE_BLADE, xi.slot.MAIN,
            {}, false,
            function()
                assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 8000)
                assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 99999)
            end)
    end)

    it('caps Odyssey weaponskills at 349,999 with a small fTP and curve bump', function()
        local player = makePlayer({ [xi.slot.MAIN] = 21637 }, 99) -- Sakpata's Sword
        local target = makeTarget(150, 1000000)
        local native = { ftpMod = { 4.0, 10.25, 13.75 } }

        assert(math.abs(catalog.getWeaponskillMultiplier(player, target, xi.slot.MAIN) - 9.2) < 0.000001)
        local tuned = catalog.applyOdysseyFtp(player, xi.slot.MAIN, native)
        assert(math.abs(tuned.ftpMod[1] - 5.4) < 0.0001)
        assert(math.abs(tuned.ftpMod[3] - 18.5625) < 0.0001)
        assert(native.ftpMod[1] == 4.0)

        local naegling = makePlayer({ [xi.slot.MAIN] = 21621 }, 99)
        assert(catalog.applyOdysseyFtp(naegling, xi.slot.MAIN, native) == native)

        xi.standardWsTuning.withStandardEffects(
            player, target, xi.weaponskill.SAVAGE_BLADE, xi.slot.MAIN,
            {}, false,
            function()
                assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 9200)
                assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 349999)
            end)
    end)

    it('keeps pre-119 III REMA staged and lets finished REMA off-native WS climb to 500,000', function()
        local target = makeTarget(150, 1000000)
        local excalibur119I = makePlayer({ [xi.slot.MAIN] = 20645 }, 99)
        local sequence = makePlayer({ [xi.slot.MAIN] = 20695 }, 99)

        xi.standardWsTuning.withStandardEffects(
            excalibur119I, target, xi.weaponskill.SAVAGE_BLADE, xi.slot.MAIN,
            {}, false,
            function()
                assert(excalibur119I:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 99999)
            end)

        xi.standardWsTuning.withStandardEffects(
            excalibur119I, target, xi.weaponskill.KNIGHTS_OF_ROUND, xi.slot.MAIN,
            {}, false,
            function()
                assert(excalibur119I:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 149999)
            end)

        xi.standardWsTuning.withStandardEffects(
            sequence, target, xi.weaponskill.SAVAGE_BLADE, xi.slot.MAIN,
            {}, false,
            function()
                assert(sequence:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 500000)
                assert(sequence:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 8000)
            end)

        local aeneas = makePlayer({ [xi.slot.MAIN] = 20594 }, 99)
        xi.standardWsTuning.withStandardEffects(
            aeneas, target, xi.weaponskill.EVISCERATION, xi.slot.MAIN,
            {}, false,
            function()
                assert(aeneas:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 500000)
                assert(aeneas:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 8000)
            end)

        aeneas:setLocalVar('RemaWsTuned', 1)
        xi.standardWsTuning.withStandardEffects(
            aeneas, target, xi.weaponskill.EXENTERATOR, xi.slot.MAIN,
            {}, false,
            function()
                assert(aeneas:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 0)
                assert(aeneas:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 0)
            end)

        local bstSequence = makePlayer({ [xi.slot.MAIN] = 20695 }, 99, 0, xi.job.BST)
        xi.standardWsTuning.withStandardEffects(
            bstSequence, target, xi.weaponskill.SAVAGE_BLADE, xi.slot.MAIN,
            {}, false,
            function()
                assert(bstSequence:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 249999)
            end)
    end)

    it('caps pre-119 III Gastraphetes Trueflight at 149,999 on the ranged slot', function()
        local target = makeTarget(150, 1000000)
        for _, itemId in ipairs({ 19829, 21247, 21266 }) do
            local info = catalog.getRemaPathInfo(itemId)
            assert(info ~= nil and info.final == false)
            assert(info.wsId == xi.weaponskill.TRUEFLIGHT)
            assert(info.slot == xi.slot.RANGED)

            local player = makePlayer({ [xi.slot.RANGED] = itemId }, 99)
            xi.standardWsTuning.withStandardEffects(
                player, target, xi.weaponskill.TRUEFLIGHT, xi.slot.RANGED, {}, false,
                function()
                    assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 149999, itemId)
                end)

            -- Off-native marksman WS on the same stick stay at 99,999.
            xi.standardWsTuning.withStandardEffects(
                player, target, xi.weaponskill.LAST_STAND, xi.slot.RANGED, {}, false,
                function()
                    assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 99999, itemId)
                end)
        end

        local finished = catalog.getRemaPathInfo(22139)
        assert(finished ~= nil and finished.final == true)
        assert(finished.wsId == xi.weaponskill.TRUEFLIGHT)
    end)

    it('still tunes ordinary WSs used with a special weapon', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20509 }, 99)
        local target = makeTarget(155, 120000)

        xi.standardWsTuning.withStandardEffects(
            player, target, xi.weaponskill.RAGING_FISTS, xi.slot.MAIN,
            {}, false,
            function()
                assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 8000)
            end)
    end)

    it('restores local variables and accuracy after a calculation error', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20819 }, 50)
        local target = makeTarget(58, 10000)
        player:setLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR, 17)
        player:setLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR, 23)
        player:setMod(xi.mod.WSACC, 11)

        local ok = pcall(function()
            xi.standardWsTuning.withStandardEffects(
                player, target, xi.weaponskill.RAGING_RUSH, xi.slot.MAIN,
                {}, false,
                function()
                    error('expected test failure')
                end)
        end)

        assert(not ok)
        assert(player:getLocalVar(catalog.DAMAGE_MULTIPLIER_LOCAL_VAR) == 17)
        assert(player:getLocalVar(catalog.DAMAGE_CAP_LOCAL_VAR) == 23)
        assert(player:getMod(xi.mod.WSACC) == 11)
    end)
end)
