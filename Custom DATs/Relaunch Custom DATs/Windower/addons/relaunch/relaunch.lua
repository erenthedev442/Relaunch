--[[
========================================================================
Relaunch server -- Windower resource overrides
========================================================================
XIPivot patches the CLIENT's item text (ROM/286/73.DAT), but Windower
ships its own static `res.items` table that was baked from RETAIL DATs.
GearSwap, autoexec, and every other Lua addon that resolves items by
name reads that static table -- NOT the client's DAT.

Without this addon:
  * `left_ring = "Legendary Ring"` in a GearSwap set fails to resolve
    (Windower still thinks item 26169 is "Reraise Ring").
  * The four Legendary Track Suit pieces (ids 23875-78) don't exist in
    Windower's table at all, so no name resolves.

What this addon does:
  * Renames existing entries (Reraise Ring -> Legendary Ring).
  * Inserts new entries cloned from the donor items the server-side
    records were cloned from, then overrides the display fields.

Runs once on load; safe to re-run (idempotent). Compatible with any
addon that consumes `resources` -- GearSwap, autoexec, itemwatch, etc.

Load order: this must load BEFORE the first GearSwap item resolution.
Add `lua load relaunch` to Windower4/scripts/init.txt (the installer
offers to do this for you), or type it once per session.
========================================================================
--]]

_addon.name    = 'relaunch'
_addon.author  = 'Relaunch'
_addon.version = '1.0.0'
_addon.command = 'relaunch'

local res = require('resources')

-- Rename table: id -> new display name. Both `en` (English name) and
-- `enl` (log form, allows a leading period for wrap) get set; both are
-- read by different code paths in various addons.
local RENAMES = {
    [26169] = 'Legendary Ring',   -- retail: Reraise Ring
}

-- Insert table: id -> { donor_id, name }. donor_id is a retail item
-- whose slot / jobs / level / category we copy verbatim; only the id and
-- name change. Donor picks come from the DAT pack manifest
-- (Custom DATs/manifest.md).
local INSERTS = {
    [23875] = { donor = 24213, name = 'Track Jacket'   },  -- Body (donor: Arrogance Jacket)
    [23876] = { donor = 23859, name = 'Track Pants'    },  -- Legs (donor: Arrogance Brais)
    [23877] = { donor = 23831, name = 'Track Shoes'    },  -- Feet (donor: Emerald Crackows)
    [23878] = { donor = 24213, name = 'Legend Sweater' },  -- Body sweater (donor: Arrogance Jacket)
    [19968] = { donor = 20753, name = 'Epeolatry'      },  -- 99
    [19969] = { donor = 20753, name = 'Epeolatry'      },  -- 119 I
    [19970] = { donor = 21070, name = 'Idris'          },  -- 99
    [19971] = { donor = 21070, name = 'Idris'          },  -- 119 I
}

local applied = { rename = 0, insert = 0, skipped = 0 }

-- ── Renames ────────────────────────────────────────────────────────────
for id, name in pairs(RENAMES) do
    local it = res.items[id]
    if it then
        it.en   = name
        it.enl  = name
        -- Some addons match on Japanese name too; overwrite for consistency
        -- (a native JP-client player would want to keep the JP text -- swap
        -- the two lines below if you localise).
        it.ja   = name
        it.jal  = name
        applied.rename = applied.rename + 1
    else
        applied.skipped = applied.skipped + 1
    end
end

-- ── Inserts (clone a donor entry, override id + name) ──────────────────
for id, spec in pairs(INSERTS) do
    local donor = res.items[spec.donor]
    if donor and not res.items[id] then
        -- Copy every field so the entry has the same metatable-driven
        -- accessors GearSwap expects (slots, jobs, level, category, ...).
        local clone = setmetatable({}, getmetatable(donor))
        for k, v in pairs(donor) do clone[k] = v end
        clone.id  = id
        clone.en  = spec.name
        clone.enl = spec.name
        clone.ja  = spec.name
        clone.jal = spec.name
        res.items[id] = clone
        applied.insert = applied.insert + 1
    elseif res.items[id] then
        -- Someone else already registered this id -- don't clobber.
        applied.skipped = applied.skipped + 1
    else
        -- Donor missing (Windower res doesn't know that retail item) --
        -- can't clone. Log and continue; the item just won't resolve
        -- from Lua, which matches pre-addon behaviour.
        windower.add_to_chat(207, ('[relaunch] cannot clone item %d: donor %d missing from res.items'):format(id, spec.donor))
        applied.skipped = applied.skipped + 1
    end
end

windower.add_to_chat(207, ('[relaunch] resource overrides: %d renamed, %d inserted, %d skipped'):format(
    applied.rename, applied.insert, applied.skipped))

-- Each Windower addon has its own res.items. Push the same names into GearSwap.
local function inject_gearswap()
    windower.send_command('lua i GearSwap require legendary_res')
    windower.send_command('wait 0.2; lua i GearSwap legendary_apply_resources')
end

windower.register_event('load', function()
    windower.send_command('wait 1; lua i GearSwap require legendary_res')
    windower.send_command('wait 12; lua i GearSwap require legendary_res')
end)

windower.register_event('login', function()
    windower.send_command('wait 2; lua i GearSwap require legendary_res')
end)

-- Seasonal /ma "Matsui-P" (spell 1003) R0s the client. Rewrite to Exc_S (1004)
-- before the DAT lookup. Also catch /matsui-p as a bare command.
local function isMatsuiCast(text)
    local t = (text or ''):lower():gsub('^%s+', '')
    t = t:gsub('^/+', '/')
    if t:match('^/matsui') then
        return true
    end
    if t:match('^/ma%s') or t:match('^/magic%s') then
        return t:find('matsui', 1, true) ~= nil
    end
    return false
end

windower.register_event('outgoing text', function(original, modified)
    local text = modified or original
    if not isMatsuiCast(text) then
        return
    end
    local target = text:match('(<[^>]+>)') or '<me>'
    windower.add_to_chat(207, '[relaunch] /ma "Matsui-P" crashes. Using Excenmille (S).')
    return '/ma "Excenmille (S)" ' .. target
end)

-- ── Commands ───────────────────────────────────────────────────────────
-- `//relaunch check <name>`  print what Windower now resolves for that name
-- `//relaunch show <id>`     print the current res.items entry for that id
windower.register_event('addon command', function(cmd, ...)
    cmd = (cmd or ''):lower()
    local args = { ... }
    if cmd == 'check' then
        local q = table.concat(args, ' ')
        if q == '' then
            windower.add_to_chat(207, '[relaunch] usage: //relaunch check <item name>')
            return
        end
        local item = res.items:with('en', q) or res.items:with('name', q)
        if item then
            windower.add_to_chat(207, ('[relaunch] "%s" -> id %d (%s)'):format(q, item.id, item.en))
        else
            windower.add_to_chat(207, ('[relaunch] "%s" is NOT in res.items'):format(q))
        end
    elseif cmd == 'show' then
        local id = tonumber(args[1] or '')
        if not id then
            windower.add_to_chat(207, '[relaunch] usage: //relaunch show <item id>')
            return
        end
        local item = res.items[id]
        if item then
            windower.add_to_chat(207, ('[relaunch] id %d: en="%s" slots=%s jobs=%s'):format(
                id, item.en or '?', tostring(item.slots), tostring(item.jobs)))
        else
            windower.add_to_chat(207, ('[relaunch] id %d has no res.items entry'):format(id))
        end
    elseif cmd == 'inject' then
        inject_gearswap()
        windower.add_to_chat(207, '[relaunch] injected names into GearSwap. Idle once, or //gs r if a set still fails.')
    else
        windower.add_to_chat(207, '[relaunch] commands: check <name> | show <id> | inject')
    end
end)
