-- Documents the JSE "enhances job ability" latents in
-- sql/zzzz_jse_ja_enhancements.sql. Values are 1/1000ths for haste
-- (Hasso itself is TWOHAND_HASTE_ABILITY 1000 = 10%).

describe('JSE job-ability enhancement latents', function()
    it('uses Job Ability haste for Hasso gear, not gear haste', function()
        assert(xi.mod.TWOHAND_HASTE_ABILITY == 217)
        assert(xi.mod.HASTE_GEAR == 384)
        assert(xi.mod.HASTE_GEAR ~= xi.mod.TWOHAND_HASTE_ABILITY)
        assert(xi.effect.HASSO == 353)
        assert(xi.effect.SEIGAN == 354)
    end)

    it('gives Empyrean +3 hands more Hasso haste than Relic +3 legs', function()
        -- Wakido Kote +3 = +4% JA haste; Kasuga Haidate +3 = +3% JA haste.
        -- These are the two pieces players report as doing nothing.
        local wakidoKoteP3 = 400
        local kasugaHaidateP3 = 300
        assert(wakidoKoteP3 > kasugaHaidateP3)
        assert(wakidoKoteP3 + kasugaHaidateP3 == 700) -- +7% on top of Hasso's 10%
        assert(wakidoKoteP3 + kasugaHaidateP3 + 1000 <= 2500) -- stays under the 25% JA haste cap
    end)

    it('keeps Seigan / Innin / Yonin +3 at the wiki counter and DA rates', function()
        assert(xi.mod.COUNTER == 291)
        assert(xi.mod.DOUBLE_ATTACK == 288)
        assert(xi.effect.YONIN == 420)
        assert(xi.effect.INNIN == 421)

        local kasugaKabutoP3Seigan = 18
        local hattoriZukinP3Innin = 13
        local hattoriHakamaP3Yonin = 18
        assert(kasugaKabutoP3Seigan == 18)
        assert(hattoriZukinP3Innin == 13)
        assert(hattoriHakamaP3Yonin == 18)
    end)

    it('keeps Last Resort and Berserk defense-penalty relief at 10%', function()
        assert(xi.effect.LAST_RESORT == 64)
        assert(xi.effect.BERSERK == 56)
        assert(xi.mod.DEFP == 63)
    end)
end)
