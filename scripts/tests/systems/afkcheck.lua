describe('AFK check timeout', function()
    local function readFile(path)
        local file = assert(io.open(path, 'r'))
        local text = file:read('*a')
        file:close()
        return text
    end

    it('does not let a late menu click pass after the 30-second timeout', function()
        local text = readFile('scripts/commands/afkcheck.lua')

        assert(text:find('CAPTCHA_PENDING', 1, true))
        assert(text:find('CAPTCHA_FAILED', 1, true))
        assert(text:find("getLocalVar('CAPTCHA') ~= CAPTCHA_PENDING", 1, true))
        assert(text:find('AFK Check already expired', 1, true))
        assert(text:find('AFK Check failed (timed out)', 1, true))
        assert(text:find('Legendary Ring', 1, true))
    end)
end)
