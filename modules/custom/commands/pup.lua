-----------------------------------
-- func: pup
-- desc: Puppetmaster automaton quick-loadout manager. Save the full setup
--       (frame + head + all 12 attachments) of your deployed automaton to a
--       named slot, then swap to it instantly from anywhere -- no Automaton
--       Trunk trip, no menu drag-and-drop.
--
-- Usage:
--   !pup                 - open the loadout menu (click a set to apply it)
--   !pup save <name>     - save the CURRENT (deployed) automaton to <name>
--   !pup load <name>     - apply a saved loadout (auto-dismisses the automaton)
--   !pup list            - list your saved loadouts
--   !pup show            - show your deployed automaton's current parts
--   !pup clear <name>    - delete a saved loadout
--
-- Names: one word, letters/numbers, up to 10 chars (e.g. tank, nuke, rngacc).
-- 5 slots per character. Pure Lua (charVar storage) -- no rebuild.
--
-- Engine constraints this works around:
--   * Attachments can only be CHANGED while the automaton is put away, so
--     "load" auto-dismisses it; you just re-deploy after.
--   * Attachments can only be READ off a DEPLOYED automaton, so "save"
--     requires it to be out.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'ss',
}

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_1

local NUM_SLOTS = 5
local NUM_ATT   = 12       -- attachment slots 0..11
local ATT_CLEAR = 0x2100   -- setAttachment(0x2100, slot) clears a slot (id - 0x2100 = 0)

local FRAME_NAME =
{
    [0x20] = 'Harlequin', [0x21] = 'Valoredge', [0x22] = 'Sharpshot', [0x23] = 'Stormwaker',
}

local HEAD_NAME =
{
    [0x01] = 'Harlequin', [0x02] = 'Valoredge', [0x03] = 'Sharpshot',
    [0x04] = 'Stormwaker', [0x05] = 'Soulsoother', [0x06] = 'Spiritreaver',
}

-----------------------------------
-- Free-form name <-> integer codec.
-- charVars are integer-only, so we pack a sanitized name (a-z0-9, <=10 chars)
-- into two int32s: base-37 with symbol 0 = terminator, 1..36 = the charset.
-- 5 chars/int (37^5 = 69,343,957 < 2^31), so 2 ints hold 10 chars.
-----------------------------------
local NAME_CHARS = 'abcdefghijklmnopqrstuvwxyz0123456789'

local function sanitizeName(name)
    return (name or ''):lower():gsub('[^a-z0-9]', ''):sub(1, 10)
end

local function packChunk(s) -- up to 5 chars -> int
    local n = 0
    for i = #s, 1, -1 do
        n = n * 37 + (NAME_CHARS:find(s:sub(i, i), 1, true) or 0)
    end
    return n
end

local function unpackChunk(n) -- int -> up to 5 chars
    local s = ''
    for _ = 1, 5 do
        local sym = n % 37
        if sym == 0 then break end
        s = s .. NAME_CHARS:sub(sym, sym)
        n = math.floor(n / 37)
    end
    return s
end

-----------------------------------
-- charVar slot storage. Per slot N: frame, head, a0..a11, n1, n2.
-- frame == 0 means the slot is empty.
-----------------------------------
local function key(n, suffix)
    return string.format('pupLd%d%s', n, suffix)
end

local function slotFrame(player, n)
    return player:getCharVar(key(n, 'fr')) or 0
end

local function readSlot(player, n)
    local frame = slotFrame(player, n)
    if frame == 0 then
        return nil
    end

    local set = { slot = n, frame = frame, head = player:getCharVar(key(n, 'hd')) or 0, att = {} }
    for i = 0, NUM_ATT - 1 do
        set.att[i] = player:getCharVar(key(n, 'a' .. i)) or 0
    end
    set.name = unpackChunk(player:getCharVar(key(n, 'n1')) or 0)
            .. unpackChunk(player:getCharVar(key(n, 'n2')) or 0)
    return set
end

local function writeSlot(player, n, frame, head, att, name)
    player:setCharVar(key(n, 'fr'), frame)
    player:setCharVar(key(n, 'hd'), head)
    for i = 0, NUM_ATT - 1 do
        player:setCharVar(key(n, 'a' .. i), att[i] or 0)
    end
    player:setCharVar(key(n, 'n1'), packChunk(name:sub(1, 5)))
    player:setCharVar(key(n, 'n2'), packChunk(name:sub(6, 10)))
end

local function clearSlot(player, n)
    player:setCharVar(key(n, 'fr'), 0)
    player:setCharVar(key(n, 'hd'), 0)
    for i = 0, NUM_ATT - 1 do
        player:setCharVar(key(n, 'a' .. i), 0)
    end
    player:setCharVar(key(n, 'n1'), 0)
    player:setCharVar(key(n, 'n2'), 0)
end

local function findSlotByName(player, name)
    for n = 1, NUM_SLOTS do
        local set = readSlot(player, n)
        if set and set.name == name then
            return n, set
        end
    end
    return nil
end

local function firstEmptySlot(player)
    for n = 1, NUM_SLOTS do
        if slotFrame(player, n) == 0 then
            return n
        end
    end
    return nil
end

-----------------------------------
-- Helpers
-----------------------------------
local function isPup(player)
    return player:getMainJob() == xi.job.PUP or player:getSubJob() == xi.job.PUP
end

local function getAutomaton(player)
    local pet = player:getPet()
    if pet and pet:isAutomaton() then
        return pet
    end
    return nil
end

local function describe(set)
    return string.format('%s / %s', HEAD_NAME[set.head] or '?', FRAME_NAME[set.frame] or '?')
end

-----------------------------------
-- Actions
-----------------------------------
local function doSave(player, name)
    local pet = getAutomaton(player)
    if not pet then
        player:printToPlayer('Deploy your automaton with the setup you want, then !pup save <name>.', H)
        return
    end

    name = sanitizeName(name)
    if name == '' then
        player:printToPlayer('Name it: !pup save tank   (one word, letters/numbers, up to 10).', H)
        return
    end

    local frame = player:getAutomatonFrame()
    local head  = player:getAutomatonHead()
    if not frame or not head then
        player:printToPlayer('Could not read your automaton frame/head.', H)
        return
    end

    local equipped = pet:getAttachments() or {}
    local att = {}
    for i = 0, NUM_ATT - 1 do
        local item = equipped[i]
        att[i] = item and item:getID() or 0
    end

    local n = findSlotByName(player, name) or firstEmptySlot(player)
    if not n then
        player:printToPlayer('All 5 loadout slots are full. Reuse a name, or !pup clear <name> first.', H)
        return
    end

    writeSlot(player, n, frame, head, att, name)
    player:printToPlayer(string.format('Saved automaton loadout "%s"  [%s]  to slot %d.',
        name, describe({ head = head, frame = frame }), n), H)
end

local function doLoad(player, name)
    name = sanitizeName(name)
    local _, set = findSlotByName(player, name)
    if not set then
        player:printToPlayer(string.format('No loadout named "%s". Try !pup list.', name), H)
        return
    end

    -- Parts can only be changed with the automaton put away.
    if getAutomaton(player) then
        player:despawnPet()
    end

    player:setAutomatonFrame(set.frame)
    player:setAutomatonHead(set.head)

    local skipped = 0
    for i = 0, NUM_ATT - 1 do
        local id = set.att[i] or 0
        if id == 0 then
            player:setAttachment(ATT_CLEAR, i)
        elseif player:hasAttachment(id) then
            player:setAttachment(id, i)
        else
            player:setAttachment(ATT_CLEAR, i) -- never grant an attachment they no longer own
            skipped = skipped + 1
        end
    end

    local note = skipped > 0
        and string.format('  (%d attachment(s) you no longer own were left empty)', skipped)
        or ''
    player:printToPlayer(string.format('Loadout "%s" applied: %s.%s  Deploy your automaton!',
        name, describe(set), note), H)
end

local function doClear(player, name)
    name = sanitizeName(name)
    local n = findSlotByName(player, name)
    if not n then
        player:printToPlayer(string.format('No loadout named "%s".', name), H)
        return
    end
    clearSlot(player, n)
    player:printToPlayer(string.format('Cleared loadout "%s".', name), H)
end

local function doList(player)
    player:printToPlayer('[Automaton] == Saved Loadouts ==', H)
    local any = false
    for n = 1, NUM_SLOTS do
        local set = readSlot(player, n)
        if set then
            any = true
            player:printToPlayer(string.format('  %-10s  %s', set.name, describe(set)), B)
        end
    end
    if not any then
        player:printToPlayer('  (none yet -- deploy a setup, then !pup save <name>)', B)
    end
    player:printToPlayer('  !pup load <name> | save <name> | clear <name> | show | (no arg = menu)', B)
end

local function doShow(player)
    local pet = getAutomaton(player)
    if not pet then
        player:printToPlayer('Deploy your automaton first to see its current parts.', H)
        return
    end

    local frame = player:getAutomatonFrame() or 0
    local head  = player:getAutomatonHead() or 0
    player:printToPlayer('[Automaton] == Current ==', H)
    player:printToPlayer(string.format('  Frame: %s    Head: %s',
        FRAME_NAME[frame] or '?', HEAD_NAME[head] or '?'), B)

    local equipped = pet:getAttachments() or {}
    local shown = false
    for i = 0, NUM_ATT - 1 do
        local item = equipped[i]
        if item then
            shown = true
            player:printToPlayer(string.format('  [%2d] %s', i + 1, item:getName()), B)
        end
    end
    if not shown then
        player:printToPlayer('  (no attachments equipped)', B)
    end
end

local function openMenu(player)
    local options = {}
    for n = 1, NUM_SLOTS do
        local set = readSlot(player, n)
        if set then
            local label = string.format('%s  (%s/%s)', set.name,
                (HEAD_NAME[set.head] or '?'):sub(1, 4), (FRAME_NAME[set.frame] or '?'):sub(1, 4))
            table.insert(options, { label, function(p) doLoad(p, set.name) end })
        end
    end

    if #options == 0 then
        table.insert(options, { 'No loadouts yet', function(p)
            p:printToPlayer('Deploy a setup, then !pup save <name>.', H)
        end })
    end

    table.insert(options, { 'Show current parts', function(p) doShow(p) end })
    table.insert(options, { 'Close', function() end })

    player:customMenu({ title = 'Automaton Loadouts', options = options })
end

-----------------------------------
commandObj.onTrigger = function(player, sub, name)
    if not isPup(player) then
        player:printToPlayer('Set Puppetmaster as your main or support job to manage automaton loadouts.', H)
        return
    end

    sub = sub and sub:lower() or nil

    if sub == nil then
        openMenu(player)
    elseif sub == 'save' then
        doSave(player, name)
    elseif sub == 'load' or sub == 'l' then
        doLoad(player, name)
    elseif sub == 'list' or sub == 'ls' then
        doList(player)
    elseif sub == 'show' or sub == 'current' then
        doShow(player)
    elseif sub == 'clear' or sub == 'delete' or sub == 'del' then
        doClear(player, name)
    else
        player:printToPlayer('Usage: !pup (menu) | save <name> | load <name> | list | show | clear <name>', H)
    end
end

return commandObj
