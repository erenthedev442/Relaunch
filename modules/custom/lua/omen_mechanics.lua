-----------------------------------
-- Omen boss / mid-boss mechanics
--
-- Attached per spawned boss by omen_instance.lua. Everything here uses
-- entity/instance localvars only (concurrent runs share this module).
--
-- The Caturae's regular TP kit comes from mob_skill_lists 'Caturae' (450)
-- via the SQL layer; the Glassy NMs use their retail Promyvion kits
-- (lists 78 / 137 / 241). This module adds the SIGNATURE moves whose
-- animations were never captured on any server (mob_skills 4096-4107):
-- they resolve as scripted effects with chat-line telegraphs instead of
-- client animations. If those animation IDs are ever captured, promote
-- them to real mobskills and slim this file down.
--
-- Retail references: bg-wiki pages for Kin / Gin / Fu / Kyou / Kei / Ou
-- and Glassy Craver / Gorger / Thinker.
-----------------------------------
local mechanics = package.loaded['modules/custom/lua/omen_mechanics']
if type(mechanics) ~= 'table' then mechanics = {} end

-----------------------------------
-- Helpers
-----------------------------------
local function announce(instance, message)
    for _, player in ipairs(instance:getChars()) do
        player:printToPlayer('[Omen] ' .. message, xi.msg.channel.SYSTEM_3)
    end
end

local function forEachCharNear(instance, mob, radius, fn)
    for _, player in ipairs(instance:getChars()) do
        if player:getHP() > 0 and player:checkDistance(mob) <= radius then
            fn(player)
        end
    end
end

local function trueDamage(player, mob, amount)
    player:takeDamage(amount, mob, xi.attackType.SPECIAL, xi.damageType.DARK)
end

-- Fires `fn(mob, threshold)` once per threshold as HP falls through it.
-- Threshold state lives on the mob (OmenThresh<value>), so each spawned
-- boss tracks its own crossings.
local function onThresholds(mob, instance, thresholds, fn)
    mob:addListener('TAKE_DAMAGE', 'OMEN_THRESHOLDS', function(mobArg, amount, attacker, attackType, damageType)
        local hpp = mobArg:getHPP()
        for _, threshold in ipairs(thresholds) do
            if hpp <= threshold and mobArg:getLocalVar('OmenThresh' .. threshold) == 0 then
                mobArg:setLocalVar('OmenThresh' .. threshold, 1)
                fn(mobArg, threshold)
            end
        end
    end)
end

-- Periodic combat mechanic: fn runs roughly every `seconds` while engaged.
local function onCombatInterval(mob, instance, name, seconds, fn)
    mob:addListener('COMBAT_TICK', name, function(mobArg)
        local now  = os.time()
        local mark = mobArg:getLocalVar(name .. 'At')
        if mark == 0 then
            mobArg:setLocalVar(name .. 'At', now + seconds)
        elseif now >= mark then
            mobArg:setLocalVar(name .. 'At', now + seconds)
            fn(mobArg)
        end
    end)
end

-----------------------------------
-- Signature effects (shared building blocks)
-----------------------------------
local function ebullientNullification(mob, instance, label)
    announce(instance, string.format('%s uses Ebullient Nullification! Beneficial auras are torn away...', label))

    local absorbed = 0
    forEachCharNear(instance, mob, 20, function(player)
        absorbed = absorbed + (player:dispelAllStatusEffect() or 0)
    end)

    if absorbed > 0 then
        -- Grows stronger per stolen buff.
        mob:addMod(xi.mod.ATT, 20 * absorbed)
        mob:addMod(xi.mod.MATT, 5 * absorbed)
        announce(instance, string.format('It swells with power! (%d effects absorbed)', absorbed))
    end
end

local function unfalteringBravado(mob, instance, label)
    local victims = {}
    forEachCharNear(instance, mob, 15, function(player)
        table.insert(victims, player)
    end)

    announce(instance, string.format('%s readies Unfaltering Bravado!', label))

    if #victims > 0 then
        local share = math.floor(10000 / #victims)
        for _, player in ipairs(victims) do
            trueDamage(player, mob, share)
        end
    end

    -- Brief avoidance-down window afterwards (retail behaviour).
    mob:addMod(xi.mod.EVA, -300)
    mob:setLocalVar('OmenBravadoDownUntil', os.time() + 10)
end

local function dancingFullers(mob, instance, label)
    announce(instance, string.format('%s uses Dancing Fullers!', label))
    forEachCharNear(instance, mob, 10, function(player)
        trueDamage(player, mob, 2500)
    end)
end

local function zeroHour(mob, instance, label)
    announce(instance, string.format('%s uses Zero Hour! It slips from everyone\'s attention...', label))
    forEachCharNear(instance, mob, 50, function(player)
        mob:resetEnmity(player)
    end)
    mob:addStatusEffect(xi.effect.PERFECT_DODGE, 1, 0, 15)
end

local function targetMark(mob, instance, label)
    local victim = mob:getTarget()
    if not victim or not victim:isPC() then
        return
    end

    local victimId = victim:getID()
    mob:setLocalVar('OmenMarkedTarget', victimId)
    announce(instance, string.format('%s uses Target -- %s is marked! Break line of sight or perish!', label, victim:getName()))

    mob:timer(8000, function(mobArg)
        if mobArg:getHP() <= 0 then
            return
        end

        local marked = GetPlayerByID(victimId)
        if marked and marked:getHP() > 0 and marked:checkDistance(mobArg) <= 30 then
            announce(instance, string.format('Eleventh Dimension consumes %s!', marked:getName()))
            trueDamage(marked, mobArg, 2000)
            marked:addStatusEffect(xi.effect.TERROR, 1, 0, 45)
        else
            announce(instance, 'Eleventh Dimension finds no purchase.')
        end
    end)
end

-- Restores avoidance after Unfaltering Bravado's window on any boss using it.
local function attachBravadoRecovery(mob)
    mob:addListener('COMBAT_TICK', 'OMEN_BRAVADO_RECOVER', function(mobArg)
        local until_ = mobArg:getLocalVar('OmenBravadoDownUntil')
        if until_ ~= 0 and os.time() >= until_ then
            mobArg:setLocalVar('OmenBravadoDownUntil', 0)
            mobArg:addMod(xi.mod.EVA, 300)
        end
    end)
end

-----------------------------------
-- Glassy mid-bosses
-----------------------------------
local glassy = {}

glassy.craver = function(mob, instance)
    -- View Sync: periodic draw-in on a random distant target.
    onCombatInterval(mob, instance, 'OmenViewSync', 45, function(mobArg)
        local candidates = {}
        forEachCharNear(instance, mobArg, 30, function(player)
            if player:checkDistance(mobArg) > 8 then
                table.insert(candidates, player)
            end
        end)

        if #candidates > 0 then
            local victim = candidates[math.random(#candidates)]
            announce(instance, string.format('Glassy Craver\'s View Sync drags %s in!', victim:getName()))
            victim:setPos(mobArg:getXPos(), mobArg:getYPos(), mobArg:getZPos())
            trueDamage(victim, mobArg, 1000)
        end
    end)

    onThresholds(mob, instance, { 66, 33 }, function(mobArg, threshold)
        announce(instance, 'Glassy Craver uses Material Fend! (Its evasion boost can be dispelled.)')
        mobArg:addStatusEffect(xi.effect.EVASION_BOOST, 100, 0, 30)
    end)

    onThresholds(mob, instance, { 25 }, function(mobArg)
        announce(instance, 'Glassy Craver goes berserk!')
        mobArg:addStatusEffect(xi.effect.MIGHTY_STRIKES, 1, 0, 30)
    end)
end

glassy.gorger = function(mob, instance)
    -- Blessing Sync: copies nearby players' buffs into damage resistance.
    local watched =
    {
        xi.effect.PROTECT, xi.effect.SHELL, xi.effect.HASTE, xi.effect.REFRESH,
        xi.effect.REGEN, xi.effect.STONESKIN, xi.effect.PHALANX, xi.effect.AQUAVEIL,
        xi.effect.BLINK, xi.effect.BARFIRE, xi.effect.STR_BOOST, xi.effect.ATTACK_BOOST,
        xi.effect.FOOD, xi.effect.MULTI_STRIKES, xi.effect.MAGIC_ATK_BOOST,
    }

    onCombatInterval(mob, instance, 'OmenBlessingSync', 30, function(mobArg)
        local copied = 0
        forEachCharNear(instance, mobArg, 10, function(player)
            for _, effect in ipairs(watched) do
                if player:hasStatusEffect(effect) then
                    copied = copied + 1
                end
            end
        end)

        -- Clear the previous stack, then apply the new one.
        local previous = mobArg:getLocalVar('OmenBlessingDT')
        if previous ~= 0 then
            mobArg:addMod(xi.mod.DMG, previous)
        end

        local reduction = -math.min(copied * 200, 5000) -- -2% per buff, cap -50%
        mobArg:setLocalVar('OmenBlessingDT', -reduction)
        mobArg:addMod(xi.mod.DMG, reduction)

        if copied > 0 then
            announce(instance, string.format(
                'Glassy Gorger\'s Blessing Sync mirrors %d effects -- its shell hardens! Spread out or shed buffs.', copied))
        end
    end)

    onThresholds(mob, instance, { 50 }, function(mobArg)
        local victim = mobArg:getTarget()
        if victim and victim:isPC() then
            announce(instance, string.format('Glassy Gorger\'s Spirit Absorption ravages %s!', victim:getName()))
            trueDamage(victim, mobArg, 2000)
            xi.mobskills.mobHealMove(mobArg, 10000)
        end
    end)
end

glassy.thinker = function(mob, instance)
    -- Trinary Tap: steals up to three effects from its target.
    onThresholds(mob, instance, { 75, 50, 25 }, function(mobArg)
        local victim = mobArg:getTarget()
        if victim and victim:isPC() then
            announce(instance, string.format('Glassy Thinker\'s Trinary Tap drinks deep of %s!', victim:getName()))
            for _ = 1, 3 do
                victim:dispelStatusEffect()
            end
            mobArg:addStatusEffect(xi.effect.HASTE, 2000, 0, 60)
        end
    end)

    onThresholds(mob, instance, { 10 }, function(mobArg)
        announce(instance, 'Glassy Thinker\'s thoughts race -- its assaults quicken!')
        mobArg:addStatusEffect(xi.effect.HASTE, 4000, 0, 300)
    end)
end

-----------------------------------
-- The Caturae
-----------------------------------
local caturae = {}

caturae.kin = function(mob, instance)
    onThresholds(mob, instance, { 75, 50, 25, 10 }, function(mobArg)
        targetMark(mobArg, instance, 'Kin')
    end)
end

caturae.gin = function(mob, instance)
    onThresholds(mob, instance, { 75, 50, 25, 10 }, function(mobArg)
        zeroHour(mobArg, instance, 'Gin')
    end)

    -- Suppressive Sphere: after a skillchain, Gin sheds most magic damage
    -- until struck by physical blows (approximation of the retail absorb
    -- shield broken by physical damage).
    mob:addListener('WEAPONSKILL_TAKE', 'OMEN_GIN_SC', function(user, target, skill, tp, action)
        local resonance = target:getStatusEffect(xi.effect.SKILLCHAIN)
        if not resonance then
            target:setLocalVar('GinChainMark', 0)
            return
        end

        local chainCount = resonance:getSubPower()
        if chainCount >= 1 and chainCount ~= target:getLocalVar('GinChainMark') then
            target:setLocalVar('GinChainMark', chainCount)

            if target:getLocalVar('GinSphereHits') == 0 then
                announce(instance, 'Gin erects a Suppressive Sphere! Magic glances off -- strike it down by hand!')
                target:setLocalVar('GinSphereHits', 8)
                target:addMod(xi.mod.UDMGMAGIC, -7500)
            end
        end
    end)

    mob:addListener('TAKE_DAMAGE', 'OMEN_GIN_SPHERE', function(mobArg, amount, attacker, attackType, damageType)
        local hits = mobArg:getLocalVar('GinSphereHits')
        if hits > 0 and attackType == xi.attackType.PHYSICAL and amount and amount > 0 then
            hits = hits - 1
            mobArg:setLocalVar('GinSphereHits', hits)
            if hits == 0 then
                mobArg:addMod(xi.mod.UDMGMAGIC, 7500)
                announce(instance, 'The Suppressive Sphere shatters!')
            end
        end
    end)
end

caturae.fu = function(mob, instance)
    mob:addListener('ENGAGE', 'OMEN_FU_OPEN', function(mobArg, target)
        if mobArg:getLocalVar('FuOpened') == 0 then
            mobArg:setLocalVar('FuOpened', 1)
            ebullientNullification(mobArg, instance, 'Fu')
        end
    end)

    onThresholds(mob, instance, { 75, 50, 25, 10 }, function(mobArg)
        ebullientNullification(mobArg, instance, 'Fu')
    end)
end

caturae.kyou = function(mob, instance)
    -- Extreme natural evasion; Bravado briefly lowers it.
    mob:addMod(xi.mod.EVA, 400)
    attachBravadoRecovery(mob)

    onThresholds(mob, instance, { 75, 50, 25, 10 }, function(mobArg)
        unfalteringBravado(mobArg, instance, 'Kyou')
    end)

    onThresholds(mob, instance, { 20 }, function(mobArg)
        announce(instance, 'Kyou uses Hundred Fists!')
        mobArg:addStatusEffect(xi.effect.HUNDRED_FISTS, 1, 0, 30)
    end)
end

caturae.kei = function(mob, instance)
    -- Permanent magic ward, broken briefly by completing a skillchain.
    mob:addMod(xi.mod.UDMGMAGIC, -10000)
    mob:setLocalVar('KeiShieldUp', 1)

    mob:addListener('WEAPONSKILL_TAKE', 'OMEN_KEI_SC', function(user, target, skill, tp, action)
        local resonance = target:getStatusEffect(xi.effect.SKILLCHAIN)
        if not resonance then
            target:setLocalVar('KeiChainMark', 0)
            return
        end

        local chainCount = resonance:getSubPower()
        if chainCount >= 1 and chainCount ~= target:getLocalVar('KeiChainMark') then
            target:setLocalVar('KeiChainMark', chainCount)

            if target:getLocalVar('KeiShieldUp') == 1 then
                target:setLocalVar('KeiShieldUp', 0)
                target:setLocalVar('KeiShieldDownUntil', os.time() + 6)
                target:addMod(xi.mod.UDMGMAGIC, 10000)
                announce(instance, 'The skillchain rends Kei\'s ward -- magic bites for a few breaths!')
            end
        end
    end)

    mob:addListener('COMBAT_TICK', 'OMEN_KEI_WARD', function(mobArg)
        -- Restore the ward when its window lapses.
        if
            mobArg:getLocalVar('KeiShieldUp') == 0 and
            os.time() >= mobArg:getLocalVar('KeiShieldDownUntil')
        then
            mobArg:setLocalVar('KeiShieldUp', 1)
            mobArg:addMod(xi.mod.UDMGMAGIC, -10000)
        end
    end)

    -- Rotating elemental spikes.
    local spikes = { xi.effect.BLAZE_SPIKES, xi.effect.ICE_SPIKES, xi.effect.SHOCK_SPIKES }
    onCombatInterval(mob, instance, 'OmenKeiSpikes', 30, function(mobArg)
        local index = (mobArg:getLocalVar('KeiSpikeIndex') % #spikes) + 1
        mobArg:setLocalVar('KeiSpikeIndex', index)
        mobArg:delStatusEffect(spikes[((index - 2) % #spikes) + 1])
        mobArg:addStatusEffect(spikes[index], 30, 0, 35)
    end)

    -- One Benediction, early.
    onThresholds(mob, instance, { 80 }, function(mobArg)
        announce(instance, 'Kei uses Benediction!')
        mobArg:eraseAllStatusEffect()
        xi.mobskills.mobHealMove(mobArg, math.floor(mobArg:getMaxHP() * 0.25))
    end)

    onThresholds(mob, instance, { 60, 40, 20 }, function(mobArg)
        dancingFullers(mobArg, instance, 'Kei')
    end)
end

caturae.ou = function(mob, instance)
    attachBravadoRecovery(mob)

    -- The full scripted ladder (bg-wiki: 95/75/65/60/45/30/15/10).
    onThresholds(mob, instance, { 95 }, function(mobArg)
        ebullientNullification(mobArg, instance, 'Ou')
    end)

    onThresholds(mob, instance, { 75 }, function(mobArg)
        unfalteringBravado(mobArg, instance, 'Ou')
    end)

    onThresholds(mob, instance, { 65 }, function(mobArg)
        announce(instance, 'Ou uses Chainspell!')
        mobArg:addStatusEffect(xi.effect.CHAINSPELL, 1, 0, 45)
    end)

    onThresholds(mob, instance, { 60 }, function(mobArg)
        dancingFullers(mobArg, instance, 'Ou')
    end)

    onThresholds(mob, instance, { 45 }, function(mobArg)
        zeroHour(mobArg, instance, 'Ou')
    end)

    onThresholds(mob, instance, { 30 }, function(mobArg)
        targetMark(mobArg, instance, 'Ou')
    end)

    onThresholds(mob, instance, { 15 }, function(mobArg)
        announce(instance, 'Ou assumes Gardez -- its guard is impenetrable!')
        mobArg:addStatusEffect(xi.effect.PHALANX, 250, 0, 30)
    end)

    onThresholds(mob, instance, { 10 }, function(mobArg)
        if mobArg:getLocalVar('OuProphylaxis') ~= 0 then
            return
        end

        mobArg:setLocalVar('OuProphylaxis', 1)
        announce(instance, 'Ou uses Prophylaxis! Its wounds knit at a terrifying pace -- END IT NOW!')

        local maxHp = mobArg:getMaxHP()
        mobArg:setHP(math.floor(maxHp * 0.22))

        -- ~78% of max HP restored over 30 seconds unless slain first.
        local regenPerTick = math.floor((maxHp * 0.78) / 10)
        mobArg:addMod(xi.mod.REGEN, regenPerTick)
        mobArg:setLocalVar('OuRegenUntil', os.time() + 30)
        mobArg:setLocalVar('OuRegenAmount', regenPerTick)
    end)

    mob:addListener('COMBAT_TICK', 'OMEN_OU_REGEN', function(mobArg)
        local until_ = mobArg:getLocalVar('OuRegenUntil')
        if until_ ~= 0 and os.time() >= until_ then
            mobArg:setLocalVar('OuRegenUntil', 0)
            mobArg:addMod(xi.mod.REGEN, -mobArg:getLocalVar('OuRegenAmount'))
            announce(instance, 'Ou\'s regeneration subsides.')
        end
    end)
end

-----------------------------------
-- Entry point
-----------------------------------
mechanics.attach = function(mob, key, instance)
    local kit = caturae[key] or glassy[key]
    if kit then
        kit(mob, instance)
    end
end

return mechanics
