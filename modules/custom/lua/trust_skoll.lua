-----------------------------------
-- trust_skoll.lua
-- Void Keeper NPC in GM Home: the SINGLE source for all custom trusts.
-- Each trust is gated on trust collection progress and paid in gil.
--
--   Corvus   -> spell 902 : 40 trusts collected, 10M gil
--   Meat     -> spell 899 : 50 trusts collected, 10M gil
--   Gemma    -> spell 901 : 60 trusts collected, 10M gil
--   Cornelia -> spell 1002: full farmable roster (114), 50M gil
--   Matsui-P -> spell 1004 (Excenmille S slot): full farmable roster (114), 50M gil
--   Meat/Gemma/Corvus/Matsui/Cornelia are NOT part of catch-'em-all.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/Abdhaljs_Isle-Purgonorgo/Zone')
require('scripts/globals/combat/magic_aoe')

local m = Module:new('trust_skoll')

local TRUSTS =
{
    {
        spellId               = 902,
        name                  = 'Corvus',
        clientName            = 'Curilla',
        trustsRequired        = 40,
        gilCost               = 10000000,
        requireFullCollection = false,
        bindLabel             = 'Bind Corvus',
        boundMsg              = 'Corvus already shadows you. Cast "Curilla" from your Trust menu.',
        sealMsgs              = {
            'The covenant is sealed. The Black Arrow is yours.',
            'Look for "Curilla" in your Trust menu -- casting it calls Corvus.',
        },
    },
    {
        spellId               = 899,
        name                  = 'Meat',
        clientName            = 'Excenmille',
        trustsRequired        = 50,
        gilCost               = 10000000,
        requireFullCollection = false,
        bindLabel             = 'Bind Meat',
        boundMsg              = 'Meat already answers to you. Cast "Excenmille" from your Trust menu.',
        sealMsgs              = {
            'It is bound. The little wall is yours.',
            'Look for "Excenmille" in your Trust menu -- casting it raises Meat.',
        },
    },
    {
        spellId               = 901,
        name                  = 'Gemma',
        clientName            = 'Nanaa Mihgo',
        trustsRequired        = 60,
        gilCost               = 10000000,
        requireFullCollection = false,
        bindLabel             = 'Bind Gemma',
        boundMsg              = 'Gemma already stands with you. Cast "Nanaa Mihgo" from your Trust menu.',
        sealMsgs              = {
            'The covenant is sealed.',
            'Look for "Nanaa Mihgo" in your Trust menu -- casting it calls Gemma.',
        },
    },
    {
        spellId               = 1002,
        name                  = 'Cornelia',
        clientName            = 'Cornelia',
        gilCost               = 50000000,
        requireFullCollection = true,
        bindLabel             = 'Bind Cornelia',
        boundMsg              = 'Cornelia already marches with you.',
        sealMsgs              = {
            'Cornelia accepts your coin. Never give up.',
            'She will keep the party standing when the fight turns ugly.',
        },
    },
    {
        spellId               = 1004,
        name                  = 'Matsui-P',
        clientName            = 'Excenmille (S)',
        gilCost               = 50000000,
        requireFullCollection = true,
        bindLabel             = 'Bind Matsui-P',
        boundMsg              = 'Matsui-P is already bound to your service. Cast "Excenmille (S)" from your Trust menu.',
        sealMsgs              = {
            'Matsui-P cracks his knuckles. The cap is his problem now.',
            'Look for "Excenmille (S)" in your Trust menu -- casting it calls Matsui-P.',
        },
    },
}

local NPC_NAME = 'Void_Keeper'
local NPC_POS  = { x = 539.4993, y = -3.4665, z = 496.0069, rot = 218 }

local function formatGil(amount)
    if amount >= 1000000 then
        return string.format('%dM', amount / 1000000)
    end

    return tostring(amount)
end

local function gateLabel(t)
    if t.requireFullCollection then
        return string.format('%s ALL/%s', t.name, formatGil(t.gilCost))
    end

    return string.format('%s %d/%s', t.name, t.trustsRequired, formatGil(t.gilCost))
end

local function meetsGate(player, t)
    if t.requireFullCollection then
        return xi.trust.isCollectionComplete(player)
    end

    return xi.trust.countCollected(player) >= t.trustsRequired
end

local function gateMessage(player, t)
    if t.requireFullCollection then
        return string.format(
            '%s requires every trust in the roster (%d/%d collected).',
            t.name,
            xi.trust.countCollected(player),
            #xi.trust.collectionRoster)
    end

    return string.format(
        '%s requires %d trusts collected (%d/%d).',
        t.name,
        t.trustsRequired,
        xi.trust.countCollected(player),
        t.trustsRequired)
end

m:addOverride('xi.zones.Abdhaljs_Isle-Purgonorgo.Zone.onInitialize', function(zone)
    super(zone)

    local menu = { title = '', options = {} }

    local function trustOption(player, t)
        if player:hasSpell(t.spellId) then
            return {
                string.format('%s: owned', t.name),
                function(p)
                    p:printToPlayer(t.boundMsg, xi.msg.channel.SYSTEM_3)
                end,
            }
        end

        return {
            gateLabel(t),
            function(p)
                if p:hasSpell(t.spellId) then
                    p:printToPlayer(string.format('%s is already bound to you.', t.name), xi.msg.channel.SYSTEM_3)
                    return
                end

                if not meetsGate(p, t) then
                    p:printToPlayer(gateMessage(p, t), xi.msg.channel.SYSTEM_3)
                    return
                end

                if p:getGil() < t.gilCost then
                    p:printToPlayer(
                        string.format('%s costs %s gil (you have %d).', t.name, formatGil(t.gilCost), p:getGil()),
                        xi.msg.channel.SYSTEM_3)
                    return
                end

                p:delGil(t.gilCost)
                if xi.trustGrant and xi.trustGrant.grantSpell then
                    xi.trustGrant.grantSpell(p, t.spellId)
                else
                    p:addSpell(t.spellId)
                end

                local S = xi.msg.channel.SYSTEM_3
                for _, line in ipairs(t.sealMsgs) do
                    p:printToPlayer(line, S)
                end
            end,
        }
    end

    local function buildMenu(player)
        local options = {}

        table.insert(options, {
            'Who are you?',
            function(p)
                local S = xi.msg.channel.SYSTEM_3
                p:printToPlayer('I am what remains of an old covenant.', S)
                p:printToPlayer('Collect trusts. Return when you have earned the right.', S)
                p:printToPlayer('Corvus at forty. Meat at fifty. Gemma at sixty.', S)
                p:printToPlayer('Cornelia and Matsui-P wait for those who collect them all.', S)
            end,
        })

        for _, t in ipairs(TRUSTS) do
            table.insert(options, trustOption(player, t))
        end

        table.insert(options, {
            'Leave',
            function(p)
                p:printToPlayer('...', xi.msg.channel.SYSTEM_3)
            end,
        })

        menu.title   = 'Custom Trusts'
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local VoidKeeper = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = NPC_NAME,
        packetName = string.format('%sCustom Trusts', xi.icon.STAR_LARGE),
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
            player:printToPlayer(string.format(
                '[Custom Trusts]  Trusts collected: %d / %d  |  Gil: %d',
                xi.trust.countCollected(player),
                #xi.trust.collectionRoster,
                player:getGil()), xi.msg.channel.SYSTEM_3)
            buildMenu(player)
        end,
    })
    utils.unused(VoidKeeper)
end)

local GEMMA_SONG_RADIUS = 50

m:addOverride('xi.combat.magicAoE.calculateSongRadius', function(caster, spell)
    local base = super(caster, spell)
    if base > 0 and caster:getLocalVar('SKOLL_WIDE_AOE') > 0 then
        return math.max(base, GEMMA_SONG_RADIUS)
    end
    return base
end)

local QUIP_INTERVAL_SEC = 900
local lastQuipTime = 0

local GEMMA_QUIPS =
{
    '[Gemma] Small hands. Protectra V, Shellra V, Haste II, and a raise queued before you finish hitting the floor.',
    '[Relaunch] Gemma: songs, rolls, debuffs, raise -- sold by the Void Keeper after sixty trusts. Worth every coin.',
    '[Relaunch] The Void Keeper in GM Home sells a five-foot woman who will personally keep your party alive.',
}

m:addOverride('xi.player.onZoneIn', function(player, prevZone)
    super(player, prevZone)

    local now = GetSystemTime()
    if now - lastQuipTime < QUIP_INTERVAL_SEC then return end
    lastQuipTime = now

    local quip = GEMMA_QUIPS[math.random(#GEMMA_QUIPS)]
    player:printToArea(quip, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)
end)

return m
