-----------------------------------
-- maat_infamy_fight.lua
-- Custom post-T4 Maat challenge ("Maat's Echo").
--
-- Entry NPC: Ru'Lude Gardens (zone 243), near the original Maat NPC.
-- Token: Echo's Testimony (key item). The client DAT has no name for it, so
-- every player-facing line prints "Echo's Testimony" ourselves.
--
-- Flow:
--   1. Talk to Maat's Echo. Pay 150 Infamy, receive Echo's Testimony.
--   2. Warp to Palborough Mines at the Waughroon zone line -- not into the fight.
--   3. Zone into the shrine lobby (burning circle, no Maat, no aggro).
--   4. Use the KI at BC_Entrance to enter a private battlefield.
--   5. Maat stands in the ring and does not engage until you attack or walk
--      onto him (retail mixin: 8 yalms). Buff / summon first.
--   6. This fight only: 2 companion slots. Fellow counts. 2 trusts, or
--      1 trust + Fellow.
--
-- Rewards (unchanged): first win unlocks T5 augments (Maat_Kills), 25% Maat's
-- Cap, 0.5% Prime voucher if PW_Trial3_Done == 0.
--
-- Aeonic Maat (aeonic_maat_trials.lua) is a separate NPC and is not touched.
--
-- Battlefield id 4230 sits after HTBF (4000-4220). Menu index 19 is the unused
-- Palborough Project slot in the Waughroon DAT (retail uses 0-18 and 21).
-- Index 22 does not show a selectable row on this client. Custom battlefield
-- ids are not in the DAT, so we warp into the ring ourselves (HTBF workaround).
--
-- SQL: modules/custom/sql/maats_echo_bcnm_records.sql must be applied
-- (deploy applies modules/custom/sql/*.sql). Map restart after Lua changes.
-----------------------------------
require('modules/module_utils')
require('scripts/zones/RuLude_Gardens/Zone')
require('scripts/zones/Waughroon_Shrine/Zone')

local mechanics = require('modules/custom/lua/mob_mechanics_library')

local m = Module:new('maat_infamy_fight')

local SYS = xi.msg.channel.SYSTEM_3

m.BATTLEFIELD_ID = 4230
m.MENU_INDEX     = 19 -- client DAT: "The Palborough Project" (unused retail slot)
m.COMPANION_CAP  = 2
m.INFAMY_COST    = 150
m.KI_NAME        = "Echo's Testimony"

-- Post-T4 mechanics. Private challenger fight, after Rank 4 Hunts / Divergence
-- / Wave Master Insane and before T5 augments.
local MAAT_MECH_CFG =
{
    name = 'Maat',

    enrage =
    {
        sec   = 240,
        att   = 3000,
        haste = 150,
        msg   = "You haven't proven yourself yet. Witness TRUE power!",
    },

    stance =
    {
        startHpp  = 100,
        periodSec = 18,
        stances   =
        {
            {
                mods = { [xi.mod.DMGPHYS] = -3000, [xi.mod.DMGMAGIC] = 0 },
                msg  = 'Maat fortifies his body against weapons -- unleash your magic!',
            },
            {
                mods = { [xi.mod.DMGPHYS] = 0, [xi.mod.DMGMAGIC] = -3000 },
                msg  = 'Maat channels Chainspell -- steel cuts deeper than spells now!',
            },
        },
    },

    aoe =
    {
        periodSec = 16,
        dmgPct    = 12,
        msg       = 'Maat releases a burst of concentrated aura!',
    },

    cc =
    {
        periodSec = 30,
        effect    = xi.effect.TERROR,
        power     = 1,
        dur       = 3,
        msg       = "Maat's presence overwhelms you!",
    },

    drain =
    {
        periodSec = 12,
        healPct   = 0.25,
    },

    phases =
    {
        { hp = 50, action = 'fury',   att = 1800, haste = 80,
          msg = 'Maat cries out -- his speed and power surge!' },
        { hp = 25, action = 'nuke',   dmgPct = 25,
          msg = 'Maat unleashes Chainspell -- brace yourself!' },
        { hp = 15, action = 'dispel', count = 2,
          msg = 'Maat tears your enhancements away!' },
    },

    doom =
    {
        startHpp = 12,
        dur      = 30,
        msg      = 'Maat marks you for oblivion -- end this NOW!',
    },
}

local CRIT_TOKEN_ID = 15194 -- Maat's Cap (retail Rare/EX)
local DROP_CHANCE   = 0.25
-- Echo sits beside H4 progression, well before the Lv150 Prime ceiling. Hunt
-- ranks preserve Lv99 and layer difficulty through stat overlays, so Echo
-- follows that same Lv99 baseline rather than the old endgame Lv175 value.
local MAAT_LEVEL    = 99
local MAAT_HP       = 7000000
local MAAT_MODS     =
{
    [xi.mod.DEF]           = 2000,
    [xi.mod.ATT]           = 8500,
    [xi.mod.ACC]           = 2200,
    [xi.mod.EVASION]       = 800,
    [xi.mod.MATT]          = 1500,
    [xi.mod.MACC]          = 1800,
    [xi.mod.MEVA]          = 1000,
    [xi.mod.MDEF]          = 900,
    [xi.mod.STR]           = 450,
    [xi.mod.INT]           = 450,
    [xi.mod.DOUBLE_ATTACK] = 18,
    [xi.mod.TRIPLE_ATTACK] = 5,
    [xi.mod.HASTE_GEAR]    = 300,
    [xi.mod.REGEN]         = 120,
}

-- Palborough Mines side of the shrine zone line (sql/zonelines.sql 808465530).
local PALBOROUGH_X, PALBOROUGH_Y, PALBOROUGH_Z, PALBOROUGH_R = 114.483, -41.944, -140.014, 128

-- Official BCNM entry tiles (documentation/BCNM_entrance_coord_and_offsets.txt).
-- Custom battlefield ids are not in the client DAT, so we setPos here on enter.
local ENTRY_POS_BY_AREA =
{
    [1] = { -262.139,  60.3048, -139.863, 0 },
    [2] = {  -61.865,   0.3048,   20.101, 0 },
    [3] = {  138.085, -59.6952,  140.083, 0 },
}

-- Echo NPC: a step beside retail Maat (8, 3, 118). !maat / !warp stay here.
local NPC_X, NPC_Y, NPC_Z, NPC_ROT = 12.0, 3.0, 118.0, 128

local function echoKi()
    return xi.ki.ECHOS_TESTIMONY
end

local function say(player, text)
    player:printToPlayer(text, SYS)
end

function m.isEchoBattlefield(battlefield)
    return battlefield ~= nil and battlefield:getID() == m.BATTLEFIELD_ID
end

function m.isInEchoFight(player)
    if not player then
        return false
    end

    local ok, battlefield = pcall(function()
        return player:getBattlefield()
    end)
    return ok and m.isEchoBattlefield(battlefield)
end

-- Trusts and the Fellow each consume one of the two Echo slots.
function m.companionSlots(player)
    local slots = 0
    local ok, party = pcall(function()
        return player:getPartyWithTrusts()
    end)
    if not ok or not party then
        return 0
    end

    for _, member in pairs(party) do
        if member:getObjType() == xi.objType.TRUST then
            slots = slots + 1
        end
    end

    return slots
end

function m.enforceCompanionCap(player)
    local trusts = {}
    local fellow = nil
    local ok, party = pcall(function()
        return player:getPartyWithTrusts()
    end)
    if not ok or not party then
        return
    end

    for _, member in pairs(party) do
        if member:getObjType() == xi.objType.TRUST then
            if member:getLocalVar('fellowApplied') == 1 then
                fellow = member
            else
                trusts[#trusts + 1] = member
            end
        end
    end

    local used = #trusts + (fellow and 1 or 0)
    if used <= m.COMPANION_CAP then
        return
    end

    local keepTrusts = fellow and (m.COMPANION_CAP - 1) or m.COMPANION_CAP
    for i = keepTrusts + 1, #trusts do
        pcall(function()
            player:despawnTrust(trusts[i])
        end)
    end

    say(player, "[Maat] This echo allows only two companions. Extra alter egos were dismissed.")
end

function m.applyRewards(player, elapsed)
    local kills = (player:getCharVar('Maat_Kills') or 0) + 1
    player:setCharVar('Maat_Kills', kills)

    if kills == 1 then
        say(player, 'Maat acknowledges your mastery! Tier 5 augment rolls are now unlocked at the Augment Moogle.')
    end

    if elapsed and elapsed > 0 then
        local best = player:getCharVar('Maat_Best_Time') or 0
        if best == 0 or elapsed < best then
            player:setCharVar('Maat_Best_Time', elapsed)
        end
    end

    if math.random() < DROP_CHANCE then
        if player:addItem(CRIT_TOKEN_ID, 1) then
            say(player, "Maat relinquishes his Cap! Bring Maat's Cap to the Augment Moogle for a guaranteed critical augment.")
        else
            say(player, "Maat offered his Cap, but you couldn't carry it (inventory full, or you already hold one).")
        end
    end

    if (player:getCharVar('PW_Trial3_Done') or 0) == 0 and math.random() < 0.005 then
        pcall(function()
            require('modules/custom/lua/prime_voucher_reward').award(player, 1, 'Maat')
        end)
    end
end

local function scaleEchoMaat(mob, ownerName)
    -- Retail Shattering Stars yields at 20% HP and on THF steal. This fight
    -- is a full kill of the post-T4 profile, so strip those listeners.
    pcall(function()
        mob:removeListener('MAAT_CTICK')
        mob:removeListener('MAAT_ITEM_STOLEN')
    end)

    if mob:getLocalVar('MaatEchoScaled') == 1 then
        return
    end
    mob:setLocalVar('MaatEchoScaled', 1)

    mob:setMobLevel(MAAT_LEVEL)
    mob:setMobMod(xi.mobMod.NO_CAPACITY_POINTS, 1)
    mob:setAggressive(false)
    mob:setLocalVar('MaatEcho', 1)
    mob:setLocalVar('maatStartTime', 0)

    for mod, val in pairs(MAAT_MODS) do
        mob:addMod(mod, val)
    end
    mob:setMaxHP(MAAT_HP)
    mob:setHP(MAAT_HP)

    mechanics.attach(mob, MAAT_MECH_CFG, ownerName)

    mob:addListener('ENGAGE', 'ECHO_ENGAGE', function(engaged)
        if engaged:getLocalVar('maatStartTime') == 0 then
            local now = os.time()
            engaged:setLocalVar('maatStartTime', now)
            local battlefield = engaged:getBattlefield()
            if battlefield and battlefield:getLocalVar('maatStartTime') == 0 then
                battlefield:setLocalVar('maatStartTime', now)
            end
        end
    end)

    -- The retail Maat mixin announces proximity but does not itself create
    -- enmity. Echo is passive, so explicitly engage only this battlefield's
    -- owner once they walk within 8 yalms.
    mob:addListener('ROAM_TICK', 'ECHO_PROXIMITY_ENGAGE', function(roaming)
        if roaming:isEngaged() or not ownerName then
            return
        end

        local owner = GetPlayerByName(ownerName)
        local ownerBattlefield = owner and owner:getBattlefield() or nil
        if
            owner and
            ownerBattlefield and
            ownerBattlefield:getID() == m.BATTLEFIELD_ID and
            ownerBattlefield:getArea() == roaming:getBattlefield():getArea() and
            owner:getHP() > 0 and
            roaming:checkDistance(owner) < 8
        then
            roaming:updateClaim(owner)
            roaming:addEnmity(owner, 30000, 30000)
        end
    end)

    mob:addListener('COMBAT_TICK', 'ECHO_MECH_TICK', function(ticking)
        mechanics.tick(ticking, ticking:getTarget())
    end)

    mob:addListener('DEATH', 'ECHO_MECH_CLEANUP', function(dead)
        mechanics.cleanup(dead)
    end)
end

local function warpToPalborough(player)
    player:setPos(PALBOROUGH_X, PALBOROUGH_Y, PALBOROUGH_Z, PALBOROUGH_R, xi.zone.PALBOROUGH_MINES)
end

local function grantTestimonyAndWarp(player)
    local infamy = player:getCharVar('Infamy') or 0
    if infamy < m.INFAMY_COST then
        say(player, string.format("[Maat] Entering Maat's arena costs %d Infamy. You have %d.", m.INFAMY_COST, infamy))
        return
    end

    if player:hasKeyItem(echoKi()) then
        say(player, string.format('[Maat] You already carry %s. The shrine still waits.', m.KI_NAME))
        warpToPalborough(player)
        return
    end

    player:setCharVar('Infamy', infamy - m.INFAMY_COST)
    player:addKeyItem(echoKi())
    say(player, string.format('[Maat] %d Infamy paid. You obtain %s.', m.INFAMY_COST, m.KI_NAME))
    say(player, '[Maat] The burning circle lies beyond Palborough Mines. Two companions. Make them count.')
    warpToPalborough(player)
end

local function showEchoMenu(player)
    player:timer(30, function(p)
        if p:hasKeyItem(echoKi()) then
            say(p, string.format('[Maat] You already carry %s. The shrine still waits.', m.KI_NAME))
            p:customMenu({
                title = "Maat's Echo",
                options =
                {
                    { 'Return to Palborough', function(pp) warpToPalborough(pp) end },
                    { 'Not yet', function() end },
                },
            })
            return
        end

        local infamy = p:getCharVar('Infamy') or 0
        if infamy < m.INFAMY_COST then
            say(p, string.format("[Maat] So... you've climbed far enough to stand before my echo."))
            say(p, string.format('[Maat] %d Infamy. You have %d. Come back when you have earned it.', m.INFAMY_COST, infamy))
            return
        end

        say(p, "[Maat] So... you've climbed far enough to stand before my echo.")
        say(p, string.format('[Maat] %d Infamy. I will give you %s. Take it to the burning circle in Waughroon Shrine.', m.INFAMY_COST, m.KI_NAME))
        say(p, '[Maat] Two companions. No more. Prove you still remember how to fight.')
        p:customMenu({
            title = "Maat's Echo",
            options =
            {
                { string.format('I accept (%d Infamy)', m.INFAMY_COST), function(pp) grantTestimonyAndWarp(pp) end },
                { 'Not yet', function() end },
            },
        })
    end)
end

local function installHooks()
    if xi.trust and xi.trust.checkBattlefieldTrustCount and not xi.trust._echoTrustPatched then
        xi.trust._echoTrustPatched = true
        local origCheck = xi.trust.checkBattlefieldTrustCount
        xi.trust.checkBattlefieldTrustCount = function(caster)
            if m.isInEchoFight(caster) then
                return m.companionSlots(caster) < m.COMPANION_CAP
            end

            return origCheck(caster)
        end
    end

    if xi.battlefield and xi.battlefield.getBattlefieldOptions and not xi.battlefield._echoLegendPatched then
        xi.battlefield._echoLegendPatched = true
        local origOptions = xi.battlefield.getBattlefieldOptions
        xi.battlefield.getBattlefieldOptions = function(player, npc, trade)
            local options = origOptions(player, npc, trade)
            if
                not trade and
                player:getZoneID() == xi.zone.WAUGHROON_SHRINE and
                npc:getName() == 'BC_Entrance' and
                player:hasKeyItem(echoKi())
            then
                if bit.band(options, bit.lshift(1, m.MENU_INDEX)) ~= 0 then
                    say(player, "[Maat] Pick 'The Palborough Project' -- that unused row is Maat's Echo. Two companions. He waits until you strike or close in.")
                else
                    say(player, "[Maat] Echo's Testimony is ready, but the circle has not listed the fight. The shrine needs a map restart.")
                end
            end

            return options
        end
    end
end

function m.registerBattlefield()
    installHooks()

    local waughroonID = zones[xi.zone.WAUGHROON_SHRINE]
    local content = Battlefield:new({
        zoneId           = xi.zone.WAUGHROON_SHRINE,
        battlefieldId    = m.BATTLEFIELD_ID,
        maxPlayers       = 1,
        timeLimit        = utils.minutes(20),
        index            = m.MENU_INDEX,
        entryNpc         = 'BC_Entrance',
        exitNpc          = 'Burning_Circle',
        allowSubjob      = true,
        allowTrusts      = true,
        canLoseExp       = false,
        requiredKeyItems = { echoKi() },
    })

    content.groups =
    {
        {
            mobIds =
            {
                { waughroonID.mob.MAAT     },
                { waughroonID.mob.MAAT + 1 },
                { waughroonID.mob.MAAT + 2 },
            },

            allDeath = function(battlefield)
                battlefield:setStatus(xi.battlefield.status.WON)
            end,
        },
    }

    function content:setupBattlefield(battlefield)
        battlefield:setLocalVar('MaatEcho', 1)

        local initiatorId = battlefield:getInitiator()
        local owner = initiatorId and GetPlayerByID(initiatorId) or nil
        local ownerName = owner and owner:getName() or nil

        for _, mob in ipairs(battlefield:getMobs(true, true)) do
            pcall(function()
                scaleEchoMaat(mob, ownerName)
            end)
        end
    end

    function content:onBattlefieldEnter(player, battlefield)
        Battlefield.onBattlefieldEnter(self, player, battlefield)
        m.enforceCompanionCap(player)

        local entryPos = ENTRY_POS_BY_AREA[battlefield:getArea()]
        if entryPos then
            pcall(function()
                player:setPos(entryPos[1], entryPos[2], entryPos[3], entryPos[4] or 0)
            end)
        end

        say(player, string.format("[Maat] %s fades as you step into the ring. Two companions. He will not move until you do.", m.KI_NAME))
    end

    function content:onEventFinishWin(player)
        local battlefield = player:getBattlefield()
        if battlefield then
            local latch = 'echoPaid_' .. player:getID()
            if battlefield:getLocalVar(latch) == 1 then
                return
            end

            battlefield:setLocalVar(latch, 1)
        end

        local elapsed = 0
        if battlefield then
            local started = battlefield:getLocalVar('maatStartTime')
            if started and started > 0 then
                elapsed = os.time() - started
            end
        end

        m.applyRewards(player, elapsed)
    end

    return content:register()
end

m:addOverride('xi.zones.RuLude_Gardens.Zone.onInitialize', function(zone)
    super(zone)

    local maatEcho = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Maat_Echo',
        packetName = string.format("%sMaat's Echo", xi.icon.STAR_LARGE),
        look       = 3037, -- Trust Maat. Distinct from Aeonic Maat (3064) and retail Maat (126).
        x          = NPC_X,
        y          = NPC_Y,
        z          = NPC_Z,
        rotation   = NPC_ROT,
        widescan   = 1,

        onTrigger = function(player)
            showEchoMenu(player)
        end,
    })
    utils.unused(maatEcho)
end)

-- Battlefield scripts can miss a hot-reload. Register from the shrine itself
-- if the Echo BCNM is not already in contents.
m:addOverride('xi.zones.Waughroon_Shrine.Zone.onInitialize', function(zone)
    super(zone)
    if not (xi.battlefield.contents and xi.battlefield.contents[m.BATTLEFIELD_ID]) then
        pcall(function()
            m.registerBattlefield()
        end)
    end
end)

pcall(installHooks)

return m
