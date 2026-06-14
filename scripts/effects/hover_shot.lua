-----------------------------------
-- xi.effect.HOVER_SHOT
-- Stacking ranged accuracy + ranged attack buff earned by attacking
-- from a position >= 1 yalm from the previous attack position.
--
-- effect:getPower() = current stack count (0..MAX_STACKS).
-- Mods are applied incrementally on each stack change and fully
-- removed on effect loss.
-----------------------------------
---@type TStatusEffect
local effectObject = {}

local MAX_STACKS     = 25
local RACC_PER_STACK = 4
local RATT_PER_STACK = 30

-- LocalVar names (session-scoped, default 0 on first access).
local LV_INIT    = 'HoverShot_Init'    -- 1 once the first shot has been tracked
local LV_LAST_X  = 'HoverShot_LastX'
local LV_LAST_Z  = 'HoverShot_LastZ'
local LV_LAST_TG = 'HoverShot_LastTg'  -- last target's entity ID

-- Apply a mod delta (positive = add, negative = remove).
local function applyDelta(player, delta)
    if delta == 0 then return end
    if delta > 0 then
        player:addMod(xi.mod.RACC, delta * RACC_PER_STACK)
        player:addMod(xi.mod.RATT, delta * RATT_PER_STACK)
    else
        player:delMod(xi.mod.RACC, (-delta) * RACC_PER_STACK)
        player:delMod(xi.mod.RATT, (-delta) * RATT_PER_STACK)
    end
end

local function setStacks(player, newStacks)
    local effect = player:getStatusEffect(xi.effect.HOVER_SHOT)
    if not effect then return end
    local old = effect:getPower()
    if old == newStacks then return end
    applyDelta(player, newStacks - old)
    effect:setPower(newStacks)
end

local function clearLocalVars(player)
    player:setLocalVar(LV_INIT,    0)
    player:setLocalVar(LV_LAST_X,  0)
    player:setLocalVar(LV_LAST_Z,  0)
    player:setLocalVar(LV_LAST_TG, 0)
end

effectObject.onEffectGain = function(player, effect)
    effect:setPower(0)

    -- RANGE_STATE_EXIT fires after every ranged attack with
    -- (attacker, target_or_nil, action).  target is nil when the
    -- attack was interrupted before the shot completed.
    player:addListener('RANGE_STATE_EXIT', 'HOVER_SHOT', function(entity, target, _action)
        if not target then return end  -- interrupted; don't count

        local cx  = entity:getXPos()
        local cz  = entity:getZPos()
        local cur = target:getID()
        local ini = entity:getLocalVar(LV_INIT)
        local ltg = entity:getLocalVar(LV_LAST_TG)

        if ini == 0 then
            -- First shot: establish baseline, no stack yet.
            entity:setLocalVar(LV_INIT,    1)
            entity:setLocalVar(LV_LAST_X,  cx)
            entity:setLocalVar(LV_LAST_Z,  cz)
            entity:setLocalVar(LV_LAST_TG, cur)
            return
        end

        -- Target switch resets stacks.
        if ltg ~= cur then
            setStacks(entity, 0)
            entity:setLocalVar(LV_LAST_X,  cx)
            entity:setLocalVar(LV_LAST_Z,  cz)
            entity:setLocalVar(LV_LAST_TG, cur)
            return
        end

        -- Compare distance from where the last shot was fired.
        local lx   = entity:getLocalVar(LV_LAST_X)
        local lz   = entity:getLocalVar(LV_LAST_Z)
        local dx   = cx - lx
        local dz   = cz - lz
        local dist = math.sqrt(dx * dx + dz * dz)

        if dist >= 1.0 then
            local eff = entity:getStatusEffect(xi.effect.HOVER_SHOT)
            local cur_stacks = eff and eff:getPower() or 0
            setStacks(entity, math.min(MAX_STACKS, cur_stacks + 1))
        else
            setStacks(entity, 0)
        end

        entity:setLocalVar(LV_LAST_X,  cx)
        entity:setLocalVar(LV_LAST_Z,  cz)
        entity:setLocalVar(LV_LAST_TG, cur)
    end)
end

effectObject.onEffectLose = function(player, effect)
    -- Remove all stacked mods cleanly.
    local stacks = effect:getPower()
    if stacks > 0 then
        player:delMod(xi.mod.RACC, stacks * RACC_PER_STACK)
        player:delMod(xi.mod.RATT, stacks * RATT_PER_STACK)
    end
    player:removeListener('HOVER_SHOT')
    clearLocalVars(player)
end

effectObject.onEffectTick = function(player, effect)
end

return effectObject
