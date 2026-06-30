-----------------------------------
-- AugmentBrowser — Windower 4 Addon
-- FJB Relaunch server augment system UI
--
-- Commands:
--   //ab          toggle window
--   //ab show     open
--   //ab hide     close
--   //ab sync     re-fetch rank info + refresh inventory
--
-- Requires the Windower imgui library:
--   https://github.com/Windower/Lua/tree/release/addons/imgui
--   Place imgui.lua in Windower/addons/libs/
-----------------------------------
_addon.name     = 'AugmentBrowser'
_addon.version  = '1.1.0'
_addon.author   = 'FJB'
_addon.commands = {'augmentbrowser', 'ab'}

local imgui_ok, imgui = pcall(require, 'imgui')
if not imgui_ok then
    error('[AugmentBrowser] imgui library not found. Install it to Windower/addons/libs/imgui.lua')
end

local catalog = require('data/catalog')
local cats    = require('data/categories')

-----------------------------------
-- Constants
-----------------------------------
local RANK_NAMES = {
    [0] = 'Unranked',
    [1] = 'Initiate',
    [2] = 'Adept',
    [3] = 'Magus',
    [4] = 'Sage',
    [5] = 'Archon',
}

local TIER_COLOR = {
    [0] = { 0.65, 0.65, 0.65, 1.00 },  -- grey    – free
    [1] = { 0.40, 0.90, 0.40, 1.00 },  -- green   – Initiate
    [2] = { 0.35, 0.75, 1.00, 1.00 },  -- cyan    – Adept
    [3] = { 1.00, 0.90, 0.25, 1.00 },  -- yellow  – Magus
    [4] = { 1.00, 0.55, 0.15, 1.00 },  -- orange  – Sage
    [5] = { 0.85, 0.25, 1.00, 1.00 },  -- purple  – Archon
}

-- Mirrors augment_sage_catalog.lua ranks table
local RANK_REQS = {
    [1] = { title = 'Initiate', hlRank = 2 },
    [2] = { title = 'Adept',    hlRank = 3 },
    [3] = { title = 'Magus',    hlRank = 5,  prestigeLevel = 5,  rebirths = 1  },
    [4] = { title = 'Sage',                  prestigeLevel = 15, rebirths = 10 },
    [5] = { title = 'Archon',                prestigeLevel = 30, rebirths = 20, gauntletClears = 1 },
}

local MASTMULT = { 1.00, 1.20, 1.40, 1.60, 1.80, 2.00 }
local CRITPCT  = { 0.05, 0.10, 0.15, 0.20, 0.25, 0.30 }

-----------------------------------
-- State
-----------------------------------
local vis = { false }    -- imgui open flag

local info = {           -- populated from !auginfo server response
    rank     = 0,
    count    = 0,
    aff      = 0,
    hl_tier  = 1,
    prestige = 0,
    rebirths = 0,
    gauntlet = 0,
}

local inv    = {}        -- item_id → qty in inventory
local sorted = {}        -- flat sorted list of catalog entries for display

-- Filter controls (imgui 1-element arrays)
local f_tier  = { 0 }   -- combo index 0=All, 1–6 map to tier 0–5
local f_cat   = { 0 }   -- combo index 0=All, 1–24 map to cat 1–24
local f_owned = { false }
local f_avail = { false }

-----------------------------------
-- Combo label tables
-----------------------------------
local TIER_LABELS = {
    'All Tiers',
    'T0 – Free',
    'T1 – Initiate',
    'T2 – Adept',
    'T3 – Magus',
    'T4 – Sage',
    'T5 – Archon',
}

local CAT_LABELS = { 'All Categories' }
for i = 1, 24 do
    local c = cats[i]
    CAT_LABELS[#CAT_LABELS + 1] = c and (i .. ': ' .. c.name) or ('Cat ' .. i)
end

-----------------------------------
-- Helpers
-----------------------------------
local function update_inventory()
    inv = {}
    local bags = windower.ffxi.get_items()
    for bag_idx = 0, 12 do
        local bag = bags[bag_idx]
        if type(bag) == 'table' then
            for slot = 0, (bag.count or 80) do
                local item = bag[slot]
                if type(item) == 'table' and item.id and item.id > 0 then
                    inv[item.id] = (inv[item.id] or 0) + (item.count or 1)
                end
            end
        end
    end
end

local function build_sorted()
    sorted = {}
    for item_id, e in pairs(catalog) do
        sorted[#sorted + 1] = {
            id    = item_id,
            label = e.label,
            cat   = e.cat,
            tier  = e.tier,
        }
    end
    table.sort(sorted, function(a, b)
        if a.tier ~= b.tier then return a.tier < b.tier end
        if a.cat  ~= b.cat  then return a.cat  < b.cat  end
        return a.label < b.label
    end)
end

local function tier_text(tier)
    local c = TIER_COLOR[tier] or TIER_COLOR[0]
    local label = tier == 0 and 'Free' or ('T' .. tier .. ': ' .. (RANK_NAMES[tier] or '?'))
    imgui.TextColored(c, label)
end

local function req_line(label, have, need)
    if have >= need then
        imgui.TextColored({ 0.30, 1.00, 0.30, 1 }, ('  %s: %d/%d  [OK]'):format(label, have, need))
    else
        imgui.TextColored({ 1.00, 0.35, 0.35, 1 }, ('  %s: %d/%d'):format(label, have, need))
    end
end

local function rank_color(rank)
    return TIER_COLOR[rank] or TIER_COLOR[0]
end

local function request_info()
    windower.ffxi.chat('!auginfo')
end

-----------------------------------
-- Tab: Catalog
-----------------------------------
local function draw_catalog()
    -- Filter bar
    imgui.SetNextItemWidth(145)
    imgui.Combo('##ftier', f_tier, TIER_LABELS, #TIER_LABELS)
    imgui.SameLine()
    imgui.SetNextItemWidth(180)
    imgui.Combo('##fcat', f_cat, CAT_LABELS, #CAT_LABELS)
    imgui.SameLine()
    imgui.Checkbox('Owned', f_owned)
    imgui.SameLine()
    imgui.Checkbox('Unlocked', f_avail)
    imgui.Separator()

    local TF = imgui.constant.TableFlags
    local tflags = TF.BordersOuter + TF.BordersInnerV + TF.ScrollY + TF.RowBg + TF.Resizable
    local CF = imgui.constant.TableColumnFlags

    if imgui.BeginTable('augcat', 5, tflags, 0, 390) then
        imgui.TableSetupScrollFreeze(0, 1)
        imgui.TableSetupColumn('Augment Stat',  CF.WidthStretch,  0.35)
        imgui.TableSetupColumn('Category',      CF.WidthStretch,  0.25)
        imgui.TableSetupColumn('Tier',          CF.WidthFixed,    110)
        imgui.TableSetupColumn('In Bag',        CF.WidthFixed,     55)
        imgui.TableSetupColumn('Item ID',       CF.WidthFixed,     65)
        imgui.TableHeadersRow()

        local sel_tier  = f_tier[1]   -- 0 = All; 1–6 → tier 0–5
        local sel_cat   = f_cat[1]    -- 0 = All; 1–24 → cat 1–24

        for _, e in ipairs(sorted) do
            if sel_tier > 0 and e.tier ~= (sel_tier - 1) then goto skip end
            if sel_cat  > 0 and e.cat  ~= sel_cat         then goto skip end
            local qty = inv[e.id] or 0
            if f_owned[1] and qty == 0                     then goto skip end
            if f_avail[1] and e.tier > info.rank           then goto skip end

            local locked = e.tier > info.rank
            local col    = locked and { 0.45, 0.45, 0.45, 1 } or { 1, 1, 1, 1 }

            imgui.TableNextRow()
            imgui.TableSetColumnIndex(0)
            imgui.TextColored(col, e.label)

            imgui.TableSetColumnIndex(1)
            local cat_info = cats[e.cat]
            imgui.TextColored(col, cat_info and cat_info.name or ('Cat ' .. e.cat))

            imgui.TableSetColumnIndex(2)
            tier_text(e.tier)

            imgui.TableSetColumnIndex(3)
            if qty > 0 then
                imgui.TextColored({ 0.30, 1.00, 0.30, 1 }, tostring(qty))
            else
                imgui.TextColored({ 0.40, 0.40, 0.40, 1 }, '—')
            end

            imgui.TableSetColumnIndex(4)
            imgui.TextColored({ 0.55, 0.55, 0.55, 1 }, tostring(e.id))

            ::skip::
        end
        imgui.EndTable()
    end
end

-----------------------------------
-- Tab: Rank Progress
-----------------------------------
local function draw_rank()
    local rc = rank_color(info.rank)
    imgui.Text('Current Rank: ')
    imgui.SameLine()
    imgui.TextColored(rc, ('%d – %s'):format(info.rank, RANK_NAMES[info.rank] or '?'))

    imgui.Text(('Mastery Multiplier: %.2fx    Crit Chance: %.0f%%')
        :format(MASTMULT[info.rank + 1] or 1.00, (CRITPCT[info.rank + 1] or 0.05) * 100))
    imgui.Text(('Total Augments Applied: %d'):format(info.count))
    imgui.Separator()

    local next_rank = info.rank + 1
    local req       = RANK_REQS[next_rank]

    if not req then
        imgui.Spacing()
        imgui.TextColored({ 0.90, 0.80, 0.20, 1 }, 'Max rank reached: Augment Archon!')
        imgui.TextColored({ 0.65, 0.65, 0.65, 1 }, 'All augments are now accessible.')
        return
    end

    local nc = rank_color(next_rank)
    imgui.Text('Next Rank: ')
    imgui.SameLine()
    imgui.TextColored(nc, ('%d – %s'):format(next_rank, req.title))
    imgui.Spacing()
    imgui.Text('Requirements:')

    if req.hlRank then
        req_line('Hunting League Rank', info.hl_tier, req.hlRank)
    end
    if req.prestigeLevel then
        req_line('Prestige Level (best job)', info.prestige, req.prestigeLevel)
    end
    if req.rebirths then
        req_line('Total Rebirths', info.rebirths, req.rebirths)
        imgui.Spacing()
        imgui.Text('  Rebirth progress:')
        local frac = math.min(info.rebirths / req.rebirths, 1.0)
        imgui.ProgressBar(frac, -1, 0, ('%d / %d'):format(info.rebirths, req.rebirths))
    end
    if req.gauntletClears then
        req_line('Gauntlet Clears', info.gauntlet, req.gauntletClears)
    end

    imgui.Separator()
    imgui.Spacing()
    -- All 5 ranks overview
    imgui.Text('Rank overview:')
    imgui.Spacing()
    for r = 0, 5 do
        local c = rank_color(r)
        local marker = r == info.rank and '>' or ' '
        imgui.TextColored(c, (' %s  Rank %d %-10s  %.2fx mult  %.0f%% crit')
            :format(marker, r, RANK_NAMES[r] or '', MASTMULT[r + 1] or 1.0, (CRITPCT[r + 1] or 0.05) * 100))
    end
end

-----------------------------------
-- Tab: My Catalysts
-----------------------------------
local function draw_catalysts()
    -- Count how many usable vs locked
    local usable_count, locked_count = 0, 0
    for _, e in ipairs(sorted) do
        local qty = inv[e.id] or 0
        if qty > 0 then
            if e.tier <= info.rank then usable_count = usable_count + 1
            else                        locked_count  = locked_count  + 1 end
        end
    end

    imgui.TextColored({ 0.30, 1.00, 0.30, 1 }, ('Usable catalysts: %d'):format(usable_count))
    imgui.SameLine()
    imgui.TextColored({ 0.45, 0.45, 0.45, 1 }, ('   Locked: %d'):format(locked_count))
    imgui.Separator()

    local TF = imgui.constant.TableFlags
    local tflags = TF.BordersOuter + TF.BordersInnerV + TF.ScrollY + TF.RowBg
    local CF = imgui.constant.TableColumnFlags

    if imgui.BeginTable('mycats', 5, tflags, 0, 380) then
        imgui.TableSetupScrollFreeze(0, 1)
        imgui.TableSetupColumn('Augment Stat',  CF.WidthStretch, 0.38)
        imgui.TableSetupColumn('Category',      CF.WidthStretch, 0.25)
        imgui.TableSetupColumn('Tier',          CF.WidthFixed,   110)
        imgui.TableSetupColumn('Qty',           CF.WidthFixed,    40)
        imgui.TableSetupColumn('Status',        CF.WidthFixed,    80)
        imgui.TableHeadersRow()

        -- Usable first, then locked
        for pass = 1, 2 do
            for _, e in ipairs(sorted) do
                local qty    = inv[e.id] or 0
                local locked = e.tier > info.rank
                if qty == 0 then goto skip2 end
                if pass == 1 and locked  then goto skip2 end
                if pass == 2 and not locked then goto skip2 end

                imgui.TableNextRow()
                imgui.TableSetColumnIndex(0)
                if locked then
                    imgui.TextColored({ 0.45, 0.45, 0.45, 1 }, e.label)
                else
                    imgui.Text(e.label)
                end

                imgui.TableSetColumnIndex(1)
                local cat_info = cats[e.cat]
                imgui.Text(cat_info and cat_info.name or '')

                imgui.TableSetColumnIndex(2)
                tier_text(e.tier)

                imgui.TableSetColumnIndex(3)
                imgui.Text(tostring(qty))

                imgui.TableSetColumnIndex(4)
                if locked then
                    local need = e.tier
                    imgui.TextColored({ 1.00, 0.35, 0.35, 1 }, 'Need T' .. need)
                else
                    imgui.TextColored({ 0.30, 1.00, 0.30, 1 }, 'Ready!')
                end

                ::skip2::
            end
        end
        imgui.EndTable()
    end

    imgui.Separator()
    imgui.TextColored({ 0.55, 0.55, 0.55, 1 },
        'Trade ready catalysts to the Augment Moogle in Leafallia.')
end

-----------------------------------
-- Main window
-----------------------------------
windower.register_event('prerender', function()
    if not vis[1] then return end

    imgui.SetNextWindowSize(720, 540, 'FirstUseEver')
    imgui.SetNextWindowPos(120, 80, 'FirstUseEver')

    local title = ('Augment Browser  [Rank %d: %s]###AugBrowser')
        :format(info.rank, RANK_NAMES[info.rank] or '?')

    if imgui.Begin(title, vis) then
        if imgui.BeginTabBar('ab_tabs') then
            if imgui.BeginTabItem('Catalog') then
                draw_catalog()
                imgui.EndTabItem()
            end
            if imgui.BeginTabItem('Rank Progress') then
                draw_rank()
                imgui.EndTabItem()
            end
            if imgui.BeginTabItem('My Catalysts') then
                draw_catalysts()
                imgui.EndTabItem()
            end
            imgui.EndTabBar()
        end
    end
    imgui.End()
end)

-----------------------------------
-- Parse [AUGINFO] server response
-----------------------------------
windower.register_event('incoming text', function(orig, _, _)
    -- Strip FFXI color/escape codes before matching
    local clean = orig:gsub('\x1E.', ''):gsub('\x1F.', '')
    local data  = clean:match('%[AUGINFO%](.+)')
    if not data then return end

    info.rank     = tonumber(data:match('rank=(%d+)'))     or 0
    info.count    = tonumber(data:match('count=(%d+)'))    or 0
    info.aff      = tonumber(data:match('aff=(%d+)'))      or 0
    info.hl_tier  = tonumber(data:match('hl=(%d+)'))       or 1
    info.prestige = tonumber(data:match('prestige=(%d+)')) or 0
    info.rebirths = tonumber(data:match('rebirths=(%d+)')) or 0
    info.gauntlet = tonumber(data:match('gauntlet=(%d+)')) or 0

    return true  -- suppress display
end)

-----------------------------------
-- Events
-----------------------------------
windower.register_event('load', function()
    build_sorted()
    update_inventory()
    coroutine.sleep(3)
    request_info()
end)

windower.register_event('login', function()
    update_inventory()
    coroutine.sleep(5)
    request_info()
end)

windower.register_event('zone change', function()
    update_inventory()
    coroutine.sleep(3)
    request_info()
end)

windower.register_event('item change', function(_, _, _, _, _)
    update_inventory()
end)

windower.register_event('unload', function()
    vis[1] = false
end)

-----------------------------------
-- Commands
-----------------------------------
windower.register_event('addon command', function(cmd, ...)
    cmd = (cmd or 'toggle'):lower()
    if cmd == 'toggle' or cmd == 't' then
        vis[1] = not vis[1]
    elseif cmd == 'show' or cmd == 'open' then
        vis[1] = true
    elseif cmd == 'hide' or cmd == 'close' then
        vis[1] = false
    elseif cmd == 'sync' then
        update_inventory()
        request_info()
        windower.add_to_chat(207, '[AugmentBrowser] Synced inventory and rank info.')
    else
        windower.add_to_chat(207, '[AugmentBrowser] Commands: //ab  //ab show  //ab hide  //ab sync')
    end
end)
