-----------------------------------
-- !aoews  [ <weapon skill name> ]
--
-- Binds the ONE weapon skill that splashes its damage to nearby enemies, for
-- players who unlocked the AoE Weapon Skill perk at the Rupture Sage NPC.
-- AoEWeaponSkill.lua does the actual splash on WEAPONSKILL_USE, but it reads the
-- charVar AoEWSID -- which ONLY this command sets. Without it the (expensive)
-- unlock is inert (AoEWSID stays 0 and the splash never fires). See
-- [[reference_gear_finder]] / AoEWeaponSkill.lua.
--
--   !aoews            -> show your current bound WS (and splash %)
--   !aoews <name>     -> bind that weapon skill, e.g. !aoews Savage Blade
--                        (case/space/punctuation-insensitive; matches xi.weaponskill)
--
-- Gated on having bought at least the 50% splash tier at the Rupture Sage
-- (charVar AoEWSPct > 0). Re-bind anytime, no cost.
-----------------------------------
require('scripts/enum/weaponskill')

---@type TCommand
local commandObj = {}

local CHANNEL = xi.msg.channel.SYSTEM_3

-- Display form (mirrors AoEWeaponSkill.wsDisplayName): SAVAGE_BLADE -> "Savage blade".
local function displayName(key)
    return key:sub(1, 1) .. key:sub(2):lower():gsub('_', ' ')
end

-- Normalize for matching: lowercase, strip everything non-alphanumeric.
-- "Tachi: Fudo" / "tachi fudo" / "TACHI_FUDO" all -> "tachifudo".
local function norm(s)
    return (s or ''):lower():gsub('[^%a%d]+', '')
end

local function nameForId(id)
    for k, v in pairs(xi.weaponskill) do
        if v == id then
            return displayName(k)
        end
    end
    return string.format('WS#%d', id)
end

-- Resolve a (possibly multi-word) name to a WS id: exact match first, then a
-- substring fallback so partials like "savage" still land.
local function resolveWS(name)
    local q = norm(name)
    if q == '' then
        return nil
    end
    for k, v in pairs(xi.weaponskill) do
        if type(v) == 'number' and norm(k) == q then
            return v, displayName(k)
        end
    end
    for k, v in pairs(xi.weaponskill) do
        if type(v) == 'number' and norm(k):find(q, 1, true) then
            return v, displayName(k)
        end
    end
    return nil
end

commandObj.cmdprops =
{
    permission = 0, -- all players
    parameters = 'ssssssss', -- WS names are multi-word; collect up to 8 tokens
}

commandObj.onTrigger = function(player, ...)
    local pct = player:getCharVar('AoEWSPct') or 0
    if pct <= 0 then
        player:printToPlayer('[AoE WS] Unlock the AoE Weapon Skill at the Rupture Sage (GM Home) first, then use !aoews.', CHANNEL)
        return
    end

    -- Re-join the parsed tokens into the full WS name (handles spaces).
    local count = select('#', ...)
    local parts = {}
    for i = 1, count do
        local v = select(i, ...)
        if v ~= nil and v ~= '' then
            parts[#parts + 1] = tostring(v)
        end
    end
    local arg = table.concat(parts, ' ')

    local curId = player:getCharVar('AoEWSID') or 0

    if arg == '' then
        if curId == 0 then
            player:printToPlayer('[AoE WS] No weapon skill bound yet. Use "!aoews <name>" -- e.g. !aoews Savage Blade.', CHANNEL)
        else
            player:printToPlayer(string.format(
                '[AoE WS] Bound: %s  (%d%% splash to enemies within 10y). Change it with "!aoews <name>".',
                nameForId(curId), pct), CHANNEL)
        end
        return
    end

    local id, disp = resolveWS(arg)
    if not id then
        player:printToPlayer(string.format(
            '[AoE WS] No weapon skill matches "%s". Type the WS name, e.g. !aoews Savage Blade.', arg), CHANNEL)
        return
    end

    player:setCharVar('AoEWSID', id)
    player:printToPlayer(string.format(
        '[AoE WS] Bound %s -- it now splashes %d%% of its damage to enemies within 10y of your target.', disp, pct), CHANNEL)
end

return commandObj
