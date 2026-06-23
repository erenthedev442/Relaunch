-----------------------------------
-- AoE Weapon Skill
--
-- Players designate one WS to splash damage to enemies within 10y of primary target.
-- Unlock + upgrade at the Rupture Sage NPC in GM Home (x=9, z=-35).
-- Choose WS once via !aoews <wsname> after unlock (permanent, no swapping).
--
-- CharVars:
--   AoEWSID  (int): WS ID of chosen WS (0 = not yet chosen)
--   AoEWSPct (int): current splash % (0 = not unlocked, 50/60/.../100)
--
-- Cost ladder (each step 10% cheaper than the last):
--   Unlock   50%: 500M gil / 20000 Paragon Points / 20000 Infamy
--   -> 60%:  450M / 18000 / 18000
--   -> 70%:  400M / 16000 / 16000
--   -> 80%:  350M / 14000 / 14000
--   -> 90%:  300M / 12000 / 12000
--   -> 100%: 250M / 10000 / 10000
-----------------------------------
require('modules/module_utils')
require('scripts/enum/weaponskill')

local m   = Module:new('aoe_weaponskill')
local SYS = xi.msg.channel.SYSTEM_3

local AoE_RADIUS = 10
local BASE       = { gil = 500000000, pp = 20000, infamy = 20000 }

-- tier = number of purchases completed (0 = nothing bought yet)
local function getTier(pct)
    if pct <= 0 then return 0 end
    return math.floor((pct - 40) / 10)
end

local function getCost(tier)
    local f = 1.0 - tier * 0.1
    return {
        gil    = math.floor(BASE.gil    * f),
        pp     = math.floor(BASE.pp     * f),
        infamy = math.floor(BASE.infamy * f),
    }
end

local function wsDisplayName(id)
    for k, v in pairs(xi.weaponskill) do
        if v == id then
            return k:sub(1,1) .. k:sub(2):lower():gsub('_', ' ')
        end
    end
    return string.format('WS#%d', id)
end

--------------------------------------------------------------------
-- Combat hook: splash on WEAPONSKILL_USE
--------------------------------------------------------------------
m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    player:addListener('WEAPONSKILL_USE', 'AOE_WS_SPLASH', function(attacker, target, skill, tp, action, damage)
        local aoeWSID = attacker:getCharVar('AoEWSID')
        if aoeWSID == 0 or skill:getID() ~= aoeWSID then return end
        if not damage or damage <= 0 then return end

        local pct = attacker:getCharVar('AoEWSPct')
        if pct <= 0 then return end

        local splashDmg = math.floor(damage * pct / 100)
        if splashDmg <= 0 then return end

        local damType = attacker:getWeaponDamageType(xi.slot.MAIN)
        local enemies = attacker:getEntitiesInRange(
            target,
            xi.aoeType.ROUND,
            xi.aoeRadius.TARGET,
            AoE_RADIUS,
            0,
            xi.targetType.ENEMY
        )
        for _, enemy in ipairs(enemies) do
            if not enemy:isDead() and enemy:getID() ~= target:getID() then
                enemy:takeDamage(splashDmg, attacker, xi.attackType.PHYSICAL, damType)
            end
        end
    end)
end)

--------------------------------------------------------------------
-- NPC menu
--------------------------------------------------------------------
local function openMenu(player)
    local wsID   = player:getCharVar('AoEWSID')
    local pct    = player:getCharVar('AoEWSPct')
    local pp     = player:getCharVar('Paragon_Points') or 0
    local infamy = player:getCharVar('Infamy') or 0
    local gil    = player:getGil()

    if pct == 0 then
        player:printToPlayer('[Rupture Sage] No AoE WS unlocked yet.', SYS)
    elseif wsID == 0 then
        player:printToPlayer(string.format('[Rupture Sage] Unlocked (%d%% splash) — use !aoews <wsname> in-game to lock in your WS.', pct), SYS)
    else
        player:printToPlayer(string.format('[Rupture Sage] AoE WS: %s at %d%% splash.', wsDisplayName(wsID), pct), SYS)
    end
    player:printToPlayer(string.format('  Gil: %dM  |  Paragon: %d  |  Infamy: %d',
        math.floor(gil / 1000000), pp, infamy), SYS)

    local options = {}

    if pct == 0 then
        local c    = getCost(0)
        local gilM = math.floor(c.gil / 1000000)
        local ppK  = math.floor(c.pp / 1000)
        local infK = math.floor(c.infamy / 1000)
        options[#options + 1] = {
            string.format('Unlock 50%% (%dM/%dk PP/%dk Inf)', gilM, ppK, infK),
            function(p)
                local c2 = getCost(0)
                if p:getGil() < c2.gil then
                    p:printToPlayer(string.format('[Rupture Sage] Need %dM gil (you have %dM).', math.floor(c2.gil/1000000), math.floor(p:getGil()/1000000)), SYS)
                elseif (p:getCharVar('Paragon_Points') or 0) < c2.pp then
                    p:printToPlayer(string.format('[Rupture Sage] Need %d Paragon Points (you have %d).', c2.pp, p:getCharVar('Paragon_Points') or 0), SYS)
                elseif (p:getCharVar('Infamy') or 0) < c2.infamy then
                    p:printToPlayer(string.format('[Rupture Sage] Need %d Infamy (you have %d).', c2.infamy, p:getCharVar('Infamy') or 0), SYS)
                else
                    p:delGil(c2.gil)
                    p:setCharVar('Paragon_Points', (p:getCharVar('Paragon_Points') or 0) - c2.pp)
                    p:setCharVar('Infamy', (p:getCharVar('Infamy') or 0) - c2.infamy)
                    p:setCharVar('AoEWSPct', 50)
                    p:printToPlayer('[Rupture Sage] AoE WS unlocked at 50% splash! Now use !aoews <wsname> to permanently bind your weapon skill.', SYS)
                end
            end,
        }
    elseif pct < 100 then
        local tier   = getTier(pct)
        local c      = getCost(tier)
        local newPct = pct + 10
        local gilM   = math.floor(c.gil / 1000000)
        local ppK    = math.floor(c.pp / 1000)
        local infK   = math.floor(c.infamy / 1000)
        options[#options + 1] = {
            string.format('Upgrade %d->%d%% (%dM/%dkPP/%dk Inf)', pct, newPct, gilM, ppK, infK),
            function(p)
                local curPct  = p:getCharVar('AoEWSPct')
                local curTier = getTier(curPct)
                local c2      = getCost(curTier)
                if p:getGil() < c2.gil then
                    p:printToPlayer(string.format('[Rupture Sage] Need %dM gil (you have %dM).', math.floor(c2.gil/1000000), math.floor(p:getGil()/1000000)), SYS)
                elseif (p:getCharVar('Paragon_Points') or 0) < c2.pp then
                    p:printToPlayer(string.format('[Rupture Sage] Need %d Paragon Points (you have %d).', c2.pp, p:getCharVar('Paragon_Points') or 0), SYS)
                elseif (p:getCharVar('Infamy') or 0) < c2.infamy then
                    p:printToPlayer(string.format('[Rupture Sage] Need %d Infamy (you have %d).', c2.infamy, p:getCharVar('Infamy') or 0), SYS)
                else
                    p:delGil(c2.gil)
                    p:setCharVar('Paragon_Points', (p:getCharVar('Paragon_Points') or 0) - c2.pp)
                    p:setCharVar('Infamy', (p:getCharVar('Infamy') or 0) - c2.infamy)
                    p:setCharVar('AoEWSPct', curPct + 10)
                    p:printToPlayer(string.format('[Rupture Sage] AoE WS upgraded to %d%% splash!', curPct + 10), SYS)
                end
            end,
        }
    else
        options[#options + 1] = { 'Fully Upgraded (100%)', function(p)
            p:printToPlayer('[Rupture Sage] Your AoE WS is at maximum power.', SYS)
        end }
    end

    options[#options + 1] = { 'About', function(p)
        p:printToPlayer('[Rupture Sage] Your chosen WS splashes enemies within 10y of its primary target.', SYS)
        p:printToPlayer('[Rupture Sage] Splash % is a fraction of the primary hit. Bind your WS once with !aoews <wsname>.', SYS)
    end }
    options[#options + 1] = { 'Close', function(p) end }

    player:customMenu({ title = 'Rupture Sage', options = options })
end

--------------------------------------------------------------------
-- GM Home NPC
--------------------------------------------------------------------
m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)
    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Rupture_Sage',
        packetName = string.format('%sRupture Sage', xi.icon.SWORD),
        look       = 2419,
        x          = 9.000,
        y          = 0.000,
        z          = -35.000,
        rotation   = 128,
        widescan   = 1,
        onTrigger  = function(player, npc)
            player:timer(30, function(p) openMenu(p) end)
        end,
    })
end)

return m
