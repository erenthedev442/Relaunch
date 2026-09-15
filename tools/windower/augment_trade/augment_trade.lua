-----------------------------------
-- AugmentTrade — Windower 4 Addon
-- Clickable Arcane Augmenter bank + inventory trade UI.
--
-- Left-click gear / stored catalyst to select.
-- Right-click a catalyst to remove one.
-- Chat commands still work (//at or //augmenttrade).
-----------------------------------
_addon.name     = 'AugmentTrade'
_addon.version  = '5.4.2'
_addon.author   = 'Eren{Legendary}'
_addon.commands = {'augmenttrade', 'at'}

local texts      = require('texts')
local catalog    = require('data/catalog')
local cats       = require('data/categories')
local bank_names = require('data/bank_names')
local MAX_CAT    = #cats

local res_ok, resources = pcall(require, 'resources')
local res_items = (res_ok and resources and resources.items) or nil
local ext_ok, extdata = pcall(require, 'extdata')

-----------------------------------
-- Constants
-----------------------------------
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
local RANK_REQS  = {
    [1] = { title='Initiate', hlRank=2 },
    [2] = { title='Adept',    hlRank=3 },
    [3] = { title='Magus',    hlRank=5,  prestigeLevel=5,  rebirths=1  },
    [4] = { title='Sage',                prestigeLevel=15, rebirths=10 },
    [5] = { title='Archon',              prestigeLevel=30, rebirths=20, gauntletClears=1 },
}
local MAX_SLOTS = 5
local PAGE_SIZE = 8
local TRADE_RANGE = 6
local AUGMENTER_ZONE = 44 -- Abdhaljs Isle-Purgonorgo (Arcane Augment)
local AUGMENTER_ID   = 16959491 -- live Arcane Augment dynamic NPC

local NON_AUGMENTABLE = {
    [18987]=true,[19007]=true,[19076]=true,[19096]=true,
    [19628]=true,[19726]=true,[19835]=true,[19964]=true,
    [21262]=true,[21263]=true,[21268]=true,[22141]=true,
}

-----------------------------------
-- State
-----------------------------------
local visible   = false
local cur_tab   = 'gear'
local gear_page = 1
local cat_page  = 1

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

local f_tier  = 0
local f_cat   = 0
local f_owned = false
local f_avail = false
local f_slot  = 'all'
local f_sort  = 'name'

local sel_cats = {}
local sel_gear = 0
local sel_slot = 0
local search_q = ''
local search_focus = false
local shift_down = false
local last_click = { key = '', t = 0 }
local pending_confirm = nil
local LOCK_MASK_BYTE = 13

local DIK_CHAR = {
    [2]='1',[3]='2',[4]='3',[5]='4',[6]='5',[7]='6',[8]='7',[9]='8',[10]='9',[11]='0',
    [12]='-',[13]='=',
    [16]='q',[17]='w',[18]='e',[19]='r',[20]='t',[21]='y',[22]='u',[23]='i',[24]='o',[25]='p',
    [26]='[',[27]=']',[39]=';',[40]="'",[41]='`',[43]='\\',
    [30]='a',[31]='s',[32]='d',[33]='f',[34]='g',[35]='h',[36]='j',[37]='k',[38]='l',
    [44]='z',[45]='x',[46]='c',[47]='v',[48]='b',[49]='n',[50]='m',
    [51]=',',[52]='.',[53]='/',
}
local DIK_SHIFT = {
    [2]='!',[3]='@',[4]='#',[5]='$',[6]='%',[7]='^',[8]='&',[9]='*',[10]='(',[11]=')',
    [12]='_',[13]='+',
    [26]='{',[27]='}',[39]=':',[40]='"',[41]='~',[43]='|',
    [51]='<',[52]='>',[53]='?',
}

-----------------------------------
-- Theme — matches Legendary Launcher (App.xaml)
-----------------------------------
local FONT   = 'Segoe UI'
local TITLEF = 'Georgia'
local LISTF  = 'Consolas'
local ui = { x = 36, y = 22, w = 1520 }
local TITLE_H = 52
local TAB_H   = 40
local ROW_H   = 38
local PAD     = 18
local GAP     = 16
local LEFT_W  = 800
local MID_W   = 300
local RIGHT_W = 370
local BODY_TOP = TITLE_H + TAB_H + 8
local FOOT_H  = 96
local INSET   = 12
local SLOT_H  = 46
local SEARCH_H = 78
local TRAY_HEAD = 70
local TRAY_H  = TRAY_HEAD + MAX_SLOTS * SLOT_H + 18
local STAT_H  = 38
local FILTER_H = 84
local PANEL_H = BODY_TOP + 8 + 26 + SEARCH_H + FILTER_H + 26 + 22 + PAGE_SIZE * (ROW_H + 4) + 24 + FOOT_H
local CAT_SHORT = {
    [1]='Stat',[2]='Melee',[3]='Magic',[4]='Def',[5]='Delay',
    [6]='Dur',[7]='Pet',[8]='Pot',[9]='Skill',[10]='EXP',[11]='Job',
}
local SLOT_NAMES = {
    [0]='Main',[1]='Sub',[2]='Range',[3]='Ammo',[4]='Head',[5]='Body',
    [6]='Hands',[7]='Legs',[8]='Feet',[9]='Neck',[10]='Waist',
    [11]='L.Ear',[12]='R.Ear',[13]='L.Ring',[14]='R.Ring',[15]='Back',
}

local C = {
    ink     = { 246, 239, 216 },
    mute    = { 154, 146, 128 },
    gold    = { 212, 177, 90 },
    goldhot = { 240, 210, 122 },
    title   = { 11, 12, 16 },
    panel   = { 20, 22, 28 },
    btn     = { 28, 31, 40 },
    hover   = { 42, 36, 22 },
    press   = { 32, 28, 18 },
    tab_on  = { 36, 32, 22 },
    row     = { 16, 18, 24 },
    sel     = { 52, 44, 24 },
    gear    = { 52, 44, 24 },
    trade   = { 68, 58, 30 },
    maat    = { 42, 38, 30 },
    clear   = { 140, 64, 54 },
    locked  = { 42, 28, 26 },
    off     = { 16, 18, 24 },
    search  = { 16, 18, 24 },
    col     = { 16, 17, 22 },
    inner   = { 12, 13, 17 },
    frame   = { 74, 64, 42 },
    slot    = { 34, 36, 44 },
    slot_on = { 62, 54, 30 },
}

local PRIM = {
    shadow  = 'AugmentTrade_Shadow',
    border  = 'AugmentTrade_Border',
    bg      = 'AugmentTrade_BG',
    title   = 'AugmentTrade_Title',
    line    = 'AugmentTrade_Line',
    tabline = 'AugmentTrade_TabLine',
    col_l      = 'AugmentTrade_ColL',
    frame_m    = 'AugmentTrade_FrameM',
    box_m      = 'AugmentTrade_BoxM',
    frame_tray = 'AugmentTrade_FrameTray',
    box_tray   = 'AugmentTrade_BoxTray',
    frame_pred = 'AugmentTrade_FramePred',
    box_pred   = 'AugmentTrade_BoxPred',
}

for i = 1, PAGE_SIZE do
    PRIM['sel'..i] = 'AugmentTrade_Sel'..i
end

local widgets = {}
local ui_ready = false
local hover_key = nil
local pointer = nil
local drag = nil
local panel_h = 400

-----------------------------------
-- Utility
-----------------------------------
local function cat_name(n)
    return cats[n] and cats[n].name or ('Cat '..n)
end

local function cat_short(n)
    return CAT_SHORT[n] or cat_name(n)
end

local function pad(s, n)
    s = tostring(s or '')
    if #s > n then
        return s:sub(1, math.max(1, n - 2)) .. '..'
    end
    return s .. string.rep(' ', n - #s)
end

local function gear_kind(id)
    local it = res_items and res_items[id]
    if not it then
        return ''
    end
    if type(it.slots) == 'table' then
        local first
        for slot in pairs(it.slots) do
            slot = tonumber(slot) or slot
            local name = SLOT_NAMES[slot]
            if name and (not first or slot < first.id) then
                first = { id = slot, name = name }
            end
        end
        if first then
            return first.name
        end
    end
    return tostring(it.category or '')
end

local function lock_mask_of(it)
    if type(it) ~= 'table' then
        return 0
    end
    local extra = it.extdata
    if type(extra) == 'string' and extra:match('^%x+$') then
        local i = (LOCK_MASK_BYTE - 1) * 2 + 1
        if #extra >= i + 1 then
            return tonumber(extra:sub(i, i + 1), 16) or 0
        end
        return 0
    end
    if type(extra) == 'string' and #extra >= LOCK_MASK_BYTE then
        return bit.band(string.byte(extra, LOCK_MASK_BYTE) or 0, 0x1F)
    end
    return 0
end

local function read_augments(it)
    if not ext_ok or type(it) ~= 'table' then
        return {}
    end
    local ok, decoded = pcall(extdata.decode, it)
    if not ok or type(decoded) ~= 'table' or type(decoded.augments) ~= 'table' then
        return {}
    end
    local out = {}
    for _, a in ipairs(decoded.augments) do
        a = tostring(a or ''):gsub('^%s+', ''):gsub('%s+$', '')
        if a ~= '' and a:lower() ~= 'none' then
            out[#out + 1] = a
        end
    end
    return out
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

local function value_short(id)
    local lo, hi = predict_range(id)
    if not lo then
        return ''
    end
    if lo == hi then
        return string.format('+%s', lo)
    end
    return string.format('+%s-+%s', lo, hi)
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

local function aug_short(list)
    if not list or #list == 0 then
        return 'no augments yet'
    end
    local s = table.concat(list, ', ')
    if #s > 32 then
        return s:sub(1, 30) .. '..'
    end
    return s
end

local function matches_search(...)
    if search_q == '' then
        return true
    end
    local q = search_q:lower()
    for i = 1, select('#', ...) do
        local s = tostring(select(i, ...) or ''):lower()
        if s:find(q, 1, true) then
            return true
        end
    end
    return false
end

local function set_search(q)
    q = tostring(q or '')
    if q == search_q then
        return
    end
    search_q = q
    gear_page = 1
    cat_page = 1
end

local function search_label()
    local inner
    if search_q ~= '' then
        inner = search_q .. (search_focus and '_' or '')
    elseif search_focus then
        inner = '_'
    elseif cur_tab == 'cats' then
        inner = 'Search augment, catalyst, or category...'
    else
        inner = 'Search inventory gear...'
    end
    if #inner < 52 then
        inner = inner .. string.rep(' ', 52 - #inner)
    end
    return '  ' .. inner
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
        if matches_search(e.name, e.id, e.kind, table.concat(e.augs or {}, ' ')) then
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
    elseif f_sort == 'aug' then
        table.sort(out, function(a, b)
            local na, nb = #(a.augs or {}), #(b.augs or {})
            if na ~= nb then return na > nb end
            return a.name:lower() < b.name:lower()
        end)
    else
        table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
    end
    return out
end

local function filter_cats(list)
    local out = {}
    for _, e in ipairs(list) do
        if matches_search(e.name, e.item, e.id, cat_name(e.cat), cat_short(e.cat)) then
            out[#out + 1] = e
        end
    end
    return out
end

local function sel_total_slots()
    local n = 0
    for _, s in ipairs(sel_cats) do n = n + s.qty end
    return n
end

local function sel_find(id)
    for i, s in ipairs(sel_cats) do
        if s.id == id then return i end
    end
    return nil
end

local function is_catalog_catalyst(id)
    return id and id > 0 and catalog[id] ~= nil
end

local function inventory_qty(id)
    return inv[id] or 0
end

local function catalyst_qty(id)
    return bank[id] or 0
end

local function item_name(id)
    local it = res_items and res_items[id]
    if it then
        return it.en or it.enl or ('Item '..id)
    end
    if catalog[id] then
        return catalog[id].label
    end
    return 'Item '..id
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

-- DAT holes: empty slots (and category != Armor/Weapon) on real equip.
local DAT_SLOT0_EQUIP = {
    [12415] = true, -- Shell Shield (category is often "Shield", not "Armor")
    [15899] = true, -- Velocious Belt
}

local function is_equipment(id)
    if not id or id <= 0 or is_catalog_catalyst(id) or NON_AUGMENTABLE[id] then
        return false
    end
    if DAT_SLOT0_EQUIP[id] then
        return true
    end
    if res_items and res_items[id] then
        local it = res_items[id]
        if type(it.slots) == 'table' then
            for _ in pairs(it.slots) do
                return true
            end
        end
        local cat = tostring(it.category or ''):lower()
        if cat:find('weapon', 1, true) or cat:find('armor', 1, true)
            or cat:find('shield', 1, true) or cat:find('grip', 1, true) then
            return true
        end
        local typ = tonumber(it.type) or 0
        if typ == 4 or typ == 5 then
            return true
        end
        return false
    end
    return true
end

local function has_maat()
    return inventory_qty(15194) > 0 or inventory_qty(29000) > 0
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

local function equipped_inv_slots(bag)
    local slots = {}
    local items = windower.ffxi.get_items()
    local eq = items and items.equipment
    if type(eq) == 'table' then
        local names = {
            'main', 'sub', 'range', 'ammo', 'head', 'body', 'hands', 'legs', 'feet',
            'neck', 'waist', 'left_ear', 'right_ear', 'left_ring', 'right_ring', 'back',
        }
        for _, name in ipairs(names) do
            local idx = tonumber(eq[name]) or 0
            local bagId = tonumber(eq[name .. '_bag']) or 0
            if idx > 0 and bagId == 0 then
                slots[idx] = true
            end
        end
    end
    if type(bag) == 'table' then
        for s = 1, 80 do
            local it = bag[s]
            if type(it) == 'table' and (it.status == 5 or it.status == 19) then
                slots[s] = true
            end
        end
    end
    return slots
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
    local bags = windower.ffxi.get_items()
    local bag = bags and (bags[0] or bags.inventory)
    local worn = equipped_inv_slots(bag)
    if type(bag) == 'table' then
        for s = 1, 80 do
            local it = bag[s]
            if type(it) == 'table' and it.id and it.id > 0 and is_equipment(it.id) then
                gear_rows[#gear_rows+1] = {
                    slot = s, id = it.id, count = it.count or 1,
                    name = item_name(it.id),
                    kind = gear_kind(it.id),
                    augs = read_augments(it),
                    lock_mask = lock_mask_of(it),
                    equipped = worn[s] and true or false,
                }
            end
        end
    end

    for id, qty in pairs(bank) do
        id = tonumber(id)
        qty = tonumber(qty) or 0
        if id and qty > 0 and is_catalog_catalyst(id) then
            local e = catalog[id]
            cat_rows[#cat_rows+1] = {
                id = id, count = qty,
                name = e.label or item_name(id),
                item = bank_names[id] or item_name(id),
                cat = e.cat, tier = e.tier,
            }
        end
    end
    table.sort(cat_rows, function(a, b)
        if a.tier ~= b.tier then return a.tier < b.tier end
        return a.name:lower() < b.name:lower()
    end)
end

local function update_inventory()
    inv = {}
    bag_leftover = 0
    local bags = windower.ffxi.get_items()
    local bag = bags and (bags[0] or bags.inventory)
    if type(bag) == 'table' then
        for s = 1, 80 do
            local it = bag[s]
            if type(it) == 'table' and it.id and it.id > 0 then
                inv[it.id] = (inv[it.id] or 0) + (it.count or 1)
                if is_catalog_catalyst(it.id) then
                    bag_leftover = bag_leftover + (it.count or 1)
                end
            end
        end
    end
    rebuild_rows()
    prune_selection()
end

local function selected_qty(id)
    local idx = sel_find(id)
    return idx and sel_cats[idx].qty or 0
end

local function ready_catalysts()
    local ready = {}
    for _, e in ipairs(sorted) do
        if catalyst_qty(e.id) > 0 and e.tier <= info.rank then
            ready[#ready + 1] = e
        end
    end
    return ready
end

-- Client nametag is "Arcane Augment" (star icon + 15-char packet cap).
-- Windower may also report underscores, Augment_Moogle, or a blank/NPC name.
local function is_augmenter_name(name)
    if type(name) ~= 'string' or name == '' then
        return false
    end
    local n = name:gsub('^[\128-\255]+', ''):gsub('_', ' ')
    return n:find('Arcane Augment', 1, true) ~= nil or n == 'Augment Moogle'
end

local function is_augmenter_mob(mob)
    if type(mob) ~= 'table' then
        return false
    end
    if mob.valid == false or mob.valid == 0 then
        return false
    end
    if tonumber(mob.id) == AUGMENTER_ID then
        return true
    end
    return is_augmenter_name(mob.name)
end

-- Windower's mob.distance is squared yalms.
local function yalm_distance(mob)
    if type(mob) ~= 'table' then
        return nil
    end
    if type(mob.distance) == 'number' and mob.distance >= 0 then
        return math.sqrt(mob.distance)
    end
    local me = windower.ffxi.get_mob_by_target('me')
    if not me then
        return nil
    end
    local dx = (me.x or 0) - (mob.x or 0)
    local dy = (me.y or 0) - (mob.y or 0)
    local dz = (me.z or 0) - (mob.z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function augmenter_mob()
    local okId, byId = pcall(windower.ffxi.get_mob_by_id, AUGMENTER_ID)
    if okId and is_augmenter_mob(byId) then
        return byId
    end

    local ok, mobs = pcall(windower.ffxi.get_mob_array)
    if not ok or type(mobs) ~= 'table' then
        return nil
    end
    local best, bestDist
    for _, mob in pairs(mobs) do
        if is_augmenter_mob(mob) then
            local dist = yalm_distance(mob) or 1e9
            if not best or dist < bestDist then
                best, bestDist = mob, dist
            end
        end
    end
    return best
end

local function near_augmenter()
    local mob = augmenter_mob()
    if not mob then
        return false
    end
    local dist = yalm_distance(mob)
    return dist ~= nil and dist <= TRADE_RANGE
end

local function find_gear_row(id, slot)
    slot = tonumber(slot)
    for _, e in ipairs(gear_rows) do
        if e.id == id and (not slot or e.slot == slot) then
            return e
        end
    end
    return nil
end

local function gear_aug_state(id, slot)
    local row = find_gear_row(id, slot or sel_slot)
    local augs = row and row.augs or {}
    local mask = row and tonumber(row.lock_mask) or 0
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
    local row = find_gear_row(sel_gear, sel_slot)
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
    local augn, locked, full = gear_aug_state(sel_gear)
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
            windower.add_to_chat(207, '[AugmentTrade] Click a stored catalyst, or //at pick <id>')
        end
        return
    end
    if not is_catalog_catalyst(id) then
        windower.add_to_chat(207, '[AugmentTrade] ' .. id .. ' is not a catalog catalyst. Command not sent.')
        return
    end
    local e = catalog[id]
    if e.tier > info.rank then
        windower.add_to_chat(207, '[AugmentTrade] ' .. (e.label or id) .. ' is locked until rank ' .. e.tier .. '.')
        return
    end
    if catalyst_qty(id) < selected_qty(id) + qty then
        windower.add_to_chat(207, string.format(
            '[AugmentTrade] Only %d %s stored at the Arcane Augmenter.',
            catalyst_qty(id), e.label or tostring(id)))
        return
    end
    if sel_total_slots() + qty > MAX_SLOTS then
        windower.add_to_chat(207, string.format('[AugmentTrade] Only %d slots remain.', MAX_SLOTS - sel_total_slots()))
        return
    end
    local idx = sel_find(id)
    if idx then
        sel_cats[idx].qty = sel_cats[idx].qty + qty
    else
        sel_cats[#sel_cats + 1] = { id = id, qty = qty }
    end
    if not quiet then
        windower.add_to_chat(207, '[AugmentTrade] Added ' .. qty .. 'x ' .. (e.label or id) .. '.')
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
        windower.add_to_chat(207, '[AugmentTrade] That ID is not augmentable gear.')
        return
    end
    if not slot then
        local free
        for _, e in ipairs(gear_rows) do
            if e.id == id and not e.equipped then
                if free then
                    windower.add_to_chat(207, '[AugmentTrade] You have more than one unequipped copy. Click the specific row.')
                    return
                end
                free = e
            end
        end
        if not free then
            if inventory_qty(id) > 0 then
                windower.add_to_chat(207, '[AugmentTrade] Unequip that piece first.')
            else
                windower.add_to_chat(207, '[AugmentTrade] That item is not in inventory.')
            end
            return
        end
        slot = free.slot
    end
    local row = find_gear_row(id, slot)
    if not row then
        windower.add_to_chat(207, '[AugmentTrade] That item is not in inventory.')
        return
    end
    if row.equipped then
        windower.add_to_chat(207, '[AugmentTrade] Unequip that piece first.')
        return
    end
    if toggle and sel_gear == id and sel_slot == slot then
        clear_sel_gear()
    else
        sel_gear = id
        sel_slot = slot
    end
end

local function set_gear(id)
    choose_gear(id, true)
end

local function do_trade(use_maat, skip_confirm)
    local ok, reason = validate_trade()
    if not ok then
        windower.add_to_chat(207, '[AugmentTrade] ' .. reason .. ' Command not sent.')
        return
    end
    local augn, locked = gear_aug_state(sel_gear)
    if use_maat and (locked + sel_total_slots()) ~= MAX_SLOTS then
        windower.add_to_chat(207, "[AugmentTrade] Maat's Cap needs five slots in total (crystalized + new).")
        return
    end
    if use_maat and not has_maat() then
        windower.add_to_chat(207, "[AugmentTrade] You do not have Maat's Cap in inventory.")
        return
    end
    if augn > 0 and not skip_confirm then
        pending_confirm = { kind = 'overwrite', maat = use_maat and true or false }
        return
    end
    local parts = { gear_token() }
    for _, s in ipairs(sel_cats) do
        parts[#parts+1] = s.id .. ':' .. s.qty
    end
    if use_maat then
        parts[#parts+1] = 'maat'
    end
    if augn > 0 then
        parts[#parts+1] = 'confirm'
    end
    windower.add_to_chat(207, '[AugmentTrade] Sending: !augment ' .. table.concat(parts, ' '))
    windower.send_command('input !augment ' .. table.concat(parts, ' '))
    pending_confirm = nil
    sel_cats = {}
    clear_sel_gear()
end

local function do_scour(skip_confirm)
    update_inventory()
    if not near_augmenter() then
        windower.add_to_chat(207, '[AugmentTrade] You must be within 6 yalms of the Arcane Augment. Command not sent.')
        return
    end
    if not has_sel_gear() then
        windower.add_to_chat(207, '[AugmentTrade] Select a gear piece first. Command not sent.')
        return
    end
    local row = find_gear_row(sel_gear, sel_slot)
    if not row then
        windower.add_to_chat(207, '[AugmentTrade] Gear is not in inventory (bag only; not wardrobe/satchel). Command not sent.')
        return
    end
    if row.equipped then
        windower.add_to_chat(207, '[AugmentTrade] Unequip that piece first. Command not sent.')
        return
    end
    local augn, locked = gear_aug_state(sel_gear, sel_slot)
    if augn == 0 and locked == 0 then
        windower.add_to_chat(207, '[AugmentTrade] That piece has no augments to scour. Command not sent.')
        return
    end
    if not skip_confirm then
        pending_confirm = { kind = 'scour' }
        return
    end
    windower.add_to_chat(207, '[AugmentTrade] Sending: !scour ' .. gear_token() .. ' confirm')
    windower.send_command('input !scour ' .. gear_token() .. ' confirm')
    pending_confirm = nil
    sel_cats = {}
    clear_sel_gear()
end

local function build_sorted()
    sorted = {}
    for id, e in pairs(catalog) do
        sorted[#sorted+1] = { id=id, label=e.label, cat=e.cat, tier=e.tier }
    end
    table.sort(sorted, function(a,b)
        if a.tier ~= b.tier then return a.tier < b.tier end
        if a.cat  ~= b.cat  then return a.cat  < b.cat  end
        return a.label < b.label
    end)
end

local function filtered()
    local out = {}
    for _, e in ipairs(sorted) do
        if (f_tier == 0 or e.tier == f_tier) and
           (f_cat  == 0 or e.cat  == f_cat ) and
           (not f_owned or catalyst_qty(e.id) > 0) and
           (not f_avail or e.tier <= info.rank) then
            out[#out+1] = e
        end
    end
    return out
end

local function send_auginfo()
    -- Live bank list is !catalysts. !auginfo is optional (rank + [AUGBANK]);
    -- it is not registered on live yet and was wiping the list / printing an error.
    windower.send_command('input !catalysts')
end

-----------------------------------
-- Widget kit
-----------------------------------
local function paint_btn(w, rgb)
    if w and w.t then
        w.t:bg_color(rgb[1], rgb[2], rgb[3])
    end
end

local function make_text(label, size, bg, pad, font)
    return texts.new(label or ' ', {
        pos = { x = 0, y = 0 },
        text = {
            font = font or FONT, size = size or 16,
            red = C.ink[1], green = C.ink[2], blue = C.ink[3],
            stroke = { width = 2, alpha = 180, red = 8, green = 8, blue = 10 },
        },
        bg = {
            visible = bg ~= nil,
            alpha = 240,
            red = (bg and bg[1]) or 0,
            green = (bg and bg[2]) or 0,
            blue = (bg and bg[3]) or 0,
        },
        padding = pad or 8,
        flags = { draggable = false },
    })
end

local function add_label(key, size, font)
    local t = make_text(' ', size or 16, nil, 4, font)
    t:bg_visible(false)
    t:hide()
    widgets[key] = { kind = 'label', t = t }
    return widgets[key]
end

local function add_btn(key, label, idle, hover, size, pad, font)
    idle = idle or C.btn
    hover = hover or C.hover
    local t = make_text(label, size or 16, idle, pad or 10, font)
    t:hide()
    widgets[key] = {
        kind = 'btn', t = t, action = nil, id = nil, arg = nil,
        idle = idle, hover = hover, enabled = true,
    }
    return widgets[key]
end

local function place(key, x, y, label, show)
    local w = widgets[key]
    if not w then return end
    w.t:pos(ui.x + x, ui.y + y)
    if label then
        w.t:text(label)
    end
    if show == false then
        w.t:hide()
    else
        w.t:show()
    end
end

local function col_x(which)
    if which == 'mid' then
        return PAD + LEFT_W + GAP
    end
    if which == 'right' then
        return PAD + LEFT_W + GAP + MID_W + GAP
    end
    return PAD
end

local function place_search(x, y)
    widgets.search.t:color(search_q == '' and C.mute[1] or C.ink[1],
                           search_q == '' and C.mute[2] or C.ink[2],
                           search_q == '' and C.mute[3] or C.ink[3])
    paint_btn(widgets.search, search_focus and C.hover or C.search)
    place('search', x, y, search_label())
    place('search_clear', x + LEFT_W - 100, y, '  Clear  ')
end

local function hide_key(key)
    local w = widgets[key]
    if w then w.t:hide() end
end

local function prims_init()
    for _, name in pairs({ 'AugmentTrade_ColM', 'AugmentTrade_ColR' }) do
        pcall(windower.prim.delete, name)
    end
    for _, name in pairs(PRIM) do
        pcall(windower.prim.create, name)
        pcall(windower.prim.set_visibility, name, false)
    end
end

local function prims_hide()
    for _, name in pairs(PRIM) do
        pcall(windower.prim.set_visibility, name, false)
    end
end

local function ensure_ui()
    if ui_ready then
        return
    end
    prims_init()
    add_label('title', 22, TITLEF)
    add_label('subtitle', 14)
    add_label('credit', 12)
    add_btn('close', '   X   ', C.clear, { 160, 80, 70 }, 16, 8)
    widgets.close.action = 'hide'

    add_btn('help', '  ?  ', C.btn, C.hover, 14, 6)
    widgets.help.action = 'help'
    add_btn('tab_gear',   '     Gear     ', C.btn, C.hover, 15, 8)
    add_btn('tab_cats',   '   Catalysts   ', C.btn, C.hover, 15, 8)
    widgets.tab_gear.action   = 'tab'; widgets.tab_gear.arg   = 'gear'
    widgets.tab_cats.action   = 'tab'; widgets.tab_cats.arg   = 'cats'
    add_btn('sync', '  Refresh  ', C.btn, C.hover, 13, 6)
    widgets.sync.action = 'sync'

    add_btn('search', '  Search inventory gear...', C.search, C.hover, 14, 8)
    add_btn('search_clear', '  Clear  ', C.btn, C.hover, 13, 6)
    widgets.search.action = 'search_focus'
    widgets.search_clear.action = 'search_clear'

    add_label('section', 15)
    add_label('colhead', 12, LISTF)
    add_label('mid_title', 15)
    add_label('gear', 16)
    add_label('cats', 13)
    add_label('pred', 15)
    add_label('stats', 12)
    add_label('statrow', 13)
    add_label('result', 15)
    add_label('body', 13)
    add_label('page', 12)
    add_label('hint', 12)
    add_label('left', 12)
    add_label('empty', 13)
    add_label('foot', 11)
    add_btn('mid_clear', '  Clear  ', C.clear, { 170, 80, 70 }, 12, 6)
    widgets.mid_clear.action = 'clear_gear'
    add_btn('tray_clear', '  Clear All  ', C.clear, { 170, 80, 70 }, 12, 6)
    widgets.tray_clear.action = 'clear_tray'

    add_btn('trade', '      Trade      ', C.trade, C.goldhot, 18, 12)
    add_btn('maat',  '     + Maat     ', C.maat,  C.hover, 16, 10)
    add_btn('clear', '     Clear     ', C.clear, { 170, 80, 70 }, 16, 10)
    add_btn('scour', '     Scour     ', C.clear, { 170, 80, 70 }, 16, 10)
    widgets.trade.action = 'trade'
    widgets.maat.action  = 'maat'
    widgets.clear.action = 'clear'
    widgets.scour.action = 'scour'

    add_btn('prev', '   <   ', C.btn, C.hover, 14, 6)
    add_btn('next', '   >   ', C.btn, C.hover, 14, 6)
    widgets.prev.action = 'page'
    widgets.next.action = 'page'
    widgets.prev.arg = -1
    widgets.next.arg = 1

    add_btn('f_tier',  '  All  ', C.btn, C.hover, 12, 6)
    add_btn('f_owned', ' Weapons ', C.btn, C.hover, 12, 6)
    add_btn('f_avail', '  Head  ', C.btn, C.hover, 12, 6)
    add_btn('f_cat',   '  Body  ', C.btn, C.hover, 12, 6)
    add_btn('f_hands', ' Hands ', C.btn, C.hover, 12, 6)
    add_btn('f_legs',  '  Legs  ', C.btn, C.hover, 12, 6)
    add_btn('f_feet',  '  Feet  ', C.btn, C.hover, 12, 6)
    add_btn('f_acc',   '  Acc  ', C.btn, C.hover, 12, 6)
    add_btn('f_sort',  '  Sort  ', C.btn, C.hover, 12, 6)
    widgets.f_tier.action  = 'set_filter'; widgets.f_tier.arg  = 'all'
    widgets.f_owned.action = 'set_filter'; widgets.f_owned.arg = 'weapon'
    widgets.f_avail.action = 'set_filter'; widgets.f_avail.arg = 'head'
    widgets.f_cat.action   = 'set_filter'; widgets.f_cat.arg   = 'body'
    widgets.f_hands.action = 'set_filter'; widgets.f_hands.arg = 'hands'
    widgets.f_legs.action  = 'set_filter'; widgets.f_legs.arg  = 'legs'
    widgets.f_feet.action  = 'set_filter'; widgets.f_feet.arg  = 'feet'
    widgets.f_acc.action   = 'set_filter'; widgets.f_acc.arg   = 'acc'
    widgets.f_sort.action  = 'cycle_sort'

    for i = 1, 5 do
        add_btn('chip'..i, '  ', C.slot, C.hover, 14, 10, LISTF)
        widgets['chip'..i].action = 'unpick'
    end

    for i = 1, PAGE_SIZE do
        add_btn('row'..i, ' ', C.row, C.hover, 13, 8, LISTF)
    end

    ui_ready = true
end

local function hide_all_widgets()
    for _, w in pairs(widgets) do
        w.t:hide()
    end
    prims_hide()
end

local function set_btn_state(key, enabled, idle)
    local w = widgets[key]
    if not w then return end
    w.enabled = enabled and true or false
    w.idle = idle or w.idle
    paint_btn(w, w.enabled and w.idle or C.off)
    if not w.enabled then
        w.t:color(C.mute[1], C.mute[2], C.mute[3])
    else
        w.t:color(C.ink[1], C.ink[2], C.ink[3])
    end
end

local function fill_prim(name, x, y, w, h, rgb, a)
    pcall(windower.prim.set_color, name, a or 248, rgb[1], rgb[2], rgb[3])
    pcall(windower.prim.set_position, name, x, y)
    pcall(windower.prim.set_size, name, w, h)
    pcall(windower.prim.set_visibility, name, true)
end

local function fill_box(frame, box, x, y, w, h)
    fill_prim(frame, ui.x + x - 1, ui.y + y - 1, w + 2, h + 2, C.frame, 255)
    fill_prim(box, ui.x + x, ui.y + y, w, h, C.inner, 242)
end

local function layout_panel(height)
    panel_h = height
    fill_prim(PRIM.shadow, ui.x + 4, ui.y + 5, ui.w, height, { 0, 0, 0 }, 130)
    fill_prim(PRIM.border, ui.x - 1, ui.y - 1, ui.w + 2, height + 2, { 58, 51, 36 }, 255)
    fill_prim(PRIM.bg, ui.x, ui.y, ui.w, height, C.panel, 236)
    fill_prim(PRIM.title, ui.x, ui.y, ui.w, TITLE_H, C.title, 250)
    fill_prim(PRIM.line, ui.x, ui.y + TITLE_H, ui.w, 2, C.gold, 255)

    local y = ui.y + BODY_TOP
    local h = height - BODY_TOP - FOOT_H
    fill_prim(PRIM.col_l, ui.x + col_x('left'), y, LEFT_W, h, C.col, 230)
end

local function layout_chrome()
    local r = info.rank
    widgets.title.t:color(C.gold[1], C.gold[2], C.gold[3])
    place('title', PAD, 8, 'Augment Trade')
    widgets.credit.t:color(110, 103, 88)
    place('credit', PAD, 32, 'Eren{Legendary}')
    widgets.subtitle.t:color(C.mute[1], C.mute[2], C.mute[3])
    place('subtitle', 320, 16, string.format('Rank  %s     Tier  %d     Mastery  %.2fx     Crit  %.0f%%',
        RANK_NAMES[r] or '?', info.tier or 1, MASTMULT[r+1] or 1, (CRITPCT[r+1] or 0.05)*100))
    place('help', ui.w - 132, 10, '  ?  ')
    place('close', ui.w - 76, 10, '   X   ')

    local tabs = {
        { 'tab_gear', 'gear', '     Gear     ' },
        { 'tab_cats', 'cats', '   Catalysts   ' },
    }
    local tx = PAD
    local underline_x = PAD
    for _, row in ipairs(tabs) do
        local key, name, label = row[1], row[2], row[3]
        local on = cur_tab == name
        set_btn_state(key, true, on and C.tab_on or C.btn)
        widgets[key].t:color(on and C.gold[1] or C.mute[1], on and C.gold[2] or C.mute[2], on and C.gold[3] or C.mute[3])
        place(key, tx, TITLE_H + 6, label)
        if on then underline_x = tx end
        tx = tx + 150
    end
    fill_prim(PRIM.tabline, ui.x + underline_x + 10, ui.y + TITLE_H + TAB_H - 4, 120, 3, C.gold, 255)
    if cur_tab == 'cats' then
        place('sync', PAD + 310, TITLE_H + 6, '  Refresh  ')
    else
        hide_key('sync')
    end
end

local function hide_rows()
    for i = 1, PAGE_SIZE do
        hide_key('row'..i)
        widgets['row'..i].action = nil
        widgets['row'..i].id = nil
        widgets['row'..i].slot = nil
        widgets['row'..i].enabled = false
        pcall(windower.prim.set_visibility, PRIM['sel'..i], false)
    end
end

local function fill_row(i, x, y, label, action, id, idle, enabled, slot)
    local key = 'row'..i
    local w = widgets[key]
    w.action = enabled and action or nil
    w.id = id
    w.slot = slot
    w.enabled = enabled and true or false
    w.idle = idle or C.row
    w.hover = C.hover
    paint_btn(w, w.idle)
    local selected = idle == C.sel or idle == C.gear
    if not enabled then
        w.t:color(C.mute[1], C.mute[2], C.mute[3])
    elseif selected then
        w.t:color(C.gold[1], C.gold[2], C.gold[3])
    else
        w.t:color(C.ink[1], C.ink[2], C.ink[3])
    end
    place(key, x, y, label)
    if selected then
        fill_prim(PRIM['sel'..i], ui.x + x - 2, ui.y + y, 3, ROW_H, C.gold, 255)
    else
        pcall(windower.prim.set_visibility, PRIM['sel'..i], false)
    end
end

local function page_slice(list, page)
    local total = #list
    local pages = math.max(1, math.ceil(math.max(total, 1) / PAGE_SIZE))
    page = math.min(math.max(1, page), pages)
    local first = (page - 1) * PAGE_SIZE + 1
    local last = math.min(first + PAGE_SIZE - 1, total)
    return page, pages, first, last, total
end

local function selected_gear_row()
    if not has_sel_gear() then return nil end
    for _, e in ipairs(gear_rows) do
        if e.id == sel_gear and e.slot == sel_slot then return e end
    end
    return nil
end

local function flat_slots()
    local flat = {}
    for _, s in ipairs(sel_cats) do
        for _ = 1, s.qty do
            flat[#flat + 1] = s.id
        end
    end
    return flat
end

local function gold(key)
    local w = widgets[key]
    if w then w.t:color(C.gold[1], C.gold[2], C.gold[3]) end
end

local function mute(key)
    local w = widgets[key]
    if w then w.t:color(C.mute[1], C.mute[2], C.mute[3]) end
end

local function ink(key)
    local w = widgets[key]
    if w then w.t:color(C.ink[1], C.ink[2], C.ink[3]) end
end

local function chip_filter(x, y, defs, current)
    local cx = x
    for _, row in ipairs(defs) do
        local key, id, label = row[1], row[2], row[3]
        local on = current == id
        set_btn_state(key, true, on and C.tab_on or C.btn)
        widgets[key].t:color(on and C.gold[1] or C.ink[1], on and C.gold[2] or C.ink[2], on and C.gold[3] or C.ink[3])
        place(key, cx, y, label)
        cx = cx + 88
    end
end

local function render_left()
    local x = col_x('left')
    local y = BODY_TOP + 8
    gold('section')
    if cur_tab == 'cats' then
        place('section', x + 8, y, 'INVENTORY  /  BANK')
    else
        place('section', x + 8, y, 'INVENTORY GEAR')
    end
    y = y + 26
    place_search(x + 6, y)
    y = y + SEARCH_H

    if cur_tab == 'cats' then
        widgets.f_tier.action = 'set_cat'; widgets.f_tier.arg = 0
        widgets.f_owned.action = 'set_cat'; widgets.f_owned.arg = 2
        widgets.f_avail.action = 'set_cat'; widgets.f_avail.arg = 3
        widgets.f_cat.action = 'set_cat'; widgets.f_cat.arg = 4
        widgets.f_hands.action = 'set_cat'; widgets.f_hands.arg = 7
        widgets.f_legs.action = 'set_cat'; widgets.f_legs.arg = 5
        widgets.f_feet.action = 'set_cat'; widgets.f_feet.arg = 6
        widgets.f_acc.action = 'set_cat'; widgets.f_acc.arg = 9
        chip_filter(x + 6, y, {
            { 'f_tier',  0, '  All  ' },
            { 'f_owned', 2, ' Melee ' },
            { 'f_avail', 3, ' Magic ' },
            { 'f_cat',   4, '  Def  ' },
            { 'f_hands', 7, '  Pet  ' },
        }, f_cat)
        chip_filter(x + 6, y + 42, {
            { 'f_legs', 5, ' Delay ' },
            { 'f_feet', 6, '  Dur  ' },
            { 'f_acc',  9, ' Skill ' },
        }, f_cat)
        hide_key('f_sort')
    else
        widgets.f_tier.action = 'set_filter'; widgets.f_tier.arg = 'all'
        widgets.f_owned.action = 'set_filter'; widgets.f_owned.arg = 'weapon'
        widgets.f_avail.action = 'set_filter'; widgets.f_avail.arg = 'head'
        widgets.f_cat.action = 'set_filter'; widgets.f_cat.arg = 'body'
        widgets.f_hands.action = 'set_filter'; widgets.f_hands.arg = 'hands'
        widgets.f_legs.action = 'set_filter'; widgets.f_legs.arg = 'legs'
        widgets.f_feet.action = 'set_filter'; widgets.f_feet.arg = 'feet'
        widgets.f_acc.action = 'set_filter'; widgets.f_acc.arg = 'acc'
        widgets.f_sort.action = 'cycle_sort'
        chip_filter(x + 6, y, {
            { 'f_tier',  'all',    '  All  ' },
            { 'f_owned', 'weapon', '  Wep  ' },
            { 'f_avail', 'head',   ' Head ' },
            { 'f_cat',   'body',   ' Body ' },
            { 'f_hands', 'hands',  ' Hands ' },
        }, f_slot)
        chip_filter(x + 6, y + 42, {
            { 'f_legs', 'legs', ' Legs ' },
            { 'f_feet', 'feet', ' Feet ' },
            { 'f_acc',  'acc',  '  Acc  ' },
        }, f_slot)
        local sort_lbl = f_sort == 'slot' and '  Slot  ' or (f_sort == 'aug' and '  Augs  ' or '  Name  ')
        set_btn_state('f_sort', true, C.btn)
        place('f_sort', x + 6 + 88 * 3, y + 42, sort_lbl)
    end
    y = y + FILTER_H

    local shown
    if cur_tab == 'cats' then
        shown = {}
        for _, e in ipairs(filter_cats(cat_rows)) do
            if f_cat == 0 or e.cat == f_cat then
                shown[#shown + 1] = e
            end
        end
    else
        shown = filter_gear(gear_rows)
    end

    local page_var = cur_tab == 'cats' and cat_page or gear_page
    local page, pages, first, last, total = page_slice(shown, page_var)
    if cur_tab == 'cats' then cat_page = page else gear_page = page end

    mute('page')
    place('page', x + 8, y, string.format('%d-%d of %d', total == 0 and 0 or first, last, total))
    set_btn_state('prev', page > 1, C.btn)
    set_btn_state('next', page < pages, C.btn)
    place('prev', x + LEFT_W - 92, y - 14, '  <  ')
    place('next', x + LEFT_W - 50, y - 14, '  >  ')
    y = y + 28

    mute('colhead')
    if cur_tab == 'cats' then
        place('colhead', x + 8, y, pad('AUGMENT', 20) .. '      ' .. pad('ROLL', 10) .. '      ' .. pad('CATALYST', 22) .. '      ' .. pad('QTY', 5) .. '      CAT')
    else
        place('colhead', x + 8, y, pad('ITEM', 24) .. '    ' .. pad('SLOT', 8) .. '    AUGMENTS')
    end
    y = y + 24
    hide_rows()

    if total == 0 then
        mute('empty')
        local msg
        if cur_tab == 'cats' then
            msg = search_q ~= '' and ('No bank match for "' .. search_q .. '"') or 'No stored catalysts. Click Refresh.'
            if bag_leftover > 0 then
                msg = msg .. string.format('\n%d still in your bag — trade those to the Augmenter.', bag_leftover)
            end
        else
            msg = search_q ~= '' and ('No gear match for "' .. search_q .. '"') or 'No augmentable gear in inventory.'
        end
        place('empty', x + 8, y, msg)
    else
        hide_key('empty')
        local ri = 0
        for i = first, last do
            ri = ri + 1
            local e = shown[i]
            if cur_tab == 'cats' then
                local locked = e.tier > info.rank
                local seln = selected_qty(e.id)
                local tag = locked and 'lock' or cat_short(e.cat)
                fill_row(ri, x + 8, y,
                    pad(e.name, 20) .. '      ' .. pad(value_short(e.id), 10) .. '      ' .. pad(e.item or '', 22) .. '      ' .. pad('x'..e.count, 5) .. '      ' .. tag,
                    locked and nil or 'pick', e.id,
                    locked and C.locked or (seln > 0 and C.sel or C.row), not locked)
            else
                local on = sel_gear == e.id and sel_slot == e.slot
                local kind = e.equipped and 'eq' or (e.kind or '')
                fill_row(ri, x + 8, y,
                    pad(e.name, 24) .. '    ' .. pad(kind, 8) .. '    ' .. aug_short(e.augs),
                    e.equipped and nil or 'gear', e.id,
                    on and C.gear or (e.equipped and C.locked or C.row),
                    not e.equipped, e.slot)
            end
            y = y + ROW_H + 4
        end
    end
end

local function render_mid()
    local x = col_x('mid')
    local y = BODY_TOP
    local h = panel_h - BODY_TOP - FOOT_H
    fill_box(PRIM.frame_m, PRIM.box_m, x, y, MID_W, h)

    gold('mid_title')
    place('mid_title', x + INSET, y + INSET, 'SELECTED ITEM')
    hide_key('mid_clear')
    local row = selected_gear_row()
    y = y + 40
    if not row then
        mute('gear')
        mute('cats')
        place('gear', x + INSET, y + 8, 'No item selected')
        place('cats', x + INSET, y + 36, 'Click a piece in the list.')
        hide_key('hint')
        hide_key('left')
        return
    end
    gold('gear')
    place('gear', x + INSET, y, row.name)
    y = y + 28
    mute('cats')
    place('cats', x + INSET, y, string.format('Slot   %s%s',
        row.kind ~= '' and row.kind or 'Gear',
        row.equipped and '  (equipped)' or ''))
    y = y + 32
    gold('hint')
    place('hint', x + INSET, y, 'CURRENT AUGMENTS')
    y = y + 22
    mute('left')
    if row.augs and #row.augs > 0 then
        local lines = {}
        for i = 1, math.min(8, #row.augs) do
            lines[#lines + 1] = row.augs[i]
        end
        if #row.augs > 8 then
            lines[#lines + 1] = '(and more...)'
        end
        place('left', x + INSET, y, table.concat(lines, '\n'))
    else
        place('left', x + INSET, y, 'No augments yet.')
    end
end

local function render_right()
    local x = col_x('right')
    local body_h = panel_h - BODY_TOP - FOOT_H
    local tray_y = BODY_TOP
    local pred_h = math.max(120, body_h - TRAY_H - STAT_H - GAP)
    local pred_y = tray_y + TRAY_H + STAT_H
    fill_box(PRIM.frame_tray, PRIM.box_tray, x, tray_y, RIGHT_W, TRAY_H)
    fill_box(PRIM.frame_pred, PRIM.box_pred, x, pred_y, RIGHT_W, pred_h)

    local used = sel_total_slots()
    local r = info.rank
    gold('pred')
    place('pred', x + INSET, tray_y + INSET, string.format('CATALYST TRAY  %d / %d', used, MAX_SLOTS))
    mute('stats')
    place('stats', x + INSET, tray_y + 38, 'Left-click add   ·   Right-click remove')
    hide_key('tray_clear')

    local flat = flat_slots()
    local cy = tray_y + TRAY_HEAD
    for i = 1, 5 do
        local id = flat[i]
        local w = widgets['chip'..i]
        if id then
            local e = catalog[id]
            w.id = id
            w.enabled = true
            w.action = 'unpick'
            w.idle = C.slot_on
            w.hover = C.hover
            paint_btn(w, C.slot_on)
            w.t:color(C.gold[1], C.gold[2], C.gold[3])
            place('chip'..i, x + INSET, cy, string.format('  %d    %s', i, pad(pred_name(id), 28)))
        else
            w.id = nil
            w.enabled = true
            w.action = 'focus_cats'
            w.idle = C.slot
            w.hover = C.hover
            paint_btn(w, C.slot)
            w.t:color(C.mute[1], C.mute[2], C.mute[3])
            place('chip'..i, x + INSET, cy, string.format('  %d    %s', i, pad('empty', 26)))
        end
        cy = cy + SLOT_H
    end

    ink('statrow')
    place('statrow', x + INSET, tray_y + TRAY_H + 10, string.format(
        'Mastery  %.2fx     Crit  %.0f%%     10,000 gil',
        MASTMULT[r+1] or 1, (CRITPCT[r+1] or 0.05)*100))

    gold('result')
    place('result', x + INSET, pred_y + 10, 'PREDICTED RESULT')
    mute('body')
    local L = { string.format('Expected at Sage %s / Tier %d.',
        RANK_NAMES[info.rank] or 'Unranked', info.tier or 1),
        'Exact numbers roll on the server.' }
    if #flat == 0 then
        L[#L + 1] = ''
        L[#L + 1] = 'No catalysts selected.'
    else
        L[#L + 1] = ''
        for i, id in ipairs(flat) do
            local e = catalog[id]
            L[#L + 1] = string.format('%d   %s   %s', i, pred_name(id), e and cat_short(e.cat) or '')
        end
        L[#L + 1] = ''
        if used == MAX_SLOTS then
            L[#L + 1] = has_maat() and 'Ready to crystalize. +Maat can lock.'
                or 'Five slots ready. Need Maat Cap for +Maat.'
        else
            L[#L + 1] = string.format('%d slot%s free. Five needed to crystalize.',
                MAX_SLOTS - used, (MAX_SLOTS - used) == 1 and '' or 's')
        end
        widgets.body.t:color(C.ink[1], C.ink[2], C.ink[3])
    end
    place('body', x + INSET, pred_y + 40, table.concat(L, '\n'))
end

local function render_footer()
    local y = panel_h - FOOT_H + 10
    local used = sel_total_slots()
    local near = near_augmenter()
    local can_trade = has_sel_gear() and #sel_cats > 0 and near
    local maat_ok = can_trade and used == MAX_SLOTS and has_maat()
    if pending_confirm then
        set_btn_state('trade', true, C.trade)
        set_btn_state('maat', true, C.clear)
        set_btn_state('clear', true, C.clear)
        set_btn_state('scour', false, C.clear)
        gold('trade')
        widgets.trade.action = 'confirm_yes'
        widgets.maat.action = 'confirm_no'
        local bx = col_x('mid')
        place('trade', bx, y, '    Continue    ')
        place('maat', bx + 170, y, '     Cancel     ')
        place('clear', 0, 0, nil, false)
        place('scour', 0, 0, nil, false)
        mute('hint')
        if pending_confirm.kind == 'scour' then
            place('hint', bx, y + 40, 'STRIP all augments including crystalized (25,000 gil). Continue?')
        else
            place('hint', bx, y + 40, 'This will overwrite the current augment. Continue?')
        end
        return
    end
    widgets.trade.action = 'trade'
    widgets.maat.action = 'maat'
    widgets.scour.action = 'scour'
    local augn, locked = gear_aug_state(sel_gear)
    local can_scour = has_sel_gear() and near and (augn > 0 or locked > 0)
    set_btn_state('trade', can_trade, C.trade)
    set_btn_state('maat', maat_ok, C.maat)
    set_btn_state('clear', true, C.clear)
    set_btn_state('scour', can_scour, C.clear)
    if can_trade then
        gold('trade')
    end
    local bx = col_x('mid')
    place('trade', bx, y, '      Trade      ')
    place('maat', bx + 170, y, '      + Maat      ')
    place('clear', bx + 340, y, '      Clear      ')
    place('scour', bx + 490, y, '      Scour      ')
    mute('foot')
    if not near then
        place('foot', PAD, y + 42, 'Stand within 6 yalms of the Arcane Augment and click him once, then Trade.')
    else
        place('foot', PAD, y + 42, 'Click the Arcane Augment once, then Trade. Unequip the piece first. Scour is 25,000 gil.')
    end
end

local function paint()
    layout_panel(PANEL_H)
    layout_chrome()
    render_left()
    render_mid()
    render_right()
    render_footer()
end

local function render()
    ensure_ui()
    hover_key = nil
    if not visible then
        hide_all_widgets()
        return
    end
    if cur_tab ~= 'cats' then
        cur_tab = 'gear'
    end
    update_inventory()
    paint()
end

-----------------------------------
-- Actions
-----------------------------------
local function handle_action(w, btn)
    if not w or not w.action or not w.enabled then
        return
    end
    local action = w.action
    if action ~= 'search_focus' then
        search_focus = false
    end
    if action == 'hide' then
        visible = false
        search_focus = false
    elseif action == 'search_focus' then
        search_focus = true
    elseif action == 'search_clear' then
        set_search('')
        search_focus = true
    elseif action == 'tab' then
        if w.arg == 'cats' then
            cur_tab = 'cats'
        else
            cur_tab = 'gear'
        end
        update_inventory()
    elseif action == 'focus_cats' then
        cur_tab = 'cats'
        update_inventory()
    elseif action == 'page' then
        local dir = tonumber(w.arg) or 0
        if cur_tab == 'cats' then
            cat_page = math.max(1, cat_page + dir)
        else
            gear_page = math.max(1, gear_page + dir)
        end
    elseif action == 'sync' then
        send_auginfo()
        windower.add_to_chat(207, '[AugmentTrade] Asking the Arcane Augmenter for your stored catalysts...')
    elseif action == 'clear' then
        pending_confirm = nil
        sel_cats = {}
        clear_sel_gear()
    elseif action == 'clear_gear' then
        clear_sel_gear()
    elseif action == 'clear_tray' then
        sel_cats = {}
    elseif action == 'help' then
        windower.add_to_chat(207, '[AugmentTrade] Left list is inventory (Gear) or the Arcane Augmenter bank (Catalysts).')
        windower.add_to_chat(207, '[AugmentTrade] Click unequipped gear to select. Equipped pieces must come off first. Double-click jumps to the bank. Left-click a catalyst to add, right-click to remove.')
        windower.add_to_chat(207, '[AugmentTrade] Trade needs a piece plus at least one catalyst. Click the Arcane Augment once and stay within 6 yalms. +Maat needs five slots and Maat\'s Cap. The server rejects trades that skip that.')
        windower.add_to_chat(207, '[AugmentTrade] Scour strips every augment including crystalized for 25,000 gil.')
    elseif action == 'trade' then
        do_trade(false)
    elseif action == 'maat' then
        do_trade(true)
    elseif action == 'scour' then
        do_scour(false)
    elseif action == 'confirm_yes' then
        local kind = pending_confirm and pending_confirm.kind
        local maat = pending_confirm and pending_confirm.maat
        pending_confirm = nil
        if kind == 'scour' then
            do_scour(true)
        else
            do_trade(maat, true)
        end
    elseif action == 'confirm_no' then
        pending_confirm = nil
    elseif action == 'gear' then
        local now = os.clock()
        local key = 'gear'..tostring(w.id)..'@'..tostring(w.slot)
        local dbl = last_click.key == key and (now - last_click.t) < 0.4
        choose_gear(w.id, false, w.slot)
        if dbl and sel_gear == w.id and sel_slot == w.slot then
            cur_tab = 'cats'
        end
        last_click.key, last_click.t = key, now
    elseif action == 'set_filter' then
        f_slot = w.arg or 'all'
        gear_page = 1
    elseif action == 'cycle_sort' then
        f_sort = (f_sort == 'name' and 'slot') or (f_sort == 'slot' and 'aug') or 'name'
        gear_page = 1
    elseif action == 'set_cat' then
        f_cat = tonumber(w.arg) or 0
        cat_page = 1
    elseif action == 'unpick' then
        unpick_one(w.id)
    elseif action == 'pick' then
        if btn == 'right' then
            unpick_one(w.id)
        else
            pick_catalyst(w.id, 1, true)
        end
    end
    render()
end

local function widget_at(x, y)
    for key, w in pairs(widgets) do
        if w.kind == 'btn' and w.enabled and w.t:visible() and w.t:hover(x, y) then
            return key, w
        end
    end
    return nil, nil
end

local function in_title(x, y)
    return x >= ui.x and x <= ui.x + ui.w and y >= ui.y and y <= ui.y + TITLE_H
end

local function in_panel(x, y)
    return visible
        and x >= ui.x and x <= ui.x + ui.w
        and y >= ui.y and y <= ui.y + panel_h
end

local function nudge_ui(nx, ny)
    ui.x, ui.y = nx, ny
    paint()
end

-----------------------------------
-- Incoming text
-----------------------------------
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
    -- Empty dump is only trusted when the server sent the explicit empty packet
    -- with no tokens. A truncated / failed dump must not wipe a known bank.
    if got > 0 or (n == 1 and (bank_buf[1] or '') == '') then
        bank = merged
        rebuild_rows()
        render()
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
        render()
    elseif visible then
        windower.add_to_chat(207, '[AugmentTrade] Bank list did not parse. Keeping the last known store.')
    end
    bank_parse = {}
end

windower.register_event('incoming text', function(orig)
    local clean = tostring(orig or ''):gsub('\x1E.', ''):gsub('\x1F.', ''):gsub('\x7F.', '')
    clean = clean:gsub('^%[%d%d?:%d%d:%d%d%]%s*', '')

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
        render()
        return true
    end

    local sage_rank = clean:match('%[Augment Sage%] Rank:.-%((%d+)/5%)')
    if sage_rank then
        info.rank = tonumber(sage_rank) or info.rank
    end
    local aug_tier = clean:match('Augment Tier:%s*(%d+)/5')
    if aug_tier then
        info.tier = tonumber(aug_tier) or 0
    end
    if sage_rank or aug_tier then
        if visible then
            render()
        end
    end

    if apply_augbank(clean) then
        return true
    end

    if clean:find('[Augment Bank]', 1, true) then
        if clean:find('no catalysts', 1, true) then
            bank = {}
            bank_listen = false
            bank_parse = {}
            rebuild_rows()
            render()
            return true
        end
        bank_listen = true
        bank_parse = {}
        return true
    end
    if bank_listen then
        if clean:find('Total catalysts stored', 1, true) then
            apply_bank_parse()
            return true
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
            return true
        end
    end

    if clean:match('%[AUGDONE%]') then
        update_inventory()
        coroutine.sleep(1)
        send_auginfo()
    end
end)

-----------------------------------
-- Mouse
-----------------------------------
windower.register_event('mouse', function(typ, x, y, delta, blocked)
    if not visible then
        return
    end

    if typ == 0 then
        if drag then
            nudge_ui(x - drag.dx, y - drag.dy)
            return true
        end
        local key, w = widget_at(x, y)
        if hover_key and hover_key ~= key then
            local prev = widgets[hover_key]
            if prev then
                paint_btn(prev, prev.enabled and prev.idle or C.off)
            end
        end
        if key and w and w.enabled and hover_key ~= key then
            paint_btn(w, w.hover)
        end
        hover_key = key
        return
    end

    if typ == 1 then
        if in_title(x, y) and not widget_at(x, y) then
            drag = { dx = x - ui.x, dy = y - ui.y }
            pointer = nil
            return true
        end
        local key = widget_at(x, y)
        if key then
            pointer = { x = x, y = y, btn = 'left', key = key }
            local w = widgets[key]
            if w and w.enabled then
                paint_btn(w, C.press)
            end
            return true
        end
        if in_panel(x, y) then
            if search_focus then
                search_focus = false
                render()
            end
            return true
        end
    elseif typ == 4 then
        local key = widget_at(x, y)
        if key then
            pointer = { x = x, y = y, btn = 'right', key = key }
            return true
        end
    elseif typ == 2 or typ == 5 then
        if drag then
            drag = nil
            return true
        end
        local p = pointer
        pointer = nil
        if p then
            local dx, dy = x - p.x, y - p.y
            if dx*dx + dy*dy <= 36 then
                local _, w = widget_at(x, y)
                if w then
                    handle_action(w, p.btn)
                end
            end
            return true
        end
    elseif delta and delta ~= 0 then
        local _, w = widget_at(x, y)
        if w or in_panel(x, y) then
            local dir = delta > 0 and -1 or 1
            if cur_tab == 'cats' then
                cat_page = math.max(1, cat_page + dir)
            elseif cur_tab == 'gear' then
                gear_page = math.max(1, gear_page + dir)
            end
            render()
            return true
        end
    end
end)

-----------------------------------
-- Events
-----------------------------------
local function bag_changed(bag)
    if bag ~= nil and bag ~= 0 then
        return
    end
    update_inventory()
    if visible then
        render()
    end
end

windower.register_event('add item', function(bag)
    bag_changed(bag)
end)

windower.register_event('remove item', function(bag)
    bag_changed(bag)
end)

windower.register_event('load', function()
    build_sorted()
    build_name_index()
    update_inventory()
    coroutine.sleep(3)
    send_auginfo()
end)

local last_range_check = 0
local last_near = false
windower.register_event('prerender', function()
    if not visible then
        return
    end
    local now = os.clock()
    if now - last_range_check < 0.4 then
        return
    end
    last_range_check = now
    local near = near_augmenter()
    if near ~= last_near then
        last_near = near
        render()
    end
end)

windower.register_event('login', function()
    update_inventory()
    coroutine.sleep(5)
    send_auginfo()
end)

windower.register_event('zone change', function()
    update_inventory()
    coroutine.sleep(3)
    send_auginfo()
end)

windower.register_event('keyboard', function(dik, pressed)
    if dik == 42 or dik == 54 then
        shift_down = pressed and true or false
        if search_focus then
            return true
        end
        return
    end
    if not visible then
        return
    end
    if not search_focus then
        if pressed and dik == 1 then
            visible = false
            render()
            return true
        end
        return
    end
    if not pressed then
        return true
    end
    if dik == 1 or dik == 15 or dik == 28 then
        search_focus = false
        render()
        return true
    end
    if dik == 14 then
        if #search_q > 0 then
            set_search(search_q:sub(1, -2))
            render()
        end
        return true
    end
    if dik == 57 then
        if #search_q < 40 then
            set_search(search_q .. ' ')
            render()
        end
        return true
    end
    local ch = DIK_CHAR[dik]
    if ch then
        if shift_down then
            ch = DIK_SHIFT[dik] or ch:upper()
        end
        if #search_q < 40 then
            set_search(search_q .. ch)
            render()
        end
        return true
    end
    return true
end)

windower.register_event('unload', function()
    visible = false
    search_focus = false
    hide_all_widgets()
    for _, name in pairs(PRIM) do
        pcall(windower.prim.delete, name)
    end
end)

-----------------------------------
-- Commands
-----------------------------------
windower.register_event('addon command', function(cmd, ...)
    cmd  = (cmd  or ''):lower()
    local args = { ... }
    local arg1 = args[1] or ''
    local arg2 = args[2] or ''
    local rest = table.concat(args, ' ')

    if cmd == '' or cmd == 'toggle' or cmd == 't' then
        visible = not visible
        if visible then
            update_inventory()
            send_auginfo()
        end
        render()

    elseif cmd == 'show'  then visible = true; update_inventory(); send_auginfo(); render()
    elseif cmd == 'hide'  then visible = false; search_focus = false; render()

    elseif cmd == 'find' or cmd == 'search' then
        set_search(rest)
        search_focus = false
        visible = true
        if cur_tab == 'result' then
            cur_tab = 'gear'
        end
        update_inventory()
        render()

    elseif cmd == 'tab' then
        local t = arg1:lower()
        if     t == 'gear' or t == '1' then cur_tab = 'gear'
        elseif t == 'cats' or t == 'catalysts' or t == '2' then cur_tab = 'cats'
        elseif t == 'result' or t == '3' then
            -- Predicted result is always visible on the right.
        end
        visible = true; update_inventory(); render()

    elseif cmd == 'n' or cmd == 'next' then
        if cur_tab == 'cats' then cat_page = cat_page + 1 else gear_page = gear_page + 1 end
        render()
    elseif cmd == 'p' or cmd == 'prev' then
        if cur_tab == 'cats' then cat_page = math.max(1, cat_page-1) else gear_page = math.max(1, gear_page-1) end
        render()

    elseif cmd == 'cat' then f_cat = math.min(MAX_CAT, math.max(0, tonumber(arg1) or 0)); cat_page=1; render()

    elseif cmd == 'gear' then
        set_gear(arg1)
        cur_tab = 'gear'; visible = true; render()

    elseif cmd == 'add' then
        update_inventory()
        local e = ready_catalysts()[tonumber(arg1)]
        if e then pick_catalyst(e.id, 1) end
        cur_tab = 'cats'; visible = true; render()

    elseif cmd == 'pick' then
        pick_catalyst(arg1, arg2)
        cur_tab = 'cats'; visible = true; render()

    elseif cmd == 'unpick' then
        local id = tonumber(arg1)
        if id then
            local idx = sel_find(id)
            if idx then table.remove(sel_cats, idx) end
        else
            sel_cats = {}
        end
        visible = true; render()

    elseif cmd == 'clear' then
        sel_cats = {}
        clear_sel_gear()
        visible = true; render()

    elseif cmd == 'trade' then
        do_trade(arg1:lower() == 'maat')
        render()

    elseif cmd == 'scour' then
        do_scour(false)
        render()

    elseif cmd == 'sync' then
        update_inventory()
        send_auginfo()
        windower.add_to_chat(207, '[AugmentTrade] Syncing...')

    else
        windower.add_to_chat(207, '[AugmentTrade] //at toggles the window. //at find <text> searches. Click the search bar to type.')
    end
end)
