-----------------------------------
-- Trust: Ulmia
-- BRD/BRD. Does not engage / no WS. Party songs: double March (default),
-- double Madrigal if March covered, Minuet if both covered; Ballad by MP burn.
-- Recasts shortly before expiry. Pianissimo for master (Ballad / Prelude /
-- Minuet / Scherzo). S-tier buffer CORE — no kit inject.
-----------------------------------
---@type TSpellTrust
local spellObject = {}

local RECAST_PIANISSIMO = 112
local REFRESH_MS        = 25000 -- recast when <25s remain
local SONG_BUSY_SECS    = 4

local NATIVE_MP_JOBS =
{
    [xi.job.WHM] = true, [xi.job.BLM] = true, [xi.job.RDM] = true,
    [xi.job.PLD] = true, [xi.job.DRK] = true, [xi.job.BRD] = true,
    [xi.job.SMN] = true, [xi.job.BLU] = true, [xi.job.PUP] = true,
    [xi.job.SCH] = true, [xi.job.GEO] = true, [xi.job.RUN] = true,
}

local MAGE_BALLAD_JOBS =
{
    [xi.job.WHM] = true, [xi.job.BLM] = true, [xi.job.RDM] = true,
    [xi.job.SMN] = true, [xi.job.GEO] = true, [xi.job.SCH] = true,
}

local RANGED_PIANO_JOBS =
{
    [xi.job.RNG] = true,
    [xi.job.COR] = true,
}

local SONG_EFFECTS =
{
    [xi.effect.MARCH]    = true,
    [xi.effect.MADRIGAL] = true,
    [xi.effect.MINUET]   = true,
    [xi.effect.BALLAD]   = true,
    [xi.effect.PRELUDE]  = true,
    [xi.effect.SCHERZO]  = true,
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

local function hasNativeMp(member)
    return NATIVE_MP_JOBS[member:getMainJob()] or NATIVE_MP_JOBS[member:getSubJob()]
end

local function countNativeMp(master)
    local count = 0
    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if member:isAlive() and hasNativeMp(member) then
            count = count + 1
        end
    end

    return count
end

local function songOwnedBy(entity, effectId, casterId, tier)
    for _, eff in pairs(entity:getStatusEffects() or {}) do
        if
            eff:getEffectType() == effectId and
            eff:getSubType() == casterId and
            (not tier or eff:getTier() == tier)
        then
            return eff
        end
    end

    return nil
end

local function songFromOther(entity, effectId, selfId)
    for _, eff in pairs(entity:getStatusEffects() or {}) do
        if eff:getEffectType() == effectId and eff:getSubType() ~= selfId then
            return true
        end
    end

    return false
end

local function countOwnSongs(master, selfId)
    local n = 0
    for _, eff in pairs(master:getStatusEffects() or {}) do
        if SONG_EFFECTS[eff:getEffectType()] and eff:getSubType() == selfId then
            n = n + 1
        end
    end

    return n
end

local function needsCast(mob, master, spellId, effectId, tier)
    local eff = songOwnedBy(master, effectId, mob:getID(), tier)
    if not eff then
        return true
    end

    return eff:getTimeRemaining() < REFRESH_MS
end

local function bestPrelude(lvl)
    if lvl >= 71 then
        return xi.magic.spell.ARCHERS_PRELUDE
    elseif lvl >= 31 then
        return xi.magic.spell.HUNTERS_PRELUDE
    end

    return nil
end

-- Track MP burn; return ally with highest % MP spent since last sample.
local function updateMpBurn(mobArg, master)
    local bestMember = nil
    local bestBurn   = 0

    for _, member in pairs(master:getPartyWithTrusts() or {}) do
        if member:isAlive() and hasNativeMp(member) then
            local idKey  = 'ulmiaMp' .. member:getID()
            local prevMp = mobArg:getLocalVar(idKey)
            local curMp  = member:getMP()
            local maxMp  = member:getMaxMP()

            if prevMp > 0 and maxMp > 0 and curMp < prevMp then
                local burn = (prevMp - curMp) / maxMp
                if burn > bestBurn then
                    bestBurn   = burn
                    bestMember = member
                end
            end

            mobArg:setLocalVar(idKey, curMp)
        end
    end

    if bestMember then
        mobArg:setLocalVar('ulmiaBalladTarg', bestMember:getID())
    end

    return bestMember, bestBurn
end

local function balladThreshold(master)
    return countNativeMp(master) >= 3 and 75 or 33
end

local function wantsPartyBallad(mobArg, master)
    local target = nil
    local targId = mobArg:getLocalVar('ulmiaBalladTarg')
    if targId > 0 then
        for _, member in pairs(master:getPartyWithTrusts() or {}) do
            if member:getID() == targId then
                target = member
                break
            end
        end
    end

    if not target or not target:isAlive() then
        return false
    end

    -- Must have shown recent MP consumption (burn check).
    if mobArg:getLocalVar('ulmiaHadBurn') < os.time() then
        return false
    end

    return target:getMPP() < balladThreshold(master)
end

local function desiredPartySongs(mobArg, master)
    local lvl    = mobArg:getMainLvl()
    local selfId = mobArg:getID()
    local songs  = {}

    local function push(spellId)
        if spellId and #songs < 2 then
            table.insert(songs, spellId)
        end
    end

    local marchOther    = songFromOther(master, xi.effect.MARCH, selfId)
    local madrigalOther = songFromOther(master, xi.effect.MADRIGAL, selfId)

    -- Ballad can claim a slot when MP burn + threshold pass.
    if wantsPartyBallad(mobArg, master) then
        push(pickTier(lvl, BALLAD_TIERS))
        -- Double Ballad when very low on the burn target.
        local targId = mobArg:getLocalVar('ulmiaBalladTarg')
        for _, member in pairs(master:getPartyWithTrusts() or {}) do
            if member:getID() == targId and member:getMPP() < 40 then
                push(pickTier(lvl, BALLAD_TIERS))
            end
        end
    end

    if not marchOther then
        -- Default: Victory March + Advancing March.
        if lvl >= 60 then
            push(xi.magic.spell.VICTORY_MARCH)
        end

        if lvl >= 29 then
            push(xi.magic.spell.ADVANCING_MARCH)
        end
    elseif not madrigalOther then
        if lvl >= 51 then
            push(xi.magic.spell.BLADE_MADRIGAL)
        end

        if lvl >= 11 then
            push(xi.magic.spell.SWORD_MADRIGAL)
        end
    else
        -- Both March + Madrigal from other Bards → Minuets.
        push(pickTier(lvl, MINUET_TIERS))
        -- Second Minuet: next-lower tier if available.
        local top = pickTier(lvl, MINUET_TIERS)
        if top and top > xi.magic.spell.VALOR_MINUET then
            push(top - 1)
        else
            push(top)
        end
    end

    if #songs < 2 then
        push(pickTier(lvl, MINUET_TIERS))
    end

    return songs
end

local function spellMeta(spellId)
    if spellId == xi.magic.spell.VICTORY_MARCH then
        return xi.effect.MARCH, 2
    elseif spellId == xi.magic.spell.ADVANCING_MARCH then
        return xi.effect.MARCH, 1
    elseif spellId == xi.magic.spell.BLADE_MADRIGAL then
        return xi.effect.MADRIGAL, 2
    elseif spellId == xi.magic.spell.SWORD_MADRIGAL then
        return xi.effect.MADRIGAL, 1
    elseif
        spellId >= xi.magic.spell.VALOR_MINUET and
        spellId <= xi.magic.spell.VALOR_MINUET_V
    then
        return xi.effect.MINUET, spellId - xi.magic.spell.VALOR_MINUET + 1
    elseif
        spellId >= xi.magic.spell.MAGES_BALLAD and
        spellId <= xi.magic.spell.MAGES_BALLAD_III
    then
        return xi.effect.BALLAD, spellId - xi.magic.spell.MAGES_BALLAD + 1
    elseif spellId == xi.magic.spell.ARCHERS_PRELUDE then
        return xi.effect.PRELUDE, 2
    elseif spellId == xi.magic.spell.HUNTERS_PRELUDE then
        return xi.effect.PRELUDE, 1
    elseif spellId == xi.magic.spell.SENTINELS_SCHERZO then
        return xi.effect.SCHERZO, 1
    end

    return nil, nil
end

local function tryPartySongs(mobArg, master)
    if mobArg:getLocalVar('ulmiaSongBusy') > os.time() then
        return false
    end

    local songs = desiredPartySongs(mobArg, master)
    for _, spellId in ipairs(songs) do
        local effectId, tier = spellMeta(spellId)
        if effectId and needsCast(mobArg, master, spellId, effectId, tier) then
            mobArg:castSpell(spellId, mobArg)
            mobArg:setLocalVar('ulmiaSongBusy', os.time() + SONG_BUSY_SECS)
            return true
        end
    end

    return false
end

local function tryPianissimo(mobArg, master)
    if countOwnSongs(master, mobArg:getID()) < 2 then
        return false
    end

    if mobArg:getLocalVar('ulmiaSongBusy') > os.time() then
        return false
    end

    if mobArg:hasRecast(xi.recast.ABILITY, RECAST_PIANISSIMO) then
        return false
    end

    local lvl    = mobArg:getMainLvl()
    local job    = master:getMainJob()
    local spellId = nil

    -- Scherzo: Weakness or recent large damage on master.
    if
        master:hasStatusEffect(xi.effect.WEAKNESS) or
        mobArg:getLocalVar('ulmiaNeedScherzo') == 1
    then
        if
            lvl >= 82 and
            needsCast(mobArg, master, xi.magic.spell.SENTINELS_SCHERZO, xi.effect.SCHERZO, 1)
        then
            spellId = xi.magic.spell.SENTINELS_SCHERZO
            mobArg:setLocalVar('ulmiaNeedScherzo', 0)
        end
    end

    -- Mage Ballad on player @ <75% MP.
    if
        not spellId and
        MAGE_BALLAD_JOBS[job] and
        master:getMPP() < 75
    then
        local ballad = pickTier(lvl, BALLAD_TIERS)
        local effectId, tier = spellMeta(ballad)
        if ballad and needsCast(mobArg, master, ballad, effectId, tier) then
            spellId = ballad
        end
    end

    -- RNG / COR: Prelude then Minuet.
    if not spellId and RANGED_PIANO_JOBS[job] then
        local prelude = bestPrelude(lvl)
        if prelude then
            local effectId, tier = spellMeta(prelude)
            if needsCast(mobArg, master, prelude, effectId, tier) then
                spellId = prelude
            end
        end

        if not spellId then
            local minuet = pickTier(lvl, MINUET_TIERS)
            local effectId, tier = spellMeta(minuet)
            if minuet and needsCast(mobArg, master, minuet, effectId, tier) then
                spellId = minuet
            end
        end
    end

    if not spellId then
        return false
    end

    if not mobArg:hasStatusEffect(xi.effect.PIANISSIMO) then
        mobArg:useJobAbility(xi.ja.PIANISSIMO, mobArg)
        mobArg:setLocalVar('ulmiaSongBusy', os.time() + 1)
        mobArg:setLocalVar('ulmiaPianoSpell', spellId)
        return true
    end

    mobArg:castSpell(spellId, master)
    mobArg:setLocalVar('ulmiaSongBusy', os.time() + SONG_BUSY_SECS)
    mobArg:setLocalVar('ulmiaPianoSpell', 0)
    return true
end

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return xi.trust.canCast(caster, spell)
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.trust.spawn(caster, spell)
end

spellObject.onMobSpawn = function(mob)
    xi.trust.teamworkMessage(mob, {
        [xi.magic.spell.PRISHE] = xi.trust.messageOffset.TEAMWORK_1,
        [xi.magic.spell.MILDAURION] = xi.trust.messageOffset.TEAMWORK_2,
    })

    mob:setLocalVar('ulmiaSongBusy', 0)
    mob:setLocalVar('ulmiaHadBurn', 0)
    mob:setLocalVar('ulmiaNeedScherzo', 0)
    mob:setLocalVar('ulmiaMasterHp', 0)

    mob:setAutoAttackEnabled(false)
    mob:setMobMod(xi.mobMod.TRUST_DISTANCE, xi.trust.movementType.NO_MOVE)

    mob:addListener('COMBAT_TICK', 'ULMIA_SONGS', function(mobArg)
        local master = mobArg:getMaster()
        if not master or not master:isAlive() then
            return
        end

        -- Large damage / Weakness → Scherzo via Pianissimo.
        local hp = master:getHP()
        local prev = mobArg:getLocalVar('ulmiaMasterHp')
        if prev > 0 and (prev - hp) >= math.floor(master:getMaxHP() * 0.25) then
            mobArg:setLocalVar('ulmiaNeedScherzo', 1)
        end

        mobArg:setLocalVar('ulmiaMasterHp', hp)

        local _, burn = updateMpBurn(mobArg, master)
        if burn > 0.02 then -- >2% max MP in a tick sample
            mobArg:setLocalVar('ulmiaHadBurn', os.time() + 30)
        end

        if not canAct(mobArg) then
            return
        end

        -- Finish Pianissimo cast if JA just applied.
        local pending = mobArg:getLocalVar('ulmiaPianoSpell')
        if pending > 0 and mobArg:hasStatusEffect(xi.effect.PIANISSIMO) then
            mobArg:castSpell(pending, master)
            mobArg:setLocalVar('ulmiaPianoSpell', 0)
            mobArg:setLocalVar('ulmiaSongBusy', os.time() + SONG_BUSY_SECS)
            return
        end

        if tryPartySongs(mobArg, master) then
            return
        end

        tryPianissimo(mobArg, master)
    end)
end

spellObject.onMobDespawn = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DESPAWN)
end

spellObject.onMobDeath = function(mob)
    xi.trust.message(mob, xi.trust.messageOffset.DEATH)
end

return spellObject
