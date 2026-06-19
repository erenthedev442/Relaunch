-----------------------------------
-- PrimeArmory_NPC.lua
-- "Prime Armory" -- a GM Home NPC where players forge a Prime Weapon by
-- completing the four Prime Weapon Trials:
--
--   Trial 1 (PW_Trial1_Done)  10 Shadow Fragments from Nightmare dungeons
--   Trial 2 (PW_Trial2_Done)  Clear floor 50 of the Endless Tower
--   Trial 3 (PW_Trial3_Done)  Earn kill credit on 3 Weekly World Bosses
--   Trial 4 (PW_Trial4_Done)  Defeat any Weapon Guardian (Job Mastery)
--
-- Once all four are complete the player may claim ONE Prime weapon of their
-- choice. Claiming sets PW_WeaponClaimed = item_id (0 = none yet).
--
-- Each Prime weapon's ADDS_WEAPONSKILL mod unlocks its Prime weapon skill the
-- moment it is equipped (wired in modules/custom/sql/prime_weapons_gear.sql):
--   Prime Fists      -> Dragon Blow        Mpu Gandring -> Merciless Strike
--   Varga Purnikawa  -> Maru Kala          Naegling     -> Savage Blade
--   Prime Sword      -> Imperator          Prime Maul   -> Dagda
--   Prime Staff      -> Oshala
--
-- Zone: GM Home (zone 210).
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')

local m = Module:new('prime_armory')

local TRIALS =
{
    { var = 'PW_Trial1_Done', label = 'Trial 1', desc = '10 Shadow Fragments (Nightmare dungeons)' },
    { var = 'PW_Trial2_Done', label = 'Trial 2', desc = 'Endless Tower floor 50' },
    { var = 'PW_Trial3_Done', label = 'Trial 3', desc = '3 Weekly World Boss kills' },
    { var = 'PW_Trial4_Done', label = 'Trial 4', desc = 'Weapon Guardian defeated (Job Mastery)' },
}

local WEAPONS =
{
    { id = 21531, name = 'Prime Fists',     ws = 'Dragon Blow',      info = 'Hand-to-Hand. STR/DEX, Acc, Att, Store TP, Double Attack.' },
    { id = 21534, name = 'Varga Purnikawa', ws = 'Maru Kala',        info = 'Hand-to-Hand. STR/DEX, Acc, Att, Store TP, Double Attack.' },
    { id = 21589, name = 'Mpu Gandring',    ws = 'Merciless Strike',  info = 'Dagger. DEX/AGI, Acc, Att, Store TP, Double Attack.' },
    { id = 21621, name = 'Naegling',        ws = 'Savage Blade',     info = 'Sword. STR/DEX/INT/MND, Acc/Att, MAcc/MAtt, Magic Dmg +217, Savage Blade DMG+15%.' },
    { id = 21642, name = 'Prime Sword',     ws = 'Imperator',        info = 'Sword. STR/DEX/MND, Acc, Att, Store TP, Double Attack.' },
    { id = 21999, name = 'Prime Maul',      ws = 'Dagda',            info = 'Club. STR/MND, Acc, Att, Store TP, Double Attack.' },
    { id = 22102, name = 'Prime Staff',     ws = 'Oshala',           info = 'Staff. INT/MND, Magic Acc/Att, Magic Dmg, Acc, Att.' },
    { id = 21781, name = 'Prime Great Axe', ws = 'Disaster',         info = 'Great Axe. STR/VIT, Acc, Att, Store TP, Double Attack.' },
    { id = 21833, name = 'Prime Scythe',    ws = 'Origin',           info = 'Scythe. STR/INT, Acc, Att, Store TP, Double Attack. WS drains HP/MP.' },
    { id = 21887, name = 'Prime Lance',     ws = 'Diarmuid',         info = 'Polearm. STR/VIT, Acc, Att, Store TP, Double Attack.' },
    { id = 22155, name = 'Prime Bow',       ws = 'Sarv',             info = 'Archery. AGI/STR, Ranged Acc/Att, Store TP, Rapid Shot. Needs arrows.' },
    { id = 22159, name = 'Prime Gun',       ws = 'Terminus',         info = 'Marksmanship. AGI/DEX, Ranged Acc/Att, Store TP, Rapid Shot. Needs bullets.' },
}

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    local function sendMenu(player, menu)
        local snapshot = { title = menu.title, options = menu.options }
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local showMain

    -- customMenu cap ~150 bytes across title + ALL labels. 4 items/page keeps
    -- every page under the cap (worst case: 18 title + 107 labels = 125 bytes).
    local PAGE_SIZE = 4

    -----------------------------------
    -- Returns true if all four trials are complete.
    -----------------------------------
    local function trialsComplete(player)
        for _, t in ipairs(TRIALS) do
            if (player:getCharVar(t.var) or 0) == 0 then return false end
        end
        return true
    end

    -----------------------------------
    -- Print trial status to the player (used on first talk when incomplete).
    -----------------------------------
    local function printTrialStatus(player)
        player:printToPlayer('[Prime Armory] Complete all four trials to forge a Prime Weapon:', xi.msg.channel.SYSTEM_3)
        for _, t in ipairs(TRIALS) do
            local done  = (player:getCharVar(t.var) or 0) == 1
            local icon  = done and '[+]' or '[ ]'
            player:printToPlayer(string.format('  %s %s — %s', icon, t.label, t.desc), xi.msg.channel.SYSTEM_3)
        end
    end

    -----------------------------------
    -- Forge the selected weapon (one per player, ever).
    -----------------------------------
    local function claim(player, weapon)
        -- Guard: all trials must still be complete (in case a GM cleared them).
        if not trialsComplete(player) then
            player:printToPlayer('[Prime Armory] Trial requirement no longer met. Cannot forge.', xi.msg.channel.SYSTEM_3)
            return
        end
        -- Guard: one prime weapon per player.
        local alreadyClaimed = player:getCharVar('PW_WeaponClaimed') or 0
        if alreadyClaimed ~= 0 then
            -- Find the weapon name for the message.
            for _, w in ipairs(WEAPONS) do
                if w.id == alreadyClaimed then
                    player:printToPlayer(string.format(
                        '[Prime Armory] You already forged %s. Each hero may forge one Prime Weapon. Kupo!', w.name),
                        xi.msg.channel.SYSTEM_3)
                    return
                end
            end
            player:printToPlayer('[Prime Armory] You have already forged a Prime Weapon. Kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        -- Inventory check.
        if player:getFreeSlotsCount() == 0 then
            player:printToPlayer('[Prime Armory] Your inventory is full — free a slot first! Kupo!', xi.msg.channel.SYSTEM_3)
            return
        end
        -- Forge!
        player:setCharVar('PW_WeaponClaimed', weapon.id)
        player:addItem({ id = weapon.id, quantity = 1 })
        player:printToPlayer(string.format(
            '[Prime Armory] %s has been forged! Equip it to unlock the weapon skill %s. Kupo!',
            weapon.name, weapon.ws), xi.msg.channel.SYSTEM_3)
    end

    -----------------------------------
    -- Per-weapon detail + confirm menu.
    -----------------------------------
    local function showWeapon(player, weapon, page)
        player:printToPlayer(string.format('[Prime Armory] %s — Weapon Skill: %s', weapon.name, weapon.ws), xi.msg.channel.SYSTEM_3)
        player:printToPlayer('  ' .. weapon.info, xi.msg.channel.SYSTEM_3)
        local claimed = player:getCharVar('PW_WeaponClaimed') or 0
        if claimed ~= 0 then
            player:printToPlayer('[Prime Armory] You have already forged a Prime Weapon. Each hero gets one.', xi.msg.channel.SYSTEM_3)
        end

        sendMenu(player, {
            title   = weapon.name,
            options =
            {
                { 'Forge this weapon', function(p) claim(p, weapon) end },
                { '<< Back',           function(p) showMain(p, page) end },
            },
        })
    end

    -----------------------------------
    -- Paginated weapon browse menu.
    -----------------------------------
    showMain = function(player, page)
        page = page or 1
        local totalPages = math.ceil(#WEAPONS / PAGE_SIZE)
        local startIdx   = (page - 1) * PAGE_SIZE + 1
        local endIdx     = math.min(startIdx + PAGE_SIZE - 1, #WEAPONS)

        local options = {}
        for i = startIdx, endIdx do
            local weapon = WEAPONS[i]
            table.insert(options, {
                string.format('%s [%s]', weapon.name, weapon.ws),
                function(p) showWeapon(p, weapon, page) end,
            })
        end

        if page < totalPages then
            table.insert(options, { 'Next >>',  function(p) showMain(p, page + 1) end })
        end
        if page > 1 then
            table.insert(options, { '<< Prev',  function(p) showMain(p, page - 1) end })
        end

        local title = totalPages > 1
            and string.format('Prime Armory (%d/%d)', page, totalPages)
            or  'Prime Armory'
        sendMenu(player, { title = title, options = options })
    end

    -----------------------------------
    -- NPC entity.
    -----------------------------------
    zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'Prime_Armory',
        packetName = string.format('%sPrime Armory', xi.icon.STAR_LARGE),
        look       = 3000,
        x          = 0.000,
        y          =  0.000,
        z          = -20.000,
        rotation   =  128,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('[Prime Armory] Talk to me to forge your Prime Weapon, kupo!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            local claimed = player:getCharVar('PW_WeaponClaimed') or 0
            if claimed ~= 0 then
                for _, w in ipairs(WEAPONS) do
                    if w.id == claimed then
                        player:printToPlayer(string.format(
                            '[Prime Armory] You have forged %s. Each hero may forge one Prime Weapon. Kupo!', w.name),
                            xi.msg.channel.SYSTEM_3)
                        return
                    end
                end
            end

            if not trialsComplete(player) then
                printTrialStatus(player)
                return
            end

            -- All trials done and no weapon claimed yet — show the forge menu.
            player:printToPlayer('[Prime Armory] All four trials complete! Choose your Prime Weapon. Kupo!', xi.msg.channel.SYSTEM_3)
            showMain(player)
        end,
    })
end)

return m
