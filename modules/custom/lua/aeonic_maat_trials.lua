-----------------------------------
-- Weapon-specific solo Maat trials for final Aeonic forging.
--
-- Entry: "Aeonic Maat" beside Maat in Ru'Lude Gardens.
-- Arena: Waughroon Shrine. Every challenger receives a private, claim-locked
-- dynamic Maat. Trusts and the custom Fellow are dismissed on entry and on
-- every fight tick; real parties/alliances abort the trial.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/RuLude_Gardens/Zone')
require('scripts/zones/Waughroon_Shrine/Zone')

local catalog = require('modules/custom/lua/aeonic_maat_catalog')
local m = Module:new('aeonic_maat_trials')

local S = xi.msg.channel.SYSTEM_3
local ZONE_ID = xi.zone.WAUGHROON_SHRINE
local TEMPLATE_GROUP_ID = 12
local TEMPLATE_ZONE_ID = 144
local MAAT_LEVEL = 150
local FIGHT_LIMIT = 180
local TICK_MS = 1000
local ENGAGE_DIST = 15

local ENTRY = { x = -361.434, y = 101.798, z = -259.996, rot = 0 }
local SPAWN = { x = -334.553, y = 104.824, z = -259.501, rot = 128 }
local NPC = { x = 10.99660, y = 3.1000, z = 116.2006, rot = 153 }

local activeFights = {}
local fightState = {}

local JOB_SPECIALS =
{
    [xi.job.WAR] = xi.mobSkill.MIGHTY_STRIKES_MAAT,
    [xi.job.MNK] = xi.mobSkill.HUNDRED_FISTS_MAAT,
    [xi.job.WHM] = xi.mobSkill.BENEDICTION_MAAT,
    [xi.job.BLM] = xi.mobSkill.MANAFONT_MAAT,
    [xi.job.RDM] = xi.mobSkill.CHAINSPELL_MAAT,
    [xi.job.THF] = xi.mobSkill.PERFECT_DODGE_MAAT,
    [xi.job.PLD] = xi.mobSkill.INVINCIBLE_MAAT,
    [xi.job.DRK] = xi.mobSkill.BLOOD_WEAPON_MAAT,
    [xi.job.BST] = xi.mobSkill.FAMILIAR_MAAT,
    [xi.job.BRD] = xi.mobSkill.SOUL_VOICE_MAAT,
    [xi.job.RNG] = xi.mobSkill.EES_MAAT,
    [xi.job.SAM] = xi.mobSkill.MEIKYO_SHISUI_MAAT,
    [xi.job.NIN] = xi.mobSkill.MIJIN_GAKURE_MAAT,
    [xi.job.DRG] = xi.mobSkill.CALL_WYVERN_MAAT,
    [xi.job.SMN] = xi.mobSkill.ASTRAL_FLOW_MAAT,
    [xi.job.BLU] = xi.mobSkill.AZURE_LORE,
    [xi.job.COR] = xi.mobSkill.WILD_CARD,
    [xi.job.PUP] = xi.mobSkill.OVERDRIVE,
    [xi.job.DNC] = xi.mobSkill.TRANCE,
    [xi.job.SCH] = xi.mobSkill.TABULA_RASA,
    [xi.job.GEO] = xi.mobSkill.BOLSTER,
}

local EXPANSION_SPECIAL_EFFECTS =
{
    [xi.job.BLU] = xi.effect.AZURE_LORE,
    [xi.job.PUP] = xi.effect.OVERDRIVE,
    [xi.job.DNC] = xi.effect.TRANCE,
    [xi.job.SCH] = xi.effect.TABULA_RASA,
    [xi.job.GEO] = xi.effect.BOLSTER,
    [xi.job.RUN] = xi.effect.ELEMENTAL_SFORZO,
}

local BASE_MODS =
{
    [xi.mod.DEF] = 5200,
    [xi.mod.ATT] = 7500,
    [xi.mod.ACC] = 4300,
    [xi.mod.EVASION] = 2200,
    [xi.mod.MATT] = 3300,
    [xi.mod.MACC] = 3500,
    [xi.mod.MEVA] = 2700,
    [xi.mod.MDEF] = 2500,
    [xi.mod.STR] = 700,
    [xi.mod.DEX] = 700,
    [xi.mod.VIT] = 700,
    [xi.mod.AGI] = 700,
    [xi.mod.INT] = 700,
    [xi.mod.MND] = 700,
    [xi.mod.CHR] = 700,
    [xi.mod.DOUBLE_ATTACK] = 22,
    [xi.mod.TRIPLE_ATTACK] = 8,
    [xi.mod.HASTE_GEAR] = 250,
    [xi.mod.REGAIN] = 250,
    [xi.mod.REGEN] = 600,
}

local PROFILE_HP =
{
    momentum = 8500000,
    performance = 7800000,
    rune_cycle = 9000000,
    doom_brand = 9000000,
    beast_rage = 8800000,
    war_cry = 9200000,
    dread_cycle = 9000000,
    sky_assault = 8400000,
    shadow_wheel = 8000000,
    skillchain = 8600000,
    sanctuary = 8200000,
    grimoire = 8000000,
    deadzone = 7600000,
    crooked_roll = 7800000,
}

local JOB_COMPANIONS =
{
    [xi.job.BST] = { groupId = 15, groupZoneId = 144, name = "Maat's Familiar" },
    [xi.job.SMN] = { groupId = 12, groupZoneId = 146, name = "Maat's Avatar" },
    [xi.job.DRG] = { groupId = 7, groupZoneId = 168, name = "Maat's Wyvern" },
    [xi.job.PUP] = { groupId = 15, groupZoneId = 13, name = "Maat's Automaton" },
}

local function ownerMessage(owner, text)
    if owner then
        owner:printToPlayer('[Aeonic Maat] ' .. text, S)
    end
end

local function dismissCompanions(player)
    local ok, party = pcall(function() return player:getPartyWithTrusts() end)
    if not ok or not party then return end
    for _, member in ipairs(party) do
        pcall(function()
            if member:isTrust() then
                local master = member:getMaster()
                if master then
                    master:despawnTrust(member)
                end
            end
        end)
    end
end

local isGrouped = catalog.isGrouped

local function damageOwner(mob, owner, percent, text)
    if not owner or owner:getHP() <= 0 then return end
    local damage = math.max(1, math.floor(owner:getMaxHP() * percent / 100))
    owner:takeDamage(damage, mob, xi.attackType.SPECIAL, xi.damageType.ELEMENTAL)
    if text then ownerMessage(owner, text) end
end

local function addDispellableBuff(mob, effect, power, duration)
    mob:delStatusEffect(effect)
    mob:addStatusEffect(effect, { power = power, duration = duration, origin = mob })
end

local function applyBardOpening(mob, owner, st)
    addDispellableBuff(mob, xi.effect.MINUET, 10000, 180)
    addDispellableBuff(mob, xi.effect.MINNE, 6000, 180)
    addDispellableBuff(mob, xi.effect.MADRIGAL, 4000, 180)
    st.nextSongAt = os.time() + math.random(30, 45)
    ownerMessage(owner,
        'Maat instantly sings Minuet, Minne, and Madrigal. Dispel them before he overwhelms you!')
end

local function maintainBardSongs(mob, owner, st, now)
    if st.jobId ~= xi.job.BRD then return end
    if not st.bardOpened then
        st.bardOpened = true
        applyBardOpening(mob, owner, st)
        return
    end
    if now < (st.nextSongAt or 0) then return end

    local missing = {}
    if not mob:hasStatusEffect(xi.effect.MINUET) then
        missing[#missing + 1] = { xi.effect.MINUET, 10000, 'Valor Minuet' }
    end
    if not mob:hasStatusEffect(xi.effect.MINNE) then
        missing[#missing + 1] = { xi.effect.MINNE, 6000, 'Knight Minne' }
    end
    if not mob:hasStatusEffect(xi.effect.MADRIGAL) then
        missing[#missing + 1] = { xi.effect.MADRIGAL, 4000, 'Blade Madrigal' }
    end

    if #missing > 0 then
        local song = missing[math.random(#missing)]
        addDispellableBuff(mob, song[1], song[2], 180)
        ownerMessage(owner, string.format('Maat instantly resings %s!', song[3]))
    end
    st.nextSongAt = now + math.random(30, 45)
end

local function forCompanions(st, callback)
    for _, addId in ipairs(st.companionIds or {}) do
        local add = GetMobByID(addId)
        if add and add:getHP() > 0 then
            callback(add)
        end
    end
end

local function activateJobSpecial(mob, owner, st)
    if st.specialUsed then return end
    st.specialUsed = true
    ownerMessage(owner,
        string.format('Maat unleashes the full power of %s!', catalog.jobNames[st.jobId] or 'his job'))

    local effect = EXPANSION_SPECIAL_EFFECTS[st.jobId]
    if effect then
        mob:addStatusEffect(effect, { power = 1, duration = 45, origin = mob })
    else
        local ability = JOB_SPECIALS[st.jobId]
        if ability then
            pcall(function() mob:useMobAbility(ability, owner) end)
        end
    end

    if JOB_COMPANIONS[st.jobId] then
        forCompanions(st, function(add)
            add:addMod(xi.mod.ATT, 3000)
            add:addMod(xi.mod.DOUBLE_ATTACK, 30)
            add:addMod(xi.mod.REGEN, 1500)
            if st.jobId == xi.job.PUP then
                add:addStatusEffect(xi.effect.OVERDRIVE, {
                    power = 1, duration = 45, origin = mob,
                })
            end
        end)
        if st.jobId == xi.job.SMN then
            damageOwner(mob, owner, 25, "Maat's avatar answers Astral Flow!")
        end
    end
end

local function runJobAction(mob, owner, st)
    local job = st.jobId
    if job == xi.job.WAR then
        addDispellableBuff(mob, xi.effect.BERSERK, 35, 20)
        ownerMessage(owner, 'Maat uses a maximized Berserk.')
    elseif job == xi.job.MNK then
        addDispellableBuff(mob, xi.effect.COUNTERSTANCE, 75, 18)
        ownerMessage(owner, 'Maat assumes Counterstance.')
    elseif job == xi.job.WHM then
        mob:addHP(math.floor(mob:getMaxHP() * 0.06))
        ownerMessage(owner, 'Maat invokes an instant curative prayer.')
    elseif job == xi.job.BLM then
        damageOwner(mob, owner, 16, 'Maat releases an instant elemental burst.')
    elseif job == xi.job.RDM then
        addDispellableBuff(mob, xi.effect.HASTE, 3000, 20)
        owner:addStatusEffect(xi.effect.SLOW, { power = 2500, duration = 12, origin = mob })
        ownerMessage(owner, 'Maat quickens himself and weighs down your attacks.')
    elseif job == xi.job.THF then
        damageOwner(mob, owner, 18, 'Maat slips behind you for a perfect Sneak Attack.')
    elseif job == xi.job.PLD then
        addDispellableBuff(mob, xi.effect.SENTINEL, 80, 18)
        ownerMessage(owner, 'Maat braces behind Sentinel.')
    elseif job == xi.job.DRK then
        addDispellableBuff(mob, xi.effect.DREAD_SPIKES, 25, 15)
        ownerMessage(owner, 'Dread Spikes coil around Maat.')
    elseif job == xi.job.BST then
        mob:addMod(xi.mod.ATT, 350)
        mob:addMod(xi.mod.DOUBLE_ATTACK, 3)
        forCompanions(st, function(add)
            add:addMod(xi.mod.ATT, 500)
            add:addMod(xi.mod.DOUBLE_ATTACK, 5)
        end)
        ownerMessage(owner, 'Maat channels Familiar and grows more feral.')
    elseif job == xi.job.RNG then
        damageOwner(mob, owner, 17, 'Maat fires an unerring barrage.')
    elseif job == xi.job.SAM then
        mob:setTP(3000)
        damageOwner(mob, owner, 18, 'Maat spends 3000 TP on a perfectly timed weaponskill.')
        mob:setTP(0)
    elseif job == xi.job.NIN then
        addDispellableBuff(mob, xi.effect.COPY_IMAGE_4, 4, 30)
        ownerMessage(owner, 'Four perfect shadows surround Maat.')
    elseif job == xi.job.DRG then
        damageOwner(mob, owner, 16, 'Maat crashes down with a perfectly timed Jump.')
    elseif job == xi.job.SMN then
        damageOwner(mob, owner, 17, 'Maat channels an avatar through an instant blood pact.')
    elseif job == xi.job.BLU then
        damageOwner(mob, owner, 15, 'Maat releases a mastered blue-magic combination.')
        owner:addStatusEffect(xi.effect.PARALYSIS, { power = 35, duration = 10, origin = mob })
    elseif job == xi.job.COR then
        addDispellableBuff(mob, xi.effect.HUNTERS_ROLL, 3500, 25)
        ownerMessage(owner, "Maat's Hunter's Roll lands on XI.")
    elseif job == xi.job.PUP then
        mob:addStatusEffect(xi.effect.OVERDRIVE, { power = 1, duration = 20, origin = mob })
        forCompanions(st, function(add)
            add:addStatusEffect(xi.effect.OVERDRIVE, {
                power = 1, duration = 20, origin = mob,
            })
        end)
        damageOwner(mob, owner, 12, 'Maat coordinates an Overdrive volley.')
    elseif job == xi.job.DNC then
        mob:addHP(math.floor(mob:getMaxHP() * 0.03))
        addDispellableBuff(mob, xi.effect.HASTE, 2500, 18)
        ownerMessage(owner, 'Maat closes his wounds with a perfected Waltz.')
    elseif job == xi.job.SCH then
        st.schDark = not st.schDark
        if st.schDark then
            damageOwner(mob, owner, 15, 'Maat executes an instant Dark Arts helix.')
        else
            mob:addHP(math.floor(mob:getMaxHP() * 0.04))
            ownerMessage(owner, 'Maat converts to Light Arts and restores himself.')
        end
    elseif job == xi.job.GEO then
        addDispellableBuff(mob, xi.effect.BOLSTER, 1, 18)
        mob:addMod(xi.mod.ATT, 250)
        ownerMessage(owner, 'Maat intensifies his geomantic field.')
    elseif job == xi.job.RUN then
        addDispellableBuff(mob, xi.effect.ELEMENTAL_SFORZO, 1, 16)
        ownerMessage(owner, 'Maat invokes Elemental Sforzo.')
    end
end

local PROFILE_PERIOD =
{
    momentum = 8, performance = 24, rune_cycle = 18, doom_brand = 25,
    beast_rage = 20, war_cry = 15, dread_cycle = 38, sky_assault = 18,
    shadow_wheel = 28, skillchain = 32, sanctuary = 30, grimoire = 17,
    deadzone = 5, crooked_roll = 30,
}

local function runProfileAction(mob, owner, st, now)
    local mechanic = st.trial.mechanic
    if mechanic == 'momentum' then
        st.momentum = math.min((st.momentum or 0) + 1, 8)
        mob:addMod(xi.mod.ATT, 450)
        mob:addMod(xi.mod.DOUBLE_ATTACK, 4)
        ownerMessage(owner, string.format('Relentless Momentum rises to %d/8. Weaponskills break his rhythm.', st.momentum))

    elseif mechanic == 'performance' then
        if st.jobId ~= xi.job.BRD then
            addDispellableBuff(mob, xi.effect.EVASION_BOOST, 1800, 12)
            damageOwner(mob, owner, 10, 'Maat vanishes into a deadly flourish.')
        end

    elseif mechanic == 'rune_cycle' then
        st.runeMagic = not st.runeMagic
        if st.runeMagic then
            mob:setMod(xi.mod.DMGPHYS, -4000)
            mob:setMod(xi.mod.DMGMAGIC, 1500)
            ownerMessage(owner, 'Runic Reversal: weapons are resisted; magic pierces him.')
        else
            mob:setMod(xi.mod.DMGPHYS, 1500)
            mob:setMod(xi.mod.DMGMAGIC, -4000)
            ownerMessage(owner, 'Runic Reversal: magic is resisted; weapons pierce him.')
        end

    elseif mechanic == 'doom_brand' then
        st.brandDue = now + 6
        ownerMessage(owner, 'The Lionheart Brand ignites. Prepare for the detonation!')

    elseif mechanic == 'beast_rage' then
        st.beastStacks = math.min((st.beastStacks or 0) + 1, 5)
        mob:addMod(xi.mod.ATT, 300)
        mob:addMod(xi.mod.DOUBLE_ATTACK, 4)
        mob:addHP(math.floor(mob:getMaxHP() * 0.015))
        ownerMessage(owner, string.format('Primal Dominion strengthens (%d/5).', st.beastStacks))

    elseif mechanic == 'war_cry' then
        mob:addMod(xi.mod.ATT, 250)
        damageOwner(mob, owner, 16, 'Chango answers Maat with an unavoidable warcry.')

    elseif mechanic == 'dread_cycle' then
        addDispellableBuff(mob, xi.effect.DREAD_SPIKES, 30, 18)
        mob:addStatusEffect(xi.effect.BLOOD_WEAPON, { power = 1, duration = 12, origin = mob })
        ownerMessage(owner, 'The Dread Covenant awakens. Dispel the spikes or stop attacking.')

    elseif mechanic == 'sky_assault' then
        damageOwner(mob, owner, 22, 'Maat descends from beyond your sight with Skybreaker.')
        owner:addStatusEffect(xi.effect.WEIGHT, { power = 35, duration = 8, origin = mob })

    elseif mechanic == 'shadow_wheel' then
        addDispellableBuff(mob, xi.effect.COPY_IMAGE_4, 4, 30)
        st.shadowBurstDue = now + 8
        ownerMessage(owner, 'The Wheel of Shadows forms. Strip his images before it detonates!')

    elseif mechanic == 'skillchain' then
        st.chainHits = 3
        st.nextChainHit = now
        ownerMessage(owner, 'Maat begins a three-step Perfect Skillchain!')

    elseif mechanic == 'sanctuary' then
        st.sanctuaryHeal = not st.sanctuaryHeal
        if st.sanctuaryHeal then
            addDispellableBuff(mob, xi.effect.REGEN, 3500, 18)
            ownerMessage(owner, 'A dispellable healing sanctuary surrounds Maat.')
        else
            addDispellableBuff(mob, xi.effect.STONESKIN, 30000, 18)
            ownerMessage(owner, 'A dispellable stone sanctuary shields Maat.')
        end

    elseif mechanic == 'grimoire' then
        st.grimoireStep = ((st.grimoireStep or 0) % 3) + 1
        local names = { 'Pyrohelix', 'Cryohelix', 'Noctohelix' }
        damageOwner(mob, owner, 14 + st.grimoireStep * 2,
            string.format('The Forbidden Grimoire opens to %s.', names[st.grimoireStep]))

    elseif mechanic == 'deadzone' then
        local distance = mob:checkDistance(owner)
        if distance < 8 then
            damageOwner(mob, owner, 20, "You are inside the archer's deadzone!")
        elseif distance > 22 then
            damageOwner(mob, owner, 14, 'You stray beyond cover and Maat lines up a distant shot!')
        else
            ownerMessage(owner, 'You hold the safe firing lane between 8 and 22 yalms.')
        end

    elseif mechanic == 'crooked_roll' then
        local rolls =
        {
            { xi.effect.CHAOS_ROLL, 150, "Chaos Roll" },
            { xi.effect.HUNTERS_ROLL, 4000, "Hunter's Roll" },
            { xi.effect.SAMURAI_ROLL, 500, "Samurai Roll" },
            { xi.effect.TACTICIANS_ROLL, 250, "Tactician's Roll" },
        }
        local roll = rolls[math.random(#rolls)]
        addDispellableBuff(mob, roll[1], roll[2], 28)
        ownerMessage(owner, string.format("Crooked %s lands on XI. Dispel it!", roll[3]))
    end
end

local function resetMomentum(mob, st)
    local stacks = st.momentum or 0
    if stacks <= 0 then return end
    mob:delMod(xi.mod.ATT, stacks * 450)
    mob:delMod(xi.mod.DOUBLE_ATTACK, stacks * 4)
    st.momentum = 0
end

local function cleanup(mob)
    local id = mob and mob:getID()
    if id then
        local st = fightState[id]
        for _, addId in ipairs((st and st.companionIds) or {}) do
            local add = GetMobByID(addId)
            if add and add:getHP() > 0 then
                add:setLocalVar('AeonicMaatCompanionCleanup', 1)
                add:setHP(0)
            end
        end
        fightState[id] = nil
    end
end

local function trialTick(mob, target)
    local st = fightState[mob:getID()]
    if not st then return end

    local owner = GetPlayerByName(st.ownerName)
    if not owner or owner:getZoneID() ~= ZONE_ID or owner:getHP() <= 0 then
        st.idle = (st.idle or 0) + 1
        if st.idle >= 6 then
            activeFights[st.ownerName] = nil
            mob:setLocalVar('AeonicMaatAborted', 1)
            mob:setHP(0)
        end
        return
    end
    st.idle = 0

    dismissCompanions(owner)
    if isGrouped(owner) then
        ownerMessage(owner, 'The trial ends because another player joined your group.')
        activeFights[st.ownerName] = nil
        mob:setLocalVar('AeonicMaatAborted', 1)
        mob:setHP(0)
        return
    end

    if not mob:isEngaged() then
        if mob:checkDistance(owner) <= ENGAGE_DIST then
            mob:updateClaim(owner)
            mob:addEnmity(owner, 30000, 30000)
            st.startedAt = os.time()
            st.nextJobAt = st.startedAt + 20
            st.nextProfileAt = st.startedAt + (PROFILE_PERIOD[st.trial.mechanic] or 20)
            maintainBardSongs(mob, owner, st, st.startedAt)
        end
        return
    end

    local now = os.time()
    for _, addId in ipairs(st.companionIds or {}) do
        local add = GetMobByID(addId)
        if add and add:getHP() > 0 and not add:isEngaged() then
            add:updateClaim(owner)
            add:addEnmity(owner, 30000, 30000)
        end
    end
    maintainBardSongs(mob, owner, st, now)

    if st.brandDue and now >= st.brandDue then
        st.brandDue = nil
        damageOwner(mob, owner, 35, 'The Lionheart Brand detonates!')
    end
    if st.shadowBurstDue and now >= st.shadowBurstDue then
        st.shadowBurstDue = nil
        if mob:hasStatusEffect(xi.effect.COPY_IMAGE_4) then
            damageOwner(mob, owner, 28, 'The Wheel of Shadows detonates through its remaining images!')
        else
            ownerMessage(owner, 'The stripped Wheel of Shadows collapses harmlessly.')
        end
    end
    if (st.chainHits or 0) > 0 and now >= (st.nextChainHit or 0) then
        local step = 4 - st.chainHits
        damageOwner(mob, owner, 10 + step * 3,
            string.format('Perfect Skillchain step %d/3 lands!', step))
        st.chainHits = st.chainHits - 1
        st.nextChainHit = now + 2
    end

    if not st.specialUsed and mob:getHPP() <= 55 then
        activateJobSpecial(mob, owner, st)
    end

    if now >= (st.nextJobAt or now + 1) then
        runJobAction(mob, owner, st)
        st.nextJobAt = now + 24
    end
    if now >= (st.nextProfileAt or now + 1) then
        runProfileAction(mob, owner, st, now)
        st.nextProfileAt = now + (PROFILE_PERIOD[st.trial.mechanic] or 20)
    end

    if st.startedAt and now - st.startedAt >= FIGHT_LIMIT and not st.enraged then
        st.enraged = true
        mob:addMod(xi.mod.ATT, 6000)
        mob:addMod(xi.mod.TRIPLE_ATTACK, 30)
        mob:addMod(xi.mod.REGAIN, 1000)
        ownerMessage(owner, 'Time expires. Maat enters an overwhelming final enrage!')
    end
end

local function scheduleTick(mob)
    mob:timer(TICK_MS, function(current)
        if current and current:getHP() > 0 then
            trialTick(current, current:getTarget())
            scheduleTick(current)
        end
    end)
end

local function spawnJobCompanion(zone, owner, jobId, sx, sz)
    local def = JOB_COMPANIONS[jobId]
    if not def then return nil end

    local companion = zone:insertDynamicEntity({
        objtype = xi.objType.MOB,
        groupId = def.groupId,
        groupZoneId = def.groupZoneId,
        name = string.format('AeMComp_%d_%d', jobId, owner:getID()),
        packetName = def.name,
        x = sx + 2.5, y = SPAWN.y, z = sz + 2.5, rotation = SPAWN.rot,
        minLevel = MAAT_LEVEL, maxLevel = MAAT_LEVEL,
        detection = 0,
        isAggroable = false,
        releaseIdOnDisappear = true,
    })
    if not companion then return nil end

    companion:setSpawn(sx + 2.5, SPAWN.y, sz + 2.5, SPAWN.rot)
    companion:spawn()
    companion:setAggressive(false)
    companion:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    companion:setMod(xi.mod.ATT, 5200)
    companion:setMod(xi.mod.ACC, 4000)
    companion:setMod(xi.mod.DEF, 3800)
    companion:setMod(xi.mod.MATT, 2800)
    companion:setMod(xi.mod.MACC, 3000)
    companion:setMod(xi.mod.DOUBLE_ATTACK, 15)
    companion:setMaxHP(1500000)
    companion:setHP(1500000)
    companion:updateClaim(owner)
    return companion:getID()
end

local function spawnTrial(player, trial, jobId)
    local ownerName = player:getName()
    local zone = player:getZone()
    local sx = SPAWN.x + (math.random() * 4 - 2)
    local sz = SPAWN.z + (math.random() * 4 - 2)

    local mob = zone:insertDynamicEntity({
        objtype = xi.objType.MOB,
        groupId = TEMPLATE_GROUP_ID,
        groupZoneId = TEMPLATE_ZONE_ID,
        name = string.format('AeMaat_%d_%d_%d', trial.finalId, jobId, player:getID()),
        packetName = 'Maat',
        x = sx, y = SPAWN.y, z = sz, rotation = SPAWN.rot,
        minLevel = MAAT_LEVEL, maxLevel = MAAT_LEVEL,
        detection = 0,
        isAggroable = false,
        releaseIdOnDisappear = true,

        onMobFight = function(fightMob, target)
            trialTick(fightMob, target)
        end,

        onMobDeath = function(deadMob)
            local st = fightState[deadMob:getID()]
            cleanup(deadMob)
            activeFights[ownerName] = nil
            if deadMob:getLocalVar('AeonicMaatAborted') == 1 or not st then
                return
            end

            local owner = GetPlayerByName(ownerName)
            if not owner then return end
            owner:setCharVar(catalog.completionVar(trial.finalId), jobId)

            local elapsed = st.startedAt and (os.time() - st.startedAt) or 0
            if elapsed > 0 then
                local bestVar = catalog.bestTimeVar(trial.finalId)
                local best = owner:getCharVar(bestVar) or 0
                if best == 0 or elapsed < best then
                    owner:setCharVar(bestVar, elapsed)
                end
            end

            ownerMessage(owner, string.format(
                '%s acknowledges your %s mastery. The final %s forge gate is cleared!',
                'Maat', catalog.jobNames[jobId] or 'job', trial.name))
        end,
    })

    if not mob then
        ownerMessage(player, 'The trial could not manifest. Try again.')
        return false
    end

    activeFights[ownerName] = mob:getID()
    mob:setSpawn(sx, SPAWN.y, sz, SPAWN.rot)
    mob:spawn()
    mob:changeJob(jobId)
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    mob:setMobMod(xi.mobMod.SKILL_LIST, 0)
    mob:setSpellList(0)
    mob:setAggressive(false)
    for modId, value in pairs(BASE_MODS) do
        mob:setMod(modId, value)
    end
    local hp = PROFILE_HP[trial.mechanic] or 8000000
    mob:setMaxHP(hp)
    mob:setHP(hp)
    mob:updateClaim(player)

    fightState[mob:getID()] =
    {
        ownerName = ownerName,
        trial = trial,
        jobId = jobId,
        companionIds = {},
    }
    local companionId = spawnJobCompanion(zone, player, jobId, sx, sz)
    if companionId then
        fightState[mob:getID()].companionIds[1] = companionId
        ownerMessage(player, string.format(
            'Maat calls forth a fully empowered %s companion.',
            catalog.jobNames[jobId] or 'job'))
    end

    if trial.mechanic == 'momentum' then
        mob:addListener('WEAPONSKILL_TAKE', 'AEONIC_MAAT_MOMENTUM', function(_, target)
            local state = fightState[target:getID()]
            if state then
                resetMomentum(target, state)
                local owner = GetPlayerByName(state.ownerName)
                ownerMessage(owner, 'Your weaponskill breaks Maat\'s momentum!')
            end
        end)
    end

    scheduleTick(mob)
    ownerMessage(player, string.format(
        '%s Maat awaits: %s. Approach when ready.',
        catalog.jobNames[jobId] or 'Job', trial.mechanicLabel))
    return true
end

local function beginTrial(player, trial)
    dismissCompanions(player)
    local canEnter, reason = catalog.canEnter(player, trial)
    if not canEnter and reason == 'grouped' then
        ownerMessage(player, 'Leave your party or alliance before beginning this solo trial.')
        return
    end

    local jobId = player:getMainJob()
    if not canEnter and reason == 'wrong_job' then
        ownerMessage(player, string.format(
            '%s must be challenged on %s. You are currently %s.',
            trial.name, catalog.jobList(trial), catalog.jobNames[jobId] or tostring(jobId)))
        return
    end
    if not canEnter and reason == 'not_empowered' then
        ownerMessage(player, string.format('Complete %s Aeonic Pilgrimage Chapters I and II first.', trial.name))
        return
    end
    if not canEnter then
        ownerMessage(player, 'That Aeonic Maat trial is invalid.')
        return
    end

    local existingId = activeFights[player:getName()]
    if existingId and GetMobByID(existingId) then
        ownerMessage(player, 'Your existing Aeonic Maat trial is still active.')
        return
    end

    player:setCharVar('AeonicMaatPending', trial.finalId)
    player:setCharVar('AeonicMaatPendingJob', jobId)
    player:setPos(ENTRY.x, ENTRY.y, ENTRY.z, ENTRY.rot, ZONE_ID)
end

local function showTrialMenu(player, page)
    local held = {}
    for _, trial in ipairs(catalog.trials) do
        if catalog.isReady(player, trial) and not catalog.isComplete(player, trial.finalId) then
            held[#held + 1] = trial
        end
    end
    if #held == 0 then
        ownerMessage(player, 'Complete Chapters I and II of an Aeonic pilgrimage to challenge its Maat trial.')
        return
    end

    local pageSize = 3
    local maxPage = math.max(1, math.ceil(#held / pageSize))
    page = math.max(1, math.min(page or 1, maxPage))
    local first = (page - 1) * pageSize + 1
    local options = {}
    for index = first, math.min(first + pageSize - 1, #held) do
        local trial = held[index]
        options[#options + 1] =
        {
            string.format('%s [%s]', trial.name, catalog.jobList(trial)),
            function(p) beginTrial(p, trial) end,
        }
    end
    if page < maxPage then
        options[#options + 1] = { 'Next page', function(p) showTrialMenu(p, page + 1) end }
    end
    if page > 1 then
        options[#options + 1] = { 'Previous page', function(p) showTrialMenu(p, page - 1) end }
    end
    options[#options + 1] = { 'Not yet', function() end }

    local menu =
    {
        title = string.format('Aeonic Maat (%d/%d)', page, maxPage),
        options = options,
    }
    player:timer(30, function(p) p:customMenu(menu) end)
end

m:addOverride('xi.zones.RuLude_Gardens.Zone.onInitialize', function(zone)
    super(zone)
    local npc = zone:insertDynamicEntity({
        objtype = xi.objType.NPC,
        name = 'Aeonic_Maat',
        packetName = string.format('%sAeonic Maat', xi.icon.STAR_LARGE),
        look = 3064,
        x = NPC.x, y = NPC.y, z = NPC.z, rotation = NPC.rot,
        widescan = 1,
        onTrigger = function(player)
            showTrialMenu(player, 1)
        end,
    })
    utils.unused(npc)
end)

m:addOverride('xi.zones.Waughroon_Shrine.Zone.onZoneIn', function(player, prevZone)
    local cs = super(player, prevZone)
    local finalId = player:getCharVar('AeonicMaatPending') or 0
    if finalId > 0 then
        local jobId = player:getCharVar('AeonicMaatPendingJob') or 0
        player:setCharVar('AeonicMaatPending', 0)
        player:setCharVar('AeonicMaatPendingJob', 0)
        player:timer(1000, function(p)
            dismissCompanions(p)
            local trial = catalog.byFinalId[finalId]
            local canEnter = trial and catalog.canEnter(p, trial)
            if not canEnter or p:getMainJob() ~= jobId then
                ownerMessage(p, 'The pending trial was invalid and has been cancelled.')
                return
            end
            spawnTrial(p, trial, jobId)
        end)
    end
    return cs
end)

xi.aeonicMaatTrials =
{
    catalog = catalog,
    beginTrial = beginTrial,
    isGrouped = isGrouped,
}

return m
