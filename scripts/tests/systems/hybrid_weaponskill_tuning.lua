describe('Hybrid weaponskill tuning', function()
    it('halves only the elemental rider fTP', function()
        local params = { ftpMod = { 0.5, 1.5, 2.5 } }

        assert(xi.weaponskills.HYBRID_MAGIC_FTP_SCALE == 0.5)
        assert(xi.weaponskills.fTP(1000, params.ftpMod) == 0.5)
        assert(xi.weaponskills.fTP(2000, params.ftpMod) == 1.5)
        assert(xi.weaponskills.fTP(3000, params.ftpMod) == 2.5)
        assert(xi.weaponskills.getHybridMagicFtp(1000, params) == 0.25)
        assert(xi.weaponskills.getHybridMagicFtp(2000, params) == 0.75)
        assert(xi.weaponskills.getHybridMagicFtp(3000, params) == 1.25)
    end)

    it('honors a dedicated hybrid fTP table', function()
        local params =
        {
            ftpMod       = { 1, 2, 3 },
            hybridFtpMod = { 0.4, 0.8, 1.2 },
        }

        assert(math.abs(xi.weaponskills.getHybridMagicFtp(1500, params) - 0.3) < 0.0001)
        assert(math.abs(xi.weaponskills.getHybridMagicFtp(2500, params) - 0.5) < 0.0001)
    end)

    it('allows an explicit per-weaponskill scale without changing the default', function()
        local untuned = { ftpMod = { 0.5, 1.5, 2.5 } }
        local tuned   = { ftpMod = { 0.5, 1.5, 2.5 }, hybridFtpScale = 0.4 }

        assert(xi.weaponskills.getHybridMagicFtp(3000, untuned) == 1.25)
        assert(xi.weaponskills.getHybridMagicFtp(3000, tuned) == 1.0)
        assert(xi.weaponskills.HYBRID_MAGIC_FTP_SCALE == 0.5)
    end)
end)
