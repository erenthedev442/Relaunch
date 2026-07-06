-----------------------------------
-- func: targetstats
-- desc: Prints a detailed stat snapshot for your cursor-targeted mob, Trust, or player-owned pet.
--
-- Usage:
--   !targetstats
--
-- Target a pet directly, target a pet owner to inspect their active pet, or
-- run with no target to inspect your own active pet. Built for checking custom
-- spawned mobs plus SMN avatars, BST jug/charmed pets, PUP automatons, and Trusts.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local S = xi.msg.channel.SYSTEM_3

local function out(player, fmt, ...)
    player:printToPlayer('[TargetStats] ' .. string.format(fmt, ...), S)
end

local function pct100(raw)
    return raw / 100
end

local function sdtPct(raw)
    return math.floor((1 + raw / 10000) * 100 + 0.5)
end

local function jobNameById()
    local jobs = {}
    for name, id in pairs(xi.job) do
        jobs[id] = name
    end

    return jobs
end

local function masterOf(target)
    return target:getMaster()
end

local function isPlayerOwnedMob(target)
    local master = masterOf(target)
    return target:isMob() and master ~= nil and master:isPC()
end

local function isPlayerPet(target)
    return target:isPet() or isPlayerOwnedMob(target)
end

local function petKind(target)
    if target:isAutomaton() then
        return 'Automaton'
    elseif target:isAvatar() then
        return 'Avatar'
    elseif target:isJugPet() then
        return 'Jug Pet'
    elseif target:isCharmed() then
        return 'Charmed Pet'
    elseif target:isPet() then
        return 'Pet'
    end

    return 'Player-Owned Mob'
end

local function targetKind(target)
    if target:isTrust() then
        return 'Trust'
    elseif isPlayerPet(target) then
        return petKind(target)
    elseif target:isMob() then
        return 'Mob'
    end

    return 'Entity'
end

local function immunityText(target)
    local parts = {}
    for name, flag in pairs(xi.immunity) do
        if flag > 0 and target:hasImmunity(flag) then
            parts[#parts + 1] = name
        end
    end

    if #parts == 0 then
        return 'None'
    end

    table.sort(parts)
    return table.concat(parts, ', ')
end

local function resolveTarget(player)
    local target = player:getCursorTarget()
    if target == nil then
        local ownPet = player:getPet()
        if ownPet ~= nil then
            return ownPet, 'your active pet'
        end

        return nil, 'Target a mob, Trust, pet, or pet owner first.'
    end

    if target:isPC() then
        local ownerPet = target:getPet()
        if ownerPet ~= nil then
            return ownerPet, string.format('%s active pet', target:getName())
        end

        return nil, string.format('%s has no active pet.', target:getName())
    end

    if target:isMob() or target:isTrust() or target:isPet() then
        return target, nil
    end

    return nil, 'Current target has no combat stats.'
end

local function petIdentity(player, target, jobs)
    local master = masterOf(target)
    local masterName = master and master:getName() or 'None'
    local petID = target:isPet() and target:getPetID() or 0

    out(player, 'PetInfo: Type:%s  PetID:%d  Owner:%s',
        petKind(target),
        petID,
        masterName)

    if master ~= nil and master:isPC() then
        local mJob = master:getMainJob()
        local sJob = master:getSubJob()
        out(player, 'Owner: Lv:%d/%d  Job:%s/%s',
            master:getMainLvl(),
            master:getSubLvl(),
            jobs[mJob] or tostring(mJob),
            jobs[sJob] or tostring(sJob))

        if target:isAutomaton() then
            out(player, 'Automaton skills: Melee:%d Ranged:%d Magic:%d',
                target:getSkillLevel(xi.skill.AUTOMATON_MELEE),
                target:getSkillLevel(xi.skill.AUTOMATON_RANGED),
                target:getSkillLevel(xi.skill.AUTOMATON_MAGIC))
        elseif target:isAvatar() then
            out(player, 'Owner SummoningSkill:%d',
                master:getSkillLevel(xi.skill.SUMMONING_MAGIC))
        end
    end
end

commandObj.onTrigger = function(player)
    local target, source = resolveTarget(player)
    if target == nil then
        player:printToPlayer('[TargetStats] ' .. source, S)
        return
    end

    local jobs = jobNameById()
    local mJob = target:getMainJob()
    local sJob = target:getSubJob()
    local isTrust = target:isTrust()
    local isPetTarget = isPlayerPet(target)

    out(player, '=== %s (%s) ===', target:getName(), targetKind(target))
    if source ~= nil then
        out(player, 'Source:%s', source)
    end

    out(player, 'ID:%d  Targ:%d  Pool:%d  Lv:%d/%d  Job:%s/%s',
        target:getID(),
        target:getTargID(),
        target:getPool(),
        target:getMainLvl(),
        target:getSubLvl(),
        jobs[mJob] or tostring(mJob),
        jobs[sJob] or tostring(sJob))

    out(player, 'HP:%d/%d  MP:%d/%d  TP:%d  BattleTime:%ds',
        target:getHP(),
        target:getMaxHP(),
        target:getMP(),
        target:getMaxMP(),
        target:getTP(),
        target:getBattleTime())

    if isPetTarget then
        petIdentity(player, target, jobs)
    elseif isTrust then
        local master = masterOf(target)
        out(player, 'TrustID:%d  Master:%s',
            target:getTrustID(),
            master and master:getName() or 'None')
    else
        out(player, 'TH:%d', target:getTHlevel())
    end

    out(player, 'Attrs total: STR:%d DEX:%d VIT:%d AGI:%d INT:%d MND:%d CHR:%d',
        target:getStat(xi.mod.STR),
        target:getStat(xi.mod.DEX),
        target:getStat(xi.mod.VIT),
        target:getStat(xi.mod.AGI),
        target:getStat(xi.mod.INT),
        target:getStat(xi.mod.MND),
        target:getStat(xi.mod.CHR))

    out(player, 'Combat total: ATT:%d ACC:%d DEF:%d EVA:%d MATT:%d MACC:%d MDEF:%d MEVA:%d',
        target:getStat(xi.mod.ATT),
        target:getStat(xi.mod.ACC),
        target:getStat(xi.mod.DEF),
        target:getStat(xi.mod.EVA),
        target:getMod(xi.mod.MATT),
        target:getMod(xi.mod.MACC),
        target:getMod(xi.mod.MDEF),
        target:getMod(xi.mod.MEVA))

    out(player, 'Raw mods: ATT:%d ACC:%d DEF:%d EVA:%d STR:%d DEX:%d',
        target:getMod(xi.mod.ATT),
        target:getMod(xi.mod.ACC),
        target:getMod(xi.mod.DEF),
        target:getMod(xi.mod.EVA),
        target:getMod(xi.mod.STR),
        target:getMod(xi.mod.DEX))

    out(player, 'Tempo: HasteGear:%d HasteMagic:%d HasteAbility:%d DA:%d TA:%d QA:%d',
        target:getMod(xi.mod.HASTE_GEAR),
        target:getMod(xi.mod.HASTE_MAGIC),
        target:getMod(xi.mod.HASTE_ABILITY),
        target:getMod(xi.mod.DOUBLE_ATTACK),
        target:getMod(xi.mod.TRIPLE_ATTACK),
        target:getMod(xi.mod.QUAD_ATTACK))

    out(player, 'Recovery: Regen:%d Refresh:%d Regain:%d',
        target:getMod(xi.mod.REGEN),
        target:getMod(xi.mod.REFRESH),
        target:getMod(xi.mod.REGAIN))

    out(player, 'Damage taken raw: All:%d Phys:%d Magic:%d Breath:%d',
        target:getMod(xi.mod.DMG),
        target:getMod(xi.mod.DMGPHYS),
        target:getMod(xi.mod.DMGMAGIC),
        target:getMod(xi.mod.DMGBREATH))

    out(player, 'Damage taken pct: All:%g%% Phys:%g%% Magic:%g%% Breath:%g%%',
        pct100(target:getMod(xi.mod.DMG)),
        pct100(target:getMod(xi.mod.DMGPHYS)),
        pct100(target:getMod(xi.mod.DMGMAGIC)),
        pct100(target:getMod(xi.mod.DMGBREATH)))

    out(player, 'Phys SDT: Slash:%d%% Pierce:%d%% H2H:%d%% Impact:%d%%',
        sdtPct(target:getMod(xi.mod.SLASH_SDT)),
        sdtPct(target:getMod(xi.mod.PIERCE_SDT)),
        sdtPct(target:getMod(xi.mod.HTH_SDT)),
        sdtPct(target:getMod(xi.mod.IMPACT_SDT)))

    out(player, 'Elem SDT: Fire:%d%% Ice:%d%% Wind:%d%% Earth:%d%% Thunder:%d%% Water:%d%% Light:%d%% Dark:%d%%',
        sdtPct(target:getMod(xi.mod.FIRE_SDT)),
        sdtPct(target:getMod(xi.mod.ICE_SDT)),
        sdtPct(target:getMod(xi.mod.WIND_SDT)),
        sdtPct(target:getMod(xi.mod.EARTH_SDT)),
        sdtPct(target:getMod(xi.mod.THUNDER_SDT)),
        sdtPct(target:getMod(xi.mod.WATER_SDT)),
        sdtPct(target:getMod(xi.mod.LIGHT_SDT)),
        sdtPct(target:getMod(xi.mod.DARK_SDT)))

    out(player, 'WeaponDmg:%d  RangedDmg:%d  Immunities:%s',
        target:getWeaponDmg(),
        target:getRangedDmg(),
        immunityText(target))

    if isTrust then
        out(player, 'Trust MobMods: TRUST_DISTANCE:%d TRUST_SHIELD_SIZE:%d SPECIAL_SKILL:%d SKILL_LIST:%d',
            target:getMobMod(xi.mobMod.TRUST_DISTANCE),
            target:getMobMod(xi.mobMod.TRUST_SHIELD_SIZE),
            target:getMobMod(xi.mobMod.SPECIAL_SKILL),
            target:getMobMod(xi.mobMod.SKILL_LIST))
    elseif isPetTarget then
        out(player, 'Pet MobMods: ROAM_DISTANCE:%d SPECIAL_SKILL:%d SKILL_LIST:%d ATTACK_SKILL_LIST:%d',
            target:getMobMod(xi.mobMod.ROAM_DISTANCE),
            target:getMobMod(xi.mobMod.SPECIAL_SKILL),
            target:getMobMod(xi.mobMod.SKILL_LIST),
            target:getMobMod(xi.mobMod.ATTACK_SKILL_LIST))
    else
        out(player, 'MobMods: NO_CP:%d ROAM_DISTANCE:%d SPECIAL_SKILL:%d SKILL_LIST:%d',
            target:getMobMod(xi.mobMod.NO_CAPACITY_POINTS),
            target:getMobMod(xi.mobMod.ROAM_DISTANCE),
            target:getMobMod(xi.mobMod.SPECIAL_SKILL),
            target:getMobMod(xi.mobMod.SKILL_LIST))
    end
end

return commandObj
