-----------------------------------
-- combat_records.lua
-- Tracks personal-best combat records split by mob level tier.
--
-- Tiers:  T1 = Lv 1–33 | T2 = Lv 34–67 | T3 = Lv 68–99 | T4 = Lv 100+
--
-- CharVars written per tier (replace {N} with 1-4):
--   MaxHeal_T{N}   – largest single heal on any target
--   MaxNuke_T{N}   – largest single magic damage hit on a mob
--   MaxBurst_T{N}  – largest magic burst hit on a mob
--   MaxSC_T{N}     – largest skillchain on a mob (requires C++ rebuild for getAddEffectParam)
--   MaxDmg30_T{N}  – most combined WS + magic + ranged damage in a rolling 30-second window
--
-- Listeners are registered on every zone-in (idempotent key). The 30-second
-- damage window is cleared on zone (per-zone RAM table, not persisted).
-- Needs one map restart to start registering (addOverride on onGameIn).
-----------------------------------
require('modules/module_utils')

local m = Module:new('combat_records')

-- Per-player 30-second damage windows: [playerID][tier] = {{t=timestamp, dmg=N}, ...}
local dmgWindows = {}

local function mobTier(lv)
    if lv <= 33 then return 1
    elseif lv <= 67 then return 2
    elseif lv <= 99 then return 3
    else return 4
    end
end

local function tryRecord(player, varBase, value, tier)
    local var = varBase .. '_T' .. tier
    if value > (player:getCharVar(var) or 0) then
        player:setCharVar(var, value)
    end
end

local function updateWindow(player, dmg, tier)
    local id  = player:getID()
    local now = os.time()
    if not dmgWindows[id]       then dmgWindows[id] = {} end
    if not dmgWindows[id][tier] then dmgWindows[id][tier] = {} end
    local win = dmgWindows[id][tier]
    -- Evict hits older than 30 seconds
    local i = 1
    while i <= #win do
        if now - win[i].t > 30 then table.remove(win, i)
        else i = i + 1 end
    end
    win[#win + 1] = { t = now, dmg = dmg }
    local sum = 0
    for _, e in ipairs(win) do sum = sum + e.dmg end
    tryRecord(player, 'MaxDmg30', sum, tier)
end

-- Message IDs for magic outcome detection
local BURST_MSG = xi.msg.basic.MAGIC_BURST_DAMAGE  -- 252
local NUKE_MSG  = xi.msg.basic.MAGIC_DMG           -- 2
local HEAL_MSG  = xi.msg.basic.MAGIC_RECOVERS_HP   -- 7
local DRAIN_MSG = xi.msg.basic.MAGIC_DRAIN_HP      -- 227

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if zoning then
        -- Clear rolling 30-second window on zone; keeps RAM clean.
        dmgWindows[player:getID()] = nil
    end

    -- ── MAGIC_USE: heals / nukes / bursts ────────────────────────────────
    -- Fires once per cast with the primary target. `param` = hp healed or damage dealt.
    player:addListener('MAGIC_USE', 'COMBAT_RECORDS_MAGIC', function(attacker, target, spell, action)
        if target == nil then return end
        local tid   = target:getID()
        local msg   = action:getMsg(tid)
        local param = action:getParam(tid)
        if not param or param <= 0 then return end
        local tier  = mobTier(target:getMainLvl())

        if msg == BURST_MSG then
            -- Magic burst counts as both nuke record AND burst record
            if target:getObjType() == xi.objType.MOB then
                tryRecord(attacker, 'MaxBurst', param, tier)
                tryRecord(attacker, 'MaxNuke',  param, tier)
                updateWindow(attacker, param, tier)
            end
        elseif msg == NUKE_MSG or msg == DRAIN_MSG then
            if target:getObjType() == xi.objType.MOB then
                tryRecord(attacker, 'MaxNuke', param, tier)
                updateWindow(attacker, param, tier)
            end
        elseif msg == HEAL_MSG then
            -- Heals on any target (party members are level 99 → T3 effectively)
            tryRecord(attacker, 'MaxHeal', param, tier)
        end
    end)

    -- ── WEAPONSKILL_USE: WS damage + skillchain ───────────────────────────
    -- `damage` = total weapon skill damage (pre-calculated by the engine).
    -- `action:getAddEffectParam(targetId)` = skillchain damage; requires C++ getter
    -- (added in lua_action.cpp) - safe-fails via pcall until rebuild ships.
    player:addListener('WEAPONSKILL_USE', 'COMBAT_RECORDS_WS', function(attacker, target, skill, tp, action, damage)
        if not damage or damage <= 0 then return end
        if target == nil then return end
        if target:getObjType() ~= xi.objType.MOB then return end
        local tier = mobTier(target:getMainLvl())
        updateWindow(attacker, damage, tier)
        -- Skillchain damage is in addEffectParam; getAddEffectParam added via C++ patch
        local ok, scDmg = pcall(function() return action:getAddEffectParam(target:getID()) end)
        if ok and scDmg and scDmg > 0 then
            tryRecord(attacker, 'MaxSC', scDmg, tier)
            updateWindow(attacker, scDmg, tier)
        end
    end)

    -- ── RANGE_STATE_EXIT: ranged attacks toward 30-second window ──────────
    -- target is nil on a miss; param = ranged attack damage.
    player:addListener('RANGE_STATE_EXIT', 'COMBAT_RECORDS_RANGE', function(attacker, target, action)
        if not target then return end
        if target:getObjType() ~= xi.objType.MOB then return end
        local param = action:getParam(target:getID())
        if not param or param <= 0 then return end
        local tier = mobTier(target:getMainLvl())
        updateWindow(attacker, param, tier)
    end)
end)

-- ── PET WEAPONSKILL_USE: avatars (Blood Pacts), automatons, BST jug pets ──
-- Fired on the pet entity with true uncapped damage. Route into the master's
-- MaxDmg30 rolling window so SMN/PUP/BST appear on the same leaderboard.
m:addOverride('xi.pet.spawnPet', function(caster, petID, state, target)
    super(caster, petID, state, target)
    if not caster or not caster:isPC() then return end
    local pet = caster:getPet()
    if not pet then return end
    pet:addListener('WEAPONSKILL_USE', 'COMBAT_RECORDS_PET_WS', function(petArg, tgt, skill, tp, action, damage)
        if not damage or damage <= 0 then return end
        if not tgt or tgt:getObjType() ~= xi.objType.MOB then return end
        local master = petArg:getMaster()
        if not master or not master:isPC() then return end
        local tier = mobTier(tgt:getMainLvl())
        updateWindow(master, damage, tier)
    end)
end)

return m
