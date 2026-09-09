-----------------------------------
-- AugmentBrowser — Windower 4 Addon
-- Legendary catalog: what the catalyst is, what it rolls, where to farm it.
-- UI matches Augment Trade. Toggle: //ab
-----------------------------------
_addon.name     = 'AugmentBrowser'
_addon.version  = '2.0.0'
_addon.author   = 'Eren{Legendary}'
_addon.commands = {'augmentbrowser', 'ab'}

local texts   = require('texts')
local catalog = require('data/catalog')
local cats    = require('data/categories')
local sources = require('data/sources')
local MAX_CAT = #cats

local res_ok, resources = pcall(require, 'resources')
local res_items = (res_ok and resources and resources.items) or nil

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
local PAGE_SIZE = 8
local CAT_SHORT = {
    [1]='Stat',[2]='Melee',[3]='Magic',[4]='Def',[5]='Delay',
    [6]='Dur',[7]='Pet',[8]='Pot',[9]='Skill',[10]='EXP',[11]='Job',
}

local FONT   = 'Segoe UI'
local TITLEF = 'Georgia'
local LISTF  = 'Consolas'
local ui = { x = 36, y = 22, w = 1340 }
local TITLE_H = 52
local TAB_H   = 40
local ROW_H   = 38
local PAD     = 18
local GAP     = 16
local LEFT_W  = 860
local RIGHT_W = 410
local BODY_TOP = TITLE_H + TAB_H + 8
local FOOT_H  = 72
local SEARCH_H = 78
local FILTER_H = 126
local PANEL_H = BODY_TOP + 8 + 26 + SEARCH_H + FILTER_H + 26 + 22 + PAGE_SIZE * (ROW_H + 4) + 24 + FOOT_H

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
    locked  = { 42, 28, 26 },
    off     = { 16, 18, 24 },
    search  = { 16, 18, 24 },
    col     = { 16, 17, 22 },
    inner   = { 12, 13, 17 },
    frame   = { 74, 64, 42 },
    clear   = { 140, 64, 54 },
    trade   = { 68, 58, 30 },
}

local PRIM = {
    shadow  = 'AugmentBrowser_Shadow',
    border  = 'AugmentBrowser_Border',
    bg      = 'AugmentBrowser_BG',
    title   = 'AugmentBrowser_Title',
    line    = 'AugmentBrowser_Line',
    tabline = 'AugmentBrowser_TabLine',
    col_l   = 'AugmentBrowser_ColL',
    frame_r = 'AugmentBrowser_FrameR',
    box_r   = 'AugmentBrowser_BoxR',
}
for i = 1, PAGE_SIZE do
    PRIM['sel'..i] = 'AugmentBrowser_Sel'..i
end

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
-- State
-----------------------------------
local visible  = false
local cur_tab  = 'catalog'
local cur_page = 1
local info = { rank=0, tier=1, count=0, aff=0, hl_tier=1, prestige=0, rebirths=0, gauntlet=0 }
local bank, bank_buf = {}, {}
local sorted = {}
local sel_id = 0
local search_q = ''
local search_focus = false
local shift_down = false
local f_tier, f_cat = 0, 0
local f_owned, f_avail = false, false
local widgets = {}
local ui_ready = false
local hover_key = nil
local pointer = nil
local drag = nil
local panel_h = 400

-----------------------------------
-- Data helpers
-----------------------------------
local function cat_name(n)
    return cats[n] and cats[n].name or ('Cat '..n)
end

local function cat_short(n)
    return CAT_SHORT[n] or cat_name(n)
end

local function affinity_nm(n)
    return cats[n] and cats[n].nm or ''
end

local function pad(s, n)
    s = tostring(s or '')
    if #s > n then
        return s:sub(1, math.max(1, n - 2)) .. '..'
    end
    return s .. string.rep(' ', n - #s)
end

local function catalyst_qty(id)
    return bank[id] or 0
end

local function item_name(id)
    local src = sources[id]
    if src and src.item and src.item ~= '' then
        return src.item
    end
    local e = catalog[id]
    if e and e.item and e.item ~= '' then
        return e.item
    end
    local it = res_items and res_items[id]
    if it then
        return it.en or it.enl or ('Item '..id)
    end
    return e and e.label or ('Item '..id)
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
    if tier < 1 then tier = 1 end
    local base, mult, disp = e.base or 1, e.mult or 1, e.disp or 1
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
    if lo > hi then lo, hi = hi, lo end
    return lo, hi
end

local function value_short(id)
    local lo, hi = predict_range(id)
    if not lo then return '' end
    if lo == hi then return '+' .. lo end
    return string.format('+%s-+%s', lo, hi)
end

local function matches_search(...)
    if search_q == '' then return true end
    local q = search_q:lower()
    for i = 1, select('#', ...) do
        local s = tostring(select(i, ...) or ''):lower()
        if s:find(q, 1, true) then return true end
    end
    return false
end

local function set_search(q)
    q = tostring(q or '')
    if q == search_q then return end
    search_q = q
    cur_page = 1
end

local function search_label()
    local inner
    if search_q ~= '' then
        inner = search_q .. (search_focus and '_' or '')
    elseif search_focus then
        inner = '_'
    else
        inner = 'Search stat, catalyst, mob, or zone...'
    end
    if #inner < 48 then
        inner = inner .. string.rep(' ', 48 - #inner)
    end
    return '  ' .. inner
end

local function farm_text(id)
    local src = sources[id]
    if not src or not src.mobs or #src.mobs == 0 then
        return ''
    end
    local bits = {}
    for _, m in ipairs(src.mobs) do
        bits[#bits + 1] = m.name or ''
        if m.zone and m.zone ~= '' then
            bits[#bits + 1] = m.zone
        end
    end
    return table.concat(bits, ' ')
end

local function build_sorted()
    sorted = {}
    for id, e in pairs(catalog) do
        sorted[#sorted + 1] = { id = id, label = e.label, cat = e.cat, tier = e.tier }
    end
    table.sort(sorted, function(a, b)
        if a.tier ~= b.tier then return a.tier < b.tier end
        if a.cat ~= b.cat then return a.cat < b.cat end
        return a.label < b.label
    end)
end

local function filtered()
    local out = {}
    for _, e in ipairs(sorted) do
        local owned = catalyst_qty(e.id) > 0
        if cur_tab == 'mine' and not owned then
            -- skip
        elseif (f_tier == 0 or e.tier == f_tier)
            and (f_cat == 0 or e.cat == f_cat)
            and (not f_owned or owned)
            and (not f_avail or e.tier <= info.rank)
            and matches_search(e.label, item_name(e.id), e.id, cat_name(e.cat), cat_short(e.cat), farm_text(e.id)) then
            out[#out + 1] = e
        end
    end
    return out
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
    if label then w.t:text(label) end
    if show == false then w.t:hide() else w.t:show() end
end

local function hide_key(key)
    local w = widgets[key]
    if w then w.t:hide() end
end

local function prims_init()
    for _, name in pairs(PRIM) do
        pcall(windower.prim.delete, name)
        pcall(windower.prim.create, name)
        pcall(windower.prim.set_visibility, name, false)
    end
end

local function prims_hide()
    for _, name in pairs(PRIM) do
        pcall(windower.prim.set_visibility, name, false)
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

local function ensure_ui()
    if ui_ready then return end
    prims_init()
    add_label('title', 22, TITLEF)
    add_label('subtitle', 14)
    add_label('credit', 12)
    add_btn('close', '   X   ', C.clear, { 160, 80, 70 }, 16, 8)
    widgets.close.action = 'hide'
    add_btn('help', '  ?  ', C.btn, C.hover, 14, 6)
    widgets.help.action = 'help'
    add_btn('tab_catalog', '   Catalog   ', C.btn, C.hover, 15, 8)
    add_btn('tab_rank',    '    Rank    ', C.btn, C.hover, 15, 8)
    add_btn('tab_mine',    '    Mine    ', C.btn, C.hover, 15, 8)
    widgets.tab_catalog.action = 'tab'; widgets.tab_catalog.arg = 'catalog'
    widgets.tab_rank.action    = 'tab'; widgets.tab_rank.arg    = 'rank'
    widgets.tab_mine.action    = 'tab'; widgets.tab_mine.arg    = 'mine'
    add_btn('sync', '  Refresh  ', C.btn, C.hover, 13, 6)
    widgets.sync.action = 'sync'

    add_btn('search', '  Search...', C.search, C.hover, 14, 8)
    add_btn('search_clear', '  Clear  ', C.btn, C.hover, 13, 6)
    widgets.search.action = 'search_focus'
    widgets.search_clear.action = 'search_clear'

    add_label('section', 15)
    add_label('colhead', 12, LISTF)
    add_label('page', 12)
    add_label('empty', 13)
    add_label('foot', 11)
    add_label('d_title', 20, TITLEF)
    add_label('d_sub', 13)
    add_label('d_body', 13)
    add_btn('warp', '   Warp to farm   ', C.trade, C.goldhot, 15, 10)
    widgets.warp.action = 'warp'

    add_btn('prev', '   <   ', C.btn, C.hover, 14, 6)
    add_btn('next', '   >   ', C.btn, C.hover, 14, 6)
    widgets.prev.action = 'page'; widgets.prev.arg = -1
    widgets.next.action = 'page'; widgets.next.arg = 1

    local chips = {
        { 'f_all',  '  All  ' },
        { 'f_c1',   '  Stat  ' },
        { 'f_c2',   ' Melee ' },
        { 'f_c3',   ' Magic ' },
        { 'f_c4',   '  Def  ' },
        { 'f_c7',   '  Pet  ' },
        { 'f_c5',   ' Delay ' },
        { 'f_c6',   '  Dur  ' },
        { 'f_c8',   '  Pot  ' },
        { 'f_c9',   ' Skill ' },
        { 'f_c10',  '  EXP  ' },
        { 'f_c11',  '  Job  ' },
        { 'f_tier', '  Tier  ' },
        { 'f_owned',' Owned ' },
        { 'f_avail',' Open  ' },
    }
    for _, row in ipairs(chips) do
        add_btn(row[1], row[2], C.btn, C.hover, 12, 6)
    end
    widgets.f_all.action = 'set_cat'; widgets.f_all.arg = 0
    for i = 1, 11 do
        widgets['f_c'..i].action = 'set_cat'
        widgets['f_c'..i].arg = i
    end
    widgets.f_tier.action = 'cycle_tier'
    widgets.f_owned.action = 'toggle_owned'
    widgets.f_avail.action = 'toggle_avail'

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

local function layout_panel(height)
    panel_h = height
    fill_prim(PRIM.shadow, ui.x + 4, ui.y + 5, ui.w, height, { 0, 0, 0 }, 130)
    fill_prim(PRIM.border, ui.x - 1, ui.y - 1, ui.w + 2, height + 2, { 58, 51, 36 }, 255)
    fill_prim(PRIM.bg, ui.x, ui.y, ui.w, height, C.panel, 236)
    fill_prim(PRIM.title, ui.x, ui.y, ui.w, TITLE_H, C.title, 250)
    fill_prim(PRIM.line, ui.x, ui.y + TITLE_H, ui.w, 2, C.gold, 255)
    local y = ui.y + BODY_TOP
    local h = height - BODY_TOP - FOOT_H
    fill_prim(PRIM.col_l, ui.x + PAD, y, LEFT_W, h, C.col, 230)
end

local function layout_chrome()
    local r = info.rank
    widgets.title.t:color(C.gold[1], C.gold[2], C.gold[3])
    place('title', PAD, 8, 'Augment Browser')
    widgets.credit.t:color(110, 103, 88)
    place('credit', PAD, 32, 'Eren{Legendary}')
    widgets.subtitle.t:color(C.mute[1], C.mute[2], C.mute[3])
    place('subtitle', 340, 16, string.format('Rank  %s     Tier  %d     Mastery  %.2fx     Crit  %.0f%%',
        RANK_NAMES[r] or '?', info.tier or 1, MASTMULT[r+1] or 1, (CRITPCT[r+1] or 0.05)*100))
    place('help', ui.w - 132, 10, '  ?  ')
    place('close', ui.w - 76, 10, '   X   ')

    local tabs = {
        { 'tab_catalog', 'catalog', '   Catalog   ' },
        { 'tab_rank',    'rank',    '    Rank    ' },
        { 'tab_mine',    'mine',    '    Mine    ' },
    }
    local tx, underline_x = PAD, PAD
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
    place('sync', PAD + 460, TITLE_H + 6, '  Refresh  ')
end

local function hide_rows()
    for i = 1, PAGE_SIZE do
        hide_key('row'..i)
        widgets['row'..i].action = nil
        widgets['row'..i].id = nil
        widgets['row'..i].enabled = false
        pcall(windower.prim.set_visibility, PRIM['sel'..i], false)
    end
end

local function fill_row(i, x, y, label, id, idle, enabled)
    local key = 'row'..i
    local w = widgets[key]
    w.action = enabled and 'select' or nil
    w.id = id
    w.enabled = enabled and true or false
    w.idle = idle or C.row
    w.hover = C.hover
    paint_btn(w, w.idle)
    if not enabled then
        w.t:color(C.mute[1], C.mute[2], C.mute[3])
    elseif idle == C.sel then
        w.t:color(C.gold[1], C.gold[2], C.gold[3])
    else
        w.t:color(C.ink[1], C.ink[2], C.ink[3])
    end
    place(key, x, y, label)
    if idle == C.sel then
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

local function chip(key, x, y, label, on)
    set_btn_state(key, true, on and C.tab_on or C.btn)
    widgets[key].t:color(on and C.gold[1] or C.ink[1], on and C.gold[2] or C.ink[2], on and C.gold[3] or C.ink[3])
    place(key, x, y, label)
end

local function hide_list_chrome()
    hide_key('search')
    hide_key('search_clear')
    hide_key('section')
    hide_key('colhead')
    hide_key('page')
    hide_key('empty')
    hide_key('prev')
    hide_key('next')
    for _, key in ipairs({
        'f_all','f_c1','f_c2','f_c3','f_c4','f_c5','f_c6','f_c7','f_c8','f_c9','f_c10','f_c11',
        'f_tier','f_owned','f_avail',
    }) do
        hide_key(key)
    end
    hide_rows()
end

-----------------------------------
-- Panels
-----------------------------------
local function render_detail()
    local x = PAD + LEFT_W + GAP
    local y = BODY_TOP + 8
    local h = panel_h - BODY_TOP - FOOT_H - 8
    fill_box(PRIM.frame_r, PRIM.box_r, x, y, RIGHT_W, h)

    if cur_tab == 'rank' then
        gold('d_title')
        place('d_title', x + 14, y + 12, 'Rank ladder')
        mute('d_sub')
        place('d_sub', x + 14, y + 46, 'Higher rank unlocks higher-tier catalysts')
        local lines = {}
        for rv = 0, 5 do
            local mark = rv == info.rank and '> ' or '  '
            lines[#lines + 1] = string.format('%sRank %d  %s   %.2fx   %.0f%% crit',
                mark, rv, pad(RANK_NAMES[rv] or '?', 10),
                MASTMULT[rv + 1] or 1, (CRITPCT[rv + 1] or 0.05) * 100)
        end
        ink('d_body')
        place('d_body', x + 14, y + 80, table.concat(lines, '\n'))
        hide_key('warp')
        return
    end

    local e = catalog[sel_id]
    if not e then
        gold('d_title')
        place('d_title', x + 14, y + 12, 'Pick an augment')
        mute('d_sub')
        place('d_sub', x + 14, y + 46, 'Click a row to see the catalyst and farm.')
        hide_key('d_body')
        hide_key('warp')
        return
    end

    local src = sources[sel_id]
    local locked = e.tier > info.rank
    local qty = catalyst_qty(sel_id)
    local lo, hi = predict_range(sel_id)
    local roll
    if lo and hi then
        roll = lo == hi and ('+' .. lo) or string.format('+%s to +%s', lo, hi)
    else
        roll = '—'
    end

    gold('d_title')
    place('d_title', x + 14, y + 12, e.label)
    mute('d_sub')
    place('d_sub', x + 14, y + 46, string.format('%s   ·   T%d %s%s',
        cat_name(e.cat), e.tier, RANK_NAMES[e.tier] or '?', locked and '   ·   LOCKED' or ''))

    local lines = {
        'Catalyst',
        '  ' .. item_name(sel_id) .. '   (' .. sel_id .. ')',
        '',
        'Roll at your rank / tier',
        '  ' .. roll,
        '',
        'Bank',
        qty > 0 and ('  ' .. qty .. ' stored at the Arcane Augmenter') or '  None stored yet',
        locked and ('  Need rank ' .. (RANK_NAMES[e.tier] or e.tier) .. ' to trade this') or '  Open at your rank',
    }
    local nm = affinity_nm(e.cat)
    if nm ~= '' then
        lines[#lines + 1] = ''
        lines[#lines + 1] = 'Category unlock'
        lines[#lines + 1] = '  ' .. nm .. ' affinity'
    end
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'Farm'
    if src and src.mobs and #src.mobs > 0 then
        local rate = src.rate or 10
        lines[#lines + 1] = string.format('  %d%% on these mobs (Treasure Hunter helps)', rate)
        for _, m in ipairs(src.mobs) do
            local loc = m.name or '?'
            if m.zone and m.zone ~= '' then
                loc = loc .. '  —  ' .. m.zone
            end
            if m.lvl and m.lvl > 0 then
                loc = loc .. string.format('  (Lv.%d)', m.lvl)
            end
            lines[#lines + 1] = '  ' .. loc
        end
    else
        lines[#lines + 1] = '  No mapped mob for this catalyst'
    end
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'Same-tier unmapped mobs can also'
    lines[#lines + 1] = 'drop a random catalyst at 10%.'

    ink('d_body')
    place('d_body', x + 14, y + 80, table.concat(lines, '\n'))

    if src and src.mobs and #src.mobs > 0 then
        set_btn_state('warp', true, C.trade)
        place('warp', x + 14, y + h - 52, '   Warp to farm   ')
    else
        hide_key('warp')
    end
end

local function render_rank_left()
    local x = PAD
    local y = BODY_TOP + 8
    gold('section')
    place('section', x + 8, y, 'YOUR RANK')
    y = y + 32
    local r = info.rank
    local lines = {
        string.format('Current  %s  (rank %d)', RANK_NAMES[r] or '?', r),
        string.format('Mastery  %.2fx     Crit  %.0f%%', MASTMULT[r+1] or 1, (CRITPCT[r+1] or 0.05)*100),
        string.format('Augments applied  %d', info.count or 0),
        '',
    }
    local req = RANK_REQS[r + 1]
    if not req then
        lines[#lines + 1] = 'Max rank: Augment Archon.'
        lines[#lines + 1] = 'Every catalog line is open.'
    else
        lines[#lines + 1] = 'Next  ' .. req.title
        lines[#lines + 1] = ''
        local function row(ok, label, have, need)
            lines[#lines + 1] = string.format('  %s  %s   %s / %s',
                ok and '[OK]' or '[  ]', pad(label, 22), have, need)
        end
        if req.hlRank then
            row(info.hl_tier >= req.hlRank, 'Hunting League', info.hl_tier, req.hlRank)
        end
        if req.prestigeLevel then
            row(info.prestige >= req.prestigeLevel, 'Prestige', info.prestige, req.prestigeLevel)
        end
        if req.rebirths then
            row(info.rebirths >= req.rebirths, 'Rebirths', info.rebirths, req.rebirths)
        end
        if req.gauntletClears then
            row(info.gauntlet >= req.gauntletClears, 'Gauntlet clears', info.gauntlet, req.gauntletClears)
        end
    end
    ink('empty')
    place('empty', x + 8, y, table.concat(lines, '\n'))
    hide_key('warp')
end

local function render_list()
    local x = PAD
    local y = BODY_TOP + 8
    gold('section')
    place('section', x + 8, y, cur_tab == 'mine' and 'STORED AT THE ARCANE AUGMENTER' or 'AUGMENT CATALOG')
    y = y + 26
    widgets.search.t:color(search_q == '' and C.mute[1] or C.ink[1],
                           search_q == '' and C.mute[2] or C.ink[2],
                           search_q == '' and C.mute[3] or C.ink[3])
    paint_btn(widgets.search, search_focus and C.hover or C.search)
    place('search', x + 6, y, search_label())
    place('search_clear', x + LEFT_W - 100, y, '  Clear  ')
    y = y + SEARCH_H

    local row1 = {
        { 'f_all', 0, '  All  ' },
        { 'f_c1', 1, '  Stat  ' },
        { 'f_c2', 2, ' Melee ' },
        { 'f_c3', 3, ' Magic ' },
        { 'f_c4', 4, '  Def  ' },
        { 'f_c7', 7, '  Pet  ' },
    }
    local row2 = {
        { 'f_c5', 5, ' Delay ' },
        { 'f_c6', 6, '  Dur  ' },
        { 'f_c8', 8, '  Pot  ' },
        { 'f_c9', 9, ' Skill ' },
        { 'f_c10', 10, '  EXP  ' },
        { 'f_c11', 11, '  Job  ' },
    }
    local cx = x + 6
    for _, row in ipairs(row1) do
        chip(row[1], cx, y, row[3], f_cat == row[2])
        cx = cx + 88
    end
    cx = x + 6
    for _, row in ipairs(row2) do
        chip(row[1], cx, y + 42, row[3], f_cat == row[2])
        cx = cx + 88
    end
    local tier_lbl = f_tier == 0 and '  Tier  ' or ('  T' .. f_tier .. '   ')
    chip('f_tier', x + 6, y + 84, tier_lbl, f_tier > 0)
    chip('f_owned', x + 94, y + 84, ' Owned ', f_owned)
    chip('f_avail', x + 182, y + 84, ' Open  ', f_avail)
    y = y + FILTER_H

    local shown = filtered()
    local page, pages, first, last, total = page_slice(shown, cur_page)
    cur_page = page
    if sel_id == 0 and shown[first] then
        sel_id = shown[first].id
    end

    mute('page')
    place('page', x + 8, y, string.format('%d-%d of %d', total == 0 and 0 or first, last, total))
    set_btn_state('prev', page > 1, C.btn)
    set_btn_state('next', page < pages, C.btn)
    place('prev', x + LEFT_W - 92, y - 14, '  <  ')
    place('next', x + LEFT_W - 50, y - 14, '  >  ')
    y = y + 28

    mute('colhead')
    place('colhead', x + 8, y,
        pad('AUGMENT', 18) .. '  ' .. pad('CATALYST', 22) .. '  ' .. pad('ROLL', 9) .. '  ' .. pad('QTY', 4) .. '  CAT')
    y = y + 22

    hide_rows()
    if total == 0 then
        mute('empty')
        place('empty', x + 8, y + 8, cur_tab == 'mine'
            and 'Nothing stored yet. Farm a mapped mob, then Refresh.'
            or 'No augments match these filters.')
    else
        hide_key('empty')
        for i = first, last do
            local e = shown[i]
            local locked = e.tier > info.rank
            local qty = catalyst_qty(e.id)
            local label = '  ' .. pad(e.label, 18) .. '  ' .. pad(item_name(e.id), 22)
                .. '  ' .. pad(value_short(e.id), 9) .. '  '
                .. pad(qty > 0 and tostring(qty) or '-', 4) .. '  ' .. cat_short(e.cat)
            local idle = e.id == sel_id and C.sel or (locked and C.locked or C.row)
            fill_row(i - first + 1, x + 6, y, label, e.id, idle, true)
            y = y + ROW_H + 4
        end
    end
end

local function paint()
    layout_panel(PANEL_H)
    layout_chrome()
    if cur_tab == 'rank' then
        hide_list_chrome()
        render_rank_left()
    else
        hide_key('empty')
        render_list()
    end
    render_detail()
    mute('foot')
    if cur_tab == 'rank' then
        place('foot', PAD, panel_h - 48, 'Refresh pulls rank from the server. Catalog is the farm list.')
    else
        place('foot', PAD, panel_h - 48, 'Click a row for the catalyst and farm. Warp uses !augwarp. Unmapped mobs can still drop a random same-tier catalyst.')
    end
end

local function send_auginfo()
    windower.send_command('input !catalysts')
end

local function render()
    ensure_ui()
    hover_key = nil
    if not visible then
        hide_all_widgets()
        return
    end
    paint()
end

-----------------------------------
-- Bank / incoming
-----------------------------------
local function apply_augbank(clean)
    local p, n, rest = clean:match('%[AUGBANK%]p=(%d+),n=(%d+),?(.*)')
    if not p then return false end
    p, n = tonumber(p), tonumber(n)
    bank_buf[p] = rest or ''
    for i = 1, n do
        if bank_buf[i] == nil then return true end
    end
    local merged = {}
    for i = 1, n do
        for token in (bank_buf[i] or ''):gmatch('[^,]+') do
            local id, qty = token:match('^(%d+):(%d+)$')
            if id then merged[tonumber(id)] = tonumber(qty) end
        end
    end
    bank = merged
    bank_buf = {}
    if visible then render() end
    return true
end

windower.register_event('incoming text', function(orig)
    local clean = tostring(orig or ''):gsub('\x1E.', ''):gsub('\x1F.', ''):gsub('\x7F.', '')
    clean = clean:gsub('^%[%d%d?:%d%d:%d%d%]%s*', '')

    local data = clean:match('%[AUGINFO%](.+)')
    if data then
        info.rank     = tonumber(data:match('rank=(%d+)'))     or info.rank or 0
        local tier = data:match('tier=(%d+)')
        if tier then info.tier = tonumber(tier) or 0 end
        info.count    = tonumber(data:match('count=(%d+)'))    or info.count or 0
        info.aff      = tonumber(data:match('aff=(%d+)'))      or info.aff or 0
        info.hl_tier  = tonumber(data:match('hl=(%d+)'))       or info.hl_tier or 1
        info.prestige = tonumber(data:match('prestige=(%d+)')) or info.prestige or 0
        info.rebirths = tonumber(data:match('rebirths=(%d+)')) or info.rebirths or 0
        info.gauntlet = tonumber(data:match('gauntlet=(%d+)')) or info.gauntlet or 0
        if visible then render() end
        return true
    end
    if apply_augbank(clean) then
        return true
    end
end)

-----------------------------------
-- Actions
-----------------------------------
local function handle_action(w)
    if not w or not w.action or not w.enabled then return end
    if w.action ~= 'search_focus' then
        search_focus = false
    end
    if w.action == 'hide' then
        visible = false
        search_focus = false
    elseif w.action == 'search_focus' then
        search_focus = true
    elseif w.action == 'search_clear' then
        set_search('')
        search_focus = true
    elseif w.action == 'tab' then
        cur_tab = w.arg or 'catalog'
        cur_page = 1
    elseif w.action == 'page' then
        cur_page = math.max(1, cur_page + (tonumber(w.arg) or 0))
    elseif w.action == 'sync' then
        send_auginfo()
        windower.add_to_chat(207, '[AugmentBrowser] Refreshing rank and bank...')
    elseif w.action == 'set_cat' then
        f_cat = tonumber(w.arg) or 0
        cur_page = 1
    elseif w.action == 'cycle_tier' then
        f_tier = f_tier + 1
        if f_tier > 5 then f_tier = 0 end
        cur_page = 1
    elseif w.action == 'toggle_owned' then
        f_owned = not f_owned
        cur_page = 1
    elseif w.action == 'toggle_avail' then
        f_avail = not f_avail
        cur_page = 1
    elseif w.action == 'select' then
        sel_id = w.id or 0
    elseif w.action == 'warp' then
        local e = catalog[sel_id]
        local name = item_name(sel_id)
        local q = name
        if e and (not name or name == e.label) then
            q = e.label
        end
        windower.send_command('input !augwarp ' .. q)
        windower.add_to_chat(207, '[AugmentBrowser] !augwarp ' .. q)
    elseif w.action == 'help' then
        windower.add_to_chat(207, '[AugmentBrowser] Catalog is every augment. Click a row for the catalyst item and farm mob.')
        windower.add_to_chat(207, '[AugmentBrowser] Mine is what you have stored. Rank is unlock requirements. Warp sends !augwarp.')
        windower.add_to_chat(207, '[AugmentBrowser] Trade is still //at — this window only looks up.')
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

windower.register_event('mouse', function(typ, x, y, delta, blocked)
    if not visible then return end

    if typ == 0 then
        if drag then
            ui.x, ui.y = x - drag.dx, y - drag.dy
            paint()
            return true
        end
        local key, w = widget_at(x, y)
        if hover_key and hover_key ~= key then
            local prev = widgets[hover_key]
            if prev then paint_btn(prev, prev.enabled and prev.idle or C.off) end
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
            pointer = { x = x, y = y, key = key }
            local w = widgets[key]
            if w and w.enabled then paint_btn(w, C.press) end
            return true
        end
        if in_panel(x, y) then
            if search_focus then
                search_focus = false
                render()
            end
            return true
        end
    elseif typ == 2 then
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
                if w then handle_action(w) end
            end
            return true
        end
    elseif delta and delta ~= 0 and in_panel(x, y) then
        cur_page = math.max(1, cur_page + (delta > 0 and -1 or 1))
        render()
        return true
    end
end)

windower.register_event('keyboard', function(dik, pressed)
    if dik == 42 or dik == 54 then
        shift_down = pressed and true or false
        if search_focus then return true end
        return
    end
    if not visible then return end
    if not search_focus then
        if pressed and dik == 1 then
            visible = false
            render()
            return true
        end
        return
    end
    if not pressed then return true end
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
        if shift_down then ch = DIK_SHIFT[dik] or ch:upper() end
        if #search_q < 40 then
            set_search(search_q .. ch)
            render()
        end
        return true
    end
    return true
end)

windower.register_event('load', function()
    build_sorted()
    coroutine.sleep(3)
    send_auginfo()
end)

windower.register_event('login', function()
    coroutine.sleep(5)
    send_auginfo()
end)

windower.register_event('zone change', function()
    coroutine.sleep(3)
    send_auginfo()
end)

windower.register_event('unload', function()
    visible = false
    search_focus = false
    hide_all_widgets()
    for _, name in pairs(PRIM) do
        pcall(windower.prim.delete, name)
    end
end)

windower.register_event('addon command', function(cmd, ...)
    cmd = (cmd or ''):lower()
    local args = { ... }
    local arg1 = args[1] or ''
    local rest = table.concat(args, ' ')

    if cmd == '' or cmd == 'toggle' or cmd == 't' then
        visible = not visible
        if visible then send_auginfo() end
        render()
    elseif cmd == 'show' then
        visible = true; send_auginfo(); render()
    elseif cmd == 'hide' then
        visible = false; search_focus = false; render()
    elseif cmd == 'find' or cmd == 'search' then
        set_search(rest)
        cur_tab = 'catalog'
        visible = true
        render()
    elseif cmd == 'tab' then
        local t = arg1:lower()
        if t == 'catalog' or t == '1' then cur_tab = 'catalog'
        elseif t == 'rank' or t == '2' then cur_tab = 'rank'
        elseif t == 'mine' or t == '3' then cur_tab = 'mine' end
        cur_page = 1; visible = true; render()
    elseif cmd == 'n' or cmd == 'next' then
        cur_page = cur_page + 1; render()
    elseif cmd == 'p' or cmd == 'prev' then
        cur_page = math.max(1, cur_page - 1); render()
    elseif cmd == 'tier' then
        f_tier = math.min(5, math.max(0, tonumber(arg1) or 0)); cur_page = 1; render()
    elseif cmd == 'cat' then
        f_cat = math.min(MAX_CAT, math.max(0, tonumber(arg1) or 0)); cur_page = 1; render()
    elseif cmd == 'owned' then
        f_owned = not f_owned; cur_page = 1; render()
    elseif cmd == 'avail' then
        f_avail = not f_avail; cur_page = 1; render()
    elseif cmd == 'sync' then
        send_auginfo()
        windower.add_to_chat(207, '[AugmentBrowser] Syncing...')
    else
        windower.add_to_chat(207, '[AugmentBrowser]  //ab   //ab find haste   //ab tab catalog/rank/mine')
        windower.add_to_chat(207, '  tier 0-5   cat 0-' .. MAX_CAT .. '   owned   avail   sync')
    end
end)
