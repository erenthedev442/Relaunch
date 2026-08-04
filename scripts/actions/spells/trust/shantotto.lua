-----------------------------------
-- Trust: Shantotto
-- BLM/BLM. Single-target elemental I–V only. No WS / no melee.
-- Highest tier by default; T1–T2 when target is weak or low HP (MP conserve).
-- Top enmity: stop casting until hate moves on. Stands when OOM.
-- C-tier nuker (apprentice) — no kit inject. Soft 8–10k / hard 10k.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local LOW_HP_PCT     = 35
local WEAK_LVL_DELTA = 15 -- target at least this many levels below her

local NUKE_T2 =
{
    xi.magic.spell.FIRE_II,
    xi.magic.spell.BLIZZARD_II,
    xi.magic.spell.AERO_II,
    xi.magic.spell.STONE_II,
    xi.magic.spell.THUNDER_II,
    xi.magic.spell.WATER_II,
}

local NUKE_T1 =
{
    xi.magic.spell.FIRE,
    xi.magic.spell.BLIZZARD,
    xi.magic.spell.AERO,
    xi.magic.spell.STONE,
    xi.magic.spell.THUNDER,
    xi.magic.spell.WATER,
}

local function hasTopEnmity(mob)
    local battleTarget = mob:getTarget()
    if not battleTarget then
        return false
    end

    local hateTarget = battleTarget:getTarget()
    return hateTarget ~= nil and hateTarget:getID() == mob:getID()
end

local function shouldConserve(mob)
    local battleTarget = mob:getTarget()
    if not battleTarget or not battleTarget:isAlive() then
        return false
    end

    if battleTarget:getHPP() < LOW_HP_PCT then
        return true
    end

    -- Weaker enemy (leveling packs / much lower level).
    local tLvl = battleTarget:getMainLvl()
    local mLvl = mob:getMainLvl()
    return tLvl > 0 and mLvl > 0 and tLvl + WEAK_LVL_DELTA <= mLvl
end

local function installNormal(mob)
    mob:removeAllGambits()
    -- MB windows, then highest available ST nuke (weakness-aware).
    mob:addGambit(ai.t.TARGET, { ai.c.MB_AVAILABLE, 0 }, { ai.r.MA, ai.s.MB_ELEMENT, xi.magic.spellFamily.NONE })
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_SC_AVAILABLE, 0 }, { ai.r.MA, ai.s.BEST_AGAINST_TARGET, xi.magic.spellFamily.NONE }, 20)
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.NONE }, 45)
end

local function installConserve(mob)
    mob:removeAllGambits()
    -- ai.s.LOWEST is unimplemented — pin T1–T2 SPECIFIC (all elements).
    for _, spellId in ipairs(NUKE_T2) do
        mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, spellId }, 12)
    end

    for _, spellId in ipairs(NUKE_T1) do
        mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.MA, ai.s.SPECIFIC, spellId }, 12)
    end
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell, xi.magic.spell.SHANTOTTO_II)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.AJIDO_MARUJIDO] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.STAR_SIBYL] = xi.trust.messageOffset.TEAMWORK_2,
        [xi.magic.spell.KORU_MORU] = xi.trust.messageOffset.TEAMWORK_3,
        [xi.magic.spell.KING_OF_HEARTS] = xi.trust.messageOffset.TEAMWORK_4,
    })

    -- Modest FC on top of C apprentice scaler (rapid ST nukes).
    mob:addMod(xi.mod.FASTCAST, 25)
    mob:addMod(xi.mod.UFASTCAST, 8)
    mob:addMod(xi.mod.MACC, 30)

    -- Does not melee; no TP kit.
    mob:setAutoAttackEnabled(false)
    mob:setMobAbilityEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)

    installNormal(mob)
    mob:setLocalVar('shanMode', 0) -- 0 normal, 1 conserve
    mob:setLocalVar('shanHateMute', 0)

    mob:addListener('COMBAT_TICK', 'SHANTOTTO_AI', function(mobArg)
        -- Draw hate → stop casting; resume when enmity moves on.
        local hate  = hasTopEnmity(mobArg)
        local muted = mobArg:getLocalVar('shanHateMute') == 1
        if hate and not muted then
            mobArg:setMagicCastingEnabled(false)
            mobArg:setLocalVar('shanHateMute', 1)
        elseif not hate and muted then
            mobArg:setMagicCastingEnabled(true)
            mobArg:setLocalVar('shanHateMute', 0)
        end

        -- MP conserve: lower tiers vs weak / low-HP targets.
        local want = shouldConserve(mobArg) and 1 or 0
        if mobArg:getLocalVar('shanMode') == want then
            return
        end

        mobArg:setLocalVar('shanMode', want)
        if want == 1 then
            installConserve(mobArg)
        else
            installNormal(mobArg)
        end
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
