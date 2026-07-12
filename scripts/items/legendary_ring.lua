-----------------------------------
-- ID: 26169
-- Legendary Ring  (RELAUNCH custom -- the Legacy 1.0 migration heirloom)
--
-- Stats live in modules/custom/sql/legendary_ring.sql (EXP/Cap +100%,
-- Reraise III, Move +25%, 100% EXP retained on death). "No Weakness after
-- Reraise" is a guard in src/map/entities/charentity.cpp.
--
-- This script drives the item's ENCHANTMENT (item_usable) + appearance:
--   * onItemEquip   -> permanent "legendary form" costume aura while worn.
--   * onItemUse     -> TOGGLES between two on-demand modes (owner design):
--                        Vanish    = Sneak + Invisible (slip past anything)
--                        Transform = a monster/NPC costume (show off)
--                      Each use flips to the other mode.
--   * onItemUnequip -> clears the aura + any active vanish/transform.
--
-- COSTUME MODELS are the two ids below. They are real model ids already used
-- by in-game costume items (so they render), but pick whatever you like --
-- any value from a costume/monster look works. Change and re-run nothing
-- (Lua hot-reloads); the numbers are the only knob.
-----------------------------------
local AURA_MODEL      = 1747   -- permanent "legendary form" shown while worn
local TRANSFORM_MODEL = 2308   -- the on-demand Transform costume
local EFFECT_DUR      = 3600   -- seconds; re-applied on every toggle, so effectively "until you switch"
local MODE_VAR        = 'LegRingMode'  -- 0 = next use Vanishes, 1 = next use Transforms

---@type TItem
local itemObject = {}

local function clearLook(target)
    for _, e in ipairs({ xi.effect.COSTUME, xi.effect.SNEAK, xi.effect.INVISIBLE }) do
        if target:hasStatusEffect(e) then
            target:delStatusEffect(e)
        end
    end
end

local AURA_DUR = 31536000  -- 1 year; effectively permanent, re-applied on equip

local function applyAura(target)
    if target:canUseMisc(xi.zoneMisc.COSTUME) then
        target:addStatusEffect(xi.effect.COSTUME, { power = AURA_MODEL, duration = AURA_DUR, origin = target })
    end
end

itemObject.onItemCheck = function(target, item, param, caster)
    -- Usable any time; individual modes handle their own zone rules below.
    return 0
end

itemObject.onItemUse = function(target, user)
    local mode = user:getCharVar(MODE_VAR)

    if mode == 0 then
        -- VANISH: drop any costume, go stealthed.
        if user:hasStatusEffect(xi.effect.COSTUME) then
            user:delStatusEffect(xi.effect.COSTUME)
        end
        user:addStatusEffect(xi.effect.SNEAK,     { duration = EFFECT_DUR, origin = user, tick = 10 })
        user:addStatusEffect(xi.effect.INVISIBLE, { duration = EFFECT_DUR, origin = user, tick = 10 })
        user:setCharVar(MODE_VAR, 1)
    else
        -- TRANSFORM: drop stealth, put on the show costume.
        for _, e in ipairs({ xi.effect.SNEAK, xi.effect.INVISIBLE }) do
            if user:hasStatusEffect(e) then
                user:delStatusEffect(e)
            end
        end
        if user:canUseMisc(xi.zoneMisc.COSTUME) then
            if user:hasStatusEffect(xi.effect.COSTUME) then
                user:delStatusEffect(xi.effect.COSTUME)
            end
            user:addStatusEffect(xi.effect.COSTUME, { power = TRANSFORM_MODEL, duration = EFFECT_DUR, origin = user })
        end
        user:setCharVar(MODE_VAR, 0)
    end
end

itemObject.onItemEquip = function(target, item)
    target:setCharVar(MODE_VAR, 0)  -- fresh equip: first use Vanishes
    applyAura(target)
end

itemObject.onItemUnequip = function(target, item)
    clearLook(target)
    target:setCharVar(MODE_VAR, 0)
end

return itemObject
