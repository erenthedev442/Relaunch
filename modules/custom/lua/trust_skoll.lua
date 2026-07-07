-----------------------------------
-- trust_skoll.lua
-- Void Keeper NPC in GM Home: the SINGLE source for all custom trusts.
-- The 3 custom trusts are EARNED through Hunting League progression -- NOT
-- bought with gil. Each is gated on a Hunting League RANK (charvar HL_Tier,
-- 1-5) and costs accumulated HUNT MARKS (charvar HL_Points). One unlock per
-- character -- the spell is permanently added to the spell book on payment.
--
--   Meat   -> spell 899 : HL Rank 2, 2000 Hunt Marks
--   Gemma  -> spell 901 : HL Rank 3, 3000 Hunt Marks
--   Corvus -> spell 902 : HL Rank 4, 5000 Hunt Marks
--
-- (The standalone "Bulwark Keeper" Meat vendor was folded into this NPC on
--  2026-06-06 so champions earn every custom trust from one prominent place --
--  see trust_meat_vendor.lua, now a retired no-op.)
--
-- Custom trusts here (clientName = what the in-game Trust menu shows):
--   Gemma -> spell 901 (repurposed "Nanaa Mihgo"); pool 5901, Hume Female look
--   Meat  -> spell 899 (repurposed "Excenmille");  pool 5899, tiny Tarutaru model
-- SQL: modules/custom/sql/trust_skoll.sql, modules/custom/sql/trust_meat.sql
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')
require('scripts/globals/combat/magic_aoe')   -- defines xi.combat.magicAoE.* (overridden below)

local m = Module:new('trust_skoll')

-- Every custom trust the Void Keeper grants. Add a row to offer another one.
--   spellId    : the (repurposed) spell slot; also registered in custom_spell_ids.lua
--   name       : display name used in menu labels / messages
--   clientName : what the client's Trust menu shows (the repurposed slot's name)
--   rankReq    : minimum Hunting League rank (charvar HL_Tier) required to unlock
--   markCost   : Hunt Marks (charvar HL_Points) spent to unlock
--   bindLabel  : purchase menu label (legacy; the rank/marks suffix is built below)
--   boundMsg   : shown when the player already owns it
--   sealMsgs   : shown line-by-line on a successful unlock
local TRUSTS = {
    {
        spellId    = 901,
        name       = 'Gemma',
        clientName = 'Nanaa Mihgo',
        rankReq    = 3,
        markCost   = 3000,
        bindLabel  = 'Bind Gemma to your service',
        boundMsg   = 'Gemma already stands with you. Cast "Nanaa Mihgo" from your Trust menu -- that is her.',
        sealMsgs   = {
            'The covenant is sealed.',
            'Look for "Nanaa Mihgo" in your Trust menu -- casting it calls Gemma.',
            'She is small. She is quiet. She will keep you standing when nothing else can.',
        },
    },
    {
        spellId    = 899,
        name       = 'Meat',
        clientName = 'Excenmille',
        rankReq    = 2,
        markCost   = 2000,
        bindLabel  = 'Bind Meat to your service',
        boundMsg   = 'Meat already answers to you. Cast "Excenmille" from your Trust menu -- that is the little wall.',
        sealMsgs   = {
            'It is bound. The little wall is yours.',
            'Look for "Excenmille" in your Trust menu -- casting it raises Meat.',
            'Stand behind it. That is all you need do.',
        },
    },
    {
        spellId    = 902,
        name       = 'Corvus',
        clientName = 'Curilla',
        rankReq    = 4,
        markCost   = 5000,
        bindLabel  = 'Bind Corvus to your service',
        boundMsg   = 'Corvus already shadows you. Cast "Curilla" from your Trust menu -- the back line is his.',
        sealMsgs   = {
            'The covenant is sealed. The Black Arrow is yours.',
            'Look for "Curilla" in your Trust menu -- casting it calls Corvus.',
            'Point him at what you want dead. He does the rest, and says nothing.',
        },
    },
}

local NPC_NAME  = 'Void_Keeper'
local NPC_LOOK  = 3017          -- 3017 = Trust: Prishe - a silver-haired divine warrior model; far more fitting
                                -- for a 50M-gil vendor of legendary Trusts than a generic Moogle.
                                -- Change this value if you have a preferred divine/godlike NPC look ID.
local NPC_POS   = { x = 578.971, y = -3.360, z = 532.586, rot = 192 }

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = '', options = {} }

    -- One bind/summon menu option for a single custom trust.
    -- LABEL BUDGET: SetCustomMenuContext concatenates title + every label (all
    -- quoted) into one string. The client echoes this back in a GMTELL packet
    -- capped at 128 bytes -- overflow = silent no-op on every option. With 3
    -- trusts + 2 lore + Leave, the title + labels must total <= 128 bytes.
    -- Keep each label short; the current 7-option menu fits in ~103 bytes.
    local function trustOption(player, t)
        if player:hasSpell(t.spellId) then
            return {
                string.format('%s: owned', t.name),
                function(p)
                    p:printToPlayer(t.boundMsg, xi.msg.channel.SYSTEM_3)
                end,
            }
        end

        -- Earned, not bought: gated on Hunting League rank + Hunt Marks.
        local label = string.format('Bind %s  R%d / %dmk', t.name, t.rankReq, t.markCost)

        return {
            label,
            function(p)
                if p:hasSpell(t.spellId) then
                    p:printToPlayer(string.format('%s is already bound to you.', t.name),
                        xi.msg.channel.SYSTEM_3)
                    return
                end
                if (p:getCharVar('HL_Tier') or 1) < t.rankReq then
                    p:printToPlayer(
                        string.format('%s requires Hunting League Rank %d.', t.name, t.rankReq),
                        xi.msg.channel.SYSTEM_3)
                    return
                end
                local marks = p:getCharVar('HL_Points') or 0
                if marks < t.markCost then
                    p:printToPlayer(
                        string.format('%s costs %d Hunt Marks (you have %d).', t.name, t.markCost, marks),
                        xi.msg.channel.SYSTEM_3)
                    return
                end

                p:setCharVar('HL_Points', marks - t.markCost)
                p:addSpell(t.spellId)

                local S = xi.msg.channel.SYSTEM_3
                for _, line in ipairs(t.sealMsgs) do
                    p:printToPlayer(line, S)
                end
            end,
        }
    end

    local function buildMenu(player)
        local options = {}

        -- ---- Lore -----------------------------------------------------
        table.insert(options, {
            'Who are you?',
            function(p)
                local S = xi.msg.channel.SYSTEM_3
                p:printToPlayer('I am what remains of an old covenant.', S)
                p:printToPlayer('You are expecting someone tall. Everyone does. That is their first mistake.', S)
                p:printToPlayer('Gemma barely reaches your shoulder. Do not let that fool you, as so many have.', S)
                p:printToPlayer('She has dragged more champions back from death than I can count.', S)
                p:printToPlayer('She will not strike the killing blow. She will make certain you live to.', S)
                p:printToPlayer('Bind her to your service, and she will carry you when your legs give out.', S)
                p:printToPlayer('Small hands. Enormous reach. Never mistake the one for the other.', S)
            end,
        })
        table.insert(options, {
            'What is Meat?',
            function(p)
                local S = xi.msg.channel.SYSTEM_3
                p:printToPlayer('A wall does not fear the blade. A wall does not tire.', S)
                p:printToPlayer('I bound a tiny Tarutaru to that single purpose -- to stand, and to be struck.', S)
                p:printToPlayer('The soldiers called it "Meat." A grim joke. The name stuck.', S)
                p:printToPlayer('It cannot fall. It draws every blow to itself and shrugs them off.', S)
                p:printToPlayer('It will not win your battles. It will make sure you live to fight them.', S)
                p:printToPlayer('Bind it to your service, and let the enemy break upon it.', S)
            end,
        })

        -- ---- One bind/summon option per custom trust ------------------
        for _, t in ipairs(TRUSTS) do
            table.insert(options, trustOption(player, t))
        end

        -- ---- Dismiss --------------------------------------------------
        table.insert(options, {
            'Leave',
            function(p)
                p:printToPlayer('...', xi.msg.channel.SYSTEM_3)
            end,
        })

        menu.title   = 'Void Keeper'
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    -- NPC model 3017 (Prishe Trust): a divine warrior aesthetic, chosen so the
    -- vendor for legendary Trusts feels the part rather than like a lost Moogle.
    local VoidKeeper = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = NPC_NAME,
        packetName = string.format('%sVoid Keeper', xi.icon.STAR_LARGE),
        look       = 232,
        x          = NPC_POS.x,
        y          = NPC_POS.y,
        z          = NPC_POS.z,
        rotation   = NPC_POS.rot,
        widescan   = 1,

        onTrade = function(player, npc, trade)
            player:printToPlayer(
                'The covenant cannot be bought with trinkets. Speak to me.',
                xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            player:printToPlayer(string.format('[ Void Keeper ]  Hunting League Rank %d  -  %d Hunt Marks', player:getCharVar('HL_Tier') or 1, player:getCharVar('HL_Points') or 0), xi.msg.channel.SYSTEM_3)
            buildMenu(player)
        end,
    })
    utils.unused(VoidKeeper)
end)

-----------------------------------
-- Wide-AoE songs for Gemma. She sings on herself (party AoE), but the stock song
-- radius is only 10y (spell_list.radius / 10) and she never moves (NO_MOVE), so a
-- spread-out party can fall outside it. There is no per-entity song-range mod the
-- way rolls have Mod::ROLL_RANGE, so we override the song-radius global and widen
-- it ONLY for Gemma -- flagged by the SKOLL_WIDE_AOE localvar set in her
-- onMobSpawn (scripts/actions/spells/trust/skoll.lua). (The localvar key + the
-- script keep the legacy internal name "skoll"; only the player-facing name is
-- Gemma.) Songs are party-only (validTargets), so the larger radius never reaches
-- anyone outside the party; every other trust / player falls through to super().
--
-- calculateSongRadius works in EFFECTIVE yalms (it returns spell:getRadius(),
-- which is already the /10 value), so 50 here means a 50-yalm song radius -- a
-- match for the ~50y the ROLL_RANGE mod gives her Corsair rolls.
-----------------------------------
local GEMMA_SONG_RADIUS = 50

m:addOverride('xi.combat.magicAoE.calculateSongRadius', function(caster, spell)
    local base = super(caster, spell)
    -- base == 0 => single-target (Pianissimo / non-AoE song): leave it alone.
    if base > 0 and caster:getLocalVar('SKOLL_WIDE_AOE') > 0 then
        return math.max(base, GEMMA_SONG_RADIUS)
    end
    return base
end)

-----------------------------------
-- GEMMA SERVER ANNOUNCEMENTS
-- Broadcasts a random quip about Gemma to the whole server every
-- QUIP_INTERVAL_SEC of active uptime. "Active" means it only ticks when
-- a player zones -- so a dead server doesn't count down -- but on a live
-- server expect roughly one broadcast per QUIP_INTERVAL_SEC. Resets on
-- server restart (intended; the module reloads fresh each boot).
-----------------------------------
local QUIP_INTERVAL_SEC = 900   -- 15 minutes between broadcasts

-- Module-local: persists across zones for the life of xi_map.
local lastQuipTime = 0

local GEMMA_QUIPS =
{
    -- ---- Small, and the only reason you are alive -------------------------
    '[Gemma] She is five feet of nothing and the only reason your party is still breathing.',
    '[Gemma] You will not notice her -- right up until the moment you would have died. Then you notice her a great deal.',
    '[Legendary] Gemma is the smallest thing on the field and the last thing standing between you and the wipe.',
    '[Gemma] People keep trying to protect her. She finds it sweet. She has never once needed it.',
    '[Gemma] Small hands. Protectra V, Shellra V, Haste II, and a raise queued before you finish hitting the floor.',
    '[Gemma] The enemy went for the small one in the back. The enemy did not survive the decision.',

    -- ---- The indignity of the spell name ----------------------------------
    '[Gemma] A support goddess of overwhelming power, summoned by casting "Nanaa Mihgo." She has chosen, graciously, not to comment.',
    '[Legendary] Calling a 50-million-gil clutch healer requires typing the name of a Mithra thief. The healer is aware. The healer is very tired.',
    '[Gemma] Fifty million gil. Full support suite. Summoned with the spell "Nanaa Mihgo." Every single day is like this.',

    -- ---- She is very small -----------------------------------------------
    '[Gemma] She comes up to your belt and out-heals, out-buffs, and out-lasts everything taller than her -- which is everything.',
    '[Legendary] A woman that small should not be able to carry an entire party. She does it anyway, and she makes it look easy.',
    '[Gemma] The engine lists her as a Hume Female. The lore lists her as "the reason you are reading this instead of staring at a homepoint."',

    -- ---- Buff economics --------------------------------------------------
    '[Legendary] Somewhere right now, a five-foot woman is casting Haste II on someone who has not said thank you.',
    '[Gemma] No healing fee. No rebuff fee. She charged 50M gil once and considers your continued survival the receipt.',
    '[Gemma] Four songs. Four rolls. Full debuff suite. Total status immunity. She is not the hero of the story -- she is why the hero lived to the end of it.',
    '[Gemma] She does not fight. She keeps six debuffs on the enemy and four buffs on you, and asks only that you not stand in the AoE.',

    -- ---- The immunity list -----------------------------------------------
    '[Gemma] Immune to Sleep, Silence, Paralysis, Bind, Slow, Blind, Stun, Terror, Petrify, Addle, Poison, Plague, Aspir, Elegy, Requiem, and Dispel. Not immune to being underestimated -- she just enjoys it.',
    '[Legendary] Fun fact: Gemma cannot be silenced, slept, stunned, or paralyzed. The enemy keeps trying. The enemy keeps getting paralyzed instead.',

    -- ---- The rolls -------------------------------------------------------
    '[Legendary] Gemma is, technically, a Corsair. A tiny woman rolling dice against cosmic forces. The dice land on eleven. They would not dare do otherwise.',
    '[Gemma] Chaos Roll. Rogue\'s Roll. Allies\' Roll. Choral Roll. She runs the full table and has never busted. She is far too small to bust.',

    -- ---- Availability reminders (semi-helpful) ---------------------------
    '[Legendary] Gemma: songs, rolls, debuffs, magic bursts, raise, and a full status-cure suite -- all packed into someone who has to look UP at a Tarutaru. Sold by the Void Keeper in GM Home. 50M gil. Worth every coin.',
    '[Legendary] The Void Keeper in GM Home sells a five-foot woman who will personally keep your party alive. You have been informed. She is waiting. She is not impressed yet.',
}

m:addOverride('xi.player.onZoneIn', function(player, prevZone)
    super(player, prevZone)

    -- Piggyback on any zoning player as the broadcast vehicle.
    -- Only one message fires per QUIP_INTERVAL_SEC regardless of how
    -- many players zone simultaneously.
    local now = GetSystemTime()
    if now - lastQuipTime < QUIP_INTERVAL_SEC then return end
    lastQuipTime = now

    local quip = GEMMA_QUIPS[math.random(#GEMMA_QUIPS)]
    player:printToArea(quip, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)
end)

return m
