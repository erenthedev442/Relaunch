-----------------------------------
-- SpellSkillMastery.lua
--
-- The "Mastery Sage" NPC in Leafallia. Players spend MASTERY SIGILS (a dedicated
-- currency earned from kills) to permanently empower their weapon skills and
-- magic -- tiered POTENCY plus one-time TRAIT riders.
--
-- All upgrades are additive modifiers stored in charVars, so they are re-applied
-- on every onGameIn (a zone-in wipes in-memory mods). Same proven pattern as the
-- Cross-Job Trait Trainer -- no per-cast hooks, no C++. Needs ONE map restart to
-- activate (addOverride module); the catalog & this file hot-reload after that.
--
-- CharVars:
--   MasterySigils      (int) currency balance
--   Mastery_WSPot      (int) weapon-skill potency tier   (0..MAX_TIER)
--   Mastery_SpellPot   (int) spell potency tier          (0..MAX_TIER)
--   Mastery_T_<id>     (1)   owned trait rider
--
-- Currency faucet: xi.mob.onMobDeathEx (NMs + high normal mobs). See catalog.
-- Command: !empower (view) / !empower give <n> (GM test grant).  commands/empower.lua
-- Grant API for other systems: xi.spellSkillMastery.grant(player, n)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Leafallia/Zone')

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
local function applyAll(p)
    applyPotency(p, C.wsPotency,    tierOf(p, C.wsPotency))
    applyPotency(p, C.spellPotency, tierOf(p, C.spellPotency))
    for _, t in ipairs(C.wsTraits)    do if owns(p, t) then applyTrait(p, t) end end
    for _, t in ipairs(C.spellTraits) do if owns(p, t) then applyTrait(p, t) end end
end

-----------------------------------
-- Menus
-----------------------------------
local openMain, openTrack, openPotency, openTraits, confirmPotency, confirmTrait

-- Defer + snapshot, matching the other Leafallia NPCs.
local function show(p, title, options)
    local snapshot = { title = title, options = options }
    p:timer(30, function(pp) pp:customMenu(snapshot) end)
end

openMain = function(p)
    p:printToPlayer(string.format('[Mastery Sage] You hold %d %s.', getSigils(p), C.CURRENCY_NAME), SYS)
    show(p, 'Mastery Sage', {
        { 'Weapon Skills', function(pp) openTrack(pp, 'ws') end },
        { 'Spells',        function(pp) openTrack(pp, 'sp') end },
        { 'My Mastery',    function(pp) xi.spellSkillMastery.report(pp); openMain(pp) end },
        { 'Close',         function(pp) end },
    })
end

-- track = 'ws' | 'sp'
openTrack = function(p, track)
    local label = (track == 'ws') and 'Weapon Skills' or 'Spells'
    show(p, label, {
        { 'Potency', function(pp) openPotency(pp, track) end },
        { 'Traits',  function(pp) openTraits(pp, track) end },
        { 'Back',    function(pp) openMain(pp) end },
    })
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

-- Chat report of everything owned (also used by !empower).
xi.spellSkillMastery.report = function(p)
    p:printToPlayer(string.format('=== Mastery === %d %s', getSigils(p), C.CURRENCY_NAME), SYS)
    p:printToPlayer(string.format('  WS Potency: tier %d/%d   |   Spell Potency: tier %d/%d',
        tierOf(p, C.wsPotency), C.MAX_TIER, tierOf(p, C.spellPotency), C.MAX_TIER), SYS)
    local owned = {}
    for _, t in ipairs(C.wsTraits)    do if owns(p, t) then owned[#owned + 1] = t.name end end
    for _, t in ipairs(C.spellTraits) do if owns(p, t) then owned[#owned + 1] = t.name end end
    if #owned > 0 then
        p:printToPlayer('  Traits: ' .. table.concat(owned, ', '), SYS)
    else
        p:printToPlayer('  Traits: none yet.', SYS)
    end
end

-----------------------------------
-- Sigil faucet: NMs (and high normal mobs) drop Mastery Sigils.
-----------------------------------
m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)
    pcall(function()
        if not isKiller or player == nil then return end
        if player:getObjType() ~= xi.objType.PC then return end

        local s   = C.sigils
        local lvl = mob:getMainLvl() or 0
        if mob:isNM() then
            local amt = math.min(s.nmMax, math.floor(s.nmBase + lvl * s.nmPerLevel))
            if amt > 0 then grantSigils(player, amt, s.announceNM) end
        elseif lvl >= s.mobMinLevel and math.random(100) <= s.mobChance then
            grantSigils(player, s.mobAmount, false)
        end
    end)
end)

-----------------------------------
-- Re-apply on login (a zone-in wipes in-memory mods). Defer 3s so post-login
-- stat finalization does not clobber the addMods (Prestige/CrossJob pattern).
-----------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)
    player:timer(3000, function(p) pcall(function() applyAll(p) end) end)
end)

-----------------------------------
-- NPC placement (Leafallia).
-----------------------------------
m:addOverride('xi.zones.Leafallia.Zone.onInitialize', function(zone)
    super(zone)
    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Mastery_Sage',
        packetName = string.format('%sMastery Sage', xi.icon.STAR_LARGE),
        look       = 2419,
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
