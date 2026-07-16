local catalog = require('modules/custom/lua/rema_ws_tier_catalog')
require('modules/custom/lua/REMAWeaponskillEnhancement')

describe('Legendary REMA native-weaponskill enhancement', function()
    local function makePlayer(equipment)
        local mods = {}
        local player =
        {
            equipment = equipment or {},
        }

        player.isPC = function()
            return true
        end

        player.getEquipID = function(self, slot)
            return self.equipment[slot] or 0
        end

        player.addMod = function(_, modId, amount)
            mods[modId] = (mods[modId] or 0) + amount
        end

        player.delMod = function(_, modId, amount)
            mods[modId] = (mods[modId] or 0) - amount
        end

        player.setMod = function(_, modId, amount)
            mods[modId] = amount
        end

        player.getMod = function(_, modId)
            return mods[modId] or 0
        end

        return player
    end

    local function makeNonPlayer()
        return
        {
            isPC = function()
                return false
            end,
            getEquipID = function()
                return 0
            end,
        }
    end

    local function bonus(player, wsId, slot)
        return xi.remaWsTier.getBonusPercent(player, wsId, slot or xi.slot.MAIN)
    end

    it('uses the configured family tiers and +200 percent benchmark', function()
        assert(catalog.PRIME_EQUIVALENT_BONUS == 2.00)
        assert(catalog.getTuning(xi.weaponskill.MERCY_STROKE) == 15.00)
        assert(bonus(makePlayer({ [xi.slot.MAIN] = 20509 }), xi.weaponskill.FINAL_HEAVEN) == 100)
        assert(bonus(makePlayer({ [xi.slot.MAIN] = 20512 }), xi.weaponskill.VICTORY_SMITE) == 120)
        assert(bonus(makePlayer({ [xi.slot.MAIN] = 20510 }), xi.weaponskill.ASCETICS_FURY) == 140)
        assert(bonus(makePlayer({ [xi.slot.MAIN] = 20515 }), xi.weaponskill.SHIJIN_SPIRAL) == 160)
    end)

    it('requires the exact equipped final weapon and native WS', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20509 })

        assert(bonus(player, xi.weaponskill.FINAL_HEAVEN) == 100)
        assert(bonus(player, xi.weaponskill.MERCY_STROKE) == 0)

        player.equipment[xi.slot.MAIN] = 20583
        assert(bonus(player, xi.weaponskill.FINAL_HEAVEN) == 0)
    end)

    it('ignores inventory-only, SUB-only and intermediate weapons', function()
        local inventoryOnly = makePlayer()
        local subOnly       = makePlayer({ [xi.slot.SUB] = 20583 })
        local intermediate  = makePlayer({ [xi.slot.MAIN] = 20481 })

        assert(bonus(inventoryOnly, xi.weaponskill.FINAL_HEAVEN) == 0)
        assert(bonus(subOnly, xi.weaponskill.MERCY_STROKE) == 0)
        assert(bonus(intermediate, xi.weaponskill.FINAL_HEAVEN) == 0)
    end)

    it('requires qualifying ranged weapons in the RANGED slot', function()
        local ranged = makePlayer({ [xi.slot.RANGED] = 22129 })
        local main   = makePlayer({ [xi.slot.MAIN] = 22129 })

        assert(bonus(ranged, xi.weaponskill.NAMAS_ARROW, xi.slot.RANGED) == 100)
        assert(bonus(ranged, xi.weaponskill.CORONACH, xi.slot.RANGED) == 0)
        assert(bonus(main, xi.weaponskill.NAMAS_ARROW, xi.slot.RANGED) == 0)
        assert(bonus(makePlayer(), xi.weaponskill.NAMAS_ARROW, xi.slot.RANGED) == 0)
    end)

    it('rejects non-player attackers', function()
        for _ = 1, 4 do -- Trust, pet, monster and NPC representations.
            assert(bonus(makeNonPlayer(), xi.weaponskill.FINAL_HEAVEN) == 0)
        end
    end)

    it('excludes Prime and normal weapons', function()
        local prime  = makePlayer({ [xi.slot.MAIN] = 21535 })
        local normal = makePlayer({ [xi.slot.MAIN] = 16535 })

        assert(bonus(prime, xi.weaponskill.MARU_KALA) == 0)
        assert(bonus(normal, xi.weaponskill.FINAL_HEAVEN) == 0)
    end)

    it('uses the weapon equipped at execution time', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20509 })
        assert(bonus(player, xi.weaponskill.FINAL_HEAVEN) == 100)

        player.equipment[xi.slot.MAIN] = 20512
        assert(bonus(player, xi.weaponskill.FINAL_HEAVEN) == 0)
        assert(bonus(player, xi.weaponskill.VICTORY_SMITE) == 120)
    end)

    it('applies only the relevant MAIN or RANGED entry once', function()
        local player = makePlayer(
            {
                [xi.slot.MAIN]   = 20509,
                [xi.slot.SUB]    = 20583,
                [xi.slot.RANGED] = 22139,
            })

        assert(bonus(player, xi.weaponskill.FINAL_HEAVEN, xi.slot.MAIN) == 100)
        assert(bonus(player, xi.weaponskill.MERCY_STROKE, xi.slot.MAIN) == 0)
        assert(bonus(player, xi.weaponskill.TRUEFLIGHT, xi.slot.RANGED) == 140)
    end)

    it('supports both physical and magical WS mappings', function()
        local physical = makePlayer({ [xi.slot.MAIN] = 20509 })
        local magical  = makePlayer({ [xi.slot.MAIN] = 21752 })
        local ranged   = makePlayer({ [xi.slot.RANGED] = 22141 })

        assert(bonus(physical, xi.weaponskill.FINAL_HEAVEN) == 100)
        assert(bonus(magical, xi.weaponskill.CLOUDSPLITTER) == 120)
        assert(bonus(ranged, xi.weaponskill.LEADEN_SALUTE, xi.slot.RANGED) == 140)
    end)

    it('applies per-WS fTP tuning without mutating native parameters', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20685 })
        local native = { numHits = 1, ftpMod = { 3, 3, 3 }, str_wsc = 0.4 }
        local tuned  = xi.remaWsTier.getTunedParams(
            player, xi.weaponskill.KNIGHTS_OF_ROUND, xi.slot.MAIN, native)

        assert(tuned ~= native)
        assert(tuned.ftpMod ~= native.ftpMod)
        assert(tuned.numHits == 1 and tuned.str_wsc == 0.4)
        assert(math.abs(tuned.ftpMod[1] - 23.7) < 0.0001)
        assert(math.abs(tuned.ftpMod[3] - 23.7) < 0.0001)
        assert(native.ftpMod[1] == 3 and native.ftpMod[3] == 3)
    end)

    it('accounts for the effective WoTG Death Blossom parameters', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20686 })
        local native = { numHits = 3, ftpMod = { 1.125, 1.125, 1.125 } }
        local tuned  = xi.remaWsTier.getTunedParams(
            player, xi.weaponskill.DEATH_BLOSSOM, xi.slot.MAIN, native)

        assert(tuned.numHits == 3)
        assert(tuned.ftpMod[1] == 45)
        assert(tuned.ftpMod[3] == 45)
        assert(native.ftpMod[1] == 1.125)
    end)

    it('leaves fTP unchanged for non-qualifying weapons', function()
        local native = { ftpMod = { 5, 5, 5 } }
        local tuned  = xi.remaWsTier.getTunedParams(
            makePlayer({ [xi.slot.MAIN] = 16535 }),
            xi.weaponskill.KNIGHTS_OF_ROUND,
            xi.slot.MAIN,
            native)

        assert(tuned == native)
    end)

    it('removes the temporary modifier after successful calculation', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20509 })
        local modId  = xi.mod.WEAPONSKILL_DAMAGE_BASE + xi.weaponskill.FINAL_HEAVEN
        player:addMod(modId, 15)

        local first, second = xi.remaWsTier.withTemporaryBonus(
            player,
            xi.weaponskill.FINAL_HEAVEN,
            xi.slot.MAIN,
            function()
                assert(player:getMod(modId) == 115)
                player:setMod(modId, 999)
                return 17, 23
            end)

        assert(first == 17 and second == 23)
        assert(player:getMod(modId) == 15)
    end)

    it('removes the temporary modifier before rethrowing a Lua error', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20509 })
        local modId  = xi.mod.WEAPONSKILL_DAMAGE_BASE + xi.weaponskill.FINAL_HEAVEN
        player:addMod(modId, 15)

        local ok = pcall(function()
            xi.remaWsTier.withTemporaryBonus(
                player,
                xi.weaponskill.FINAL_HEAVEN,
                xi.slot.MAIN,
                function()
                    error('intentional REMA test error')
                end)
        end)

        assert(not ok)
        assert(player:getMod(modId) == 15)
    end)

    it('does not stack the enhancement during a nested calculation', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20509 })
        local modId  = xi.mod.WEAPONSKILL_DAMAGE_BASE + xi.weaponskill.FINAL_HEAVEN

        xi.remaWsTier.withTemporaryBonus(
            player,
            xi.weaponskill.FINAL_HEAVEN,
            xi.slot.MAIN,
            function()
                assert(player:getMod(modId) == 100)

                xi.remaWsTier.withTemporaryBonus(
                    player,
                    xi.weaponskill.FINAL_HEAVEN,
                    xi.slot.MAIN,
                    function()
                        assert(player:getMod(modId) == 100)
                    end)
            end)

        assert(player:getMod(modId) == 0)
    end)

    it('does not register wrappers again when reloaded in the same Lua state', function()
        local modulePath = 'modules/custom/lua/REMAWeaponskillEnhancement'
        local original   = package.loaded[modulePath]

        for _ = 1, 3 do
            package.loaded[modulePath] = nil
            local reloadGuard = require(modulePath)
            assert(#reloadGuard.overrides == 0)
        end

        package.loaded[modulePath] = original
    end)

    it('calls the preserved original exactly once without recursion', function()
        local player = makePlayer({ [xi.slot.MAIN] = 20509 })
        local calls  = 0

        local first, second = xi.remaWsTier.callPreservedOriginal(
            player,
            xi.weaponskill.FINAL_HEAVEN,
            xi.slot.MAIN,
            function(firstArg, secondArg)
                calls = calls + 1
                assert(firstArg == 17 and secondArg == 23)
                return 31, 47
            end,
            17,
            23)

        assert(calls == 1)
        assert(first == 31 and second == 47)
    end)

    it('produces the configured physical, ranged and magical damage multipliers', function()
        local function calculateDamage(player, wsId, slot, baseDamage)
            return xi.remaWsTier.callPreservedOriginal(
                player,
                wsId,
                slot,
                function(originalDamage)
                    local wsDamageMod = player:getMod(xi.mod.WEAPONSKILL_DAMAGE_BASE + wsId)
                    return originalDamage * (100 + wsDamageMod) / 100
                end,
                baseDamage)
        end

        -- Relic physical: +100% = 2.00x.
        assert(calculateDamage(
            makePlayer({ [xi.slot.MAIN] = 20509 }),
            xi.weaponskill.FINAL_HEAVEN,
            xi.slot.MAIN,
            1000) == 2000)

        -- Aeonic ranged physical: +160% = 2.60x.
        assert(calculateDamage(
            makePlayer({ [xi.slot.RANGED] = 22117 }),
            xi.weaponskill.APEX_ARROW,
            xi.slot.RANGED,
            1000) == 2600)

        -- Empyrean magical: +120% = 2.20x.
        assert(calculateDamage(
            makePlayer({ [xi.slot.MAIN] = 21752 }),
            xi.weaponskill.CLOUDSPLITTER,
            xi.slot.MAIN,
            1000) == 2200)
    end)

    it('leaves Prime and ordinary damage numerically unchanged', function()
        local function calculateDamage(player, wsId, baseDamage)
            local before = baseDamage * (100 + player:getMod(xi.mod.WEAPONSKILL_DAMAGE_BASE + wsId)) / 100
            local after  = xi.remaWsTier.withTemporaryBonus(player, wsId, xi.slot.MAIN,
                function()
                    return baseDamage * (100 + player:getMod(xi.mod.WEAPONSKILL_DAMAGE_BASE + wsId)) / 100
                end)

            assert(after == before)
        end

        calculateDamage(
            makePlayer({ [xi.slot.MAIN] = 21535 }),
            xi.weaponskill.MARU_KALA,
            1000)
        calculateDamage(
            makePlayer({ [xi.slot.MAIN] = 16535 }),
            xi.weaponskill.FINAL_HEAVEN,
            1000)
    end)

    it('leaves Dagan, Myrkr and Atonement unchanged', function()
        assert(bonus(makePlayer({ [xi.slot.MAIN] = 21079 }), xi.weaponskill.DAGAN) == 0)
        assert(bonus(makePlayer({ [xi.slot.MAIN] = 22064 }), xi.weaponskill.MYRKR) == 0)
        assert(bonus(makePlayer({ [xi.slot.MAIN] = 20687 }), xi.weaponskill.ATONEMENT) == 0)
    end)

    it('keeps unresolved Tishtrya and Khatvanga mappings non-qualifying', function()
        assert(bonus(makePlayer({ [xi.slot.MAIN] = 21082 }), xi.weaponskill.BLACK_HALO) == 0)
        assert(bonus(makePlayer({ [xi.slot.MAIN] = 21147 }), xi.weaponskill.SHATTERSOUL) == 0)
    end)

    it('has explicit fTP tuning and a family bonus for every enabled entry', function()
        for _, entry in ipairs(catalog.WEAPONS) do
            local expected = entry.enabled and
                math.floor(catalog.PRIME_EQUIVALENT_BONUS * catalog.REMA_TIER_SCALE[entry.family] * 100 + 0.5) or
                0

            if entry.enabled then
                assert(catalog.getTuning(entry.wsId) ~= nil)
                assert(catalog.getTuning(entry.wsId) > 0)
            end

            assert(catalog.getBonusPercent(entry.itemId, entry.wsId, entry.slot) == expected)
        end
    end)
end)
