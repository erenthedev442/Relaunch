-----------------------------------
-- Trust: Joachim
-- BRD/WHM support. No melee / no WS. Throwing ranged (traverser stones).
-- Default March + Madrigal; waits for songs to expire (does not overwrite).
-- Song priority: Paeon x2 (HP<90%) > Ballad (MP<75%) > March/Madrigal,
-- with Minuet/Minne when another Bard already covers March/Madrigal.
-- Cure / -na / Erase outrank songs. B-tier buffer (support).
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local function canAct(mobArg)
    local action = mobArg:getCurrentAction()
    return mobArg:isEngaged() and
        (action == xi.action.category.NONE or
            action == xi.action.category.BASIC_ATTACK or
            action == xi.action.category.MAGIC_FINISH)
end

local function pickTier(lvl, tiers)
    for _, entry in ipairs(tiers) do
        if lvl >= entry[1] then
            return entry[2]
        end
    end

    return nil
end

-- { minLevel, spellId } highest-first
local PAEON_TIERS =
{
    { 78, xi.magic.spell.ARMYS_PAEON_VI },
    { 65, xi.magic.spell.ARMYS_PAEON_V },
    { 45, xi.magic.spell.ARMYS_PAEON_IV },
    { 35, xi.magic.spell.ARMYS_PAEON_III },
    { 15, xi.magic.spell.ARMYS_PAEON_II },
    { 5,  xi.magic.spell.ARMYS_PAEON },
}

local BALLAD_TIERS =
{
    { 85, xi.magic.spell.MAGES_BALLAD_III },
    { 55, xi.magic.spell.MAGES_BALLAD_II },
    { 25, xi.magic.spell.MAGES_BALLAD },
}

local MINUET_TIERS =
{
    { 87, xi.magic.spell.VALOR_MINUET_V },
    { 63, xi.magic.spell.VALOR_MINUET_IV },
    { 43, xi.magic.spell.VALOR_MINUET_III },
    { 23, xi.magic.spell.VALOR_MINUET_II },
    { 3,  xi.magic.spell.VALOR_MINUET },
}

local MINNE_TIERS =
{
    { 80, xi.magic.spell.KNIGHTS_MINNE_V },
    { 61, xi.magic.spell.KNIGHTS_MINNE_IV },
    { 41, xi.magic.spell.KNIGHTS_MINNE_III },
    { 21, xi.magic.spell.KNIGHTS_MINNE_II },
    { 1,  xi.magic.spell.KNIGHTS_MINNE },
}

local function bestMarch(lvl)
    if lvl >= 60 then
        return xi.magic.spell.VICTORY_MARCH
    elseif lvl >= 29 then
        return xi.magic.spell.ADVANCING_MARCH
    end

    return nil
end

local function bestMadrigal(lvl)
    if lvl >= 51 then
        return xi.magic.spell.BLADE_MADRIGAL
    elseif lvl >= 11 then
        return xi.magic.spell.SWORD_MADRIGAL
    end

    return nil
end

local function effectForSong(spellId)
    if
        spellId == xi.magic.spell.ADVANCING_MARCH or
        spellId == xi.magic.spell.VICTORY_MARCH
    then
        return xi.effect.MARCH
    elseif
        spellId == xi.magic.spell.SWORD_MADRIGAL or
        spellId == xi.magic.spell.BLADE_MADRIGAL
    then
        return xi.effect.MADRIGAL
    elseif
        spellId >= xi.magic.spell.VALOR_MINUET and
        spellId <= xi.magic.spell.VALOR_MINUET_V
    then
        return xi.effect.MINUET
    elseif
        spellId >= xi.magic.spell.KNIGHTS_MINNE and
        spellId <= xi.magic.spell.KNIGHTS_MINNE_V
    then
        return xi.effect.MINNE
    elseif
        spellId >= xi.magic.spell.MAGES_BALLAD and
        spellId <= xi.magic.spell.MAGES_BALLAD_III
    then
        return xi.effect.BALLAD
    elseif
        spellId >= xi.magic.spell.ARMYS_PAEON and
        spellId <= xi.magic.spell.ARMYS_PAEON_VI
    then
        return xi.effect.PAEON
    end

    return nil
end

local function owns(mob, effect)
    return mob:getLocalVar('joachimOwns_' .. effect) == 1
end

local function setOwn(mob, effect, value)
    mob:setLocalVar('joachimOwns_' .. effect, value and 1 or 0)
end

local function coveredByOther(mob, effect)
    return mob:hasStatusEffect(effect) and not owns(mob, effect)
end

local function desiredSongs(mob)
    local lvl = mob:getMainLvl()

    -- Only double-up: Paeon x2 under 90% HP.
    if mob:getHPP() < 90 then
        local paeon = pickTier(lvl, PAEON_TIERS)
        if paeon then
            return { paeon, paeon }
        end
    end

    local songs = {}
    local function push(spellId)
        if spellId and #songs < 2 then
            table.insert(songs, spellId)
        end
    end

    if mob:getMPP() < 75 then
        push(pickTier(lvl, BALLAD_TIERS))
    end

    local marchCovered    = coveredByOther(mob, xi.effect.MARCH)
    local madrigalCovered = coveredByOther(mob, xi.effect.MADRIGAL)

    if marchCovered and madrigalCovered then
        push(pickTier(lvl, MINNE_TIERS))
        push(pickTier(lvl, MINUET_TIERS))
    elseif marchCovered then
        -- Another Bard has March (e.g. Ulmia double-March): Madrigal + Minuet.
        push(bestMadrigal(lvl))
        push(pickTier(lvl, MINUET_TIERS))
    else
        push(bestMarch(lvl))
        if madrigalCovered then
            push(pickTier(lvl, MINUET_TIERS))
        else
            push(bestMadrigal(lvl))
        end
    end

    if #songs < 2 then
        push(pickTier(lvl, MINUET_TIERS))
    end

    if #songs < 2 then
        push(pickTier(lvl, MINNE_TIERS))
    end

    return songs
end

local function needsSong(mob, spellId, songs)
    local effect = effectForSong(spellId)
    if not effect then
        return false
    end

    -- Double Paeon: cast twice when both desired slots are Paeon.
    local wantDoublePaeon = false
    if effect == xi.effect.PAEON then
        local paeonSlots = 0
        for _, id in ipairs(songs) do
            if effectForSong(id) == xi.effect.PAEON then
                paeonSlots = paeonSlots + 1
            end
        end

        wantDoublePaeon = paeonSlots >= 2
        if wantDoublePaeon then
            return mob:getLocalVar('joachimPaeonCasts') < 2
        end
    end

    -- Provided by another Bard — pick a different song in desiredSongs.
    if coveredByOther(mob, effect) then
        return false
    end

    -- Wait for expiry; do not overwrite our own active songs.
    if mob:hasStatusEffect(effect) and owns(mob, effect) then
        return false
    end

    return not mob:hasStatusEffect(effect)
end

local function trySongs(mobArg)
    if not canAct(mobArg) then
        return
    end

    if mobArg:getLocalVar('joachimSongBusy') > os.time() then
        return
    end

    local songs = desiredSongs(mobArg)
    for _, spellId in ipairs(songs) do
        if needsSong(mobArg, spellId, songs) then
            mobArg:castSpell(spellId, mobArg)
            mobArg:setLocalVar('joachimSongBusy', os.time() + 4)

            local effect = effectForSong(spellId)
            if effect then
                setOwn(mobArg, effect, true)
            end

            if effect == xi.effect.PAEON then
                mobArg:setLocalVar('joachimPaeonCasts', mobArg:getLocalVar('joachimPaeonCasts') + 1)
            else
                mobArg:setLocalVar('joachimPaeonCasts', 0)
            end

            return
        end
    end
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    -- Records of Eminence: Alter Ego: Joachim
    if caster:getEminenceProgress(937) then
        xi.roe.onRecordTrigger(caster, 937)
    end

    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.SPAWN)

    mob:setLocalVar('joachimPaeonCasts', 0)
    mob:setLocalVar('joachimSongBusy', 0)

    -- 1) Status removal + Erase (before songs).
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.POISON }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.POISONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PARALYSIS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.PARALYNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.BLINDNESS }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.BLINDNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SILENCE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.SILENA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.PETRIFICATION }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.STONA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.DISEASE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.VIRUNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.CURSE_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURSNA })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })
    mob:addGambit(ai.t.SELF, { ai.c.STATUS_FLAG, xi.effectFlag.ERASABLE }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.ERASE })

    -- 2) Cures outrank songs.
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_I }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.STATUS, xi.effect.SLEEP_II }, { ai.r.MA, ai.s.SPECIFIC, xi.magic.spell.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 50 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })
    mob:addGambit(ai.t.PARTY, { ai.c.HPP_LT, 75 }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.CURE })

    -- 3) Elegy when free.
    mob:addGambit(ai.t.TARGET, { ai.c.NOT_STATUS, xi.effect.ELEGY }, { ai.r.MA, ai.s.HIGHEST, xi.magic.spellFamily.ELEGY }, 60)

    -- 4) Songs (no overwrite; wait for expiry).
    mob:addListener('COMBAT_TICK', 'JOACHIM_SONGS', function(mobArg)
        trySongs(mobArg)
    end)

    mob:addListener('EFFECT_LOSE', 'JOACHIM_SONG_LOSE', function(mobArg, effect)
        if not effect then
            return
        end

        local id = effect:getEffectType()
        if
            id == xi.effect.MARCH or
            id == xi.effect.MADRIGAL or
            id == xi.effect.MINUET or
            id == xi.effect.MINNE or
            id == xi.effect.BALLAD or
            id == xi.effect.PAEON
        then
            setOwn(mobArg, id, false)
            if id == xi.effect.PAEON then
                mobArg:setLocalVar('joachimPaeonCasts', 0)
            end
        end
    end)

    -- Throwing ranged (traverser stones). No melee, no WS.
    mob:addGambit(ai.t.TARGET, { ai.c.ALWAYS, 0 }, { ai.r.RATTACK, 0, 0 }, 12)

    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.MID_RANGE)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
