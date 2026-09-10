--[[
* AugmentBrowser — Ashita v4
* Legendary catalog: catalyst item, roll, and farm. Same job as Windower //ab.
*
* Toggle: /ab   or   /augmentbrowser
--]]

addon.name      = 'augment_browser'
addon.author    = 'Eren{Legendary}'
addon.version   = '1.0.1'
addon.desc      = 'Legendary augment catalog, catalyst names, and farm locations.'
addon.commands  = { '/augmentbrowser', '/ab' }

require('common')
local chat  = require('chat')
local imgui = require('imgui')

local function load_data(name)
    local path = addon.path:gsub('[/\\]+$', '') .. '/data/' .. name .. '.lua'
    local chunk, err = loadfile(path)
    if not chunk then
        error('augment_browser missing ' .. path .. ': ' .. tostring(err))
    end
    return chunk()
end

local catalog = load_data('catalog')
local cats    = load_data('categories')
local sources = load_data('sources')
local MAX_CAT = #cats

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
local CAT_SHORT = {
    [1]='Stat',[2]='Melee',[3]='Magic',[4]='Def',[5]='Delay',
    [6]='Dur',[7]='Pet',[8]='Pot',[9]='Skill',[10]='EXP',[11]='Job',
}

local visible  = { false }
local search_q = { '' }
local cur_tab  = 'catalog'
local info = { rank=0, tier=1, count=0, aff=0, hl_tier=1, prestige=0, rebirths=0, gauntlet=0 }
local bank, bank_buf = {}, {}
local sorted = {}
local sel_id = 0
local f_cat = 0

local function say(msg)
    print(chat.header('AugmentBrowser'):append(chat.message(msg)))
end

local function input_line(line)
    AshitaCore:GetChatManager():QueueCommand(1, line)
end

local function send_auginfo()
    input_line('!catalysts')
end

local function cat_name(n)
    return cats[n] and cats[n].name or ('Cat ' .. n)
end

local function cat_short(n)
    return CAT_SHORT[n] or cat_name(n)
end

local function affinity_nm(n)
    return cats[n] and cats[n].nm or ''
end

local function catalyst_qty(id)
    return bank[id] or 0
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
    if type(field) == 'string' then
        return field ~= '' and field or nil
    end
    if field == nil then
        return nil
    end
    local ok, s = pcall(function() return field[1] end)
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
    if name_cache[id] then
        return name_cache[id]
    end
    local src = sources[id]
    if src and src.item and src.item ~= '' then
        name_cache[id] = src.item
        return src.item
    end
    local e = catalog[id]
    if e and e.item and e.item ~= '' then
        name_cache[id] = e.item
        return e.item
    end
    local res = item_res(id)
    local n = res and (i18n_text(res.Name) or i18n_text(res.LogNameSingular))
    n = n or (e and e.label) or ('Item ' .. id)
    name_cache[id] = n
    return n
end

local function farm_text(id)
    local src = sources[id]
    if not src or not src.mobs then
        return ''
    end
    local bits = {}
    for _, m in ipairs(src.mobs) do
        bits[#bits + 1] = m.name or ''
        bits[#bits + 1] = m.zone or ''
    end
    return table.concat(bits, ' ')
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
        return shown_val(base, raw - base, mult, disp), shown_val(base, raw - base, mult, disp)
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
    local q = tostring(search_q[1] or ''):lower()
    if q == '' then return true end
    for i = 1, select('#', ...) do
        local s = tostring(select(i, ...) or ''):lower()
        if s:find(q, 1, true) then return true end
    end
    return false
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
        elseif (f_cat == 0 or e.cat == f_cat)
            and matches_search(e.label, item_name(e.id), e.id, cat_name(e.cat), cat_short(e.cat), farm_text(e.id)) then
            out[#out + 1] = e
        end
    end
    return out
end

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
    return true
end

local function strip_chat(msg)
    msg = tostring(msg or '')
    msg = msg:gsub('\x1E.', ''):gsub('\x1F.', ''):gsub('\x7F.', '')
    return msg:gsub('^%[%d%d?:%d%d:%d%d%]%s*', '')
end

local function rgb(r, g, b, a)
    return { r / 255, g / 255, b / 255, a or 1 }
end

local GOLD = rgb(212, 177, 90)
local MUTE = rgb(154, 146, 128)
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
    { ImGuiCol_Text, rgb(246, 239, 216) },
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

local function draw_rank()
    local r = info.rank or 0
    imgui.TextColored(GOLD, 'YOUR RANK')
    imgui.Text(string.format('Current  %s  (rank %d)', RANK_NAMES[r] or '?', r))
    imgui.Text(string.format('Mastery  %.2fx     Crit  %.0f%%', MASTMULT[r + 1] or 1, (CRITPCT[r + 1] or 0.05) * 100))
    imgui.Text(string.format('Augments applied  %d', info.count or 0))
    imgui.Dummy({ 1, 8 })
    local req = RANK_REQS[r + 1]
    if not req then
        imgui.Text('Max rank: Augment Archon.')
        imgui.Text('Every catalog line is open.')
    else
        imgui.TextColored(GOLD, 'Next  ' .. req.title)
        local function row(ok, label, have, need)
            imgui.Text(string.format('  %s  %s   %s / %s', ok and '[OK]' or '[  ]', label, have, need))
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
end

local function draw_detail()
    if cur_tab == 'rank' then
        imgui.TextColored(GOLD, 'Rank ladder')
        imgui.TextColored(MUTE, 'Higher rank unlocks higher-tier catalysts')
        imgui.Dummy({ 1, 8 })
        for rv = 0, 5 do
            local mark = rv == info.rank and '> ' or '  '
            imgui.Text(string.format('%sRank %d  %-10s  %.2fx   %.0f%% crit',
                mark, rv, RANK_NAMES[rv] or '?',
                MASTMULT[rv + 1] or 1, (CRITPCT[rv + 1] or 0.05) * 100))
        end
        return
    end

    local e = catalog[sel_id]
    if not e then
        imgui.TextColored(GOLD, 'Pick an augment')
        imgui.TextColored(MUTE, 'Click a row to see the catalyst and farm.')
        return
    end

    local src = sources[sel_id]
    local locked = e.tier > info.rank
    local qty = catalyst_qty(sel_id)
    local lo, hi = predict_range(sel_id)
    local roll = '—'
    if lo and hi then
        roll = lo == hi and ('+' .. lo) or string.format('+%s to +%s', lo, hi)
    end

    imgui.TextColored(GOLD, e.label)
    imgui.TextColored(MUTE, string.format('%s   ·   T%d %s%s',
        cat_name(e.cat), e.tier, RANK_NAMES[e.tier] or '?', locked and '   ·   LOCKED' or ''))
    imgui.Dummy({ 1, 6 })
    imgui.TextColored(GOLD, 'Catalyst')
    imgui.Text('  ' .. item_name(sel_id) .. '   (' .. sel_id .. ')')
    imgui.Dummy({ 1, 4 })
    imgui.TextColored(GOLD, 'Roll at your rank / tier')
    imgui.Text('  ' .. roll)
    imgui.Dummy({ 1, 4 })
    imgui.TextColored(GOLD, 'Bank')
    imgui.Text(qty > 0 and ('  ' .. qty .. ' stored at the Arcane Augmenter') or '  None stored yet')
    if locked then
        imgui.TextColored(WARN, '  Need rank ' .. (RANK_NAMES[e.tier] or e.tier) .. ' to trade this')
    else
        imgui.Text('  Open at your rank')
    end
    local nm = affinity_nm(e.cat)
    if nm ~= '' then
        imgui.Dummy({ 1, 4 })
        imgui.TextColored(GOLD, 'Category unlock')
        imgui.Text('  ' .. nm .. ' affinity')
    end
    imgui.Dummy({ 1, 4 })
    imgui.TextColored(GOLD, 'Farm')
    if src and src.mobs and #src.mobs > 0 then
        imgui.Text(string.format('  %d%% on these mobs (Treasure Hunter helps)', src.rate or 10))
        for _, m in ipairs(src.mobs) do
            local loc = m.name or '?'
            if m.zone and m.zone ~= '' then
                loc = loc .. '  —  ' .. m.zone
            end
            if m.lvl and m.lvl > 0 then
                loc = loc .. string.format('  (Lv.%d)', m.lvl)
            end
            imgui.Text('  ' .. loc)
        end
        imgui.Dummy({ 1, 8 })
        if imgui.Button('   Warp to farm   ') then
            local q = item_name(sel_id)
            if q == e.label then
                q = e.label
            end
            input_line('!augwarp ' .. q)
            say('!augwarp ' .. q)
        end
    else
        imgui.Text('  No mapped mob for this catalyst')
    end
    imgui.Dummy({ 1, 6 })
    imgui.TextColored(MUTE, 'Same-tier unmapped mobs can also')
    imgui.TextColored(MUTE, 'drop a random catalyst at 10%.')
end

local function draw_list()
    imgui.TextColored(GOLD, cur_tab == 'mine' and 'STORED AT THE ARCANE AUGMENTER' or 'AUGMENT CATALOG')
    imgui.SetNextItemWidth(360)
    imgui.InputText('##ab_search', search_q, 48)
    imgui.SameLine()
    if imgui.Button('  Clear  ') then
        search_q[1] = ''
    end
    imgui.Dummy({ 1, 2 })

    if chip('  All  ', f_cat == 0) then f_cat = 0 end
    local chips = {
        { 1, '  Stat  ' }, { 2, ' Melee ' }, { 3, ' Magic ' },
        { 4, '  Def  ' }, { 7, '  Pet  ' }, { 5, ' Delay ' },
        { 6, '  Dur  ' }, { 8, '  Pot  ' }, { 9, ' Skill ' },
        { 10, '  EXP  ' }, { 11, '  Job  ' },
    }
    for _, row in ipairs(chips) do
        imgui.SameLine()
        if chip(row[2], f_cat == row[1]) then
            f_cat = row[1]
        end
    end

    local shown = filtered()
    if sel_id == 0 and shown[1] then
        sel_id = shown[1].id
    end
    imgui.TextColored(MUTE, string.format('%d matching', #shown))
    imgui.TextColored(MUTE, pad('AUGMENT', 18) .. '  ' .. pad('CATALYST', 22) .. '  ' .. pad('ROLL', 9) .. '  QTY  CAT')
    imgui.BeginChild('##ab_list', { 0, -8 }, ImGuiChildFlags_Borders)
    for _, e in ipairs(shown) do
        local qty = catalyst_qty(e.id)
        local locked = e.tier > info.rank
        local label = string.format('%s  %s  %s  %s  %s##r%d',
            pad(e.label, 18), pad(item_name(e.id), 22), pad(value_short(e.id), 9),
            qty > 0 and tostring(qty) or '-', cat_short(e.cat), e.id)
        if locked then
            imgui.PushStyleColor(ImGuiCol_Text, MUTE)
        end
        if imgui.Selectable(label, e.id == sel_id) then
            sel_id = e.id
        end
        if locked then
            imgui.PopStyleColor()
        end
    end
    if #shown == 0 then
        imgui.TextColored(MUTE, cur_tab == 'mine'
            and 'Nothing stored yet. Farm a mapped mob, then Refresh.'
            or 'No augments match these filters.')
    end
    imgui.EndChild()
end

local function draw_window()
    if not visible[1] then
        return
    end

    imgui.SetNextWindowSize({ 1220, 700 }, ImGuiCond_FirstUseEver)
    push_theme()
    local ok, err = pcall(function()
        if imgui.Begin('Augment Browser##relaunch', visible) then
            local r = info.rank or 0
            imgui.TextColored(GOLD, 'Augment Browser')
            imgui.SameLine()
            imgui.TextColored(MUTE, '  Eren{Legendary}')
            imgui.SameLine()
            imgui.TextColored(MUTE, string.format('   Rank %s   Tier %d   Mastery %.2fx   Crit %.0f%%',
                RANK_NAMES[r] or '?', info.tier or 1, MASTMULT[r + 1] or 1, (CRITPCT[r + 1] or 0.05) * 100))
            imgui.SameLine()
            if imgui.Button('  Refresh  ') then
                send_auginfo()
                say('Refreshing rank and bank...')
            end
            imgui.SameLine()
            if imgui.Button('  ?  ') then
                say('Catalog is every augment. Click a row for the catalyst item and farm mob.')
                say('Mine is what you have stored. Rank is unlock requirements. Warp sends !augwarp.')
                say('Trade is still /at — this window only looks up.')
            end

            imgui.Separator()
            imgui.Columns(2, '##ab_cols', true)
            imgui.SetColumnWidth(0, 760)

            if imgui.BeginTabBar('##ab_tabs') then
                if imgui.BeginTabItem('   Catalog   ') then
                    cur_tab = 'catalog'
                    draw_list()
                    imgui.EndTabItem()
                end
                if imgui.BeginTabItem('    Rank    ') then
                    cur_tab = 'rank'
                    draw_rank()
                    imgui.EndTabItem()
                end
                if imgui.BeginTabItem('    Mine    ') then
                    cur_tab = 'mine'
                    draw_list()
                    imgui.EndTabItem()
                end
                imgui.EndTabBar()
            end

            imgui.NextColumn()
            imgui.BeginChild('##ab_detail', { 0, -28 }, ImGuiChildFlags_Borders)
            imgui.Dummy({ 8, 8 })
            imgui.Indent(10)
            draw_detail()
            imgui.Unindent(10)
            imgui.EndChild()
            imgui.Columns(1)
            imgui.TextColored(MUTE, cur_tab == 'rank'
                and 'Refresh pulls rank from the server. Catalog is the farm list.'
                or 'Click a row for the catalyst and farm. Warp uses !augwarp. Unmapped mobs can still drop a random same-tier catalyst.')
        end
        imgui.End()
    end)
    pop_theme()
    if not ok then
        say(tostring(err))
    end
end

ashita.events.register('load', 'ab_load', function()
    build_sorted()
    ashita.tasks.once(3, send_auginfo)
end)

ashita.events.register('d3d_present', 'ab_draw', draw_window)

ashita.events.register('text_in', 'ab_text', function(e)
    local clean = strip_chat(e.message_modified or e.message)
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
        e.blocked = true
        return
    end
    if apply_augbank(clean) then
        e.blocked = true
    end
end)

ashita.events.register('command', 'ab_cmd', function(e)
    local args = e.command:args()
    if #args == 0 then
        return
    end
    local head = args[1]:lower()
    if head ~= '/ab' and head ~= '/augmentbrowser' then
        return
    end
    e.blocked = true

    local cmd = (args[2] or 'toggle'):lower()
    if cmd == 'toggle' or cmd == 't' then
        visible[1] = not visible[1]
        if visible[1] then send_auginfo() end
    elseif cmd == 'show' then
        visible[1] = true
        send_auginfo()
    elseif cmd == 'hide' then
        visible[1] = false
    elseif cmd == 'find' or cmd == 'search' then
        search_q[1] = table.concat(args, ' ', 3)
        cur_tab = 'catalog'
        visible[1] = true
    elseif cmd == 'tab' then
        local t = (args[3] or ''):lower()
        if t == 'catalog' or t == '1' then cur_tab = 'catalog'
        elseif t == 'rank' or t == '2' then cur_tab = 'rank'
        elseif t == 'mine' or t == '3' then cur_tab = 'mine' end
        visible[1] = true
    elseif cmd == 'cat' then
        f_cat = math.min(MAX_CAT, math.max(0, tonumber(args[3]) or 0))
    elseif cmd == 'sync' then
        send_auginfo()
        say('Syncing...')
    else
        say('/ab   /ab find haste   /ab tab catalog/rank/mine')
        say('cat 0-' .. MAX_CAT .. '   sync')
    end
end)
