--[[
* AugmentTrade — Ashita v4
* Clickable Arcane Augmenter bank + inventory trade UI.
*
* Toggle: /at   or   /augmenttrade
* Same server commands as the Windower addon (!catalysts / !augment).
--]]

addon.name      = 'augment_trade'
addon.author    = 'Eren{Legendary}'
addon.version   = '1.0.7'
addon.desc      = 'Arcane Augmenter bank + inventory trade UI.'
addon.commands  = { '/augmenttrade', '/at' }

require('common')
local chat  = require('chat')
local imgui = require('imgui')
local itemdata_ok, itemdata = pcall(require, 'ffxi.itemdata')

local function load_data(name)
    local path = addon.path:gsub('[/\\]+$', '') .. '/data/' .. name .. '.lua'
    local chunk, err = loadfile(path)
    if not chunk then
        error('augment_trade missing ' .. path .. ': ' .. tostring(err))
    end
    return chunk()
end

local catalog    = load_data('catalog')
local cats       = load_data('categories')
local bank_names = load_data('bank_names')
local MAX_CAT    = #cats

local RANK_NAMES = { [0]='Unranked', [1]='Initiate', [2]='Adept',
                     [3]='Magus',    [4]='Sage',      [5]='Archon' }
local MASTMULT   = { 1.00, 1.20, 1.40, 1.60, 1.80, 2.00 }
local CRITPCT    = { 0.05, 0.10, 0.15, 0.20, 0.25, 0.30 }
local TIER_SLICES = {
    { min =  0, max =  5 },
    { min =  6, max = 11 },
    { min = 12, max = 17 },
    { min = 18, max = 24 },
    { min = 25, max = 31 },
}
local MAX_SLOTS = 5
local TRADE_RANGE = 6
local AUGMENTER_ZONE = 44
local AUGMENTER_ID   = 16959491

local NON_AUGMENTABLE = {
    [18987]=true,[19007]=true,[19076]=true,[19096]=true,
    [19628]=true,[19726]=true,[19835]=true,[19964]=true,
    [21262]=true,[21263]=true,[21268]=true,[22141]=true,
}

local SLOT_NAMES = {
    [0]='Main',[1]='Sub',[2]='Range',[3]='Ammo',[4]='Head',[5]='Body',
    [6]='Hands',[7]='Legs',[8]='Feet',[9]='Neck',[10]='Waist',
    [11]='L.Ear',[12]='R.Ear',[13]='L.Ring',[14]='R.Ring',[15]='Back',
}

local visible   = { false }
local search_q  = { '' }
local cur_tab   = 'gear'
local info = { rank=0, tier=1, count=0, aff=0, hl_tier=1, prestige=0, rebirths=0, gauntlet=0 }
local inv  = {}
local bank = {}
local bank_buf = {}
local bank_listen = false
local bank_parse = {}
local gear_rows = {}
local cat_rows = {}
local bag_leftover = 0
local sorted = {}
local name_to_id = {}
local f_cat   = 0
local f_owned = { false }
local f_avail = { false }
local f_slot  = 'all'
local f_sort  = 'name'
local sel_cats = {}
local sel_gear = 0
local sel_slot = 0
local last_inv = 0
local last_range = 0
local last_near = false
local pending_confirm = nil
local LOCK_MASK_BYTE = 13

local function say(msg)
    print(chat.header('AugmentTrade'):append(chat.message(msg)))
end

local function input_line(line)
    AshitaCore:GetChatManager():QueueCommand(1, line)
end

local function has_bit(n, b)
    n = tonumber(n) or 0
    return math.floor(n / (2 ^ b)) % 2 == 1
end

local name_cache = {}

local function item_res(id)
    local ok, res = pcall(function()
        return AshitaCore:GetResourceManager():GetItemById(id)
    end)
    if ok then
        return res
    end
    return nil
end

local function i18n_text(field)
    if field == nil then
        return nil
    end
    if type(field) == 'string' then
        return field ~= '' and field or nil
    end
    local ok, s = pcall(function()
        return field[1]
    end)
    if ok and type(s) == 'string' and s ~= '' then
        return s
    end
    return nil
end

local function item_name(id)
    id = tonumber(id)
    if not id then
        return 'Item ?'
    end
    local cached = name_cache[id]
    if cached then
        return cached
    end
    local res = item_res(id)
    local n = res and (i18n_text(res.Name) or i18n_text(res.LogNameSingular))
    if not n and catalog[id] then
        n = catalog[id].label
    end
    n = n or ('Item ' .. id)
    name_cache[id] = n
    return n
end

local function extra_string(it)
    if not it then
        return ''
    end
    local extra = it.Extra
    return type(extra) == 'string' and extra or ''
end

local function lock_mask_of(it)
    local extra = extra_string(it)
    if #extra >= LOCK_MASK_BYTE then
        return bit.band(string.byte(extra, LOCK_MASK_BYTE) or 0, 0x1F)
    end
    return 0
end

local function read_inv_augs(it)
    local out = {}
    if itemdata_ok and itemdata and itemdata.parse_augments and it then
        local ok, parsed = pcall(itemdata.parse_augments, it, item_res(it.Id))
        if ok and type(parsed) == 'table' then
            for _, a in ipairs(parsed) do
                if type(a) == 'table' and (tonumber(a.index) or 0) > 0 then
                    out[#out + 1] = a
                end
            end
        end
    end
    return out
end

local function item_slots(id)
    local res = item_res(id)
    if not res then
        return 0
    end
    return tonumber(res.Slots) or 0
end

local function gear_kind(id)
    local slots = item_slots(id)
    for bit = 0, 15 do
        if has_bit(slots, bit) then
            return SLOT_NAMES[bit] or ''
        end
    end
    if id == 12415 then
        return 'Shield'
    end
    if id == 15899 then
        return 'Waist'
    end
    return ''
end

local function cat_name(n)
    return cats[n] and cats[n].name or ('Cat ' .. n)
end

local function is_catalog_catalyst(id)
    return id and id > 0 and catalog[id] ~= nil
end

-- DAT holes: Slots=0 (and sometimes Type=0) on real equip the moogle accepts.
local DAT_SLOT0_EQUIP = {
    [12415] = true, -- Shell Shield
    [15899] = true, -- Velocious Belt
}

local function is_equipment(id)
    if not id or id <= 0 or is_catalog_catalyst(id) or NON_AUGMENTABLE[id] then
        return false
    end
    if DAT_SLOT0_EQUIP[id] then
        return true
    end
    if item_slots(id) > 0 then
        return true
    end

    -- Older armor can report Slots=0 in the DAT while still being valid
    -- equipment. Type 4 = weapon, 5 = armor. Flags bit 0x0800 = can-equip.
    local res = item_res(id)
    local typ = res and tonumber(res.Type) or 0
    if typ == 4 or typ == 5 then
        return true
    end
    local flags = res and tonumber(res.Flags) or 0
    return bit.band(flags, 0x0800) ~= 0
end

local function inventory_qty(id)
    return inv[id] or 0
end

local function clear_sel_gear()
    sel_gear = 0
    sel_slot = 0
end

local function has_sel_gear()
    return sel_gear > 0 and sel_slot > 0
end

local function gear_token()
    return string.format('%d@%d', sel_gear, sel_slot)
end

local function equipped_inv_slots()
    local slots = {}
    local invMgr = AshitaCore:GetMemoryManager():GetInventory()
    for eq = 0, 15 do
        local ok, eitem = pcall(function()
            return invMgr:GetEquippedItem(eq)
        end)
        if ok and eitem and tonumber(eitem.Index) and eitem.Index ~= 0 then
            local container = math.floor(bit.band(eitem.Index, 0xFF00) / 0x0100)
            local index = bit.band(eitem.Index, 0x00FF)
            if container == 0 and index > 0 and index <= 80 then
                slots[index] = true
            end
        end
    end
    return slots
end

local function catalyst_qty(id)
    return bank[id] or 0
end

local function has_maat()
    return inventory_qty(15194) > 0 or inventory_qty(29000) > 0
end

local function norm_name(s)
    return (tostring(s or ''):lower():gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function build_name_index()
    name_to_id = {}
    for id, _ in pairs(catalog) do
        name_to_id[norm_name(item_name(id))] = id
        name_to_id[norm_name(catalog[id].label)] = id
        if bank_names[id] then
            name_to_id[norm_name(bank_names[id])] = id
        end
    end
end

local function resolve_cat_name(name)
    return name_to_id[norm_name(name)]
end

local function scale_roll(raw, boost_cap, tier, rank)
    boost_cap = math.max(0, math.min(31, boost_cap or 31))
    local scaled = math.floor(raw * boost_cap / 31 + 0.5)
    local true_max = (tier or 0) >= 5 and (rank or 0) >= 5
    if not true_max and boost_cap > 0 then
        local cap = math.floor(boost_cap * 0.80)
        if cap >= boost_cap then
            cap = boost_cap - 1
        end
        scaled = math.min(scaled, math.max(0, cap))
    end
    return math.max(0, scaled)
end

local function shown_val(base, boost, mult, disp)
    mult = (mult and mult > 1) and mult or 1
    disp = (disp and disp > 1) and disp or 1
    return math.floor((base + boost) * mult / disp + 0.5)
end

local function predict_range(id)
    local e = catalog[id]
    if not e then
        return nil, nil
    end
    local rank = info.rank or 0
    local tier = info.tier or 1
    if tier < 1 then
        tier = 1
    end
    local base = e.base or 1
    local mult = e.mult or 1
    local disp = e.disp or 1
    if e.flatValue then
        local v = shown_val(base, e.flatValue - base, mult, disp)
        return v, v
    end
    if e.tierValue then
        local raw = e.tierValue * tier
        if not ((tier >= 5) and (rank >= 5)) then
            raw = math.min(raw, math.floor(e.tierValue * 5 * 0.80))
        end
        local v = shown_val(base, raw - base, mult, disp)
        return v, v
    end
    local boost_cap = e.maxBoost and math.min(31, e.maxBoost) or 31
    if boost_cap <= 0 then
        local v = shown_val(base, 0, mult, disp)
        return v, v
    end
    local slice = TIER_SLICES[tier] or TIER_SLICES[1]
    local floor = math.min(slice.min + rank, slice.max)
    local lo = shown_val(base, scale_roll(floor, boost_cap, tier, rank), mult, disp)
    local hi = shown_val(base, scale_roll(slice.max, boost_cap, tier, rank), mult, disp)
    if lo > hi then
        lo, hi = hi, lo
    end
    return lo, hi
end

local function pred_name(id)
    local e = catalog[id]
    local lo, hi = predict_range(id)
    if not e or not lo then
        return e and e.label or tostring(id)
    end
    if lo == hi then
        return string.format('%s +%s', e.label, lo)
    end
    return string.format('%s +%s to +%s', e.label, lo, hi)
end

local function matches_search(...)
    local q = tostring(search_q[1] or ''):lower()
    if q == '' then
        return true
    end
    for i = 1, select('#', ...) do
        local s = tostring(select(i, ...) or ''):lower()
        if s:find(q, 1, true) then
            return true
        end
    end
    return false
end

local function slot_group(kind)
    local k = tostring(kind or ''):lower()
    if k == 'main' or k == 'sub' or k == 'range' or k == 'ammo' or k == 'weapon' then
        return 'weapon'
    end
    if k == 'l.ear' or k == 'r.ear' or k == 'l.ring' or k == 'r.ring'
        or k == 'ear' or k == 'ring' or k == 'neck' or k == 'waist' or k == 'back' then
        return 'acc'
    end
    return k
end

local function filter_gear(list)
    local out = {}
    for _, e in ipairs(list) do
        if matches_search(e.name, e.id, e.kind) then
            if f_slot == 'all' or slot_group(e.kind) == f_slot then
                out[#out + 1] = e
            end
        end
    end
    if f_sort == 'slot' then
        table.sort(out, function(a, b)
            if (a.kind or '') == (b.kind or '') then
                return a.name:lower() < b.name:lower()
            end
            return (a.kind or '') < (b.kind or '')
        end)
    else
        table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
    end
    return out
end

local function filter_cats(list)
    local out = {}
    for _, e in ipairs(list) do
        if (f_cat == 0 or e.cat == f_cat)
            and (not f_owned[1] or e.count > 0)
            and (not f_avail[1] or e.tier <= info.rank)
            and matches_search(e.name, e.item, e.id, cat_name(e.cat)) then
            out[#out + 1] = e
        end
    end
    return out
end

local function sel_total_slots()
    local n = 0
    for _, s in ipairs(sel_cats) do
        n = n + s.qty
    end
    return n
end

local function sel_find(id)
    for i, s in ipairs(sel_cats) do
        if s.id == id then
            return i
        end
    end
    return nil
end

local function selected_qty(id)
    local idx = sel_find(id)
    return idx and sel_cats[idx].qty or 0
end

local function prune_selection()
    if not has_sel_gear() then
        return
    end
    for _, e in ipairs(gear_rows) do
        if e.id == sel_gear and e.slot == sel_slot and not e.equipped then
            return
        end
    end
    clear_sel_gear()
end

local function rebuild_rows()
    gear_rows = {}
    cat_rows = {}
    local worn = equipped_inv_slots()
    local invMgr = AshitaCore:GetMemoryManager():GetInventory()
    for s = 1, 80 do
        local it = invMgr:GetContainerItem(0, s)
        if it and it.Id and it.Id > 0 and it.Id < 65535 and is_equipment(it.Id) then
            gear_rows[#gear_rows + 1] = {
                slot = s,
                id = it.Id,
                count = it.Count or 1,
                name = item_name(it.Id),
                kind = gear_kind(it.Id),
                augs = read_inv_augs(it),
                lock_mask = lock_mask_of(it),
                equipped = worn[s] and true or false,
            }
        end
    end
    for id, qty in pairs(bank) do
        id = tonumber(id)
        qty = tonumber(qty) or 0
        if id and qty > 0 and is_catalog_catalyst(id) then
            local e = catalog[id]
            cat_rows[#cat_rows + 1] = {
                id = id, count = qty,
                name = e.label or item_name(id),
                item = bank_names[id] or item_name(id),
                cat = e.cat, tier = e.tier,
            }
        end
    end
    table.sort(cat_rows, function(a, b)
        if a.tier ~= b.tier then
            return a.tier < b.tier
        end
        return a.name:lower() < b.name:lower()
    end)
end

local function update_inventory()
    inv = {}
    bag_leftover = 0
    local invMgr = AshitaCore:GetMemoryManager():GetInventory()
    for s = 1, 80 do
        local it = invMgr:GetContainerItem(0, s)
        if it and it.Id and it.Id > 0 and it.Id < 65535 then
            inv[it.Id] = (inv[it.Id] or 0) + (it.Count or 1)
            if is_catalog_catalyst(it.Id) then
                bag_leftover = bag_leftover + (it.Count or 1)
            end
        end
    end
    rebuild_rows()
    prune_selection()
end

local function player_index()
    local ok, idx = pcall(function()
        return AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0)
    end)
    if ok then
        return idx
    end
    return 0
end

local function player_zone()
    local ok, zone = pcall(function()
        return AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0)
    end)
    if ok then
        return zone
    end
    return 0
end

local function entity_xyz(index)
    local ok, ent = pcall(GetEntity, index)
    if not ok or not ent then
        return nil
    end
    if ent.Movement and ent.Movement.LocalPosition then
        local p = ent.Movement.LocalPosition
        return p.X, p.Z, p.Y
    end
    if ent.X then
        return ent.X, ent.Z, ent.Y
    end
    return nil
end

local function is_augmenter_name(name)
    if type(name) ~= 'string' or name == '' then
        return false
    end
    local n = name:gsub('^[\128-\255]+', ''):gsub('_', ' ')
    return n:find('Arcane Augment', 1, true) ~= nil or n == 'Augment Moogle'
end

local function yalm_distance_to(index)
    local mx, my, mz = entity_xyz(player_index())
    local x, y, z = entity_xyz(index)
    if not mx or not x then
        return nil
    end
    local dx, dy, dz = mx - x, my - y, mz - z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function augmenter_index()
    local zone = player_zone()
    if zone ~= 0 and zone ~= AUGMENTER_ZONE then
        return nil
    end
    for i = 0, 2302 do
        local ok, ent = pcall(GetEntity, i)
        if ok and ent then
            local sid = tonumber(ent.ServerId) or 0
            local name = ent.Name
            if sid == AUGMENTER_ID or is_augmenter_name(name) then
                return i
            end
        end
    end
    return nil
end

local function near_augmenter()
    local idx = augmenter_index()
    if not idx then
        return false
    end
    local dist = yalm_distance_to(idx)
    return dist ~= nil and dist <= TRADE_RANGE
end

local function selected_gear_row()
    if not has_sel_gear() then
        return nil
    end
    for _, e in ipairs(gear_rows) do
        if e.id == sel_gear and e.slot == sel_slot then
            return e
        end
    end
    return nil
end

local function selected_aug_state()
    local row = selected_gear_row()
    if not row then
        return 0, 0, false
    end
    local augs = row.augs or {}
    local mask = tonumber(row.lock_mask) or 0
    local locked = 0
    for i = 0, 4 do
        if bit.band(mask, bit.lshift(1, i)) ~= 0 then
            locked = locked + 1
        end
    end
    return #augs, locked, mask == 0x1F or locked >= MAX_SLOTS
end

local function validate_trade()
    update_inventory()
    if not near_augmenter() then
        return false, 'You must be within 6 yalms of the Arcane Augment.'
    end
    if not has_sel_gear() then
        return false, 'No gear set.'
    end
    local row = selected_gear_row()
    if not row then
        return false, 'Gear is not in inventory (bag only; not wardrobe/satchel).'
    end
    if row.equipped then
        return false, 'Unequip that piece first.'
    end
    if not is_equipment(sel_gear) then
        return false, 'That ID is not augmentable gear.'
    end
    if #sel_cats == 0 then
        return false, 'No catalysts selected.'
    end
    local slots = 0
    for _, s in ipairs(sel_cats) do
        if not is_catalog_catalyst(s.id) then
            return false, 'Catalyst ' .. s.id .. ' is not in the augment catalog.'
        end
        local need = s.qty or 0
        if need < 1 then
            return false, 'Invalid catalyst quantity.'
        end
        if catalyst_qty(s.id) < need then
            local label = catalog[s.id].label or ('item ' .. s.id)
            return false, string.format('Need %dx %s stored at the Arcane Augmenter (have %d).', need, label, catalyst_qty(s.id))
        end
        slots = slots + need
    end
    if slots > MAX_SLOTS then
        return false, string.format('Max %d catalyst slots.', MAX_SLOTS)
    end
    local augn, locked, full = selected_aug_state()
    if full then
        return false, 'This piece is fully crystalized. Use Scour (25,000 gil) to strip it first.'
    end
    if locked + slots > MAX_SLOTS then
        return false, string.format(
            'This piece has %d crystalized slot%s -- only %d free. Use Scour (25,000 gil) to free them.',
            locked, locked == 1 and '' or 's', MAX_SLOTS - locked)
    end
    return true, nil
end

local function pick_catalyst(id, qty, quiet)
    update_inventory()
    id  = tonumber(id)
    qty = math.max(1, tonumber(qty) or 1)
    if not id or id <= 0 then
        if not quiet then
            say('Click a stored catalyst, or /at pick <id>')
        end
        return
    end
    if not is_catalog_catalyst(id) then
        say(id .. ' is not a catalog catalyst. Command not sent.')
        return
    end
    local e = catalog[id]
    if e.tier > info.rank then
        say((e.label or id) .. ' is locked until rank ' .. e.tier .. '.')
        return
    end
    if catalyst_qty(id) < selected_qty(id) + qty then
        say(string.format('Only %d %s stored at the Arcane Augmenter.', catalyst_qty(id), e.label or tostring(id)))
        return
    end
    if sel_total_slots() + qty > MAX_SLOTS then
        say(string.format('Only %d slots remain.', MAX_SLOTS - sel_total_slots()))
        return
    end
    local idx = sel_find(id)
    if idx then
        sel_cats[idx].qty = sel_cats[idx].qty + qty
    else
        sel_cats[#sel_cats + 1] = { id = id, qty = qty }
    end
    if not quiet then
        say('Added ' .. qty .. 'x ' .. (e.label or id) .. '.')
    end
end

local function unpick_one(id)
    local idx = sel_find(id)
    if not idx then
        return
    end
    if sel_cats[idx].qty > 1 then
        sel_cats[idx].qty = sel_cats[idx].qty - 1
    else
        table.remove(sel_cats, idx)
    end
end

local function choose_gear(id, toggle, slot)
    update_inventory()
    if type(id) == 'string' then
        local tid, tslot = id:match('^(%d+)@(%d+)$')
        if tid then
            id, slot = tonumber(tid), tonumber(tslot)
        else
            id = tonumber(id)
        end
    else
        id = tonumber(id)
    end
    slot = tonumber(slot)
    if not id or id <= 0 then
        return
    end
    if not is_equipment(id) then
        say('That ID is not augmentable gear.')
        return
    end
    if not slot then
        local free
        for _, e in ipairs(gear_rows) do
            if e.id == id and not e.equipped then
                if free then
                    say('You have more than one unequipped copy. Click the specific row.')
                    return
                end
                free = e
            end
        end
        if not free then
            if inventory_qty(id) > 0 then
                say('Unequip that piece first.')
            else
                say('That item is not in inventory.')
            end
            return
        end
        slot = free.slot
    end
    local row
    for _, e in ipairs(gear_rows) do
        if e.id == id and e.slot == slot then
            row = e
            break
        end
    end
    if not row then
        say('That item is not in inventory.')
        return
    end
    if row.equipped then
        say('Unequip that piece first.')
        return
    end
    if toggle and sel_gear == id and sel_slot == slot then
        clear_sel_gear()
    else
        sel_gear = id
        sel_slot = slot
    end
end

local function do_trade(use_maat, skip_confirm)
    local ok, reason = validate_trade()
    if not ok then
        say(reason .. ' Command not sent.')
        return
    end
    local augn, locked = selected_aug_state()
    if use_maat and (locked + sel_total_slots()) ~= MAX_SLOTS then
        say("Maat's Cap needs five slots in total (crystalized + new).")
        return
    end
    if use_maat and not has_maat() then
        say("You do not have Maat's Cap in inventory.")
        return
    end
    if augn > 0 and not skip_confirm then
        pending_confirm = { kind = 'overwrite', maat = use_maat and true or false }
        return
    end
    local parts = { gear_token() }
    for _, s in ipairs(sel_cats) do
        parts[#parts + 1] = s.id .. ':' .. s.qty
    end
    if use_maat then
        parts[#parts + 1] = 'maat'
    end
    if augn > 0 then
        parts[#parts + 1] = 'confirm'
    end
    local cmd = '!augment ' .. table.concat(parts, ' ')
    say('Sending: ' .. cmd)
    input_line(cmd)
    pending_confirm = nil
    sel_cats = {}
    clear_sel_gear()
end

local function do_scour(skip_confirm)
    update_inventory()
    if not near_augmenter() then
        say('You must be within 6 yalms of the Arcane Augment. Command not sent.')
        return
    end
    if not has_sel_gear() then
        say('Select a gear piece first. Command not sent.')
        return
    end
    local row = selected_gear_row()
    if not row then
        say('Gear is not in inventory (bag only; not wardrobe/satchel). Command not sent.')
        return
    end
    if row.equipped then
        say('Unequip that piece first. Command not sent.')
        return
    end
    local augn, locked = selected_aug_state()
    if augn == 0 and locked == 0 then
        say('That piece has no augments to scour. Command not sent.')
        return
    end
    if not skip_confirm then
        pending_confirm = { kind = 'scour' }
        return
    end
    local cmd = '!scour ' .. gear_token() .. ' confirm'
    say('Sending: ' .. cmd)
    input_line(cmd)
    pending_confirm = nil
    sel_cats = {}
    clear_sel_gear()
end

local function build_sorted()
    sorted = {}
    for id, e in pairs(catalog) do
        sorted[#sorted + 1] = { id = id, label = e.label, cat = e.cat, tier = e.tier }
    end
    table.sort(sorted, function(a, b)
        if a.tier ~= b.tier then return a.tier < b.tier end
        if a.cat  ~= b.cat  then return a.cat  < b.cat  end
        return a.label < b.label
    end)
end

local function send_auginfo()
    input_line('!catalysts')
end

local function apply_augbank(clean)
    local p, n, rest = clean:match('%[AUGBANK%]p=(%d+),n=(%d+),?(.*)')
    if not p then
        return false
    end
    p, n = tonumber(p), tonumber(n)
    bank_buf[p] = rest or ''
    for i = 1, n do
        if bank_buf[i] == nil then
            return true
        end
    end
    local merged = {}
    for i = 1, n do
        for token in (bank_buf[i] or ''):gmatch('[^,]+') do
            local id, qty = token:match('^(%d+):(%d+)$')
            if id then
                merged[tonumber(id)] = tonumber(qty)
            end
        end
    end
    local got = 0
    for _ in pairs(merged) do
        got = got + 1
    end
    if got > 0 or (n == 1 and (bank_buf[1] or '') == '') then
        bank = merged
        rebuild_rows()
    end
    bank_buf = {}
    return true
end

local function apply_bank_parse()
    local got = 0
    for _ in pairs(bank_parse) do
        got = got + 1
    end
    bank_listen = false
    if got > 0 then
        bank = bank_parse
        rebuild_rows()
    elseif visible[1] then
        say('Bank list did not parse. Keeping the last known store.')
    end
    bank_parse = {}
end

local function strip_chat(msg)
    msg = tostring(msg or '')
    msg = msg:gsub('\x1E.', ''):gsub('\x1F.', ''):gsub('\x7F.', '')
    msg = msg:gsub('^%[%d%d?:%d%d:%d%d%]%s*', '')
    return msg
end

local function rgb(r, g, b, a)
    return { r / 255, g / 255, b / 255, a or 1 }
end

local GOLD = rgb(212, 177, 90)
local INK = rgb(246, 239, 216)
local MUTE = rgb(154, 146, 128)
local GREEN = rgb(115, 204, 115)
local WARN = rgb(230, 115, 90)

local function pad(s, n)
    s = tostring(s or '')
    if #s > n then
        return s:sub(1, math.max(1, n - 2)) .. '..'
    end
    return s .. string.rep(' ', n - #s)
end

local function chip(label, on)
    if on then
        imgui.PushStyleColor(ImGuiCol_Button, rgb(52, 44, 24))
        imgui.PushStyleColor(ImGuiCol_Text, GOLD)
    end
    local clicked = imgui.Button(label)
    if on then
        imgui.PopStyleColor(2)
    end
    return clicked
end

local THEME = {
    { ImGuiCol_Text, INK },
    { ImGuiCol_TextDisabled, MUTE },
    { ImGuiCol_WindowBg, rgb(20, 22, 28, 0.96) },
    { ImGuiCol_ChildBg, rgb(12, 13, 17, 0.95) },
    { ImGuiCol_Border, rgb(74, 64, 42) },
    { ImGuiCol_FrameBg, rgb(16, 18, 24) },
    { ImGuiCol_FrameBgHovered, rgb(42, 36, 22) },
    { ImGuiCol_TitleBg, rgb(11, 12, 16) },
    { ImGuiCol_TitleBgActive, rgb(11, 12, 16) },
    { ImGuiCol_Tab, rgb(28, 31, 40) },
    { ImGuiCol_TabHovered, rgb(42, 36, 22) },
    { ImGuiCol_TabSelected or ImGuiCol_TabActive or ImGuiCol_Tab, rgb(36, 32, 22) },
    { ImGuiCol_Button, rgb(28, 31, 40) },
    { ImGuiCol_ButtonHovered, rgb(42, 36, 22) },
    { ImGuiCol_ButtonActive, rgb(68, 58, 30) },
    { ImGuiCol_Header, rgb(52, 44, 24, 0.90) },
    { ImGuiCol_HeaderHovered, rgb(62, 54, 30, 0.95) },
    { ImGuiCol_HeaderActive, rgb(68, 58, 30) },
    { ImGuiCol_Separator, rgb(74, 64, 42, 0.70) },
    { ImGuiCol_ScrollbarBg, rgb(11, 12, 16) },
    { ImGuiCol_ScrollbarGrab, rgb(74, 64, 42) },
    { ImGuiCol_CheckMark, GOLD },
}

local function push_theme()
    for _, c in ipairs(THEME) do
        imgui.PushStyleColor(c[1], c[2])
    end
    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 6)
    imgui.PushStyleVar(ImGuiStyleVar_ChildRounding, 4)
    imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, 4)
    imgui.PushStyleVar(ImGuiStyleVar_TabRounding, 4)
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1)
    imgui.PushStyleVar(ImGuiStyleVar_ChildBorderSize, 1)
end

local function pop_theme()
    imgui.PopStyleVar(6)
    imgui.PopStyleColor(#THEME)
end

local function draw_window()
    if not visible[1] then
        return
    end

    local now = os.clock()
    if now - last_inv > 0.8 then
        last_inv = now
        update_inventory()
    end
    if now - last_range > 0.4 then
        last_range = now
        last_near = near_augmenter()
    end

    imgui.SetNextWindowSize({ 1080, 680 }, ImGuiCond_FirstUseEver)
    push_theme()

    local ok, err = pcall(function()
    if imgui.Begin('Augment Trade##relaunch', visible) then
        local r = info.rank or 0
        imgui.TextColored(GOLD, 'Augment Trade')
        imgui.SameLine()
        imgui.TextColored(MUTE, '  Eren{Legendary}')
        imgui.SameLine()
        imgui.TextColored(MUTE, string.format('   Rank %s   Tier %d   Mastery %.2fx   Crit %.0f%%',
            RANK_NAMES[r] or '?', info.tier or 1, MASTMULT[r + 1] or 1, (CRITPCT[r + 1] or 0.05) * 100))
        if last_near then
            imgui.SameLine()
            imgui.TextColored(GREEN, '   Near Augmenter')
        else
            imgui.SameLine()
            imgui.TextColored(WARN, '   Walk to Arcane Augment (6 yalms)')
        end

        imgui.Separator()
        imgui.SetNextItemWidth(360)
        imgui.InputText('##at_search', search_q, 48)
        imgui.SameLine()
        if imgui.Button('  Refresh  ') then
            update_inventory()
            send_auginfo()
            say('Asking the Arcane Augmenter for your stored catalysts...')
        end

        imgui.Columns(2, '##at_cols', true)
        imgui.SetColumnWidth(0, 680)

        if imgui.BeginTabBar('##at_tabs') then
            if imgui.BeginTabItem('     Gear     ') then
                cur_tab = 'gear'
                imgui.TextColored(GOLD, 'INVENTORY GEAR')
                imgui.SameLine()
                imgui.TextColored(MUTE, '  bag only')
                imgui.Dummy({ 1, 2 })
                if chip('  All  ', f_slot == 'all') then f_slot = 'all' end
                imgui.SameLine()
                if chip('  Wep  ', f_slot == 'weapon') then f_slot = 'weapon' end
                imgui.SameLine()
                if chip('  Head  ', f_slot == 'head') then f_slot = 'head' end
                imgui.SameLine()
                if chip('  Body  ', f_slot == 'body') then f_slot = 'body' end
                imgui.SameLine()
                if chip('  Hands  ', f_slot == 'hands') then f_slot = 'hands' end
                imgui.SameLine()
                if chip('  Legs  ', f_slot == 'legs') then f_slot = 'legs' end
                imgui.SameLine()
                if chip('  Feet  ', f_slot == 'feet') then f_slot = 'feet' end
                imgui.SameLine()
                if chip('  Acc  ', f_slot == 'acc') then f_slot = 'acc' end

                imgui.TextColored(MUTE, pad('ITEM', 28) .. '  ' .. pad('SLOT', 8))
                imgui.BeginChild('##at_gear', { 0, -8 }, ImGuiChildFlags_Borders)
                local shown = filter_gear(gear_rows)
                for _, e in ipairs(shown) do
                    local kind = e.equipped and 'eq' or (e.kind or '')
                    local label = string.format('%s  %s##g%d_%d',
                        pad(e.name, 28), pad(kind, 8), e.id, e.slot)
                    if e.equipped then
                        imgui.TextColored(MUTE, label:gsub('##.*', ''))
                        if imgui.IsItemHovered() and imgui.SetTooltip then
                            imgui.SetTooltip('Unequip this piece before augmenting.')
                        end
                    else
                        if imgui.Selectable(label, sel_gear == e.id and sel_slot == e.slot, ImGuiSelectableFlags_AllowDoubleClick) then
                            choose_gear(e.id, false, e.slot)
                        end
                        if imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0) then
                            cur_tab = 'cats'
                        end
                    end
                end
                if #shown == 0 then
                    imgui.TextColored(MUTE, 'No augmentable gear in inventory.')
                end
                imgui.EndChild()
                imgui.EndTabItem()
            end

            if imgui.BeginTabItem('   Catalysts   ') then
                cur_tab = 'cats'
                imgui.TextColored(GOLD, 'ARCANE AUGMENTER BANK')
                imgui.Dummy({ 1, 2 })
                if chip('  All  ', f_cat == 0) then f_cat = 0 end
                for i = 1, MAX_CAT do
                    imgui.SameLine()
                    if chip('  ' .. (cats[i] and cats[i].name:sub(1, 6) or i) .. '  ', f_cat == i) then
                        f_cat = i
                    end
                end
                imgui.Checkbox('Owned', f_owned)
                imgui.SameLine()
                imgui.Checkbox('Unlocked', f_avail)

                imgui.TextColored(MUTE, pad('AUGMENT', 22) .. '  ' .. pad('CATALYST', 20) .. '  QTY')
                imgui.BeginChild('##at_cats', { 0, -8 }, ImGuiChildFlags_Borders)
                local shown = filter_cats(cat_rows)
                for _, e in ipairs(shown) do
                    local picked = selected_qty(e.id)
                    local lock = e.tier > info.rank
                    local tag = lock and 'lock' or (picked > 0 and ('+' .. picked) or cat_name(e.cat))
                    local label = string.format('%s  %s  x%d  %s##c%d',
                        pad(e.name, 22), pad(e.item or '', 20), e.count, tag, e.id)
                    if lock then
                        imgui.TextColored(MUTE, label:gsub('##.*', ''))
                    elseif imgui.Selectable(label, picked > 0) then
                        if imgui.GetIO().KeyShift or imgui.IsMouseClicked(1) then
                            unpick_one(e.id)
                        else
                            pick_catalyst(e.id, 1, true)
                        end
                    end
                    if imgui.IsItemClicked(1) then
                        unpick_one(e.id)
                    end
                end
                if #shown == 0 then
                    imgui.TextColored(MUTE, 'Bank is empty. Stand by the Augmenter and press Refresh.')
                end
                imgui.EndChild()
                imgui.EndTabItem()
            end
            imgui.EndTabBar()
        end

        imgui.NextColumn()
        imgui.TextColored(GOLD, 'TRADE TRAY')
        local g = selected_gear_row()
        if g then
            imgui.TextColored(INK, string.format('%s', g.name))
            imgui.TextColored(MUTE, string.format('[%s]', g.kind))
        else
            imgui.TextColored(MUTE, 'Click a piece on the left')
        end
        imgui.Separator()
        imgui.TextColored(MUTE, string.format('Catalysts  %d / %d slots', sel_total_slots(), MAX_SLOTS))
        for i, s in ipairs(sel_cats) do
            local e = catalog[s.id]
            if imgui.Selectable(string.format('%dx  %s##t%d', s.qty, pred_name(s.id), i), false) then
                unpick_one(s.id)
            end
            if e then
                imgui.TextColored(MUTE, '    ' .. (e.label or '') .. '  ' .. cat_name(e.cat))
            end
        end
        if #sel_cats == 0 then
            imgui.TextColored(MUTE, 'Click a stored catalyst to add.\nRight-click to remove.')
        end
        imgui.Dummy({ 1, 14 })
        if pending_confirm then
            if pending_confirm.kind == 'scour' then
                imgui.TextColored(WARN, 'This will STRIP every augment, including crystalized.')
                imgui.TextColored(MUTE, 'Cost 25,000 gil. The piece comes back blank.')
            else
                imgui.TextColored(GOLD, 'This will overwrite the current augment.')
                imgui.TextColored(MUTE, 'Crystalized lines stay locked. Continue?')
            end
            imgui.Dummy({ 1, 6 })
            imgui.PushStyleColor(ImGuiCol_Button, rgb(68, 58, 30))
            imgui.PushStyleColor(ImGuiCol_ButtonHovered, rgb(212, 177, 90, 0.45))
            imgui.PushStyleColor(ImGuiCol_Text, GOLD)
            if imgui.Button('  Continue  ', { 140, 36 }) then
                local kind = pending_confirm.kind
                local maat = pending_confirm.maat
                pending_confirm = nil
                if kind == 'scour' then
                    do_scour(true)
                else
                    do_trade(maat, true)
                end
            end
            imgui.PopStyleColor(3)
            imgui.SameLine()
            if imgui.Button('  Cancel  ', { 110, 36 }) then
                pending_confirm = nil
            end
        else
            imgui.PushStyleColor(ImGuiCol_Button, rgb(68, 58, 30))
            imgui.PushStyleColor(ImGuiCol_ButtonHovered, rgb(212, 177, 90, 0.45))
            imgui.PushStyleColor(ImGuiCol_Text, GOLD)
            if imgui.Button('      Trade      ', { 168, 36 }) then
                do_trade(false)
            end
            imgui.PopStyleColor(3)
            imgui.SameLine()
            if imgui.Button('    + Maat    ', { 120, 36 }) then
                do_trade(true)
            end
            imgui.SameLine()
            imgui.PushStyleColor(ImGuiCol_Button, rgb(140, 64, 54, 0.85))
            imgui.PushStyleColor(ImGuiCol_ButtonHovered, rgb(170, 80, 70))
            if imgui.Button('   Clear   ', { 90, 36 }) then
                pending_confirm = nil
                sel_cats = {}
                clear_sel_gear()
            end
            imgui.PopStyleColor(2)
            imgui.Dummy({ 1, 6 })
            local augn, locked = selected_aug_state()
            local can_scour = has_sel_gear() and (augn > 0 or locked > 0)
            imgui.PushStyleColor(ImGuiCol_Button, rgb(140, 64, 54, 0.85))
            imgui.PushStyleColor(ImGuiCol_ButtonHovered, rgb(170, 80, 70))
            imgui.PushStyleColor(ImGuiCol_Text, INK)
            if imgui.Button('  Scour (25,000 gil)  ', { 220, 32 }) then
                if can_scour then
                    do_scour(false)
                else
                    say('Select an augmented piece first.')
                end
            end
            imgui.PopStyleColor(3)
            if can_scour then
                imgui.TextColored(MUTE, 'Scour strips crystalized lines too. Trade overwrites unlocked lines only.')
            end
        end
        imgui.Dummy({ 1, 10 })
        imgui.TextColored(MUTE, 'Left-click unequipped gear to select. Equipped pieces must come off first. Double-click jumps to the bank.')
        if bag_leftover > 0 then
            imgui.TextColored(GOLD, string.format('%d catalyst(s) still in your bag — store them with the NPC first.', bag_leftover))
        end
        imgui.Columns(1)
    end
    end)
    imgui.End()
    pop_theme()
    if not ok then
        print(chat.header('augment_trade'):append(chat.error(tostring(err))))
    end
end

ashita.events.register('load', 'at_load', function()
    build_sorted()
    build_name_index()
    update_inventory()
    ashita.tasks.once(3, function()
        send_auginfo()
    end)
end)

ashita.events.register('d3d_present', 'at_draw', draw_window)

ashita.events.register('text_in', 'at_text', function(e)
    local clean = strip_chat(e.message_modified or e.message)
    local data = clean:match('%[AUGINFO%](.+)')
    if data then
        local rank = data:match('rank=(%d+)')
        local tier = data:match('tier=(%d+)')
        if rank then
            info.rank = tonumber(rank) or 0
        end
        if tier then
            info.tier = tonumber(tier) or 0
        end
        info.count    = tonumber(data:match('count=(%d+)'))    or info.count or 0
        info.aff      = tonumber(data:match('aff=(%d+)'))      or info.aff or 0
        info.hl_tier  = tonumber(data:match('hl=(%d+)'))       or info.hl_tier or 1
        info.prestige = tonumber(data:match('prestige=(%d+)')) or info.prestige or 0
        info.rebirths = tonumber(data:match('rebirths=(%d+)')) or info.rebirths or 0
        info.gauntlet = tonumber(data:match('gauntlet=(%d+)')) or info.gauntlet or 0
        e.blocked = true
        return
    end

    local sage_rank = clean:match('%[Augment Sage%] Rank:.-%((%d+)/5%)')
    if sage_rank then
        info.rank = tonumber(sage_rank) or info.rank
    end
    local aug_tier = clean:match('Augment Tier:%s*(%d+)/5')
    if aug_tier then
        info.tier = tonumber(aug_tier) or 0
    end

    if apply_augbank(clean) then
        e.blocked = true
        return
    end

    if clean:find('[Augment Bank]', 1, true) then
        if clean:find('no catalysts', 1, true) then
            bank = {}
            bank_listen = false
            bank_parse = {}
            rebuild_rows()
        else
            bank_listen = true
            bank_parse = {}
        end
        return
    end
    if bank_listen then
        if clean:find('Total catalysts stored', 1, true) then
            apply_bank_parse()
            return
        end
        local name, qty = clean:match('^%s*(.-)%s+x(%d+)%s*$')
        if name and qty then
            name = name:gsub('%s+$', ''):gsub('^%s+', '')
            if name ~= '' and not name:lower():find('total', 1, true) then
                local id = resolve_cat_name(name)
                if id then
                    bank_parse[id] = tonumber(qty)
                end
            end
        end
    end

    if clean:match('%[AUGDONE%]') then
        update_inventory()
        ashita.tasks.once(1, send_auginfo)
    end
end)

ashita.events.register('command', 'at_cmd', function(e)
    local args = e.command:args()
    if #args == 0 then
        return
    end
    local head = args[1]:lower()
    if head ~= '/at' and head ~= '/augmenttrade' then
        return
    end
    e.blocked = true

    local cmd = (args[2] or 'toggle'):lower()
    if cmd == 'toggle' or cmd == 't' then
        visible[1] = not visible[1]
        if visible[1] then
            update_inventory()
            send_auginfo()
        end
    elseif cmd == 'show' then
        visible[1] = true
        update_inventory()
        send_auginfo()
    elseif cmd == 'hide' then
        visible[1] = false
    elseif cmd == 'find' or cmd == 'search' then
        search_q[1] = table.concat(args, ' ', 3)
        visible[1] = true
        update_inventory()
    elseif cmd == 'gear' then
        choose_gear(args[3], true)
        visible[1] = true
    elseif cmd == 'pick' then
        pick_catalyst(args[3], args[4])
        visible[1] = true
    elseif cmd == 'unpick' then
        local id = tonumber(args[3])
        if id then
            local idx = sel_find(id)
            if idx then
                table.remove(sel_cats, idx)
            end
        else
            sel_cats = {}
        end
        visible[1] = true
    elseif cmd == 'clear' then
        sel_cats = {}
        clear_sel_gear()
        visible[1] = true
    elseif cmd == 'trade' then
        do_trade((args[3] or ''):lower() == 'maat')
    elseif cmd == 'scour' then
        do_scour(false)
    elseif cmd == 'sync' then
        update_inventory()
        send_auginfo()
        say('Syncing...')
    else
        visible[1] = not visible[1]
        if visible[1] then
            update_inventory()
            send_auginfo()
        end
    end
end)
