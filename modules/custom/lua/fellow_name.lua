-----------------------------------
-- fellow_name.lua
-- Shared helper for CUSTOM (free-text) Adventuring Fellow names.
--
-- FFXI has no free-text input dialog and setCharVar is int32-only, so:
--   * PERSISTENCE: the sanitized name is byte-packed into 4 int charVars
--     (Fellow_NameW0..W3, 4 bytes each = 15-char capacity) plus a
--     Fellow_NameCustom flag. No new DB table, no rebuild -- pure charVar
--     storage, hot-reloadable.
--   * DISPLAY: fellow_companion.chosenName() reads this FIRST (a custom name
--     overrides the preset name list); the Fellow's spawn already applies it via
--     pet:renameEntity(name, true). The entity-name packet field is 16 bytes
--     (15 chars + null), hence the 15-char cap.
--
-- Set via the !fellowname command. Picking a preset name in the !fellow menu
-- clears the custom flag (see openName -> FN.clear), reverting to the preset.
-----------------------------------
local FN = {}

FN.MAXLEN = 15
FN.FLAG   = 'Fellow_NameCustom'
FN.WORDS  = { 'Fellow_NameW0', 'Fellow_NameW1', 'Fellow_NameW2', 'Fellow_NameW3' }

-- Allowed characters: letters and single internal spaces only.
-- Returns the cleaned name, or nil if nothing usable remains.
function FN.sanitize(raw)
    if type(raw) ~= 'string' then
        return nil
    end
    local s = raw:gsub('^%s+', ''):gsub('%s+$', '')  -- trim ends
    s = s:gsub('%s+', ' ')                            -- collapse internal whitespace
    s = s:gsub('[^%a ]', '')                          -- strip anything but letters and spaces
    if #s > FN.MAXLEN then
        s = s:sub(1, FN.MAXLEN)
    end
    s = s:gsub('%s+$', '')                            -- re-trim if truncation left a trailing space
    if s == '' then
        return nil
    end
    return s
end

-- Basic profanity gate. Normalizes common leetspeak and strips non-letters so
-- "sh1t", "f u c k", "$hit" still trip the substring match. Not exhaustive --
-- extend FN.PROFANITY as needed.
FN.PROFANITY =
{
    'fuck', 'shit', 'cunt', 'nigger', 'nigga', 'faggot', 'retard', 'rape',
    'bitch', 'whore', 'slut', 'dick', 'cock', 'pussy', 'penis', 'nazi',
    'hitler', 'kike', 'spic', 'chink', 'tranny', 'molest', 'pedo', 'coon',
}

local function normalizeForFilter(name)
    local s = name:lower()
    s = s:gsub('0', 'o'):gsub('1', 'i'):gsub('3', 'e'):gsub('4', 'a')
    s = s:gsub('5', 's'):gsub('7', 't'):gsub('@', 'a'):gsub('%$', 's')
    s = s:gsub('[^%a]', '')  -- letters only (defeats spaces/punctuation between letters)
    return s
end

function FN.isClean(name)
    local norm = normalizeForFilter(name)
    for _, bad in ipairs(FN.PROFANITY) do
        if norm:find(bad, 1, true) then
            return false
        end
    end
    return true
end

-- Byte-pack the name into the 4 word charVars (little-endian, null-terminated)
-- and raise the custom flag.
function FN.pack(player, name)
    local bytes = { name:byte(1, #name) }
    for w = 0, 3 do
        local v = 0
        for j = 0, 3 do
            local b = bytes[w * 4 + j + 1] or 0
            v = bit.bor(v, bit.lshift(b, j * 8))
        end
        player:setCharVar(FN.WORDS[w + 1], v)
    end
    player:setCharVar(FN.FLAG, 1)
end

function FN.clear(player)
    player:setCharVar(FN.FLAG, 0)
end

-- Unpack the stored custom name, or nil if none is set.
function FN.read(player)
    if (player:getCharVar(FN.FLAG) or 0) == 0 then
        return nil
    end
    local out = {}
    for w = 0, 3 do
        local v = player:getCharVar(FN.WORDS[w + 1]) or 0
        for j = 0, 3 do
            local b = bit.band(bit.rshift(v, j * 8), 0xFF)
            if b == 0 then
                return (#out > 0) and table.concat(out) or nil
            end
            out[#out + 1] = string.char(b)
        end
    end
    return (#out > 0) and table.concat(out) or nil
end

-- Sanitize + filter + persist, and rename the live Fellow if it is out.
-- Returns (true, cleanName) on success, or (false, errorMessage) on rejection.
function FN.apply(player, raw)
    local name = FN.sanitize(raw)
    if not name then
        return false, 'Use letters and spaces for the name (max 15 chars), e.g. !fellowname Sir Fluffy.'
    end
    if not FN.isClean(name) then
        return false, 'That name was rejected by the language filter, kupo.'
    end
    FN.pack(player, name)
    -- The Fellow is a flagged trust, not player:getPet().
    local fellow = xi.fellow and xi.fellow.getTrust and xi.fellow.getTrust(player)
    if fellow then
        pcall(function() fellow:renameEntity(name, true) end)
    end
    return true, name
end

return FN
