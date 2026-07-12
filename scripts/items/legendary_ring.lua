-----------------------------------
-- ID: 26169
-- Legendary Ring  (RELAUNCH custom -- the Legacy 1.0 migration heirloom)
--
-- Stats live in modules/custom/sql/legendary_ring.sql (EXP/Cap +100%,
-- Reraise III, Move +25%, 100% EXP retained on death). "No Weakness after
-- Reraise" is a guard in src/map/entities/charentity.cpp. The permanent aura
-- also re-applies on every zone-in via modules/custom/lua/legendary_ring_aura.
--
-- This script drives the item's ENCHANTMENT (item_usable) + appearance:
--   * onItemEquip   -> permanent legendary AURA (a pure-visual glow) while worn.
--   * onItemUse     -> TOGGLES between two on-demand modes (owner design):
--                        Vanish    = Sneak + Invisible (slip past anything)
--                        Transform = a costume (show off). The glow stays on
--                                    UNDER the costume, so you're a glowing
--                                    <whatever>.
--                      Each use flips to the other mode.
--   * onItemUnequip -> clears the aura + any active vanish/transform.
--
-- TUNABLES (all hot-reload; no rebuild):
--   AURA_EFFECT      the permanent glow. AFTERGLOW (489) is the Relic/Mythic/
--                    Aeonic weapon glow -- pure visual, no stats. Alt with a
--                    fuller body-glow: xi.effect.MUMORS_RADIANCE (613).
--   TRANSFORM_MODEL  the Transform costume model id. Cool verified options:
--                      3581 = Gargantuan Moogle (Mog Bonanza flex) [default]
--                       564 = Skeleton      368 = Ghost      290 = Cluster (bombs)
--                       644 = Quadav        673 = Goblin    2308 = Moogle
-----------------------------------
local AURA_EFFECT     = xi.effect.AFTERGLOW  -- pure-visual "legendary" glow (keep in sync with legendary_ring_aura.lua)
local TRANSFORM_MODEL = 3581                 -- Gargantuan Moogle
local AURA_DUR        = 31536000             -- 1 year; effectively permanent, re-applied on equip + zone-in
local EFFECT_DUR      = 3600                 -- vanish/transform hold time; re-applied on each toggle
local MODE_VAR        = 'LegRingMode'        -- 0 = next use Vanishes, 1 = next use Transforms

---@type TItem
local itemObject = {}

local function applyAura(target)
    if not target:hasStatusEffect(AURA_EFFECT) then
        target:addStatusEffect(AURA_EFFECT, { power = 1, duration = AURA_DUR, origin = target })
    end
end

local function clearLook(target)
    for _, e in ipairs({ AURA_EFFECT, xi.effect.COSTUME, xi.effect.SNEAK, xi.effect.INVISIBLE }) do
        if target:hasStatusEffect(e) then
            target:delStatusEffect(e)
        end
    end
end

itemObject.onItemCheck = function(target, item, param, caster)
    -- Usable any time; the Transform mode handles its own costume-zone rule.
    return 0
end

itemObject.onItemUse = function(target, user)
    local mode = user:getCharVar(MODE_VAR)

    if mode == 0 then
        -- VANISH: drop any costume, go stealthed. The aura glow stays on (hidden
        -- while Invisible, which is the point of sneaking).
        if user:hasStatusEffect(xi.effect.COSTUME) then
            user:delStatusEffect(xi.effect.COSTUME)
        end
        user:addStatusEffect(xi.effect.SNEAK,     { duration = EFFECT_DUR, origin = user, tick = 10 })
        user:addStatusEffect(xi.effect.INVISIBLE, { duration = EFFECT_DUR, origin = user, tick = 10 })
        user:setCharVar(MODE_VAR, 1)
    else
        -- TRANSFORM: drop stealth, put on the show costume (glow shows under it).
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
