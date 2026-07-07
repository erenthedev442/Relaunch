-----------------------------------
-- SpellSkillMastery.lua
--
-- The "Mastery Sage" NPC in Leafallia. Players spend MASTERY SIGILS (a dedicated
-- currency) to permanently empower their weapon skills and magic:
--   * POTENCY  -- tiered % power-ups (additive mods, re-applied on login).
--   * TRAITS   -- one-time passive riders (additive mods, re-applied on login).
--   * WS EFFECTS -- per-player weapon-skill procs (crit burst / AoE splash /
--                 lifesteal) run from a WEAPONSKILL_USE listener; read live from
--                 charVars each WS, so they need NO login re-apply.
--
-- Sigils come from an NM ROTATION (kill the active target NMs each period for a
-- big chunk) plus an optional small trickle from any NM. The mod-based pattern
-- mirrors the Cross-Job Trait Trainer -- no C++. Needs ONE map restart to
-- activate (addOverride module); the catalog & this file hot-reload after that.
--
-- CharVars:
--   MasterySigils      (int) currency balance
--   Mastery_WSPot      (int) weapon-skill potency tier   (0..MAX_TIER)
--   Mastery_SpellPot   (int) spell potency tier          (0..MAX_TIER)
--   Mastery_T_<id>     (1)   owned trait rider
--   Mastery_WSFx_<x>   (int) WS effect tier (crit/splash/drain)
--   Mastery_RotPeriod  (int) last rotation period the player's mask is valid for
--   Mastery_RotMask    (int) bitmask of rotation targets claimed this period
--
-- Currency faucet: xi.mob.onMobDeathEx (rotation + optional NM trickle).
-- Command: !empower (view) / !empower give <n> (GM test grant).  commands/empower.lua
-- Grant API for other systems: xi.spellSkillMastery.grant(player, n)
-- Rotation credit is PARTY-WIDE (every same-zone party member claims once per
-- period; catalog.rotation.partyWide). The small NM trickle stays killer-only.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')

local C   = require('modules/custom/lua/spell_skill_mastery_catalog')
local m   = Module:new('spell_skill_mastery')
local SYS = xi.msg.channel.SYSTEM_3

-----------------------------------
-- Currency helpers
-----------------------------------
local function getSigils(p)    return p:getCharVar(C.CURRENCY_VAR) or 0 end
local function setSigils(p, n) p:setCharVar(C.CURRENCY_VAR, math.max(0, math.floor(n))) end

local function grantSigils(p, n, announce)
    if n <= 0 then return end
    setSigils(p, getSigils(p) + n)
    if announce then
        p:printToPlayer(string.format('You obtained %d %s! (total: %d)',
            n, C.CURRENCY_NAME, getSigils(p)), SYS)
    end
end

-- Public grant API so other systems (or the !empower command) can award sigils.
xi.spellSkillMastery = xi.spellSkillMastery or {}
xi.spellSkillMastery.grant   = function(p, n) grantSigils(p, n, true) end
xi.spellSkillMastery.balance = function(p) return getSigils(p) end

-----------------------------------
-- Ownership / apply helpers
-----------------------------------
local function traitVar(t)  return C.traitVarPrefix .. t.id end
local function owns(p, t)   return (p:getCharVar(traitVar(t)) or 0) == 1 end
local function tierOf(p, tr) return p:getCharVar(tr.var) or 0 end
local function traitCost(t) return t.cost or C.TRAIT_COST_DEFAULT end

-- Apply a potency track's mods at the given tier (value = per * tier).
local function applyPotency(p, track, tier)
    if tier <= 0 then return end
    for _, mv in ipairs(track.mods) do
        p:addMod(mv[1], mv[2] * tier)
    end
end

-- Apply one trait's flat mods.
local function applyTrait(p, t)
    for _, mv in ipairs(t.mods) do
        p:addMod(mv[1], mv[2])
    end
end

-- Re-apply EVERYTHING the player owns (called on login after the mod wipe).
-- NOTE: WS Effects are NOT re-applied here -- the WEAPONSKILL_USE listener reads
-- their charVars live each weapon skill, so they need no login re-apply.
local function applyAll(p)
    applyPotency(p, C.wsPotency,    tierOf(p, C.wsPotency))
    applyPotency(p, C.spellPotency, tierOf(p, C.spellPotency))
    for _, t in ipairs(C.wsTraits)    do if owns(p, t) then applyTrait(p, t) end end
    for _, t in ipairs(C.spellTraits) do if owns(p, t) then applyTrait(p, t) end end
end

-----------------------------------
-- WS Effects: applied from a WEAPONSKILL_USE listener (registered on login).
-- Reads each effect's tier charVar live and runs its `kind` handler off the
-- weapon skill's own `damage`. All numeric values come from the catalog.
-----------------------------------
local function applyWSEffects(attacker, target, damage)
    if not damage or damage <= 0 then return end
    if target == nil or target:isDead() then return end
    local damType = attacker:getWeaponDamageType(xi.slot.MAIN)
    for _, fx in ipairs(C.wsEffects) do
        local tier = attacker:getCharVar(fx.var) or 0
        if tier > 0 then
            if fx.kind == 'crit' then
                if math.random(100) <= tier * fx.chancePerTier then
                    local bonus = math.floor(damage * fx.bonusPct / 100)
                    if bonus > 0 then
                        target:takeDamage(bonus, attacker, xi.attackType.PHYSICAL, damType)
                    end
                end
            elseif fx.kind == 'splash' then
                local splash = math.floor(damage * (tier * fx.pctPerTier) / 100)
                if splash > 0 then
                    local enemies = attacker:getEntitiesInRange(
                        target, xi.aoeType.ROUND, xi.aoeRadius.TARGET, fx.radius or 10, 0, xi.targetType.ENEMY)
                    for _, e in ipairs(enemies) do
                        if not e:isDead() and e:getID() ~= target:getID() then
                            e:takeDamage(splash, attacker, xi.attackType.PHYSICAL, damType)
                        end
                    end
                end
            elseif fx.kind == 'lifesteal' then
                local heal = math.floor(damage * (tier * fx.pctPerTier) / 100)
                if heal > 0 then attacker:addHP(heal) end
            end
        end
    end
end

-----------------------------------
-- NM rotation: a clock-derived set of `activeCount` target NMs from the pool.
-- Killing a live target grants sigils once per period (tracked per player).
-----------------------------------
-- Current period index (real-world clock). pcall-guarded so a sandboxed os.time
-- degrades to a single static rotation rather than erroring.
local function currentPeriod()
    local ok, t = pcall(os.time)
    if not ok or not t then return 0 end
    return math.floor(t / (C.rotation.periodHours * 3600))
end

-- Normalize a mob/pool name for matching: lower-case + underscores -> spaces, so
-- 'Lord_of_Onzozo' and 'Lord of Onzozo' both resolve regardless of which form
-- mob:getName() returns.
local function normalizeName(s) return (s or ''):lower():gsub('_', ' ') end

-- The active target set this period: the ordered list of pool ENTRIES plus a
-- normalized name/label -> active-index (1..K) map for fast kill matching.
local function currentActive()
    local pool = C.rotation.pool
    local n    = #pool
    local K    = math.min(C.rotation.activeCount, n)
    local start = (currentPeriod() * K) % n
    local list, byName = {}, {}
    for k = 0, K - 1 do
        local entry = pool[((start + k) % n) + 1]
        list[#list + 1] = entry
        byName[normalizeName(entry.name)]  = k + 1
        byName[normalizeName(entry.label)] = k + 1
    end
    return list, byName
end

-- Reset a player's claim mask if the rotation has rolled over; returns the mask.
local function rotationMask(p)
    local period = currentPeriod()
    if (p:getCharVar('Mastery_RotPeriod') or -1) ~= period then
        p:setCharVar('Mastery_RotPeriod', period)
        p:setCharVar('Mastery_RotMask', 0)
        return 0
    end
    return p:getCharVar('Mastery_RotMask') or 0
end

-- Grant one player the reward for active-index `idx`, once per period.
local function claimRotation(p, idx, label)
    local mask = rotationMask(p)
    local bit  = 2 ^ (idx - 1)
    if (math.floor(mask / bit) % 2) == 1 then return end  -- already claimed
    p:setCharVar('Mastery_RotMask', mask + bit)
    grantSigils(p, C.rotation.reward, false)
    if C.rotation.announce then
        p:printToPlayer(string.format('[Mastery] Rotation target %s defeated! +%d %s.',
            label, C.rotation.reward, C.CURRENCY_NAME), SYS)
    end
end

-----------------------------------
-- Menus
-----------------------------------
local openMain, openTrack, openPotency, openTraits, confirmPotency, confirmTrait
local openEffects, confirmEffect, openRotation

-- Defer + snapshot, matching the other Leafallia NPCs.
local function show(p, title, options)
    local snapshot = { title = title, options = options }
    p:timer(30, function(pp) pp:customMenu(snapshot) end)
end

openMain = function(p)
    p:printToPlayer(string.format('[Mastery Sage] You hold %d %s.', getSigils(p), C.CURRENCY_NAME), SYS)
    local options = {
        { 'Weapon Skills', function(pp) openTrack(pp, 'ws') end },
        { 'Spells',        function(pp) openTrack(pp, 'sp') end },
    }
    if C.rotation.enabled then
        options[#options + 1] = { 'NM Rotation', function(pp) openRotation(pp) end }
    end
    options[#options + 1] = { 'My Mastery', function(pp) xi.spellSkillMastery.report(pp); openMain(pp) end }
    options[#options + 1] = { 'Close',      function(pp) end }
    show(p, 'Mastery Sage', options)
end

-- Show the current rotation targets + claim status; killing them grants sigils.
openRotation = function(p)
    local list = currentActive()
    local mask = rotationMask(p)
    p:printToPlayer(string.format('[Mastery Sage] Rotation targets (reset every %dh) — %d %s each:',
        C.rotation.periodHours, C.rotation.reward, C.CURRENCY_NAME), SYS)
    for i, entry in ipairs(list) do
        local claimed = (math.floor(mask / (2 ^ (i - 1))) % 2) == 1
        p:printToPlayer(string.format('   %s — %s  [%s]',
            entry.label, (entry.zone:gsub('_', ' ')), claimed and 'claimed' or 'available'), SYS)
    end
    show(p, 'NM Rotation', { { 'Back', function(pp) openMain(pp) end } })
end

-- track = 'ws' | 'sp'
openTrack = function(p, track)
    local label = (track == 'ws') and 'Weapon Skills' or 'Spells'
    local options = {
        { 'Potency', function(pp) openPotency(pp, track) end },
        { 'Traits',  function(pp) openTraits(pp, track) end },
    }
    if track == 'ws' then
        options[#options + 1] = { 'Effects', function(pp) openEffects(pp) end }
    end
    options[#options + 1] = { 'Back', function(pp) openMain(pp) end }
    show(p, label, options)
end

openPotency = function(p, track)
    local potency = (track == 'ws') and C.wsPotency or C.spellPotency
    local tier    = tierOf(p, potency)
    p:printToPlayer(string.format('[Mastery Sage] %s: tier %d/%d (%s).',
        potency.name, tier, C.MAX_TIER, potency.blurb), SYS)

    local options = {}
    if tier >= C.MAX_TIER then
        options[#options + 1] = { 'Fully mastered', function(pp)
            pp:printToPlayer(string.format('[Mastery Sage] %s is at maximum.', potency.name), SYS)
            openPotency(pp, track)
        end }
    else
        local cost = C.POTENCY_COST[tier + 1]
        options[#options + 1] = {
            string.format('Upgrade to T%d (%d)', tier + 1, cost),
            function(pp) confirmPotency(pp, track) end,
        }
    end
    options[#options + 1] = { 'Back', function(pp) openTrack(pp, track) end }
    show(p, 'Potency', options)
end

confirmPotency = function(p, track)
    local potency = (track == 'ws') and C.wsPotency or C.spellPotency
    local tier    = tierOf(p, potency)
    if tier >= C.MAX_TIER then openPotency(p, track); return end

    local cost = C.POTENCY_COST[tier + 1]
    show(p, string.format('Buy T%d for %d?', tier + 1, cost), {
        {
            string.format('Yes (%d sigils)', cost),
            function(pp)
                local curTier = tierOf(pp, potency)
                if curTier >= C.MAX_TIER then openPotency(pp, track); return end
                local c = C.POTENCY_COST[curTier + 1]
                if getSigils(pp) < c then
                    pp:printToPlayer(string.format('[Mastery Sage] You need %d %s (you have %d).',
                        c, C.CURRENCY_NAME, getSigils(pp)), SYS)
                    openPotency(pp, track)
                    return
                end
                setSigils(pp, getSigils(pp) - c)
                pp:setCharVar(potency.var, curTier + 1)
                -- apply only the new tier's DELTA (in-memory already holds curTier)
                applyPotency(pp, potency, 1)
                pp:printToPlayer(string.format('[Mastery Sage] %s raised to tier %d!',
                    potency.name, curTier + 1), SYS)
                openPotency(pp, track)
            end,
        },
        { 'No', function(pp) openPotency(pp, track) end },
    })
end

openTraits = function(p, track)
    local list  = (track == 'ws') and C.wsTraits or C.spellTraits
    local title = (track == 'ws') and 'WS Traits' or 'Spell Traits'
    local options = {}
    for _, t in ipairs(list) do
        local tt    = t
        local label = owns(p, tt) and (tt.name .. ' *') or tt.name
        options[#options + 1] = { label, function(pp) confirmTrait(pp, track, tt) end }
    end
    options[#options + 1] = { 'Back', function(pp) openTrack(pp, track) end }
    show(p, title, options)
end

confirmTrait = function(p, track, t)
    p:printToPlayer(string.format('%s: %s', t.name, t.desc), SYS)
    if owns(p, t) then
        p:printToPlayer(string.format('[Mastery Sage] You already own %s.', t.name), SYS)
        openTraits(p, track)
        return
    end
    local cost = traitCost(t)
    show(p, string.format('Buy %s for %d?', t.name, cost), {
        {
            string.format('Yes (%d sigils)', cost),
            function(pp)
                if owns(pp, t) then openTraits(pp, track); return end
                if getSigils(pp) < cost then
                    pp:printToPlayer(string.format('[Mastery Sage] You need %d %s (you have %d).',
                        cost, C.CURRENCY_NAME, getSigils(pp)), SYS)
                    openTraits(pp, track)
                    return
                end
                setSigils(pp, getSigils(pp) - cost)
                pp:setCharVar(traitVar(t), 1)
                applyTrait(pp, t)
                pp:printToPlayer(string.format('[Mastery Sage] Learned %s! It applies on every job.', t.name), SYS)
                openTraits(pp, track)
            end,
        },
        { 'No', function(pp) openTraits(pp, track) end },
    })
end

-- WS Effects menu (tiered procs: Empowered Strike / Splash / Lifesteal).
openEffects = function(p)
    local options = {}
    for _, fx in ipairs(C.wsEffects) do
        local ff   = fx
        local tier = p:getCharVar(ff.var) or 0
        local label = (tier >= ff.max) and (ff.name .. ' MAX')
            or string.format('%s T%d', ff.name, tier)
        options[#options + 1] = { label, function(pp) confirmEffect(pp, ff) end }
    end
    options[#options + 1] = { 'Back', function(pp) openTrack(pp, 'ws') end }
    show(p, 'WS Effects', options)
end

confirmEffect = function(p, fx)
    local tier = p:getCharVar(fx.var) or 0
    p:printToPlayer(string.format('%s: %s', fx.name, fx.desc), SYS)
    if tier >= fx.max then
        p:printToPlayer(string.format('[Mastery Sage] %s is maxed.', fx.name), SYS)
        openEffects(p)
        return
    end
    local cost = C.EFFECT_COST[tier + 1]
    show(p, string.format('Buy %s T%d for %d?', fx.name, tier + 1, cost), {
        {
            string.format('Yes (%d sigils)', cost),
            function(pp)
                local cur = pp:getCharVar(fx.var) or 0
                if cur >= fx.max then openEffects(pp); return end
                local c = C.EFFECT_COST[cur + 1]
                if getSigils(pp) < c then
                    pp:printToPlayer(string.format('[Mastery Sage] You need %d %s (you have %d).',
                        c, C.CURRENCY_NAME, getSigils(pp)), SYS)
                    openEffects(pp)
                    return
                end
                setSigils(pp, getSigils(pp) - c)
                pp:setCharVar(fx.var, cur + 1)
                pp:printToPlayer(string.format('[Mastery Sage] %s raised to tier %d!', fx.name, cur + 1), SYS)
                openEffects(pp)
            end,
        },
        { 'No', function(pp) openEffects(pp) end },
    })
end

-- Chat report of everything owned (also used by !empower).
xi.spellSkillMastery.report = function(p)
    p:printToPlayer(string.format('=== Mastery === %d %s', getSigils(p), C.CURRENCY_NAME), SYS)
    p:printToPlayer(string.format('  WS Potency: tier %d/%d   |   Spell Potency: tier %d/%d',
        tierOf(p, C.wsPotency), C.MAX_TIER, tierOf(p, C.spellPotency), C.MAX_TIER), SYS)
    local fx = {}
    for _, e in ipairs(C.wsEffects) do
        local tier = p:getCharVar(e.var) or 0
        if tier > 0 then fx[#fx + 1] = string.format('%s T%d', e.name, tier) end
    end
    p:printToPlayer('  WS Effects: ' .. (#fx > 0 and table.concat(fx, ', ') or 'none yet.'), SYS)
    local owned = {}
    for _, t in ipairs(C.wsTraits)    do if owns(p, t) then owned[#owned + 1] = t.name end end
    for _, t in ipairs(C.spellTraits) do if owns(p, t) then owned[#owned + 1] = t.name end end
    p:printToPlayer('  Traits: ' .. (#owned > 0 and table.concat(owned, ', ') or 'none yet.'), SYS)
    if C.rotation.enabled then
        local list = currentActive()
        local mask = rotationMask(p)
        local parts = {}
        for i, entry in ipairs(list) do
            local claimed = (math.floor(mask / (2 ^ (i - 1))) % 2) == 1
            parts[#parts + 1] = entry.label .. (claimed and ' (done)' or '')
        end
        p:printToPlayer('  Rotation: ' .. table.concat(parts, ', '), SYS)
    end
end

-----------------------------------
-- Sigil faucet: the NM ROTATION is the primary source; an optional small
-- trickle on any NM keeps players from going fully dry between targets.
-----------------------------------
m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)
    pcall(function()
        if not isKiller or player == nil then return end
        if player:getObjType() ~= xi.objType.PC then return end

        -- Rotation target? (matched by name, independent of the isNM flag.)
        local idx, label
        if C.rotation.enabled then
            local list, byName = currentActive()
            idx = byName[normalizeName(mob:getName())]
            if idx then label = list[idx].label end
        end

        if idx then
            -- Credit every same-zone PC party member (or just the killer if
            -- partyWide is off). Each member claims independently, once/period.
            local zoneId  = mob:getZoneID()
            local members = { player }
            if C.rotation.partyWide then
                local ok, party = pcall(function() return player:getParty() end)
                if ok and party and #party > 0 then members = party end
            end
            for _, mem in ipairs(members) do
                if mem and mem:getObjType() == xi.objType.PC and mem:getZoneID() == zoneId then
                    claimRotation(mem, idx, label)
                end
            end
            return  -- rotation NM handled; skip the trickle
        end

        -- Secondary trickle (killer only).
        local s = C.sigils
        if mob:isNM() and s.nmTrickle then
            local amt = math.min(s.nmMax, math.floor(s.nmBase + (mob:getMainLvl() or 0) * s.nmPerLevel))
            if amt > 0 then grantSigils(player, amt, s.announceNM) end
        elseif s.mobChance > 0 and (mob:getMainLvl() or 0) >= s.mobMinLevel
               and math.random(100) <= s.mobChance then
            grantSigils(player, s.mobAmount, false)
        end
    end)
end)

-----------------------------------
-- On login: (1) re-apply potency/trait mods (deferred 3s so post-login stat
-- finalization does not clobber the addMods -- Prestige/CrossJob pattern), and
-- (2) register the WS Effects listener (reads charVars live; the named listener
-- is idempotent across zone-ins, so re-adding each login is safe).
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    player:timer(3000, function(p) pcall(function() applyAll(p) end) end)
    player:addListener('WEAPONSKILL_USE', 'MASTERY_WS_FX',
        function(attacker, target, skill, tp, action, damage)
            pcall(function() applyWSEffects(attacker, target, damage) end)
        end)
end)

-----------------------------------
-- NPC placement (Leafallia).
-----------------------------------
m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)
    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Spell_Mastery_Sage',
        packetName = string.format('%sMastery Sage', xi.icon.STAR_LARGE),
        look       = 225,
        x          = C.npcPos.x,
        y          = C.npcPos.y,
        z          = C.npcPos.z,
        rotation   = C.npcPos.rot,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:printToPlayer('[Mastery Sage] Empower your weapon skills and magic with Mastery Sigils, earned in battle.', SYS)
            openMain(player)
        end,
    })
end)

return m
