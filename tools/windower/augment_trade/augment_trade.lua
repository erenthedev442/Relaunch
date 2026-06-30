-----------------------------------
-- AugmentTrade — Windower 4 Addon  (v2 — adds in-addon trade execution)
-- FJB Relaunch server augment system UI + one-command augment trading.
--
-- Requires: scripts/commands/augment.lua deployed on the relaunch server.
-- No extra Windower libraries needed beyond the standard texts library.
--
-- TRADE FLOW:
--   1. //at pick <catalyst_id> [qty]   add catalyst(s) to pending trade
--   2. //at gear <gear_item_id>        set gear piece to augment
--   3. //at trade                      send !augment to server & execute
--
-- ALL COMMANDS  (//at or //augmenttrade):
--   //at                    toggle window
--   //at tab catalog        browse all augments
--   //at tab rank           rank progress + requirements
--   //at tab mine           catalysts in inventory + trade UI
--   //at n  /  //at p       next / prev catalog page
--   //at tier 0-5           tier filter (0=all)
--   //at cat  0-24          category filter (0=all)
--   //at owned / avail      toggle owned-only / unlocked-only
--   //at pick <id> [qty]    add catalyst to pending trade
--   //at unpick [id]        remove catalyst (or clear all)
--   //at gear <item_id>     set gear piece to augment
--   //at clear              clear pending trade selection
--   //at trade              execute pending trade
--   //at sync               re-fetch rank data from server
-----------------------------------
_addon.name     = 'AugmentTrade'
_addon.version  = '2.0.0'
_addon.author   = 'FJB'
_addon.commands = {'augmenttrade', 'at'}

local texts   = require('texts')
local catalog = require('data/catalog')
local cats    = require('data/categories')

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
local MAX_SLOTS = 5
local PAGE_SIZE = 14
local W         = 60

-----------------------------------
-- State
-----------------------------------
local visible  = false
local cur_tab  = 'mine'
local cur_page = 1

local info = { rank=0, count=0, aff=0, hl_tier=1, prestige=0, rebirths=0, gauntlet=0 }
local inv  = {}     -- item_id -> qty
local sorted = {}   -- pre-sorted catalog entries

local f_tier  = 0
local f_cat   = 0
local f_owned = false
local f_avail = false

-- Pending trade state
local sel_cats = {}    -- ordered list of {id=number, qty=number}
local sel_gear = 0     -- gear item_id

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

local function pbar(frac, w)
    w = w or 24
    local f = math.floor(math.max(0, math.min(1, frac)) * w + 0.5)
    return '[' .. string.rep('#', f) .. string.rep('-', w-f) .. ']'
end

local function cat_name(n)
    return cats[n] and cats[n].name or ('Cat'..n)
end

local function tier_tag(tier)
    return ('T%d:%-6s'):format(tier, (RANK_NAMES[tier] or '?'):sub(1,6))
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

local function update_inventory()
    inv = {}
    local bags = windower.ffxi.get_items()
    for i = 0, 12 do
        local bag = bags[i]
        if type(bag) == 'table' then
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

local function send_auginfo()
    windower.send_command('input !auginfo')
end

-----------------------------------
-- Header
-----------------------------------
local function make_header()
    local r    = info.rank
    local mult = MASTMULT[r+1] or 1.0
    local crit = (CRITPCT[r+1] or 0.05)*100
    local function tab(name)
        return cur_tab==name and ('['..name:upper()..']') or name
    end
    local L = {}
    L[#L+1] = SEP2
    L[#L+1] = (' AUGMENT TRADE      Rank %d: %s    %.2fx    %.0f%% crit')
                :format(r, RANK_NAMES[r] or '?', mult, crit)
    L[#L+1] = ('  %s   %s   %s')
                :format(tab('catalog'), tab('rank'), tab('mine'))
    return L
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
                :format(string.rep('-',24),string.rep('-',12),string.rep('-',9),'---')

    for i = first, last do
        local e   = entries[i]
        local qty = inv[e.id] or 0
        local lk  = e.tier > info.rank and '!' or ' '
        L[#L+1]   = ('%s %-24s  %-12s  %-9s  %s')
                        :format(lk, e.label:sub(1,24), cat_name(e.cat):sub(1,12),
                                tier_tag(e.tier), qty>0 and tostring(qty) or '-')
    end

    L[#L+1] = SEP
    L[#L+1] = (' Page %d / %d   (%d-%d of %d)   //at n  //at p   ! = locked')
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
        L[#L+1] = (' Next: Rank %d - %s'):format(nr, req.title)
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
-- Tab: My Catalysts + Trade UI
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

    -- Pending trade box
    local used = sel_total_slots()
    local gear_str = sel_gear > 0 and ('Item ID ' .. sel_gear) or 'None   //at gear <item_id>'
    L[#L+1] = ' PENDING TRADE'
    L[#L+1] = (' Gear:   %s'):format(gear_str)

    if #sel_cats == 0 then
        L[#L+1] = ' Cats:   None   //at pick <catalyst_id> [qty]'
    else
        local parts = {}
        for _, s in ipairs(sel_cats) do
            local e = catalog[s.id]
            local lbl = e and e.label:sub(1,18) or ('id '..s.id)
            parts[#parts+1] = string.format('%s x%d', lbl, s.qty)
        end
        L[#L+1] = (' Cats:   %s  (%d/%d slots)'):format(table.concat(parts, ',  '), used, MAX_SLOTS)
    end

    L[#L+1] = ' Cost:   10,000 gil'

    -- Trade / clear row
    local can_trade = sel_gear > 0 and #sel_cats > 0
    if can_trade then
        L[#L+1] = ' >> //at trade   to execute    //at clear   to reset'
    else
        L[#L+1] = ' (set gear and at least one catalyst to enable //at trade)'
    end

    L[#L+1] = SEP

    -- Ready catalysts
    local col_hdr = (' %-22s  %-10s  %-9s  %-4s  %s')
                        :format('Stat','Category','Tier','Bag','Add')
    local col_div = (' %-22s  %-10s  %-9s  %-4s  %s')
                        :format(string.rep('-',22),string.rep('-',10),
                                string.rep('-',9),string.rep('-',4),string.rep('-',18))

    if #ready > 0 then
        L[#L+1] = (' READY  (%d/%d slots used)   //at pick <id> [qty]   //at unpick [id]')
                    :format(used, MAX_SLOTS)
        L[#L+1] = col_hdr
        L[#L+1] = col_div
        for _, e in ipairs(ready) do
            local qty     = inv[e.id] or 0
            local sel_idx = sel_find(e.id)
            local sel_str = sel_idx and ('x'..sel_cats[sel_idx].qty..' sel') or ''
            local add_str = used < MAX_SLOTS and ('//at pick '..e.id) or '[full]'
            L[#L+1] = (' %-22s  %-10s  %-9s  %-4s  %-18s  %s')
                        :format(e.label:sub(1,22), cat_name(e.cat):sub(1,10),
                                tier_tag(e.tier), tostring(qty), add_str, sel_str)
        end
    else
        L[#L+1] = ' (no ready catalysts in inventory)'
    end

    if #locked_list > 0 then
        L[#L+1] = ''
        L[#L+1] = ' LOCKED (need higher rank):'
        for _, e in ipairs(locked_list) do
            L[#L+1] = ('  ! %-22s  %-10s  %-9s  %d')
                        :format(e.label:sub(1,22), cat_name(e.cat):sub(1,10),
                                tier_tag(e.tier), inv[e.id])
        end
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
-- Incoming text interceptors
-----------------------------------
windower.register_event('incoming text', function(orig)
    local clean = orig:gsub('\x1E.', ''):gsub('\x1F.', '')

    -- [AUGINFO] - rank data from !auginfo
    local data = clean:match('%[AUGINFO%](.+)')
    if data then
        info.rank     = tonumber(data:match('rank=(%d+)'))     or 0
        info.count    = tonumber(data:match('count=(%d+)'))    or 0
        info.aff      = tonumber(data:match('aff=(%d+)'))      or 0
        info.hl_tier  = tonumber(data:match('hl=(%d+)'))       or 1
        info.prestige = tonumber(data:match('prestige=(%d+)')) or 0
        info.rebirths = tonumber(data:match('rebirths=(%d+)')) or 0
        info.gauntlet = tonumber(data:match('gauntlet=(%d+)')) or 0
        render()
        return true
    end

    -- [AUGDONE] - trade success; refresh inventory + rank counter
    if clean:match('%[AUGDONE%]') then
        update_inventory()
        coroutine.sleep(1)
        send_auginfo()
        -- Don't suppress — let the full message show in chat
    end
end)

-----------------------------------
-- Events
-----------------------------------
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
windower.register_event('addon command', function(cmd, arg1, arg2)
    cmd  = (cmd  or ''):lower()
    arg1 = (arg1 or '')
    arg2 = (arg2 or '')

    if cmd == '' or cmd == 'toggle' or cmd == 't' then
        visible = not visible; render()

    elseif cmd == 'show'  then visible = true;  render()
    elseif cmd == 'hide'  then visible = false; render()

    elseif cmd == 'tab' then
        local t = arg1:lower()
        if     t == 'catalog' or t == '1' then cur_tab = 'catalog'
        elseif t == 'rank'    or t == '2' then cur_tab = 'rank'
        elseif t == 'mine'    or t == '3' then cur_tab = 'mine' end
        cur_page = 1; visible = true; render()

    elseif cmd == 'n' or cmd == 'next' then cur_page = cur_page + 1; render()
    elseif cmd == 'p' or cmd == 'prev' then cur_page = math.max(1, cur_page-1); render()

    elseif cmd == 'tier'  then f_tier  = math.min(5, math.max(0,tonumber(arg1) or 0)); cur_page=1; render()
    elseif cmd == 'cat'   then f_cat   = math.min(24,math.max(0,tonumber(arg1) or 0)); cur_page=1; render()
    elseif cmd == 'owned' then f_owned = not f_owned; cur_page=1; render()
    elseif cmd == 'avail' then f_avail = not f_avail; cur_page=1; render()

    -- Trade commands
    elseif cmd == 'gear' then
        local id = tonumber(arg1)
        if id and id > 0 then
            sel_gear = id
            windower.add_to_chat(207, '[AugmentTrade] Gear set to item ID ' .. id)
        else
            windower.add_to_chat(207, '[AugmentTrade] Usage: //at gear <item_id>')
        end
        cur_tab = 'mine'; visible = true; render()

    elseif cmd == 'pick' then
        local id  = tonumber(arg1)
        local qty = math.max(1, tonumber(arg2) or 1)
        if not id or id <= 0 then
            windower.add_to_chat(207, '[AugmentTrade] Usage: //at pick <catalyst_id> [qty]')
        elseif sel_total_slots() + qty > MAX_SLOTS then
            windower.add_to_chat(207, string.format('[AugmentTrade] Only %d slots remain.', MAX_SLOTS - sel_total_slots()))
        else
            local idx = sel_find(id)
            if idx then
                sel_cats[idx].qty = sel_cats[idx].qty + qty
            else
                sel_cats[#sel_cats+1] = { id=id, qty=qty }
            end
            windower.add_to_chat(207, '[AugmentTrade] Added ' .. qty .. 'x ' .. id .. ' to pending trade.')
        end
        cur_tab = 'mine'; visible = true; render()

    elseif cmd == 'unpick' then
        local id = tonumber(arg1)
        if id then
            local idx = sel_find(id)
            if idx then
                table.remove(sel_cats, idx)
                windower.add_to_chat(207, '[AugmentTrade] Removed ' .. id .. ' from selection.')
            end
        else
            sel_cats = {}
            windower.add_to_chat(207, '[AugmentTrade] Cleared all catalysts from selection.')
        end
        cur_tab = 'mine'; visible = true; render()

    elseif cmd == 'clear' then
        sel_cats = {}
        sel_gear = 0
        windower.add_to_chat(207, '[AugmentTrade] Pending trade cleared.')
        cur_tab = 'mine'; visible = true; render()

    elseif cmd == 'trade' then
        if sel_gear == 0 then
            windower.add_to_chat(207, '[AugmentTrade] No gear set. Use //at gear <item_id> first.')
        elseif #sel_cats == 0 then
            windower.add_to_chat(207, '[AugmentTrade] No catalysts selected. Use //at pick <id> [qty].')
        else
            local parts = { tostring(sel_gear) }
            for _, s in ipairs(sel_cats) do
                parts[#parts+1] = s.id .. ':' .. s.qty
            end
            local full_cmd = 'input !augment ' .. table.concat(parts, ' ')
            windower.add_to_chat(207, '[AugmentTrade] Sending: !' .. table.concat(parts, ' '))
            windower.send_command(full_cmd)
            -- Clear selection after sending; inventory + rank refresh via [AUGDONE]
            sel_cats = {}
            sel_gear = 0
            render()
        end

    elseif cmd == 'sync' then
        update_inventory()
        send_auginfo()
        windower.add_to_chat(207, '[AugmentTrade] Syncing...')

    else
        windower.add_to_chat(207, '[AugmentTrade] Commands:')
        windower.add_to_chat(207, '  //at  tab catalog/rank/mine  n  p  tier/cat/owned/avail')
        windower.add_to_chat(207, '  //at pick <id> [qty]   //at unpick [id]   //at clear')
        windower.add_to_chat(207, '  //at gear <item_id>    //at trade         //at sync')
    end
end)
