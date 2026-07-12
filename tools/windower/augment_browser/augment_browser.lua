-----------------------------------
-- AugmentBrowser — Windower 4 Addon
-- FJB Relaunch server augment system UI
-- Uses the standard Windower texts library (no extra install needed).
--
-- Toggle:  //ab
-- Commands:
--   //ab tab catalog / rank / mine   switch tabs
--   //ab n  / //ab p                 next / prev page (Catalog tab)
--   //ab tier 0-5                    tier filter  (0 = all)
--   //ab cat  0-N                    category filter (0 = all; N = #data/categories.lua)
--   //ab owned                       toggle owned-only
--   //ab avail                       toggle unlocked-only
--   //ab sync                        re-fetch rank data from server
-----------------------------------
_addon.name     = 'AugmentBrowser'
_addon.version  = '1.2.0'
_addon.author   = 'FJB'
_addon.commands = {'augmentbrowser', 'ab'}

local texts  = require('texts')
local catalog = require('data/catalog')
local cats    = require('data/categories')
local MAX_CAT = #cats   -- categories are contiguous 1..N (11 since the 2026-07-06 rework)

-----------------------------------
-- Constants
-----------------------------------
local RANK_NAMES = { [0]='Unranked', [1]='Initiate', [2]='Adept',
                     [3]='Magus',    [4]='Sage',      [5]='Archon' }
local MASTMULT   = { 1.00, 1.20, 1.40, 1.60, 1.80, 2.00 }
local CRITPCT    = { 0.05, 0.10, 0.15, 0.20, 0.25, 0.30 }
local RANK_REQS  = {
    [1] = { title='Initiate', hlRank=2 },
    [2] = { title='Adept',    hlRank=3 },
    [3] = { title='Magus',    hlRank=5,  prestigeLevel=5,  rebirths=1  },
    [4] = { title='Sage',                prestigeLevel=15, rebirths=10 },
    [5] = { title='Archon',              prestigeLevel=30, rebirths=20, gauntletClears=1 },
}
local PAGE_SIZE = 14
local W         = 60   -- column ruler width

-----------------------------------
-- State
-----------------------------------
local visible  = false
local cur_tab  = 'catalog'
local cur_page = 1

local info = { rank=0, count=0, aff=0, hl_tier=1, prestige=0, rebirths=0, gauntlet=0 }

local inv    = {}   -- item_id -> qty in inventory
local sorted = {}   -- pre-sorted flat list of catalog entries

local f_tier  = 0      -- 0=all
local f_cat   = 0      -- 0=all
local f_owned = false
local f_avail = false

-----------------------------------
-- Text window
-----------------------------------
local win = texts.new({
    pos        = { x=180, y=60 },
    text       = { font='Consolas', size=14, alpha=255, red=255, green=245, blue=210 },
    background = { alpha=240, red=4, green=6, blue=22, visible=true },
    padding    = 12,
    draggable  = true,
    visible    = false,
})

-----------------------------------
-- Utility
-----------------------------------
local SEP  = string.rep('-', W)
local SEP2 = string.rep('=', W)

local function rpad(s, n) s=tostring(s or ''); return s..string.rep(' ', math.max(0,n-#s)) end
local function lpad(s, n) s=tostring(s or ''); return string.rep(' ', math.max(0,n-#s))..s  end

local function pbar(frac, w)
    w = w or 24
    local f = math.floor(math.max(0, math.min(1, frac)) * w + 0.5)
    return '[' .. string.rep('#', f) .. string.rep('-', w-f) .. ']'
end

local function update_inventory()
    inv = {}
    local bags = windower.ffxi.get_items()
    for i = 0, 12 do
        local bag = bags[i]
        if type(bag) == 'table' then
            -- Iterate full slot range; slots are 1-indexed up to max 80
            for s = 1, 80 do
                local it = bag[s]
                if type(it)=='table' and it.id and it.id > 0 then
                    inv[it.id] = (inv[it.id] or 0) + (it.count or 1)
                end
            end
        end
    end
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
           (not f_owned or (inv[e.id] or 0) > 0) and
           (not f_avail or e.tier <= info.rank) then
            out[#out+1] = e
        end
    end
    return out
end

local function cat_name(n)
    return cats[n] and cats[n].name or ('Cat'..n)
end

local function tier_tag(tier)  -- e.g. "T3:Magus "
    return ('T%d:%-6s'):format(tier, (RANK_NAMES[tier] or '?'):sub(1,6))
end

-----------------------------------
-- Header (shared across all tabs)
-----------------------------------
local function make_header()
    local r    = info.rank
    local mult = MASTMULT[r+1] or 1.0
    local crit = (CRITPCT[r+1] or 0.05)*100
    local function tab(name) return cur_tab==name and ('['..name:upper()..']') or name end

    local lines = {}
    lines[#lines+1] = SEP2
    lines[#lines+1] = (' AUGMENT BROWSER    Rank %d: %s    %.2fx    %.0f%% crit')
                        :format(r, RANK_NAMES[r] or '?', mult, crit)
    lines[#lines+1] = ('  %s   %s   %s')
                        :format(tab('catalog'), tab('rank'), tab('mine'))
    return lines
end

-----------------------------------
-- Tab: Catalog
-----------------------------------
local function render_catalog()
    local entries = filtered()
    local total   = #entries
    local pages   = math.max(1, math.ceil(total/PAGE_SIZE))
    cur_page      = math.min(cur_page, pages)
    local first   = (cur_page-1)*PAGE_SIZE + 1
    local last    = math.min(first+PAGE_SIZE-1, total)

    local fa = f_tier==0 and 'All' or ('T'..f_tier)
    local fc = f_cat ==0 and 'All' or cat_name(f_cat):sub(1,10)

    local L = make_header()
    L[#L+1] = (' Tier: %-5s  Cat: %-12s  Owned: %-3s  Avail: %-3s')
                :format(fa, fc, f_owned and 'Yes' or 'No', f_avail and 'Yes' or 'No')
    L[#L+1] = SEP
    L[#L+1] = (' %-24s  %-12s  %-9s  %s'):format('Stat','Category','Tier','Bag')
    L[#L+1] = (' %-24s  %-12s  %-9s  %s')
                :format(string.rep('-',24), string.rep('-',12), string.rep('-',9), '---')

    for i = first, last do
        local e   = entries[i]
        local qty = inv[e.id] or 0
        local lk  = e.tier > info.rank and '!' or ' '
        L[#L+1]   = ('%s %-24s  %-12s  %-9s  %s')
                        :format(lk, e.label:sub(1,24), cat_name(e.cat):sub(1,12),
                                tier_tag(e.tier), qty>0 and tostring(qty) or '-')
    end

    L[#L+1] = SEP
    L[#L+1] = (' Page %d / %d   (%d-%d of %d)   //ab n  //ab p   ! = locked')
                :format(cur_page, pages, first, last, total)
    L[#L+1] = SEP2
    return table.concat(L, '\n')
end

-----------------------------------
-- Tab: Rank Progress
-----------------------------------
local function render_rank()
    local r    = info.rank
    local mult = MASTMULT[r+1] or 1.0
    local crit = (CRITPCT[r+1] or 0.05)*100

    local L = make_header()
    L[#L+1] = SEP
    L[#L+1] = (' Current: Rank %d: %s  |  %.2fx mastery  |  %.0f%% crit')
                :format(r, RANK_NAMES[r] or '?', mult, crit)
    L[#L+1] = (' Total augments applied: %d'):format(info.count)
    L[#L+1] = ''

    local nr  = r + 1
    local req = RANK_REQS[nr]
    if not req then
        L[#L+1] = ' *** Max rank reached: Augment Archon! ***'
        L[#L+1] = ' All augments are now accessible.'
    else
        L[#L+1] = (' Next: Rank %d – %s'):format(nr, req.title)
        L[#L+1] = ''
        L[#L+1] = ' Requirements:'
        if req.hlRank then
            local ok = info.hl_tier >= req.hlRank
            L[#L+1] = ('   %s  Hunting League Rank   %d / %d')
                        :format(ok and '[OK]' or '[ ]', info.hl_tier, req.hlRank)
        end
        if req.prestigeLevel then
            local ok = info.prestige >= req.prestigeLevel
            L[#L+1] = ('   %s  Prestige Level         %d / %d')
                        :format(ok and '[OK]' or '[ ]', info.prestige, req.prestigeLevel)
        end
        if req.rebirths then
            local ok   = info.rebirths >= req.rebirths
            local frac = math.min(info.rebirths/req.rebirths, 1.0)
            L[#L+1] = ('   %s  Total Rebirths         %d / %d')
                        :format(ok and '[OK]' or '[ ]', info.rebirths, req.rebirths)
            L[#L+1] = ('        %s  %.0f%%'):format(pbar(frac, 24), frac*100)
        end
        if req.gauntletClears then
            local ok = info.gauntlet >= req.gauntletClears
            L[#L+1] = ('   %s  Gauntlet Clears        %d / %d')
                        :format(ok and '[OK]' or '[ ]', info.gauntlet, req.gauntletClears)
        end
    end

    L[#L+1] = ''
    L[#L+1] = SEP
    L[#L+1] = ' Rank overview:'
    L[#L+1] = ''
    for rv = 0, 5 do
        local mk = rv == r and '>' or ' '
        L[#L+1] = ('  %s Rank %d: %-10s  %.2fx mult  %.0f%% crit')
                    :format(mk, rv, RANK_NAMES[rv] or '?',
                            MASTMULT[rv+1] or 1.0, (CRITPCT[rv+1] or 0.05)*100)
    end
    L[#L+1] = SEP2
    return table.concat(L, '\n')
end

-----------------------------------
-- Tab: My Catalysts
-----------------------------------
local function render_mine()
    local ready, locked_list = {}, {}
    for _, e in ipairs(sorted) do
        if (inv[e.id] or 0) > 0 then
            if e.tier <= info.rank then ready[#ready+1] = e
            else                        locked_list[#locked_list+1] = e end
        end
    end

    local L = make_header()
    L[#L+1] = SEP
    L[#L+1] = (' %d ready catalyst(s)  |  %d locked'):format(#ready, #locked_list)
    L[#L+1] = ' Trade ready catalysts to the Augment Moogle in Leafallia.'
    L[#L+1] = ''

    local hdr = (' %-24s  %-12s  %-9s  %s')
                    :format('Stat','Category','Tier','Qty')
    local div = (' %-24s  %-12s  %-9s  %s')
                    :format(string.rep('-',24),string.rep('-',12),string.rep('-',9),'---')

    local function emit_rows(list)
        L[#L+1] = hdr; L[#L+1] = div
        for _, e in ipairs(list) do
            L[#L+1] = (' %-24s  %-12s  %-9s  %d')
                        :format(e.label:sub(1,24), cat_name(e.cat):sub(1,12),
                                tier_tag(e.tier), inv[e.id])
        end
    end

    if #ready > 0 then
        L[#L+1] = ' -- READY (tradeable at your rank) --'
        emit_rows(ready)
    else
        L[#L+1] = ' (no ready catalysts in inventory)'
    end

    if #locked_list > 0 then
        L[#L+1] = ''
        L[#L+1] = ' -- LOCKED (need higher rank) --'
        emit_rows(locked_list)
    end

    L[#L+1] = SEP2
    return table.concat(L, '\n')
end

-----------------------------------
-- Render dispatcher
-----------------------------------
local function render()
    if not visible then win:hide(); return end
    local content
    if     cur_tab == 'rank' then content = render_rank()
    elseif cur_tab == 'mine' then content = render_mine()
    else                          content = render_catalog() end
    win:text(content)
    win:show()
end

-----------------------------------
-- [AUGINFO] response parser
-----------------------------------
windower.register_event('incoming text', function(orig)
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
    render()
    return true
end)

-----------------------------------
-- Events
-----------------------------------
local function send_auginfo()
    windower.send_command('input !auginfo')
end

windower.register_event('load', function()
    build_sorted()
    update_inventory()
    coroutine.sleep(3)
    send_auginfo()
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

windower.register_event('unload', function()
    visible = false; win:hide()
end)

-----------------------------------
-- Commands
-----------------------------------
windower.register_event('addon command', function(cmd, arg1)
    cmd  = (cmd  or ''):lower()
    arg1 = (arg1 or ''):lower()

    if cmd == '' or cmd == 'toggle' or cmd == 't' then
        visible = not visible; render()

    elseif cmd == 'show'  then visible = true;  render()
    elseif cmd == 'hide'  then visible = false; render()

    elseif cmd == 'tab' then
        if     arg1 == 'catalog' or arg1 == '1' then cur_tab = 'catalog'
        elseif arg1 == 'rank'    or arg1 == '2' then cur_tab = 'rank'
        elseif arg1 == 'mine'    or arg1 == '3' then cur_tab = 'mine' end
        cur_page = 1; visible = true; render()

    elseif cmd == 'n' or cmd == 'next' then cur_page = cur_page + 1; render()
    elseif cmd == 'p' or cmd == 'prev' then cur_page = math.max(1, cur_page-1); render()

    elseif cmd == 'tier'  then f_tier  = math.min(5, math.max(0,tonumber(arg1) or 0)); cur_page=1; render()
    elseif cmd == 'cat'   then f_cat   = math.min(MAX_CAT,math.max(0,tonumber(arg1) or 0)); cur_page=1; render()
    elseif cmd == 'owned' then f_owned = not f_owned; cur_page=1; render()
    elseif cmd == 'avail' then f_avail = not f_avail; cur_page=1; render()

    elseif cmd == 'sync' then
        update_inventory()
        send_auginfo()
        windower.add_to_chat(207, '[AugmentBrowser] Syncing...')

    else
        local h = '[AugmentBrowser]  //ab <cmd>:'
        windower.add_to_chat(207, h)
        windower.add_to_chat(207, '  (toggle)  tab catalog/rank/mine  n  p')
        windower.add_to_chat(207, ('  tier 0-5  cat 0-%d  owned  avail  sync'):format(MAX_CAT))
    end
end)
