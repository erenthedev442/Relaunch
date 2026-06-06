-----------------------------------
-- Spell: Divine Aegis (ID 1020)
--
-- Custom spell — Legendary server only.
-- PLD only, level 50. Divine / Enhancing Magic.
--
-- Mechanic:
--   1. Applies a Holy shield: Stoneskin with power = 150 + VIT*6 + maxHP*0.12
--      (capped at 3,000 HP absorbed).
--   2. Applies -20% physical damage taken for 30 seconds.
--   3. After 30 seconds the shield detonates:
--        • Absorbed damage  = initial_power – getMod(xi.mod.STONESKIN)
--        • Holy AoE damage  = floor(absorbed * 0.85), radius 10 yalms
--        • Cleans up the PDT bonus and any remaining Stoneskin.
--   4. If no damage was absorbed the detonation deals no damage but still
--      removes the buffs (clean and silent expiry).
-----------------------------------
---@type TSpell
local spellObject = {}

local DETONATE_DELAY = 30000  -- milliseconds until detonation
local AoE_RANGE      = 10     -- yalms
local PDT_BONUS      = -2000  -- addMod units: -2000 = -20% physical damage taken

spellObject.onMagicCastingCheck = function(caster, target, spell)
    -- Prevent overlapping casts (recast timer normally covers this, but belt+suspenders).
    if caster:hasStatusEffect(xi.effect.STONESKIN) then
        return xi.msg.basic.MAGIC_NO_EFFECT
    end
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Calculate shield strength.
    local vit   = caster:getStat(xi.mod.VIT)
    local maxhp = caster:getMaxHP()
    local power = math.min(150 + vit * 6 + math.floor(maxhp * 0.12), 3000)

    -- Apply Stoneskin with a 30-second duration.
    caster:addStatusEffect(xi.effect.STONESKIN, {
        power    = power,
        duration = 30,
        origin   = caster,
        tick     = 0,
    })

    -- Apply -20% physical damage taken.
    caster:addMod(xi.mod.DMGPHYS, PDT_BONUS)

    -- Schedule detonation.
    caster:timer(DETONATE_DELAY, function(p)
        -- Read remaining shield HP before cleanup.
        local remaining = p:getMod(xi.mod.STONESKIN)
        local absorbed  = math.max(0, power - remaining)

        -- Clean up PDT bonus.
        p:delMod(xi.mod.DMGPHYS, PDT_BONUS)

        -- Remove Stoneskin if the 30-second duration hasn't already expired it.
        if p:hasStatusEffect(xi.effect.STONESKIN) then
            p:delStatusEffect(xi.effect.STONESKIN)
            p:setMod(xi.mod.STONESKIN, 0)
        end

        -- Detonate: deal Holy AoE damage scaled to absorbed HP.
        if absorbed > 0 and not p:isDead() then
            local dmg = math.floor(absorbed * 0.85)
            -- SELF + ANY_ALLEGIANCE = "center on self, find all enemies in range"
            local targetFlag = xi.targetType.SELF + xi.targetType.ANY_ALLEGIANCE
            local enemies = p:getEntitiesInRange(
                p,
                xi.aoeType.ROUND,
                xi.aoeRadius.ATTACKER,
                AoE_RANGE,
                0,
                targetFlag
            )
            for _, enemy in ipairs(enemies) do
                if not enemy:isDead() then
                    enemy:takeDamage(dmg, p, xi.attackType.MAGICAL, xi.damageType.LIGHT)
                end
            end
        end
    end)

    return power
end

return spellObject
